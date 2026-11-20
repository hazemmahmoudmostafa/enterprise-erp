-- ERP Core Database - Migration 0005: inventory controls, movement ledger, reservations and lot/serial tracking.
CREATE TABLE IF NOT EXISTS inventory_lots (
  lot_id TEXT PRIMARY KEY,
  company_id TEXT NOT NULL REFERENCES companies(company_id),
  item_id TEXT NOT NULL REFERENCES items(item_id),
  lot_code TEXT NOT NULL,
  supplier_partner_id TEXT REFERENCES business_partners(partner_id),
  manufacture_date TEXT,
  expiry_date TEXT,
  status TEXT NOT NULL DEFAULT 'released' CHECK(status IN ('released','quarantine','expired','blocked')),
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  UNIQUE(company_id, item_id, lot_code)
);
CREATE INDEX IF NOT EXISTS idx_inventory_lots_expiry ON inventory_lots(expiry_date, status);
CREATE TABLE IF NOT EXISTS inventory_serials (
  serial_id TEXT PRIMARY KEY,
  company_id TEXT NOT NULL REFERENCES companies(company_id),
  item_id TEXT NOT NULL REFERENCES items(item_id),
  lot_id TEXT REFERENCES inventory_lots(lot_id),
  serial_number TEXT NOT NULL,
  current_warehouse_id TEXT REFERENCES warehouses(warehouse_id),
  current_location_id TEXT REFERENCES storage_locations(storage_location_id),
  status TEXT NOT NULL DEFAULT 'in_stock' CHECK(status IN ('in_stock','reserved','issued','in_transit','scrapped')),
  UNIQUE(company_id, item_id, serial_number)
);
CREATE TABLE IF NOT EXISTS inventory_transactions (
  inventory_transaction_id TEXT PRIMARY KEY,
  company_id TEXT NOT NULL REFERENCES companies(company_id),
  transaction_number TEXT NOT NULL,
  transaction_type TEXT NOT NULL CHECK(transaction_type IN ('receipt','issue','transfer','adjustment','return','production_receipt','production_issue')),
  transaction_date TEXT NOT NULL,
  source_module TEXT,
  source_document_type TEXT,
  source_document_id TEXT,
  status TEXT NOT NULL DEFAULT 'draft' CHECK(status IN ('draft','posted','cancelled')),
  posted_by TEXT REFERENCES users(user_id),
  posted_at TEXT,
  created_by TEXT REFERENCES users(user_id),
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  UNIQUE(company_id, transaction_number),
  UNIQUE(source_module, source_document_type, source_document_id)
);
CREATE TABLE IF NOT EXISTS inventory_transaction_lines (
  inventory_transaction_line_id TEXT PRIMARY KEY,
  inventory_transaction_id TEXT NOT NULL REFERENCES inventory_transactions(inventory_transaction_id) ON DELETE CASCADE,
  line_number INTEGER NOT NULL CHECK(line_number > 0),
  item_id TEXT NOT NULL REFERENCES items(item_id),
  from_warehouse_id TEXT REFERENCES warehouses(warehouse_id),
  from_location_id TEXT REFERENCES storage_locations(storage_location_id),
  to_warehouse_id TEXT REFERENCES warehouses(warehouse_id),
  to_location_id TEXT REFERENCES storage_locations(storage_location_id),
  lot_id TEXT REFERENCES inventory_lots(lot_id),
  serial_id TEXT REFERENCES inventory_serials(serial_id),
  quantity TEXT NOT NULL CHECK(CAST(quantity AS NUMERIC) > 0),
  uom_id TEXT NOT NULL REFERENCES units_of_measure(uom_id),
  unit_cost_minor INTEGER CHECK(unit_cost_minor >= 0),
  currency_code TEXT REFERENCES currencies(currency_code),
  line_value_minor INTEGER CHECK(line_value_minor >= 0),
  cost_center_id TEXT REFERENCES cost_centers(cost_center_id),
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  UNIQUE(inventory_transaction_id, line_number)
);
CREATE INDEX IF NOT EXISTS idx_inventory_lines_item ON inventory_transaction_lines(item_id, inventory_transaction_id);
CREATE INDEX IF NOT EXISTS idx_inventory_lines_from_location ON inventory_transaction_lines(from_warehouse_id, from_location_id);
CREATE INDEX IF NOT EXISTS idx_inventory_lines_to_location ON inventory_transaction_lines(to_warehouse_id, to_location_id);
-- Append-only stock ledger. Posted movements must not be edited or deleted; corrections are new movements.
CREATE TABLE IF NOT EXISTS inventory_ledger (
  inventory_ledger_id TEXT PRIMARY KEY,
  company_id TEXT NOT NULL REFERENCES companies(company_id),
  item_id TEXT NOT NULL REFERENCES items(item_id),
  warehouse_id TEXT NOT NULL REFERENCES warehouses(warehouse_id),
  storage_location_id TEXT REFERENCES storage_locations(storage_location_id),
  lot_id TEXT REFERENCES inventory_lots(lot_id),
  serial_id TEXT REFERENCES inventory_serials(serial_id),
  source_transaction_id TEXT NOT NULL REFERENCES inventory_transactions(inventory_transaction_id),
  source_line_id TEXT NOT NULL REFERENCES inventory_transaction_lines(inventory_transaction_line_id),
  movement_date TEXT NOT NULL,
  quantity_delta TEXT NOT NULL CHECK(CAST(quantity_delta AS NUMERIC) <> 0),
  value_delta_minor INTEGER NOT NULL,
  currency_code TEXT NOT NULL REFERENCES currencies(currency_code),
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  UNIQUE(source_line_id, warehouse_id, storage_location_id)
);
CREATE INDEX IF NOT EXISTS idx_inventory_ledger_item_date ON inventory_ledger(company_id, item_id, movement_date);
CREATE INDEX IF NOT EXISTS idx_inventory_ledger_location ON inventory_ledger(warehouse_id, storage_location_id, item_id);
CREATE TABLE IF NOT EXISTS inventory_balances (
  company_id TEXT NOT NULL REFERENCES companies(company_id),
  item_id TEXT NOT NULL REFERENCES items(item_id),
  warehouse_id TEXT NOT NULL REFERENCES warehouses(warehouse_id),
  storage_location_id TEXT REFERENCES storage_locations(storage_location_id),
  lot_id TEXT REFERENCES inventory_lots(lot_id),
  on_hand_quantity TEXT NOT NULL DEFAULT '0',
  reserved_quantity TEXT NOT NULL DEFAULT '0',
  available_quantity TEXT NOT NULL DEFAULT '0',
  inventory_value_minor INTEGER NOT NULL DEFAULT 0,
  currency_code TEXT NOT NULL REFERENCES currencies(currency_code),
  last_movement_at TEXT,
  updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  UNIQUE(company_id, item_id, warehouse_id, storage_location_id, lot_id)
);
CREATE INDEX IF NOT EXISTS idx_inventory_balances_item ON inventory_balances(company_id, item_id, warehouse_id);
CREATE TABLE IF NOT EXISTS stock_reservations (
  stock_reservation_id TEXT PRIMARY KEY,
  company_id TEXT NOT NULL REFERENCES companies(company_id),
  item_id TEXT NOT NULL REFERENCES items(item_id),
  warehouse_id TEXT NOT NULL REFERENCES warehouses(warehouse_id),
  storage_location_id TEXT REFERENCES storage_locations(storage_location_id),
  lot_id TEXT REFERENCES inventory_lots(lot_id),
  source_document_type TEXT NOT NULL,
  source_document_id TEXT NOT NULL,
  quantity TEXT NOT NULL CHECK(CAST(quantity AS NUMERIC) > 0),
  status TEXT NOT NULL DEFAULT 'active' CHECK(status IN ('active','fulfilled','released','cancelled')),
  reserved_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  released_at TEXT
);
CREATE INDEX IF NOT EXISTS idx_stock_reservations_active ON stock_reservations(company_id, item_id, warehouse_id, status);

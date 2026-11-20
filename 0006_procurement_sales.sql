-- ERP Core Database - Migration 0006: purchasing and sales document foundations.
CREATE TABLE IF NOT EXISTS purchase_requisitions (
  requisition_id TEXT PRIMARY KEY,
  company_id TEXT NOT NULL REFERENCES companies(company_id),
  branch_id TEXT REFERENCES branches(branch_id),
  requisition_number TEXT NOT NULL,
  requested_by TEXT NOT NULL REFERENCES users(user_id),
  requested_date TEXT NOT NULL,
  required_date TEXT,
  status TEXT NOT NULL DEFAULT 'draft' CHECK(status IN ('draft','submitted','approved','rejected','converted','cancelled')),
  notes TEXT,
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  UNIQUE(company_id, requisition_number)
);
CREATE TABLE IF NOT EXISTS purchase_requisition_lines (
  requisition_line_id TEXT PRIMARY KEY,
  requisition_id TEXT NOT NULL REFERENCES purchase_requisitions(requisition_id) ON DELETE CASCADE,
  line_number INTEGER NOT NULL CHECK(line_number > 0),
  item_id TEXT NOT NULL REFERENCES items(item_id),
  quantity TEXT NOT NULL CHECK(CAST(quantity AS NUMERIC) > 0),
  uom_id TEXT NOT NULL REFERENCES units_of_measure(uom_id),
  estimated_unit_price_minor INTEGER CHECK(estimated_unit_price_minor >= 0),
  currency_code TEXT REFERENCES currencies(currency_code),
  required_date TEXT,
  status TEXT NOT NULL DEFAULT 'open' CHECK(status IN ('open','ordered','cancelled')),
  UNIQUE(requisition_id, line_number)
);
CREATE TABLE IF NOT EXISTS purchase_orders (
  purchase_order_id TEXT PRIMARY KEY,
  company_id TEXT NOT NULL REFERENCES companies(company_id),
  branch_id TEXT REFERENCES branches(branch_id),
  supplier_partner_id TEXT NOT NULL REFERENCES business_partners(partner_id),
  po_number TEXT NOT NULL,
  order_date TEXT NOT NULL,
  expected_date TEXT,
  currency_code TEXT NOT NULL REFERENCES currencies(currency_code),
  exchange_rate TEXT NOT NULL DEFAULT '1' CHECK(CAST(exchange_rate AS NUMERIC) > 0),
  payment_term_id TEXT REFERENCES payment_terms(payment_term_id),
  status TEXT NOT NULL DEFAULT 'draft' CHECK(status IN ('draft','pending_approval','approved','partially_received','received','closed','cancelled')),
  subtotal_minor INTEGER NOT NULL DEFAULT 0 CHECK(subtotal_minor >= 0),
  tax_minor INTEGER NOT NULL DEFAULT 0 CHECK(tax_minor >= 0),
  total_minor INTEGER NOT NULL DEFAULT 0 CHECK(total_minor >= 0),
  notes TEXT,
  created_by TEXT REFERENCES users(user_id),
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  UNIQUE(company_id, po_number)
);
CREATE TABLE IF NOT EXISTS purchase_order_lines (
  purchase_order_line_id TEXT PRIMARY KEY,
  purchase_order_id TEXT NOT NULL REFERENCES purchase_orders(purchase_order_id) ON DELETE CASCADE,
  line_number INTEGER NOT NULL CHECK(line_number > 0),
  item_id TEXT NOT NULL REFERENCES items(item_id),
  description TEXT,
  quantity_ordered TEXT NOT NULL CHECK(CAST(quantity_ordered AS NUMERIC) > 0),
  quantity_received TEXT NOT NULL DEFAULT '0' CHECK(CAST(quantity_received AS NUMERIC) >= 0),
  quantity_invoiced TEXT NOT NULL DEFAULT '0' CHECK(CAST(quantity_invoiced AS NUMERIC) >= 0),
  uom_id TEXT NOT NULL REFERENCES units_of_measure(uom_id),
  unit_price_minor INTEGER NOT NULL CHECK(unit_price_minor >= 0),
  tax_code_id TEXT REFERENCES tax_codes(tax_code_id),
  line_subtotal_minor INTEGER NOT NULL DEFAULT 0 CHECK(line_subtotal_minor >= 0),
  line_tax_minor INTEGER NOT NULL DEFAULT 0 CHECK(line_tax_minor >= 0),
  line_total_minor INTEGER NOT NULL DEFAULT 0 CHECK(line_total_minor >= 0),
  warehouse_id TEXT REFERENCES warehouses(warehouse_id),
  UNIQUE(purchase_order_id, line_number)
);
CREATE INDEX IF NOT EXISTS idx_purchase_orders_supplier_date ON purchase_orders(company_id, supplier_partner_id, order_date, status);
CREATE TABLE IF NOT EXISTS goods_receipts (
  goods_receipt_id TEXT PRIMARY KEY,
  company_id TEXT NOT NULL REFERENCES companies(company_id),
  purchase_order_id TEXT NOT NULL REFERENCES purchase_orders(purchase_order_id),
  receipt_number TEXT NOT NULL,
  receipt_date TEXT NOT NULL,
  warehouse_id TEXT NOT NULL REFERENCES warehouses(warehouse_id),
  status TEXT NOT NULL DEFAULT 'draft' CHECK(status IN ('draft','posted','cancelled')),
  inventory_transaction_id TEXT REFERENCES inventory_transactions(inventory_transaction_id),
  received_by TEXT REFERENCES users(user_id),
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  UNIQUE(company_id, receipt_number)
);
CREATE TABLE IF NOT EXISTS goods_receipt_lines (
  goods_receipt_line_id TEXT PRIMARY KEY,
  goods_receipt_id TEXT NOT NULL REFERENCES goods_receipts(goods_receipt_id) ON DELETE CASCADE,
  purchase_order_line_id TEXT NOT NULL REFERENCES purchase_order_lines(purchase_order_line_id),
  line_number INTEGER NOT NULL CHECK(line_number > 0),
  item_id TEXT NOT NULL REFERENCES items(item_id),
  quantity_received TEXT NOT NULL CHECK(CAST(quantity_received AS NUMERIC) > 0),
  uom_id TEXT NOT NULL REFERENCES units_of_measure(uom_id),
  storage_location_id TEXT REFERENCES storage_locations(storage_location_id),
  lot_id TEXT REFERENCES inventory_lots(lot_id),
  UNIQUE(goods_receipt_id, line_number)
);
CREATE TABLE IF NOT EXISTS sales_orders (
  sales_order_id TEXT PRIMARY KEY,
  company_id TEXT NOT NULL REFERENCES companies(company_id),
  branch_id TEXT REFERENCES branches(branch_id),
  customer_partner_id TEXT NOT NULL REFERENCES business_partners(partner_id),
  sales_order_number TEXT NOT NULL,
  order_date TEXT NOT NULL,
  requested_delivery_date TEXT,
  currency_code TEXT NOT NULL REFERENCES currencies(currency_code),
  exchange_rate TEXT NOT NULL DEFAULT '1' CHECK(CAST(exchange_rate AS NUMERIC) > 0),
  payment_term_id TEXT REFERENCES payment_terms(payment_term_id),
  status TEXT NOT NULL DEFAULT 'draft' CHECK(status IN ('draft','pending_approval','approved','partially_shipped','shipped','invoiced','closed','cancelled')),
  subtotal_minor INTEGER NOT NULL DEFAULT 0 CHECK(subtotal_minor >= 0),
  tax_minor INTEGER NOT NULL DEFAULT 0 CHECK(tax_minor >= 0),
  total_minor INTEGER NOT NULL DEFAULT 0 CHECK(total_minor >= 0),
  notes TEXT,
  created_by TEXT REFERENCES users(user_id),
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  UNIQUE(company_id, sales_order_number)
);
CREATE TABLE IF NOT EXISTS sales_order_lines (
  sales_order_line_id TEXT PRIMARY KEY,
  sales_order_id TEXT NOT NULL REFERENCES sales_orders(sales_order_id) ON DELETE CASCADE,
  line_number INTEGER NOT NULL CHECK(line_number > 0),
  item_id TEXT NOT NULL REFERENCES items(item_id),
  description TEXT,
  quantity_ordered TEXT NOT NULL CHECK(CAST(quantity_ordered AS NUMERIC) > 0),
  quantity_shipped TEXT NOT NULL DEFAULT '0' CHECK(CAST(quantity_shipped AS NUMERIC) >= 0),
  quantity_invoiced TEXT NOT NULL DEFAULT '0' CHECK(CAST(quantity_invoiced AS NUMERIC) >= 0),
  uom_id TEXT NOT NULL REFERENCES units_of_measure(uom_id),
  unit_price_minor INTEGER NOT NULL CHECK(unit_price_minor >= 0),
  tax_code_id TEXT REFERENCES tax_codes(tax_code_id),
  line_subtotal_minor INTEGER NOT NULL DEFAULT 0 CHECK(line_subtotal_minor >= 0),
  line_tax_minor INTEGER NOT NULL DEFAULT 0 CHECK(line_tax_minor >= 0),
  line_total_minor INTEGER NOT NULL DEFAULT 0 CHECK(line_total_minor >= 0),
  warehouse_id TEXT REFERENCES warehouses(warehouse_id),
  UNIQUE(sales_order_id, line_number)
);
CREATE INDEX IF NOT EXISTS idx_sales_orders_customer_date ON sales_orders(company_id, customer_partner_id, order_date, status);
CREATE TABLE IF NOT EXISTS deliveries (
  delivery_id TEXT PRIMARY KEY,
  company_id TEXT NOT NULL REFERENCES companies(company_id),
  sales_order_id TEXT NOT NULL REFERENCES sales_orders(sales_order_id),
  delivery_number TEXT NOT NULL,
  delivery_date TEXT NOT NULL,
  warehouse_id TEXT NOT NULL REFERENCES warehouses(warehouse_id),
  status TEXT NOT NULL DEFAULT 'draft' CHECK(status IN ('draft','picked','shipped','cancelled')),
  inventory_transaction_id TEXT REFERENCES inventory_transactions(inventory_transaction_id),
  shipped_by TEXT REFERENCES users(user_id),
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  UNIQUE(company_id, delivery_number)
);
CREATE TABLE IF NOT EXISTS delivery_lines (
  delivery_line_id TEXT PRIMARY KEY,
  delivery_id TEXT NOT NULL REFERENCES deliveries(delivery_id) ON DELETE CASCADE,
  sales_order_line_id TEXT NOT NULL REFERENCES sales_order_lines(sales_order_line_id),
  line_number INTEGER NOT NULL CHECK(line_number > 0),
  item_id TEXT NOT NULL REFERENCES items(item_id),
  quantity_shipped TEXT NOT NULL CHECK(CAST(quantity_shipped AS NUMERIC) > 0),
  uom_id TEXT NOT NULL REFERENCES units_of_measure(uom_id),
  storage_location_id TEXT REFERENCES storage_locations(storage_location_id),
  lot_id TEXT REFERENCES inventory_lots(lot_id),
  UNIQUE(delivery_id, line_number)
);

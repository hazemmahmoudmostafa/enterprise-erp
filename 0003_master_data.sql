-- ERP Core Database - Migration 0003: shared master data.
CREATE TABLE IF NOT EXISTS units_of_measure (
  uom_id TEXT PRIMARY KEY,
  uom_code TEXT NOT NULL UNIQUE,
  uom_name TEXT NOT NULL,
  dimension_code TEXT NOT NULL,
  decimal_precision INTEGER NOT NULL DEFAULT 3 CHECK(decimal_precision BETWEEN 0 AND 8),
  status TEXT NOT NULL DEFAULT 'active' CHECK(status IN ('active','inactive'))
);
CREATE TABLE IF NOT EXISTS uom_conversions (
  conversion_id TEXT PRIMARY KEY,
  from_uom_id TEXT NOT NULL REFERENCES units_of_measure(uom_id),
  to_uom_id TEXT NOT NULL REFERENCES units_of_measure(uom_id),
  factor TEXT NOT NULL CHECK(CAST(factor AS NUMERIC) > 0),
  UNIQUE(from_uom_id, to_uom_id)
);
CREATE TABLE IF NOT EXISTS item_categories (
  item_category_id TEXT PRIMARY KEY,
  company_id TEXT REFERENCES companies(company_id),
  parent_category_id TEXT REFERENCES item_categories(item_category_id),
  category_code TEXT NOT NULL,
  category_name TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'active' CHECK(status IN ('active','inactive')),
  UNIQUE(company_id, category_code)
);
CREATE TABLE IF NOT EXISTS items (
  item_id TEXT PRIMARY KEY,
  company_id TEXT NOT NULL REFERENCES companies(company_id),
  item_code TEXT NOT NULL,
  item_name TEXT NOT NULL,
  item_category_id TEXT REFERENCES item_categories(item_category_id),
  item_type TEXT NOT NULL CHECK(item_type IN ('inventory','service','non_inventory','manufactured','raw_material','asset')),
  base_uom_id TEXT NOT NULL REFERENCES units_of_measure(uom_id),
  purchase_uom_id TEXT REFERENCES units_of_measure(uom_id),
  sales_uom_id TEXT REFERENCES units_of_measure(uom_id),
  track_lot INTEGER NOT NULL DEFAULT 0 CHECK(track_lot IN (0,1)),
  track_serial INTEGER NOT NULL DEFAULT 0 CHECK(track_serial IN (0,1)),
  costing_method TEXT NOT NULL DEFAULT 'moving_average' CHECK(costing_method IN ('moving_average','fifo','standard')),
  standard_cost_minor INTEGER CHECK(standard_cost_minor >= 0),
  status TEXT NOT NULL DEFAULT 'active' CHECK(status IN ('active','inactive','blocked')),
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  UNIQUE(company_id, item_code)
);
CREATE INDEX IF NOT EXISTS idx_items_company_category ON items(company_id, item_category_id, status);
CREATE TABLE IF NOT EXISTS business_partners (
  partner_id TEXT PRIMARY KEY,
  company_id TEXT NOT NULL REFERENCES companies(company_id),
  partner_code TEXT NOT NULL,
  partner_name TEXT NOT NULL,
  partner_type TEXT NOT NULL CHECK(partner_type IN ('customer','supplier','both')),
  tax_number TEXT,
  default_currency_code TEXT REFERENCES currencies(currency_code),
  payment_terms_days INTEGER NOT NULL DEFAULT 0 CHECK(payment_terms_days >= 0),
  credit_limit_minor INTEGER CHECK(credit_limit_minor >= 0),
  status TEXT NOT NULL DEFAULT 'active' CHECK(status IN ('active','inactive','blocked')),
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  UNIQUE(company_id, partner_code)
);
CREATE INDEX IF NOT EXISTS idx_partners_company_type ON business_partners(company_id, partner_type, status);
CREATE TABLE IF NOT EXISTS partner_addresses (
  partner_address_id TEXT PRIMARY KEY,
  partner_id TEXT NOT NULL REFERENCES business_partners(partner_id) ON DELETE CASCADE,
  address_type TEXT NOT NULL CHECK(address_type IN ('billing','shipping','registered','other')),
  address_line_1 TEXT NOT NULL,
  address_line_2 TEXT,
  city TEXT,
  region TEXT,
  postal_code TEXT,
  country_code TEXT NOT NULL CHECK(length(country_code)=2),
  is_default INTEGER NOT NULL DEFAULT 0 CHECK(is_default IN (0,1))
);
CREATE TABLE IF NOT EXISTS partner_contacts (
  partner_contact_id TEXT PRIMARY KEY,
  partner_id TEXT NOT NULL REFERENCES business_partners(partner_id) ON DELETE CASCADE,
  contact_name TEXT NOT NULL,
  job_title TEXT,
  email TEXT,
  phone TEXT,
  is_primary INTEGER NOT NULL DEFAULT 0 CHECK(is_primary IN (0,1))
);
CREATE TABLE IF NOT EXISTS payment_terms (
  payment_term_id TEXT PRIMARY KEY,
  company_id TEXT REFERENCES companies(company_id),
  term_code TEXT NOT NULL,
  term_name TEXT NOT NULL,
  due_days INTEGER NOT NULL DEFAULT 0 CHECK(due_days >= 0),
  discount_days INTEGER CHECK(discount_days >= 0),
  discount_percent TEXT CHECK(discount_percent IS NULL OR CAST(discount_percent AS NUMERIC) BETWEEN 0 AND 100),
  status TEXT NOT NULL DEFAULT 'active' CHECK(status IN ('active','inactive')),
  UNIQUE(company_id, term_code)
);
CREATE TABLE IF NOT EXISTS tax_codes (
  tax_code_id TEXT PRIMARY KEY,
  company_id TEXT REFERENCES companies(company_id),
  tax_code TEXT NOT NULL,
  tax_name TEXT NOT NULL,
  tax_rate TEXT NOT NULL CHECK(CAST(tax_rate AS NUMERIC) >= 0),
  tax_type TEXT NOT NULL DEFAULT 'sales' CHECK(tax_type IN ('sales','purchase','withholding','other')),
  recoverable_percent TEXT NOT NULL DEFAULT '100' CHECK(CAST(recoverable_percent AS NUMERIC) BETWEEN 0 AND 100),
  effective_from TEXT,
  effective_to TEXT,
  status TEXT NOT NULL DEFAULT 'active' CHECK(status IN ('active','inactive')),
  UNIQUE(company_id, tax_code)
);

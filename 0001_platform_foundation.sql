-- ERP Core Database - Migration 0001
-- Platform and enterprise organizational foundation for Cloudflare D1 (SQLite).
-- Monetary values in future migrations must use integer minor units or explicit decimal text,
-- never SQLite REAL for financial amounts.

PRAGMA foreign_keys = ON;


-- 1) Platform-level configuration. Keys are unique and values are JSON text when structured.
CREATE TABLE IF NOT EXISTS platform_settings (
    setting_key TEXT PRIMARY KEY,
    setting_value TEXT NOT NULL,
    value_type TEXT NOT NULL DEFAULT 'text' CHECK (value_type IN ('text','number','boolean','json')),
    description TEXT,
    updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now'))
);


-- 2) Currency master. ISO 4217 codes are stored uppercase; minor_unit_digits supports currencies
-- with 0, 2, or 3 decimal places (and other valid configured scales).
CREATE TABLE IF NOT EXISTS currencies (
    currency_code TEXT PRIMARY KEY CHECK (length(currency_code) = 3),
    currency_name TEXT NOT NULL,
    minor_unit_digits INTEGER NOT NULL DEFAULT 2 CHECK (minor_unit_digits BETWEEN 0 AND 6),
    symbol TEXT,
    is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0,1)),
    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now'))
);

CREATE TABLE IF NOT EXISTS exchange_rates (
    exchange_rate_id TEXT PRIMARY KEY,
    from_currency_code TEXT NOT NULL REFERENCES currencies(currency_code),
    to_currency_code TEXT NOT NULL REFERENCES currencies(currency_code),
    rate_type TEXT NOT NULL DEFAULT 'spot' CHECK (rate_type IN ('spot','average','closing','budget','custom')),
    effective_date TEXT NOT NULL,
    rate TEXT NOT NULL CHECK (CAST(rate AS NUMERIC) > 0),
    source TEXT,
    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
    UNIQUE(from_currency_code, to_currency_code, rate_type, effective_date)
);
CREATE INDEX IF NOT EXISTS idx_exchange_rates_lookup
    ON exchange_rates(from_currency_code, to_currency_code, rate_type, effective_date);


-- 3) Legal entities / companies. A company is the primary accounting boundary.
CREATE TABLE IF NOT EXISTS companies (
    company_id TEXT PRIMARY KEY,
    company_code TEXT NOT NULL UNIQUE,
    legal_name TEXT NOT NULL,
    display_name TEXT,
    tax_registration_number TEXT,
    registration_number TEXT,
    base_currency_code TEXT NOT NULL REFERENCES currencies(currency_code),
    country_code TEXT NOT NULL CHECK (length(country_code) = 2),
    timezone TEXT NOT NULL DEFAULT 'Africa/Cairo',
    fiscal_calendar_id TEXT,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active','inactive','suspended')),
    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
    updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now'))
);


-- 4) Company branches and business units.
CREATE TABLE IF NOT EXISTS branches (
    branch_id TEXT PRIMARY KEY,
    company_id TEXT NOT NULL REFERENCES companies(company_id),
    branch_code TEXT NOT NULL,
    branch_name TEXT NOT NULL,
    address_line_1 TEXT,
    address_line_2 TEXT,
    city TEXT,
    region TEXT,
    postal_code TEXT,
    country_code TEXT NOT NULL CHECK (length(country_code) = 2),
    phone TEXT,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active','inactive')),
    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
    updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
    UNIQUE(company_id, branch_code)
);
CREATE INDEX IF NOT EXISTS idx_branches_company_status ON branches(company_id, status);

CREATE TABLE IF NOT EXISTS business_units (
    business_unit_id TEXT PRIMARY KEY,
    company_id TEXT NOT NULL REFERENCES companies(company_id),
    business_unit_code TEXT NOT NULL,
    business_unit_name TEXT NOT NULL,
    description TEXT,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active','inactive')),
    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
    UNIQUE(company_id, business_unit_code)
);
CREATE INDEX IF NOT EXISTS idx_business_units_company ON business_units(company_id, status);


-- 5) Plants and warehouse hierarchy. A warehouse belongs to one company and may be linked
-- to a branch and/or plant. Storage locations are nested through parent_location_id.
CREATE TABLE IF NOT EXISTS plants (
    plant_id TEXT PRIMARY KEY,
    company_id TEXT NOT NULL REFERENCES companies(company_id),
    branch_id TEXT REFERENCES branches(branch_id),
    plant_code TEXT NOT NULL,
    plant_name TEXT NOT NULL,
    address_line_1 TEXT,
    city TEXT,
    country_code TEXT NOT NULL CHECK (length(country_code) = 2),
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active','inactive')),
    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
    UNIQUE(company_id, plant_code)
);
CREATE INDEX IF NOT EXISTS idx_plants_company_branch ON plants(company_id, branch_id);

CREATE TABLE IF NOT EXISTS warehouses (
    warehouse_id TEXT PRIMARY KEY,
    company_id TEXT NOT NULL REFERENCES companies(company_id),
    branch_id TEXT REFERENCES branches(branch_id),
    plant_id TEXT REFERENCES plants(plant_id),
    warehouse_code TEXT NOT NULL,
    warehouse_name TEXT NOT NULL,
    warehouse_type TEXT NOT NULL DEFAULT 'standard' CHECK (warehouse_type IN ('standard','transit','quarantine','production','returns')),
    allow_negative_stock INTEGER NOT NULL DEFAULT 0 CHECK (allow_negative_stock IN (0,1)),
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active','inactive')),
    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
    UNIQUE(company_id, warehouse_code)
);
CREATE INDEX IF NOT EXISTS idx_warehouses_company_branch ON warehouses(company_id, branch_id);

CREATE TABLE IF NOT EXISTS storage_locations (
    storage_location_id TEXT PRIMARY KEY,
    warehouse_id TEXT NOT NULL REFERENCES warehouses(warehouse_id),
    parent_location_id TEXT REFERENCES storage_locations(storage_location_id),
    location_code TEXT NOT NULL,
    location_name TEXT,
    location_type TEXT NOT NULL DEFAULT 'bin' CHECK (location_type IN ('zone','aisle','rack','bin','floor','other')),
    is_receiving_location INTEGER NOT NULL DEFAULT 0 CHECK (is_receiving_location IN (0,1)),
    is_shipping_location INTEGER NOT NULL DEFAULT 0 CHECK (is_shipping_location IN (0,1)),
    is_quarantine_location INTEGER NOT NULL DEFAULT 0 CHECK (is_quarantine_location IN (0,1)),
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active','inactive','blocked')),
    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
    UNIQUE(warehouse_id, location_code)
);
CREATE INDEX IF NOT EXISTS idx_storage_locations_parent ON storage_locations(parent_location_id);


-- 6) Fiscal calendar configuration and accounting periods. Period dates are ISO YYYY-MM-DD.
CREATE TABLE IF NOT EXISTS fiscal_calendars (
    fiscal_calendar_id TEXT PRIMARY KEY,
    calendar_code TEXT NOT NULL UNIQUE,
    calendar_name TEXT NOT NULL,
    description TEXT,
    periods_per_year INTEGER NOT NULL DEFAULT 12 CHECK (periods_per_year BETWEEN 1 AND 366),
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active','inactive')),
    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now'))
);
CREATE TABLE IF NOT EXISTS fiscal_years (
    fiscal_year_id TEXT PRIMARY KEY,
    fiscal_calendar_id TEXT NOT NULL REFERENCES fiscal_calendars(fiscal_calendar_id),
    fiscal_year_code TEXT NOT NULL,
    start_date TEXT NOT NULL,
    end_date TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open','closing','closed')),
    CHECK (start_date <= end_date),
    UNIQUE(fiscal_calendar_id, fiscal_year_code)
);
CREATE INDEX IF NOT EXISTS idx_fiscal_years_dates ON fiscal_years(start_date, end_date);
CREATE TABLE IF NOT EXISTS fiscal_periods (
    fiscal_period_id TEXT PRIMARY KEY,
    fiscal_year_id TEXT NOT NULL REFERENCES fiscal_years(fiscal_year_id),
    period_number INTEGER NOT NULL CHECK (period_number >= 1),
    period_code TEXT NOT NULL,
    period_name TEXT NOT NULL,
    start_date TEXT NOT NULL,
    end_date TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open','soft_closed','closed')),
    is_adjustment_period INTEGER NOT NULL DEFAULT 0 CHECK (is_adjustment_period IN (0,1)),
    CHECK (start_date <= end_date),
    UNIQUE(fiscal_year_id, period_number),
    UNIQUE(fiscal_year_id, period_code)
);
CREATE INDEX IF NOT EXISTS idx_fiscal_periods_dates_status ON fiscal_periods(start_date, end_date, status);


-- 7) Cost and profit centers: organizational accounting dimensions.
CREATE TABLE IF NOT EXISTS cost_centers (
    cost_center_id TEXT PRIMARY KEY,
    company_id TEXT NOT NULL REFERENCES companies(company_id),
    parent_cost_center_id TEXT REFERENCES cost_centers(cost_center_id),
    cost_center_code TEXT NOT NULL,
    cost_center_name TEXT NOT NULL,
    branch_id TEXT REFERENCES branches(branch_id),
    valid_from TEXT,
    valid_to TEXT,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active','inactive')),
    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
    UNIQUE(company_id, cost_center_code)
);
CREATE INDEX IF NOT EXISTS idx_cost_centers_parent ON cost_centers(parent_cost_center_id);
CREATE TABLE IF NOT EXISTS profit_centers (
    profit_center_id TEXT PRIMARY KEY,
    company_id TEXT NOT NULL REFERENCES companies(company_id),
    parent_profit_center_id TEXT REFERENCES profit_centers(profit_center_id),
    profit_center_code TEXT NOT NULL,
    profit_center_name TEXT NOT NULL,
    branch_id TEXT REFERENCES branches(branch_id),
    valid_from TEXT,
    valid_to TEXT,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active','inactive')),
    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
    UNIQUE(company_id, profit_center_code)
);
CREATE INDEX IF NOT EXISTS idx_profit_centers_parent ON profit_centers(parent_profit_center_id);


-- 8) Add company fiscal calendar reference after both tables exist.
CREATE INDEX IF NOT EXISTS idx_companies_status ON companies(status);
CREATE INDEX IF NOT EXISTS idx_exchange_rates_effective ON exchange_rates(effective_date);


-- 9) Minimal safe seed configuration: no real business or personal data.
INSERT OR IGNORE INTO currencies(currency_code, currency_name, minor_unit_digits, symbol)
VALUES ('EGP','Egyptian Pound',2,'ج.م'), ('USD','US Dollar',2,'$'), ('EUR','Euro',2,'€');

INSERT OR IGNORE INTO fiscal_calendars(fiscal_calendar_id, calendar_code, calendar_name, periods_per_year)
VALUES ('fc-eg-calendar','EG-CAL','Egypt Standard Calendar',12);
INSERT OR IGNORE INTO platform_settings(setting_key, setting_value, value_type, description)
VALUES ('system.locale','ar-EG','text','Default locale for the ERP'),
       ('system.timezone','Africa/Cairo','text','Default system timezone'),
       ('system.database.engine','Cloudflare D1 / SQLite','text','Database engine');

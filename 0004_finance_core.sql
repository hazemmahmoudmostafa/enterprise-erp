-- ERP Core Database - Migration 0004: accounting foundation and general ledger.
CREATE TABLE IF NOT EXISTS account_types (
  account_type_code TEXT PRIMARY KEY,
  account_type_name TEXT NOT NULL,
  normal_balance TEXT NOT NULL CHECK(normal_balance IN ('debit','credit'))
);
CREATE TABLE IF NOT EXISTS charts_of_accounts (
  chart_of_accounts_id TEXT PRIMARY KEY,
  company_id TEXT NOT NULL REFERENCES companies(company_id),
  chart_code TEXT NOT NULL,
  chart_name TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'active' CHECK(status IN ('active','inactive')),
  UNIQUE(company_id, chart_code)
);
CREATE TABLE IF NOT EXISTS gl_accounts (
  gl_account_id TEXT PRIMARY KEY,
  chart_of_accounts_id TEXT NOT NULL REFERENCES charts_of_accounts(chart_of_accounts_id),
  account_code TEXT NOT NULL,
  account_name TEXT NOT NULL,
  account_type_code TEXT NOT NULL REFERENCES account_types(account_type_code),
  parent_account_id TEXT REFERENCES gl_accounts(gl_account_id),
  is_control_account INTEGER NOT NULL DEFAULT 0 CHECK(is_control_account IN (0,1)),
  is_reconciliation_account INTEGER NOT NULL DEFAULT 0 CHECK(is_reconciliation_account IN (0,1)),
  allow_manual_posting INTEGER NOT NULL DEFAULT 1 CHECK(allow_manual_posting IN (0,1)),
  currency_code TEXT REFERENCES currencies(currency_code),
  status TEXT NOT NULL DEFAULT 'active' CHECK(status IN ('active','inactive','blocked')),
  UNIQUE(chart_of_accounts_id, account_code)
);
CREATE INDEX IF NOT EXISTS idx_gl_accounts_parent ON gl_accounts(parent_account_id);
CREATE TABLE IF NOT EXISTS journal_entries (
  journal_entry_id TEXT PRIMARY KEY,
  company_id TEXT NOT NULL REFERENCES companies(company_id),
  journal_number TEXT NOT NULL,
  journal_type TEXT NOT NULL DEFAULT 'general' CHECK(journal_type IN ('general','sales','purchase','cash','bank','inventory','payroll','asset','production','adjustment')),
  document_date TEXT NOT NULL,
  posting_date TEXT NOT NULL,
  fiscal_period_id TEXT NOT NULL REFERENCES fiscal_periods(fiscal_period_id),
  currency_code TEXT NOT NULL REFERENCES currencies(currency_code),
  exchange_rate TEXT NOT NULL DEFAULT '1' CHECK(CAST(exchange_rate AS NUMERIC) > 0),
  description TEXT,
  source_module TEXT,
  source_document_type TEXT,
  source_document_id TEXT,
  status TEXT NOT NULL DEFAULT 'draft' CHECK(status IN ('draft','pending_approval','posted','reversed','cancelled')),
  reversal_of_entry_id TEXT REFERENCES journal_entries(journal_entry_id),
  posted_by TEXT REFERENCES users(user_id),
  posted_at TEXT,
  created_by TEXT REFERENCES users(user_id),
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  UNIQUE(company_id, journal_number),
  UNIQUE(source_module, source_document_type, source_document_id)
);
CREATE INDEX IF NOT EXISTS idx_journal_entries_company_date ON journal_entries(company_id, posting_date, status);
CREATE INDEX IF NOT EXISTS idx_journal_entries_source ON journal_entries(source_module, source_document_type, source_document_id);
CREATE TABLE IF NOT EXISTS journal_entry_lines (
  journal_entry_line_id TEXT PRIMARY KEY,
  journal_entry_id TEXT NOT NULL REFERENCES journal_entries(journal_entry_id) ON DELETE CASCADE,
  line_number INTEGER NOT NULL CHECK(line_number > 0),
  gl_account_id TEXT NOT NULL REFERENCES gl_accounts(gl_account_id),
  description TEXT,
  debit_minor INTEGER NOT NULL DEFAULT 0 CHECK(debit_minor >= 0),
  credit_minor INTEGER NOT NULL DEFAULT 0 CHECK(credit_minor >= 0),
  currency_code TEXT NOT NULL REFERENCES currencies(currency_code),
  exchange_rate TEXT NOT NULL DEFAULT '1' CHECK(CAST(exchange_rate AS NUMERIC) > 0),
  base_debit_minor INTEGER NOT NULL DEFAULT 0 CHECK(base_debit_minor >= 0),
  base_credit_minor INTEGER NOT NULL DEFAULT 0 CHECK(base_credit_minor >= 0),
  cost_center_id TEXT REFERENCES cost_centers(cost_center_id),
  profit_center_id TEXT REFERENCES profit_centers(profit_center_id),
  partner_id TEXT REFERENCES business_partners(partner_id),
  item_id TEXT REFERENCES items(item_id),
  CHECK ((debit_minor = 0 AND credit_minor > 0) OR (credit_minor = 0 AND debit_minor > 0)),
  CHECK ((base_debit_minor = 0 AND base_credit_minor >= 0) OR (base_credit_minor = 0 AND base_debit_minor >= 0)),
  UNIQUE(journal_entry_id, line_number)
);
CREATE INDEX IF NOT EXISTS idx_journal_lines_account ON journal_entry_lines(gl_account_id, journal_entry_id);
CREATE INDEX IF NOT EXISTS idx_journal_lines_cost_center ON journal_entry_lines(cost_center_id);
CREATE TABLE IF NOT EXISTS document_sequences (
  document_sequence_id TEXT PRIMARY KEY,
  company_id TEXT NOT NULL REFERENCES companies(company_id),
  document_type TEXT NOT NULL,
  prefix TEXT NOT NULL DEFAULT '',
  next_number INTEGER NOT NULL DEFAULT 1 CHECK(next_number > 0),
  padding_length INTEGER NOT NULL DEFAULT 6 CHECK(padding_length BETWEEN 1 AND 20),
  reset_frequency TEXT NOT NULL DEFAULT 'never' CHECK(reset_frequency IN ('never','yearly','monthly')),
  last_reset_key TEXT,
  UNIQUE(company_id, document_type)
);
-- D1/SQLite cannot enforce cross-row journal balancing with a simple CHECK.
-- The application posting service must validate total debits = total credits and
-- transition draft -> posted in a controlled transaction; posted entries are immutable.

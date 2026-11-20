-- ERP Core Database - Migration 0002: security, access scopes, approvals, audit.
CREATE TABLE IF NOT EXISTS users (
  user_id TEXT PRIMARY KEY,
  username TEXT NOT NULL UNIQUE,
  email TEXT UNIQUE,
  password_hash TEXT NOT NULL,
  full_name TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'active' CHECK(status IN ('active','locked','disabled')),
  last_login_at TEXT,
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now'))
);
CREATE TABLE IF NOT EXISTS roles (
  role_id TEXT PRIMARY KEY,
  role_code TEXT NOT NULL UNIQUE,
  role_name TEXT NOT NULL,
  description TEXT,
  is_system_role INTEGER NOT NULL DEFAULT 0 CHECK(is_system_role IN (0,1)),
  status TEXT NOT NULL DEFAULT 'active' CHECK(status IN ('active','inactive')),
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now'))
);
CREATE TABLE IF NOT EXISTS permissions (
  permission_id TEXT PRIMARY KEY,
  permission_code TEXT NOT NULL UNIQUE,
  module_code TEXT NOT NULL,
  action_code TEXT NOT NULL,
  description TEXT
);
CREATE TABLE IF NOT EXISTS role_permissions (
  role_id TEXT NOT NULL REFERENCES roles(role_id) ON DELETE CASCADE,
  permission_id TEXT NOT NULL REFERENCES permissions(permission_id) ON DELETE CASCADE,
  PRIMARY KEY(role_id, permission_id)
);
CREATE TABLE IF NOT EXISTS user_roles (
  user_id TEXT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  role_id TEXT NOT NULL REFERENCES roles(role_id) ON DELETE CASCADE,
  assigned_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  assigned_by TEXT REFERENCES users(user_id),
  PRIMARY KEY(user_id, role_id)
);
CREATE TABLE IF NOT EXISTS user_company_access (
  user_id TEXT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  company_id TEXT NOT NULL REFERENCES companies(company_id) ON DELETE CASCADE,
  access_level TEXT NOT NULL DEFAULT 'read_write' CHECK(access_level IN ('read_only','read_write','admin')),
  PRIMARY KEY(user_id, company_id)
);
CREATE TABLE IF NOT EXISTS user_branch_access (
  user_id TEXT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  branch_id TEXT NOT NULL REFERENCES branches(branch_id) ON DELETE CASCADE,
  PRIMARY KEY(user_id, branch_id)
);
CREATE TABLE IF NOT EXISTS approval_workflows (
  workflow_id TEXT PRIMARY KEY,
  company_id TEXT REFERENCES companies(company_id),
  workflow_code TEXT NOT NULL,
  workflow_name TEXT NOT NULL,
  document_type TEXT NOT NULL,
  minimum_amount TEXT,
  currency_code TEXT REFERENCES currencies(currency_code),
  status TEXT NOT NULL DEFAULT 'active' CHECK(status IN ('active','inactive')),
  UNIQUE(company_id, workflow_code)
);
CREATE TABLE IF NOT EXISTS approval_workflow_steps (
  workflow_step_id TEXT PRIMARY KEY,
  workflow_id TEXT NOT NULL REFERENCES approval_workflows(workflow_id) ON DELETE CASCADE,
  step_number INTEGER NOT NULL CHECK(step_number > 0),
  step_name TEXT NOT NULL,
  approver_role_id TEXT REFERENCES roles(role_id),
  approver_user_id TEXT REFERENCES users(user_id),
  approval_mode TEXT NOT NULL DEFAULT 'any' CHECK(approval_mode IN ('any','all')),
  UNIQUE(workflow_id, step_number)
);
CREATE TABLE IF NOT EXISTS approval_requests (
  approval_request_id TEXT PRIMARY KEY,
  workflow_id TEXT NOT NULL REFERENCES approval_workflows(workflow_id),
  document_type TEXT NOT NULL,
  document_id TEXT NOT NULL,
  requested_by TEXT NOT NULL REFERENCES users(user_id),
  current_step_number INTEGER NOT NULL DEFAULT 1,
  status TEXT NOT NULL DEFAULT 'pending' CHECK(status IN ('pending','approved','rejected','cancelled')),
  requested_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  completed_at TEXT,
  UNIQUE(document_type, document_id)
);
CREATE TABLE IF NOT EXISTS approval_actions (
  approval_action_id TEXT PRIMARY KEY,
  approval_request_id TEXT NOT NULL REFERENCES approval_requests(approval_request_id) ON DELETE CASCADE,
  step_number INTEGER NOT NULL,
  acted_by TEXT NOT NULL REFERENCES users(user_id),
  action TEXT NOT NULL CHECK(action IN ('approved','rejected','returned','delegated')),
  comments TEXT,
  acted_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now'))
);
CREATE INDEX IF NOT EXISTS idx_approval_requests_status ON approval_requests(status, requested_at);
CREATE TABLE IF NOT EXISTS audit_log (
  audit_id TEXT PRIMARY KEY,
  actor_user_id TEXT REFERENCES users(user_id),
  company_id TEXT REFERENCES companies(company_id),
  module_code TEXT NOT NULL,
  action_code TEXT NOT NULL,
  entity_type TEXT NOT NULL,
  entity_id TEXT NOT NULL,
  before_json TEXT,
  after_json TEXT,
  request_id TEXT,
  ip_address TEXT,
  user_agent TEXT,
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now'))
);
CREATE INDEX IF NOT EXISTS idx_audit_entity ON audit_log(entity_type, entity_id, created_at);
CREATE INDEX IF NOT EXISTS idx_audit_actor ON audit_log(actor_user_id, created_at);

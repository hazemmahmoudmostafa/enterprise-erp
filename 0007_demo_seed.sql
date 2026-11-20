-- ERP Core Database - Migration 0007: fictional demo dataset for integration testing.
-- All data is fictional. No demo user/password is created; auth must be implemented separately.
INSERT OR IGNORE INTO companies(company_id, company_code, legal_name, display_name, base_currency_code, country_code, timezone, status)
VALUES ('demo-company-eg','DEMO-EG','Demo Egyptian Trading Company LLC','Demo Trading','EGP','EG','Africa/Cairo','active');
INSERT OR IGNORE INTO branches(branch_id, company_id, branch_code, branch_name, city, country_code)
VALUES ('demo-branch-cairo','demo-company-eg','CAI-HQ','Cairo Head Office','Cairo','EG');
INSERT OR IGNORE INTO business_units(business_unit_id, company_id, business_unit_code, business_unit_name)
VALUES ('demo-bu-trading','demo-company-eg','TRADING','Trading Operations');
INSERT OR IGNORE INTO plants(plant_id, company_id, branch_id, plant_code, plant_name, city, country_code)
VALUES ('demo-plant-cairo','demo-company-eg','demo-branch-cairo','CAI-PLT','Cairo Distribution Plant','Cairo','EG');
INSERT OR IGNORE INTO warehouses(warehouse_id, company_id, branch_id, plant_id, warehouse_code, warehouse_name, warehouse_type)
VALUES ('demo-warehouse-main','demo-company-eg','demo-branch-cairo','demo-plant-cairo','WH-MAIN','Main Warehouse','standard');
INSERT OR IGNORE INTO storage_locations(storage_location_id, warehouse_id, location_code, location_name, location_type, is_receiving_location, is_shipping_location)
VALUES ('demo-location-receiving','demo-warehouse-main','RECEIVING','Receiving Zone','zone',1,0),
       ('demo-location-a01','demo-warehouse-main','A-01','Rack A / Bin 01','bin',0,0),
       ('demo-location-shipping','demo-warehouse-main','SHIPPING','Shipping Zone','zone',0,1);
INSERT OR IGNORE INTO fiscal_years(fiscal_year_id, fiscal_calendar_id, fiscal_year_code, start_date, end_date, status)
VALUES ('demo-fy-2026','fc-eg-calendar','FY2026','2026-01-01','2026-12-31','open');
INSERT OR IGNORE INTO fiscal_periods(fiscal_period_id, fiscal_year_id, period_number, period_code, period_name, start_date, end_date, status)
VALUES ('demo-fp-2026-11','demo-fy-2026',11,'2026-11','November 2026','2026-11-01','2026-11-30','open');
INSERT OR IGNORE INTO cost_centers(cost_center_id, company_id, cost_center_code, cost_center_name, branch_id)
VALUES ('demo-cc-ops','demo-company-eg','OPS','Operations','demo-branch-cairo');
INSERT OR IGNORE INTO profit_centers(profit_center_id, company_id, profit_center_code, profit_center_name, branch_id)
VALUES ('demo-pc-trading','demo-company-eg','TRADING','Trading','demo-branch-cairo');
INSERT OR IGNORE INTO units_of_measure(uom_id, uom_code, uom_name, dimension_code, decimal_precision)
VALUES ('demo-uom-each','EA','Each','count',0), ('demo-uom-kg','KG','Kilogram','mass',3), ('demo-uom-box','BOX','Box','count',0);
INSERT OR IGNORE INTO uom_conversions(conversion_id, from_uom_id, to_uom_id, factor)
VALUES ('demo-conv-box-each','demo-uom-box','demo-uom-each','12');
INSERT OR IGNORE INTO item_categories(item_category_id, company_id, category_code, category_name)
VALUES ('demo-cat-electronics','demo-company-eg','ELEC','Electronics');
INSERT OR IGNORE INTO items(item_id, company_id, item_code, item_name, item_category_id, item_type, base_uom_id, purchase_uom_id, sales_uom_id, costing_method, standard_cost_minor)
VALUES ('demo-item-usb','demo-company-eg','USB-C-001','USB-C Cable 1m','demo-cat-electronics','inventory','demo-uom-each','demo-uom-each','demo-uom-each','moving_average',8000),
       ('demo-item-adapter','demo-company-eg','ADP-001','USB-C Adapter','demo-cat-electronics','inventory','demo-uom-each','demo-uom-each','demo-uom-each','moving_average',15000);
INSERT OR IGNORE INTO payment_terms(payment_term_id, company_id, term_code, term_name, due_days)
VALUES ('demo-terms-net30','demo-company-eg','NET30','Net 30 Days',30), ('demo-terms-cod','demo-company-eg','COD','Cash on Delivery',0);
INSERT OR IGNORE INTO tax_codes(tax_code_id, company_id, tax_code, tax_name, tax_rate, tax_type, recoverable_percent)
VALUES ('demo-tax-standard','demo-company-eg','VAT-14','Demo VAT 14 Percent','14','sales','100');
INSERT OR IGNORE INTO business_partners(partner_id, company_id, partner_code, partner_name, partner_type, tax_number, default_currency_code, payment_terms_days, credit_limit_minor)
VALUES ('demo-supplier-001','demo-company-eg','SUP-001','Demo Electronics Supplier','supplier','DEMO-SUP-TAX','EGP',30,NULL),
       ('demo-customer-001','demo-company-eg','CUS-001','Demo Retail Customer','customer','DEMO-CUS-TAX','EGP',0,50000000);
INSERT OR IGNORE INTO partner_addresses(partner_address_id, partner_id, address_type, address_line_1, city, country_code, is_default)
VALUES ('demo-supplier-address','demo-supplier-001','registered','Demo Supplier Street','Cairo','EG',1),
       ('demo-customer-address','demo-customer-001','billing','Demo Customer Street','Cairo','EG',1);
INSERT OR IGNORE INTO account_types(account_type_code, account_type_name, normal_balance)
VALUES ('asset','Assets','debit'),('liability','Liabilities','credit'),('equity','Equity','credit'),('revenue','Revenue','credit'),('expense','Expenses','debit');
INSERT OR IGNORE INTO charts_of_accounts(chart_of_accounts_id, company_id, chart_code, chart_name)
VALUES ('demo-coa','demo-company-eg','EG-COA','Demo Egyptian Chart of Accounts');
INSERT OR IGNORE INTO gl_accounts(gl_account_id, chart_of_accounts_id, account_code, account_name, account_type_code, is_control_account, allow_manual_posting)
VALUES ('demo-gl-cash','demo-coa','101000','Cash','asset',0,1),
       ('demo-gl-inventory','demo-coa','120000','Inventory','asset',0,0),
       ('demo-gl-ap','demo-coa','201000','Accounts Payable','liability',1,0),
       ('demo-gl-ar','demo-coa','121000','Accounts Receivable','asset',1,0),
       ('demo-gl-sales','demo-coa','401000','Sales Revenue','revenue',0,0),
       ('demo-gl-cogs','demo-coa','501000','Cost of Goods Sold','expense',0,0),
       ('demo-gl-vat','demo-coa','221000','VAT Payable','liability',0,0);
INSERT OR IGNORE INTO document_sequences(document_sequence_id, company_id, document_type, prefix, next_number, padding_length)
VALUES ('demo-seq-po','demo-company-eg','purchase_order','PO-',1001,6),
       ('demo-seq-so','demo-company-eg','sales_order','SO-',2001,6),
       ('demo-seq-journal','demo-company-eg','journal_entry','JE-',1,6);
-- Seed opening stock snapshot (test-only). Real balances must be created by posted opening inventory transactions.
INSERT OR IGNORE INTO inventory_balances(company_id, item_id, warehouse_id, storage_location_id, on_hand_quantity, reserved_quantity, available_quantity, inventory_value_minor, currency_code)
VALUES ('demo-company-eg','demo-item-usb','demo-warehouse-main','demo-location-a01','100','0','100',800000,'EGP'),
       ('demo-company-eg','demo-item-adapter','demo-warehouse-main','demo-location-a01','40','0','40',600000,'EGP');
INSERT OR IGNORE INTO purchase_orders(purchase_order_id, company_id, branch_id, supplier_partner_id, po_number, order_date, expected_date, currency_code, payment_term_id, status, subtotal_minor, tax_minor, total_minor)
VALUES ('demo-po-001','demo-company-eg','demo-branch-cairo','demo-supplier-001','PO-DEMO-001','2026-11-20','2026-11-25','EGP','demo-terms-net30','approved',160000,22400,182400);
INSERT OR IGNORE INTO purchase_order_lines(purchase_order_line_id, purchase_order_id, line_number, item_id, quantity_ordered, uom_id, unit_price_minor, tax_code_id, line_subtotal_minor, line_tax_minor, line_total_minor, warehouse_id)
VALUES ('demo-po-line-001','demo-po-001',1,'demo-item-usb','20','demo-uom-each',8000,'demo-tax-standard',160000,22400,182400,'demo-warehouse-main');
INSERT OR IGNORE INTO sales_orders(sales_order_id, company_id, branch_id, customer_partner_id, sales_order_number, order_date, requested_delivery_date, currency_code, payment_term_id, status, subtotal_minor, tax_minor, total_minor)
VALUES ('demo-so-001','demo-company-eg','demo-branch-cairo','demo-customer-001','SO-DEMO-001','2026-11-20','2026-11-22','EGP','demo-terms-cod','approved',120000,16800,136800);
INSERT OR IGNORE INTO sales_order_lines(sales_order_line_id, sales_order_id, line_number, item_id, description, quantity_ordered, uom_id, unit_price_minor, tax_code_id, line_subtotal_minor, line_tax_minor, line_total_minor, warehouse_id)
VALUES ('demo-so-line-001','demo-so-001',1,'demo-item-usb','USB-C Cable 1m','15','demo-uom-each',8000,'demo-tax-standard',120000,16800,136800,'demo-warehouse-main');

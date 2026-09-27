PRAGMA foreign_keys = ON;

CREATE TABLE schema_migrations (version INTEGER PRIMARY KEY, name TEXT NOT NULL, checksum TEXT NOT NULL, applied_at TEXT NOT NULL);
CREATE TABLE application_metadata (key TEXT PRIMARY KEY, value TEXT NOT NULL, updated_at TEXT NOT NULL);
CREATE TABLE clinics (
 id TEXT PRIMARY KEY, name TEXT NOT NULL CHECK(length(trim(name)) BETWEEN 1 AND 200), identifier TEXT NOT NULL UNIQUE,
 logo_path TEXT, address TEXT NOT NULL DEFAULT '', phone TEXT NOT NULL DEFAULT '', alternate_phone TEXT, email TEXT, website TEXT,
 registration_info TEXT, opening_time TEXT, closing_time TEXT, weekly_holidays_json TEXT NOT NULL DEFAULT '[]',
 currency_code TEXT NOT NULL DEFAULT 'BDT' CHECK(currency_code='BDT'), timezone TEXT NOT NULL DEFAULT 'Asia/Dhaka',
 date_format TEXT NOT NULL DEFAULT 'dd MMM yyyy', time_format TEXT NOT NULL DEFAULT 'hh:mm a', created_at TEXT NOT NULL, updated_at TEXT NOT NULL
);
CREATE TABLE activation_state (id INTEGER PRIMARY KEY CHECK(id=1), installation_id TEXT NOT NULL, activated_at TEXT NOT NULL, proof BLOB NOT NULL, version INTEGER NOT NULL DEFAULT 1);
CREATE TABLE permissions (code TEXT PRIMARY KEY, category TEXT NOT NULL, description TEXT NOT NULL);
CREATE TABLE roles (id TEXT PRIMARY KEY, clinic_id TEXT NOT NULL REFERENCES clinics(id), name TEXT NOT NULL, description TEXT NOT NULL DEFAULT '', is_system INTEGER NOT NULL DEFAULT 0 CHECK(is_system IN(0,1)), created_at TEXT NOT NULL, updated_at TEXT NOT NULL, UNIQUE(clinic_id,name));
CREATE TABLE role_permissions (role_id TEXT NOT NULL REFERENCES roles(id) ON DELETE CASCADE, permission_code TEXT NOT NULL REFERENCES permissions(code) ON DELETE RESTRICT, PRIMARY KEY(role_id,permission_code));
CREATE TABLE users (
 id TEXT PRIMARY KEY, clinic_id TEXT NOT NULL REFERENCES clinics(id), username TEXT NOT NULL COLLATE NOCASE, password_hash TEXT NOT NULL,
 display_name TEXT NOT NULL, status TEXT NOT NULL DEFAULT 'ACTIVE' CHECK(status IN('ACTIVE','LOCKED','DISABLED')),
 failed_attempts INTEGER NOT NULL DEFAULT 0 CHECK(failed_attempts>=0), locked_until TEXT, password_changed_at TEXT NOT NULL,
 last_login_at TEXT, created_at TEXT NOT NULL, updated_at TEXT NOT NULL, archived_at TEXT, UNIQUE(clinic_id,username)
);
CREATE TABLE user_roles (user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE, role_id TEXT NOT NULL REFERENCES roles(id) ON DELETE CASCADE, PRIMARY KEY(user_id,role_id));
CREATE TABLE dentists (
 id TEXT PRIMARY KEY, clinic_id TEXT NOT NULL REFERENCES clinics(id), dentist_code TEXT NOT NULL, full_name TEXT NOT NULL, professional_title TEXT NOT NULL DEFAULT 'Dr.',
 designations_json TEXT NOT NULL DEFAULT '[]', degrees TEXT NOT NULL DEFAULT '', specialty TEXT NOT NULL DEFAULT '', registration_number TEXT,
 phone TEXT, email TEXT, signature_path TEXT, photo_path TEXT, availability_json TEXT NOT NULL DEFAULT '{}', appointment_duration_minutes INTEGER NOT NULL DEFAULT 30 CHECK(appointment_duration_minutes BETWEEN 5 AND 480),
 status TEXT NOT NULL DEFAULT 'ACTIVE' CHECK(status IN('ACTIVE','INACTIVE')), created_at TEXT NOT NULL, updated_at TEXT NOT NULL, UNIQUE(clinic_id,dentist_code)
);
CREATE TABLE staff (
 id TEXT PRIMARY KEY, clinic_id TEXT NOT NULL REFERENCES clinics(id), staff_code TEXT NOT NULL, user_id TEXT REFERENCES users(id), name TEXT NOT NULL,
 date_of_birth TEXT, gender TEXT, address TEXT, phone TEXT, blood_group TEXT, identification_number TEXT, photo_path TEXT,
 designation TEXT NOT NULL, department TEXT, joining_date TEXT NOT NULL, salary_minor INTEGER NOT NULL DEFAULT 0, employment_status TEXT NOT NULL DEFAULT 'ACTIVE',
 emergency_contact TEXT, notes TEXT, created_at TEXT NOT NULL, updated_at TEXT NOT NULL, archived_at TEXT, UNIQUE(clinic_id,staff_code)
);
CREATE TABLE patients (
 id TEXT PRIMARY KEY, clinic_id TEXT NOT NULL REFERENCES clinics(id), patient_code TEXT NOT NULL, full_name TEXT NOT NULL,
 date_of_birth TEXT, age_years INTEGER CHECK(age_years IS NULL OR age_years BETWEEN 0 AND 150), gender TEXT, blood_group TEXT, phone TEXT,
 emergency_phone TEXT, address TEXT, chief_concern TEXT, medical_history TEXT, allergies TEXT, current_medications TEXT, notes TEXT,
 registration_at TEXT NOT NULL, referred_by TEXT, assigned_dentist_id TEXT REFERENCES dentists(id), status TEXT NOT NULL DEFAULT 'ACTIVE' CHECK(status IN('ACTIVE','INACTIVE','ARCHIVED','DECEASED')),
 created_by TEXT NOT NULL REFERENCES users(id), created_at TEXT NOT NULL, updated_at TEXT NOT NULL, archived_at TEXT, UNIQUE(clinic_id,patient_code)
);
CREATE TABLE patient_contacts (id TEXT PRIMARY KEY, patient_id TEXT NOT NULL REFERENCES patients(id), kind TEXT NOT NULL, value TEXT NOT NULL, is_primary INTEGER NOT NULL DEFAULT 0 CHECK(is_primary IN(0,1)), created_at TEXT NOT NULL);
CREATE TABLE visits (
 id TEXT PRIMARY KEY, patient_id TEXT NOT NULL REFERENCES patients(id), dentist_id TEXT NOT NULL REFERENCES dentists(id), visit_at TEXT NOT NULL,
 chief_complaint TEXT, history TEXT, examination TEXT, diagnosis TEXT, advice TEXT, follow_up_at TEXT, notes TEXT,
 status TEXT NOT NULL DEFAULT 'OPEN' CHECK(status IN('OPEN','FINALIZED','AMENDED','CANCELLED')), created_by TEXT NOT NULL REFERENCES users(id), created_at TEXT NOT NULL, updated_at TEXT NOT NULL
);
CREATE TABLE clinical_notes (id TEXT PRIMARY KEY, patient_id TEXT NOT NULL REFERENCES patients(id), visit_id TEXT REFERENCES visits(id), note_type TEXT NOT NULL, body TEXT NOT NULL, created_by TEXT NOT NULL REFERENCES users(id), created_at TEXT NOT NULL, updated_at TEXT NOT NULL, archived_at TEXT);
CREATE TABLE dental_charts (id TEXT PRIMARY KEY, patient_id TEXT NOT NULL REFERENCES patients(id), visit_id TEXT REFERENCES visits(id), dentition TEXT NOT NULL CHECK(dentition IN('ADULT','PEDIATRIC')), numbering_system TEXT NOT NULL DEFAULT 'FDI', recorded_by TEXT NOT NULL REFERENCES users(id), recorded_at TEXT NOT NULL);
CREATE TABLE tooth_conditions (
 id TEXT PRIMARY KEY, chart_id TEXT NOT NULL REFERENCES dental_charts(id) ON DELETE CASCADE, tooth_code TEXT NOT NULL, condition TEXT NOT NULL,
 surfaces_json TEXT NOT NULL DEFAULT '[]', mobility_grade INTEGER, note TEXT, recorded_at TEXT NOT NULL, UNIQUE(chart_id,tooth_code,condition)
);
CREATE TABLE treatments (
 id TEXT PRIMARY KEY, clinic_id TEXT NOT NULL REFERENCES clinics(id), treatment_code TEXT NOT NULL, name TEXT NOT NULL, category TEXT NOT NULL,
 description TEXT, default_fee_minor INTEGER NOT NULL DEFAULT 0 CHECK(default_fee_minor>=0), duration_minutes INTEGER NOT NULL DEFAULT 30 CHECK(duration_minutes>0), tax_basis_points INTEGER NOT NULL DEFAULT 0 CHECK(tax_basis_points BETWEEN 0 AND 10000),
 is_active INTEGER NOT NULL DEFAULT 1 CHECK(is_active IN(0,1)), notes TEXT, created_at TEXT NOT NULL, updated_at TEXT NOT NULL, UNIQUE(clinic_id,treatment_code)
);
CREATE TABLE treatment_records (
 id TEXT PRIMARY KEY, patient_id TEXT NOT NULL REFERENCES patients(id), visit_id TEXT REFERENCES visits(id), dentist_id TEXT NOT NULL REFERENCES dentists(id), treatment_id TEXT NOT NULL REFERENCES treatments(id),
 tooth_code TEXT, surfaces_json TEXT NOT NULL DEFAULT '[]', quantity INTEGER NOT NULL DEFAULT 1 CHECK(quantity>0), unit_price_minor INTEGER NOT NULL CHECK(unit_price_minor>=0), discount_minor INTEGER NOT NULL DEFAULT 0 CHECK(discount_minor>=0),
 total_minor INTEGER NOT NULL CHECK(total_minor>=0), status TEXT NOT NULL CHECK(status IN('PLANNED','IN_PROGRESS','COMPLETED','CANCELLED')), notes TEXT, performed_at TEXT NOT NULL, created_by TEXT NOT NULL REFERENCES users(id), created_at TEXT NOT NULL
);
CREATE TABLE appointments (
 id TEXT PRIMARY KEY, patient_id TEXT NOT NULL REFERENCES patients(id), dentist_id TEXT NOT NULL REFERENCES dentists(id), starts_at TEXT NOT NULL, ends_at TEXT NOT NULL,
 reason TEXT NOT NULL, notes TEXT, status TEXT NOT NULL CHECK(status IN('SCHEDULED','CONFIRMED','ARRIVED','IN_TREATMENT','COMPLETED','CANCELLED','NO_SHOW','RESCHEDULED')),
 reminder_at TEXT, appointment_type TEXT NOT NULL DEFAULT 'GENERAL', rescheduled_from_id TEXT REFERENCES appointments(id), created_by TEXT NOT NULL REFERENCES users(id), created_at TEXT NOT NULL, updated_at TEXT NOT NULL, CHECK(ends_at>starts_at)
);
CREATE TABLE queue_entries (
 id TEXT PRIMARY KEY, clinic_id TEXT NOT NULL REFERENCES clinics(id), patient_id TEXT NOT NULL REFERENCES patients(id), appointment_id TEXT REFERENCES appointments(id), dentist_id TEXT REFERENCES dentists(id), queue_date TEXT NOT NULL, queue_number INTEGER NOT NULL CHECK(queue_number>0),
 priority INTEGER NOT NULL DEFAULT 0 CHECK(priority BETWEEN 0 AND 9), arrived_at TEXT NOT NULL, called_at TEXT, started_at TEXT, completed_at TEXT,
 status TEXT NOT NULL CHECK(status IN('WAITING','CALLED','IN_CONSULTATION','TREATMENT','COMPLETED','CANCELLED')), created_by TEXT NOT NULL REFERENCES users(id), updated_at TEXT NOT NULL, UNIQUE(clinic_id,queue_date,queue_number)
);
CREATE TABLE prescriptions (
 id TEXT PRIMARY KEY, clinic_id TEXT NOT NULL REFERENCES clinics(id), patient_id TEXT NOT NULL REFERENCES patients(id), visit_id TEXT REFERENCES visits(id), dentist_id TEXT NOT NULL REFERENCES dentists(id),
 prescription_number TEXT NOT NULL, prescribed_at TEXT NOT NULL, chief_complaints TEXT, examination TEXT, relevant_examination TEXT, advice TEXT, additional_notes TEXT,
 status TEXT NOT NULL DEFAULT 'DRAFT' CHECK(status IN('DRAFT','FINALIZED','AMENDED','CANCELLED')), created_by TEXT NOT NULL REFERENCES users(id), created_at TEXT NOT NULL, updated_at TEXT NOT NULL, UNIQUE(clinic_id,prescription_number)
);
CREATE TABLE prescription_items (
 id TEXT PRIMARY KEY, prescription_id TEXT NOT NULL REFERENCES prescriptions(id) ON DELETE RESTRICT, sort_order INTEGER NOT NULL, medicine_name TEXT NOT NULL,
 form TEXT NOT NULL, strength TEXT, dose TEXT, frequency TEXT, morning INTEGER NOT NULL DEFAULT 0, noon INTEGER NOT NULL DEFAULT 0, night INTEGER NOT NULL DEFAULT 0,
 food_timing TEXT, duration TEXT, quantity TEXT, instructions TEXT, is_prn INTEGER NOT NULL DEFAULT 0 CHECK(is_prn IN(0,1)), UNIQUE(prescription_id,sort_order)
);
CREATE TABLE invoices (
 id TEXT PRIMARY KEY, clinic_id TEXT NOT NULL REFERENCES clinics(id), patient_id TEXT NOT NULL REFERENCES patients(id), invoice_number TEXT NOT NULL, issued_at TEXT NOT NULL,
 subtotal_minor INTEGER NOT NULL CHECK(subtotal_minor>=0), discount_minor INTEGER NOT NULL DEFAULT 0 CHECK(discount_minor>=0), tax_minor INTEGER NOT NULL DEFAULT 0 CHECK(tax_minor>=0),
 total_minor INTEGER NOT NULL CHECK(total_minor>=0), status TEXT NOT NULL CHECK(status IN('DRAFT','FINALIZED','VOID','ADJUSTED')),
 payment_status TEXT NOT NULL CHECK(payment_status IN('UNPAID','PARTIALLY_PAID','PAID','REFUNDED','ADJUSTED')), notes TEXT, created_by TEXT NOT NULL REFERENCES users(id), created_at TEXT NOT NULL, updated_at TEXT NOT NULL, UNIQUE(clinic_id,invoice_number)
);
CREATE TABLE invoice_items (
 id TEXT PRIMARY KEY, invoice_id TEXT NOT NULL REFERENCES invoices(id) ON DELETE RESTRICT, treatment_record_id TEXT REFERENCES treatment_records(id), description TEXT NOT NULL,
 quantity INTEGER NOT NULL CHECK(quantity>0), unit_price_minor INTEGER NOT NULL CHECK(unit_price_minor>=0), discount_minor INTEGER NOT NULL DEFAULT 0 CHECK(discount_minor>=0), tax_minor INTEGER NOT NULL DEFAULT 0 CHECK(tax_minor>=0), total_minor INTEGER NOT NULL CHECK(total_minor>=0), sort_order INTEGER NOT NULL, UNIQUE(invoice_id,sort_order)
);
CREATE TABLE payments (
 id TEXT PRIMARY KEY, clinic_id TEXT NOT NULL REFERENCES clinics(id), patient_id TEXT NOT NULL REFERENCES patients(id), paid_at TEXT NOT NULL, amount_minor INTEGER NOT NULL CHECK(amount_minor>0),
 method TEXT NOT NULL CHECK(method IN('CASH','BANK','CARD','BKASH','NAGAD','ROCKET','UPAY','OTHER_MOBILE_WALLET','OTHER')), reference TEXT, notes TEXT,
 received_by TEXT NOT NULL REFERENCES users(id), dentist_id TEXT REFERENCES dentists(id), status TEXT NOT NULL DEFAULT 'POSTED' CHECK(status IN('POSTED','REVERSED')), created_at TEXT NOT NULL
);
CREATE TABLE payment_allocations (id TEXT PRIMARY KEY, payment_id TEXT NOT NULL REFERENCES payments(id), invoice_id TEXT NOT NULL REFERENCES invoices(id), amount_minor INTEGER NOT NULL CHECK(amount_minor>0), created_at TEXT NOT NULL, UNIQUE(payment_id,invoice_id));
CREATE TABLE refunds (id TEXT PRIMARY KEY, clinic_id TEXT NOT NULL REFERENCES clinics(id), payment_id TEXT NOT NULL REFERENCES payments(id), amount_minor INTEGER NOT NULL CHECK(amount_minor>0), reason TEXT NOT NULL, refunded_at TEXT NOT NULL, created_by TEXT NOT NULL REFERENCES users(id));
CREATE TABLE suppliers (id TEXT PRIMARY KEY, clinic_id TEXT NOT NULL REFERENCES clinics(id), name TEXT NOT NULL, company TEXT, phone TEXT, address TEXT, email TEXT, notes TEXT, is_active INTEGER NOT NULL DEFAULT 1, created_at TEXT NOT NULL, updated_at TEXT NOT NULL);
CREATE TABLE inventory_items (
 id TEXT PRIMARY KEY, clinic_id TEXT NOT NULL REFERENCES clinics(id), item_code TEXT NOT NULL, name TEXT NOT NULL, category TEXT NOT NULL, unit TEXT NOT NULL,
 supplier_id TEXT REFERENCES suppliers(id), purchase_price_minor INTEGER NOT NULL DEFAULT 0, internal_cost_minor INTEGER NOT NULL DEFAULT 0, minimum_stock_minor INTEGER NOT NULL DEFAULT 0,
 reorder_threshold_minor INTEGER NOT NULL DEFAULT 0, storage_location TEXT, is_active INTEGER NOT NULL DEFAULT 1, created_at TEXT NOT NULL, updated_at TEXT NOT NULL, UNIQUE(clinic_id,item_code)
);
CREATE TABLE inventory_batches (id TEXT PRIMARY KEY, item_id TEXT NOT NULL REFERENCES inventory_items(id), batch_number TEXT, expiry_date TEXT, purchase_date TEXT, unit_cost_minor INTEGER NOT NULL DEFAULT 0, created_at TEXT NOT NULL);
CREATE TABLE inventory_transactions (
 id TEXT PRIMARY KEY, item_id TEXT NOT NULL REFERENCES inventory_items(id), batch_id TEXT REFERENCES inventory_batches(id), kind TEXT NOT NULL CHECK(kind IN('PURCHASE','STOCK_IN','STOCK_OUT','ADJUSTMENT','DAMAGED','EXPIRED','TREATMENT_USE','CORRECTION')),
 quantity_minor INTEGER NOT NULL CHECK(quantity_minor<>0), reference_type TEXT, reference_id TEXT, reason TEXT, occurred_at TEXT NOT NULL, created_by TEXT NOT NULL REFERENCES users(id), created_at TEXT NOT NULL
);
CREATE TABLE purchases (id TEXT PRIMARY KEY, clinic_id TEXT NOT NULL REFERENCES clinics(id), supplier_id TEXT NOT NULL REFERENCES suppliers(id), purchase_number TEXT NOT NULL, purchased_at TEXT NOT NULL, total_minor INTEGER NOT NULL CHECK(total_minor>=0), status TEXT NOT NULL, created_by TEXT NOT NULL REFERENCES users(id), UNIQUE(clinic_id,purchase_number));
CREATE TABLE purchase_items (id TEXT PRIMARY KEY, purchase_id TEXT NOT NULL REFERENCES purchases(id), item_id TEXT NOT NULL REFERENCES inventory_items(id), batch_id TEXT REFERENCES inventory_batches(id), quantity_minor INTEGER NOT NULL CHECK(quantity_minor>0), unit_cost_minor INTEGER NOT NULL CHECK(unit_cost_minor>=0), total_minor INTEGER NOT NULL CHECK(total_minor>=0));
CREATE TABLE accounts (id TEXT PRIMARY KEY, clinic_id TEXT NOT NULL REFERENCES clinics(id), code TEXT NOT NULL, name TEXT NOT NULL, type TEXT NOT NULL CHECK(type IN('ASSET','LIABILITY','EQUITY','INCOME','EXPENSE')), parent_id TEXT REFERENCES accounts(id), is_active INTEGER NOT NULL DEFAULT 1, UNIQUE(clinic_id,code));
CREATE TABLE journal_entries (id TEXT PRIMARY KEY, clinic_id TEXT NOT NULL REFERENCES clinics(id), entry_number TEXT NOT NULL, entry_at TEXT NOT NULL, description TEXT NOT NULL, reference_type TEXT, reference_id TEXT, status TEXT NOT NULL CHECK(status IN('DRAFT','POSTED','REVERSED')), created_by TEXT NOT NULL REFERENCES users(id), posted_at TEXT, UNIQUE(clinic_id,entry_number));
CREATE TABLE journal_lines (id TEXT PRIMARY KEY, entry_id TEXT NOT NULL REFERENCES journal_entries(id), account_id TEXT NOT NULL REFERENCES accounts(id), debit_minor INTEGER NOT NULL DEFAULT 0 CHECK(debit_minor>=0), credit_minor INTEGER NOT NULL DEFAULT 0 CHECK(credit_minor>=0), description TEXT, CHECK((debit_minor>0 AND credit_minor=0) OR (credit_minor>0 AND debit_minor=0)));
CREATE TABLE expenses (id TEXT PRIMARY KEY, clinic_id TEXT NOT NULL REFERENCES clinics(id), journal_entry_id TEXT NOT NULL REFERENCES journal_entries(id), category TEXT NOT NULL, amount_minor INTEGER NOT NULL CHECK(amount_minor>0), expense_at TEXT NOT NULL, payee TEXT, notes TEXT, created_by TEXT NOT NULL REFERENCES users(id));
CREATE TABLE referrals (id TEXT PRIMARY KEY, patient_id TEXT NOT NULL REFERENCES patients(id), referral_at TEXT NOT NULL, referred_by TEXT, referred_to TEXT, doctor TEXT, institution TEXT, reason TEXT NOT NULL, notes TEXT, status TEXT NOT NULL, follow_up_at TEXT, created_by TEXT NOT NULL REFERENCES users(id));
CREATE TABLE attachments (id TEXT PRIMARY KEY, patient_id TEXT NOT NULL REFERENCES patients(id), visit_id TEXT REFERENCES visits(id), stored_name TEXT NOT NULL UNIQUE, display_name TEXT NOT NULL, media_type TEXT NOT NULL, size_bytes INTEGER NOT NULL CHECK(size_bytes>=0), sha256 TEXT NOT NULL, description TEXT, created_by TEXT NOT NULL REFERENCES users(id), created_at TEXT NOT NULL, archived_at TEXT);
CREATE TABLE notifications (id TEXT PRIMARY KEY, clinic_id TEXT NOT NULL REFERENCES clinics(id), user_id TEXT REFERENCES users(id), severity TEXT NOT NULL CHECK(severity IN('INFO','SUCCESS','WARNING','DANGER')), category TEXT NOT NULL, title TEXT NOT NULL, body TEXT NOT NULL, entity_type TEXT, entity_id TEXT, route TEXT, created_at TEXT NOT NULL, read_at TEXT, dismissed_at TEXT);
CREATE TABLE audit_logs (id TEXT PRIMARY KEY, clinic_id TEXT, occurred_at TEXT NOT NULL, user_id TEXT, role_names TEXT, action TEXT NOT NULL, entity_type TEXT NOT NULL, entity_id TEXT, summary TEXT NOT NULL, before_json TEXT, after_json TEXT, context_json TEXT NOT NULL DEFAULT '{}', previous_hash TEXT, entry_hash TEXT NOT NULL UNIQUE);
CREATE TABLE settings (clinic_id TEXT NOT NULL REFERENCES clinics(id), key TEXT NOT NULL, value_json TEXT NOT NULL, updated_by TEXT REFERENCES users(id), updated_at TEXT NOT NULL, PRIMARY KEY(clinic_id,key));
CREATE TABLE printer_profiles (id TEXT PRIMARY KEY, clinic_id TEXT NOT NULL REFERENCES clinics(id), name TEXT NOT NULL, document_type TEXT NOT NULL, printer_name TEXT, paper_kind TEXT NOT NULL CHECK(paper_kind IN('A4','A5','THERMAL_80','THERMAL_58','CUSTOM')), width_mm INTEGER, height_mm INTEGER, margins_json TEXT NOT NULL, orientation TEXT NOT NULL, scale_percent INTEGER NOT NULL DEFAULT 100, copies INTEGER NOT NULL DEFAULT 1, is_default INTEGER NOT NULL DEFAULT 0, UNIQUE(clinic_id,name));
CREATE TABLE backups (id TEXT PRIMARY KEY, clinic_id TEXT NOT NULL REFERENCES clinics(id), path TEXT NOT NULL, created_at TEXT NOT NULL, completed_at TEXT, size_bytes INTEGER, sha256 TEXT, status TEXT NOT NULL CHECK(status IN('RUNNING','SUCCESS','FAILED')), error_message TEXT, app_version TEXT NOT NULL, created_by TEXT REFERENCES users(id));

CREATE INDEX idx_patients_clinic_registered ON patients(clinic_id, registration_at DESC) WHERE archived_at IS NULL;
CREATE INDEX idx_patients_name ON patients(clinic_id, full_name COLLATE NOCASE);
CREATE INDEX idx_patients_phone ON patients(clinic_id, phone);
CREATE INDEX idx_visits_patient_date ON visits(patient_id, visit_at DESC);
CREATE INDEX idx_appointments_dentist_start ON appointments(dentist_id, starts_at);
CREATE INDEX idx_appointments_patient_start ON appointments(patient_id, starts_at DESC);
CREATE INDEX idx_queue_date_status ON queue_entries(clinic_id, queue_date, status, priority DESC, arrived_at);
CREATE INDEX idx_prescriptions_patient_date ON prescriptions(patient_id, prescribed_at DESC);
CREATE INDEX idx_invoices_patient_date ON invoices(patient_id, issued_at DESC);
CREATE INDEX idx_payments_patient_date ON payments(patient_id, paid_at DESC);
CREATE INDEX idx_inventory_tx_item_date ON inventory_transactions(item_id, occurred_at DESC);
CREATE INDEX idx_journal_date ON journal_entries(clinic_id, entry_at DESC) WHERE status='POSTED';
CREATE INDEX idx_attachments_patient ON attachments(patient_id, created_at DESC) WHERE archived_at IS NULL;
CREATE INDEX idx_notifications_user_unread ON notifications(user_id, created_at DESC) WHERE read_at IS NULL AND dismissed_at IS NULL;
CREATE INDEX idx_audit_clinic_date ON audit_logs(clinic_id, occurred_at DESC);

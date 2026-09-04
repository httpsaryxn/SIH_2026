# FreshLabel Pro Supabase schema contract

This is the shared database contract for all application branches. Its source migrations are [regulator_compliance_contract.sql](supabase/migrations/20260829090000_regulator_compliance_contract.sql) and [harden_regulator_function_access.sql](supabase/migrations/20260829093000_harden_regulator_function_access.sql). The active Supabase project is `tyshfugxmwvhbmoydlnl` (LabelLens).

`uuid` company identifiers always point to `public.users.id`. A company is the same user's `business_profiles` (or legacy `small_businesses`/`large_businesses`) profile.

## Enum and controlled values

- `user_role` enum: `business_owner` (unified role), `consumer`, `regulator` (legacy `small_business` and `large_business` remain supported for backward compatibility).
- `consumer_complaints.status`: `Submitted`, `Under Review`, `Verified`, `Forwarded`, `Rejected`.
- `consumer_complaints.priority`: `Critical`, `High Priority`, `Allergen Flag`, `Weight Discrepancy`, `Pricing Violation`, `Medium Priority`, `Low Priority`, `Normal`.
- `regulator_scans.source_type`: `field_photo`, `ecommerce_url`, `consumer_evidence`, `batch_upload`; `status`: `queued`, `processing`, `completed`, `failed`.
- `declaration_checks.status`: `Compliant`, `Warning`, `Violation`, `Unable to Verify`.
- `regulator_violations.severity`: `Critical`, `High`, `Medium`, `Low`; `risk_level`: `Critical Risk`, `High Risk`, `Medium Risk`, `Low Risk`; `status`: `pending`, `confirmed`, `false_positive`, `escalated`, `manual_review`, `resolved`.
- `regulator_notices.status`: `Draft`, `Issued`, `Acknowledged`, `Resolved`, `Withdrawn`.
- `company_timeline_events.event_type`: `complaint_verified`, `complaint_rejected`, `violation`, `audit_passed`, `notice_issued`, `response_received`, `corrective_action`, `re_audit`, `status_change`.

## Role and product tables

All tables below use `id` as their primary key unless noted.

| Table | Columns | Foreign keys |
|---|---|---|
| `users` | `id uuid`, `email text unique`, `full_name text?`, `role user_role`, `avatar_url text?`, `created_at timestamptz`, `updated_at timestamptz` | `id → auth.users.id` |
| `business_profiles` | `id uuid`, `business_name text`, `company_name text?`, `business_type text?`, `gstin text?`, `fssai_license_no text?`, `cin text?`, `registered_address text?`, `address text?`, `city text?`, `state text?`, `pincode text?`, `contact_number text?`, `contact_email text?`, `nodal_officer_name text?`, timestamps | `id → users.id` |
| `regulators` | `id uuid`, `department_name text`, `designation text?`, `official_id text?`, `jurisdiction_region text?`, `verification_status text`, timestamps | `id → users.id` |
| `consumers` | `id uuid`, `phone_number text?`, `city text?`, `state text?`, `pincode text?`, timestamps | `id → users.id` |
| `small_businesses` | (Legacy alias) `id uuid`, `business_name text`, `gstin text?`, `fssai_license_no text?`, `address text?`, `city text?`, `state text?`, `pincode text?`, `contact_number text?`, timestamps | `id → users.id` |
| `large_businesses` | (Legacy alias) `id uuid`, `company_name text`, `cin text?`, `gstin text?`, `registered_address text?`, `nodal_officer_name text?`, `contact_email text?`, `contact_number text?`, timestamps | `id → users.id` |
| `products` | `id uuid`, `barcode text? unique`, `product_name text`, `brand text`, `category text?`, `net_quantity text?`, `mrp numeric?`, `ingredients text[]?`, `nutrition_facts jsonb`, `manufacturer_name text?`, `manufacturer_address text?`, `fssai_license_no text?`, `image_url text?`, `compliance_status text`, `compliance_issues jsonb`, `created_at timestamptz`, `company_id uuid?` | `company_id → users.id` |
| `consumer_scans` | `id uuid`, `consumer_id uuid`, `product_id uuid?`, `product_name text`, `brand text?`, `net_quantity text?`, `image_url text?`, `compliance_status text`, `detected_declarations jsonb`, `scan_notes text?`, `scanned_at timestamptz` | `consumer_id → users.id`; `product_id → products.id` |
| `saved_products` | `id uuid`, `consumer_id uuid`, `product_id uuid?`, `product_name text`, `brand text?`, `category text?`, `quantity text?`, `image_url text?`, `saved_at timestamptz` | `consumer_id → users.id`; `product_id → products.id` |
| `consumer_notifications` | `id uuid`, `consumer_id uuid`, `title text`, `message text`, `type text`, `related_complaint_id uuid?`, `is_read bool`, `created_at timestamptz` | `consumer_id → users.id`; `related_complaint_id → consumer_complaints.id` |

## Shared Consumer → Regulator complaint contract

`consumer_complaints` is the only complaint table. Do not create a per-role complaint table or synchronize copies.

| Column | Type / rule |
|---|---|
| `id` | `uuid`, primary key, generated |
| `complaint_code` | `text`, unique; Consumer should supply a unique readable code |
| `consumer_id` | `uuid`; must equal `auth.uid()` for a consumer insert; FK → `users.id` |
| `product_id` | `uuid?`; FK → `products.id` |
| `company_id` | `uuid?`; FK → `users.id`; use the product's `company_id` when known |
| `product_name`, `brand`, `issue_category`, `description` | existing product/report fields; `product_name`, `issue_category`, `description` are required |
| `title`, `category` | regulator display title and product category; Consumer should populate both |
| `location_name`, `address`, `store_location` | point-of-sale/location text; use `location_name` and `address` for new writes; retain `store_location` for legacy compatibility |
| `latitude`, `longitude` | `numeric(9,6)?` GPS coordinates |
| `evidence_urls` | non-null `text[]`, default `{}`; primary multi-image evidence field |
| `evidence_image_url` | legacy single-image `text?`; only retained for older data |
| `status` | controlled value; default `Submitted`; consumers must not write another initial status |
| `priority` | controlled value; default `Normal` |
| `regulator_notes` | `text?`, regulator-owned |
| `assigned_regulator_id`, `verified_by`, `rejected_by` | `uuid?`, each FK → `users.id`, regulator-owned |
| `verified_at`, `rejected_at`, `created_at`, `updated_at` | `timestamptz?` (creation/update timestamps default to `now()`) |

### Consumer insertion contract

Insert one row into `consumer_complaints` with `consumer_id: supabase.auth.currentUser!.id`, `status: 'Submitted'`, and `evidence_urls` as a list of uploaded evidence URLs. Link `product_id` and `company_id` whenever barcode/product lookup provides them. An unlinked complaint is valid, but the regulator cannot verify-and-forward it until it is linked to a company.

The database rejects consumer attempts to submit on someone else's behalf, non-consumer submissions, or any regulatory status/assignment fields. Consumers can read only their own complaints. They cannot update a filed complaint.

### Required chain

1. Consumer inserts `consumer_complaints`.
2. Regulator calls RPC `verify_and_forward_complaint(p_complaint_id)`.
3. The RPC requires `company_id`, sets `status = 'Forwarded'`, regulator actor fields, and time.
4. The `log_complaint_status_change` trigger inserts a `company_timeline_events` row with `event_type = 'complaint_verified'`.
5. The business's future compliance UI reads that same timeline. No polling/sync/copy is permitted.

Status updates also invoke `notify_consumer_complaint_update`, creating a row in `consumer_notifications` for the reporting consumer.

## Regulator enforcement tables

| Table | Columns | Foreign keys |
|---|---|---|
| `regulator_scans` | `id uuid`, `scan_code text unique`, `company_id uuid?`, `product_id uuid?`, `captured_by uuid`, `source_type text`, `source_url text?`, `image_url text?`, `product_name text`, `company_name text?`, `category text?`, `region text?`, `store_location text?`, `ocr_text text?`, `confidence_score int (0–100)`, `status text`, `captured_at`, `created_at`, `updated_at` | `company_id → users.id`; `product_id → products.id`; `captured_by → users.id` |
| `declaration_checks` | `id uuid`, `scan_id uuid`, `field_name text`, `extracted_value text`, `confidence_percent int (0–100)`, `status text`, `rule_citation text`, `rule_description text`, `top_percent`, `left_percent`, `width_percent`, `height_percent` numeric(6,5)?, `created_at` | `scan_id → regulator_scans.id` cascade. All four bounds are null or each is in `[0,1]`. |
| `regulator_violations` | `id uuid`, `scan_id uuid`, `company_id uuid?`, `product_id uuid?`, `complaint_id uuid?`, `severity text`, `risk_level text`, `confidence_score int (0–100)`, `violation_type text`, `violation_summary text`, `status text`, `reviewed_by uuid?`, `reviewed_at timestamptz?`, timestamps | `scan_id → regulator_scans.id` cascade; `company_id`, `reviewed_by → users.id`; `product_id → products.id`; `complaint_id → consumer_complaints.id` |
| `regulator_notices` | `id uuid`, `notice_number text unique`, `violation_id uuid`, `company_id uuid`, `rule_violated text`, `rule_citation text`, `issue_date`, `deadline_date`, `status text`, `officer_notes text`, `issued_by uuid?`, `evidence_summary text`, timestamps | `violation_id → regulator_violations.id`; `company_id`, `issued_by → users.id`; deadline must not precede issue date |
| `company_timeline_events` | `id uuid`, `company_id uuid`, `event_type text`, `title text`, `description text`, `actor_id uuid?`, `actor_name text`, `batch_no text?`, `complaint_id uuid?`, `violation_id uuid?`, `notice_id uuid?`, `occurred_at`, `created_at` | `company_id`, `actor_id → users.id`; `complaint_id → consumer_complaints.id`; `violation_id → regulator_violations.id`; `notice_id → regulator_notices.id` |

`company_compliance_overview` is a read-only `security_invoker` view over `users`, `small_businesses`, `large_businesses`, scans, violations, and notices. It exposes `company_id`, `company_name`, `address`, `region`, `category`, derived `compliance_score`, `open_violations_count`, `notices_issued_count`, `last_audit_date`, and derived status. Use it for business lookup and regulator company lists; do not try to insert into it.

## RLS policy matrix

Every `public` table has RLS enabled. Existing and added policies are:

| Table | Policies |
|---|---|
| `users` | Own profile select/update; regulators can select all profiles. |
| `regulators`, `consumers`, `small_businesses`, `large_businesses` | Owner select/update; regulators can select all respective profile rows. |
| `products` | Public select; authenticated insert. |
| `consumer_scans`, `saved_products` | Consumer owner select/insert/delete. |
| `consumer_notifications` | Consumer owner select/update. Rows are produced by database triggers. |
| `consumer_complaints` | Consumer insert/read own; regulator read/update all; business read only rows where `company_id = auth.uid()`. |
| `regulator_scans` | Regulator full CRUD; business select only `company_id = auth.uid()`. |
| `declaration_checks` | Regulator full CRUD; business select only checks belonging to its scans. |
| `regulator_violations` | Regulator full CRUD; business select only `company_id = auth.uid()`. |
| `company_timeline_events` | Regulator select; business select only `company_id = auth.uid()`. No client insert/update/delete policy; events are database-owned audit records. |
| `regulator_notices` | Regulator full CRUD; business select only `company_id = auth.uid()`. |

The non-REST `private` schema contains the `SECURITY DEFINER` role helpers `is_regulator()`, `is_business_user()`, and `current_actor_name()`, used by policies and workflows. Trigger functions have no client execute grant. The only regulator RPCs exposed to signed-in clients are `verify_and_forward_complaint`, `reject_complaint`, `generate_notice_draft`, and `get_regulator_dashboard_metrics`; each checks the regulator role itself.

## Realtime

`consumer_complaints` and `regulator_violations` are members of the `supabase_realtime` publication. Postgres Changes obey the same RLS select policies. The regulator app subscribes to violations for the Home priority queue and complaints for the inbox/home metrics; cancel subscriptions when their screens dispose.

## Supabase Storage (`compliance-images`)

Evidence photos, product label captures, and scan images are stored in the private Supabase Storage bucket `compliance-images`.

### Bucket configuration
- **Bucket name**: `compliance-images`
- **Visibility**: `private` (`public = false`)
- **File size limit**: 10 MB (`10485760` bytes)
- **Allowed MIME types**: `image/jpeg`, `image/png`, `image/webp`, `image/heic`, `image/jpg`
- **Access model**: Signed URLs generated on-demand with 1-year expiration (or direct storage path access for backend).

### Path structure convention
Paths are strictly hierarchical and traceable without database lookups:
```
compliance-images/{source}/{user_id}/{record_id}/{filename}
```
- `{source}`: `regulator_scans` | `consumer_scans` | `consumer_complaints`
- `{user_id}`: `auth.uid()` of the uploader
- `{record_id}`: Unique identifier for the associated entity (`scan_code`, `complaint_code`, or scan UUID)
- `{filename}`: Unique collision-safe cached filename (e.g. `scan_regulator_field_1788190333041_8a9377.jpg`)

### Storage RLS policies
1. `compliance_images_insert`: Allows authenticated users to upload if `(storage.foldername(name))[2] = auth.uid()` OR `users.role = 'regulator'`.
2. `compliance_images_read`: Allows users to read their own uploaded files (`(storage.foldername(name))[2] = auth.uid()`) OR regulators (`users.role = 'regulator'`) to read all evidence files.
3. `compliance_images_delete`: Allows deletion only by file owner or regulator.

### Database column mapping
| Table | Column | Type | Description |
|---|---|---|---|
| `regulator_scans` | `image_url` | `text?` | Signed URL or storage path for field inspection photo |
| `consumer_scans` | `image_url` | `text?` | Signed URL or storage path for scanned consumer product label |
| `products` | `image_url` | `text?` | Product label catalog image |
| `consumer_complaints` | `evidence_urls` | `text[]` | Array of uploaded evidence image signed URLs |
| `consumer_complaints` | `evidence_image_url` | `text?` | Primary evidence image URL for single-image backwards compatibility |

## Business Label Verification Requests (`label_verification_requests`)

> [!NOTE]
> **STUB TABLE** — The business branch has a separate Supabase project. This table exists in the main Supabase project (`tyshfugxmwvhbmoydlnl`) so that RLS, schema validation, and unified queue queries are live and fully typed in the mobile app. It will require a cross-project sync or migration once branches merge. Currently seeded with sample compliance review requests.

| Column | Type | Constraints / Defaults | Description |
|---|---|---|---|
| `id` | `uuid` | `PRIMARY KEY DEFAULT gen_random_uuid()` | Unique verification request identifier |
| `request_code` | `text` | `UNIQUE NOT NULL` | Human-readable tracking code (e.g. `LVR-2026-001`) |
| `business_id` | `uuid?` | `REFERENCES public.users(id) ON DELETE SET NULL` | Submitting business user account (loose FK) |
| `business_name` | `text` | `NOT NULL` | Denormalized enterprise brand name |
| `product_name` | `text` | `NOT NULL` | Declared commodity name |
| `brand` | `text?` | | Registered brand |
| `category` | `text?` | | Commodity category (e.g. Packaged Food, Beverages) |
| `label_image_url` | `text` | `NOT NULL` | High-resolution packaging label artwork photo |
| `declarations` | `jsonb` | `DEFAULT '[]'::jsonb` | Extracted declarations (Net Qty, MRP, Font Height, etc.) |
| `status` | `text` | `DEFAULT 'pending' CHECK ('pending', 'under_review', 'approved', 'rejected')` | Compliance lifecycle status |
| `priority` | `text` | `DEFAULT 'Normal' CHECK ('High Priority', 'Normal', 'Urgent')` | Processing priority |
| `reviewed_by` | `uuid?` | `REFERENCES public.users(id) ON DELETE SET NULL` | Regulator officer who reviewed the request |
| `reviewed_at` | `timestamptz?` | | Timestamp of regulatory clearance / rejection |
| `regulator_notes` | `text?` | | Officer feedback or required font/format changes |
| `submitted_at` | `timestamptz` | `DEFAULT now()` | Submission timestamp |
| `created_at` / `updated_at` | `timestamptz` | `DEFAULT now()` | Record timestamps |

### RLS Policies
- `label_verification_requests_select`: Authenticated users can query label requests.
- `label_verification_requests_all_regulator`: Regulators have full CRUD access to review and approve/reject label requests.



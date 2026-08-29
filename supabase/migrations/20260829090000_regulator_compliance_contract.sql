-- FreshLabel Pro shared regulator/consumer compliance contract.
-- This migration extends the existing role-profile and consumer tables; it
-- deliberately does not create separate per-role complaint or company tables.

create or replace function public.is_regulator()
returns boolean
language sql
stable
security definer
set search_path = public, auth
as $$
  select exists (
    select 1 from public.users
    where id = auth.uid() and role = 'regulator'::public.user_role
  );
$$;

create or replace function public.is_business_user()
returns boolean
language sql
stable
security definer
set search_path = public, auth
as $$
  select exists (
    select 1 from public.users
    where id = auth.uid()
      and role in ('small_business'::public.user_role, 'large_business'::public.user_role)
  );
$$;

create or replace function public.current_actor_name()
returns text
language sql
stable
security definer
set search_path = public, auth
as $$
  select coalesce(full_name, email, 'System') from public.users where id = auth.uid();
$$;

alter table public.products
  add column if not exists company_id uuid references public.users(id) on delete set null;

alter table public.consumer_complaints
  add column if not exists title text,
  add column if not exists category text,
  add column if not exists location_name text,
  add column if not exists address text,
  add column if not exists latitude numeric(9, 6),
  add column if not exists longitude numeric(9, 6),
  add column if not exists evidence_urls text[] not null default '{}',
  add column if not exists product_id uuid references public.products(id) on delete set null,
  add column if not exists company_id uuid references public.users(id) on delete set null,
  add column if not exists assigned_regulator_id uuid references public.users(id) on delete set null,
  add column if not exists verified_by uuid references public.users(id) on delete set null,
  add column if not exists verified_at timestamptz,
  add column if not exists rejected_by uuid references public.users(id) on delete set null,
  add column if not exists rejected_at timestamptz,
  add column if not exists priority text not null default 'Normal';

update public.consumer_complaints
set
  status = case lower(status)
    when 'submitted' then 'Submitted'
    when 'under review' then 'Under Review'
    when 'verified' then 'Verified'
    when 'forwarded' then 'Forwarded'
    when 'rejected' then 'Rejected'
    else 'Submitted'
  end,
  title = coalesce(nullif(title, ''), nullif(issue_category, ''), 'Consumer complaint'),
  category = coalesce(nullif(category, ''), nullif(issue_category, ''), 'Packaged commodity'),
  location_name = coalesce(nullif(location_name, ''), nullif(store_location, ''), 'Location not provided'),
  address = coalesce(nullif(address, ''), nullif(store_location, ''), 'Address not provided'),
  evidence_urls = case
    when cardinality(evidence_urls) > 0 then evidence_urls
    when evidence_image_url is not null and evidence_image_url <> '' then array[evidence_image_url]
    else '{}'::text[]
  end;

alter table public.consumer_complaints
  alter column status set default 'Submitted';

alter table public.consumer_complaints
  drop constraint if exists consumer_complaints_status_check,
  add constraint consumer_complaints_status_check
    check (status in ('Submitted', 'Under Review', 'Verified', 'Forwarded', 'Rejected')),
  drop constraint if exists consumer_complaints_priority_check,
  add constraint consumer_complaints_priority_check
    check (priority in ('Critical', 'High Priority', 'Allergen Flag', 'Weight Discrepancy', 'Pricing Violation', 'Medium Priority', 'Low Priority', 'Normal'));

create table if not exists public.regulator_scans (
  id uuid primary key default gen_random_uuid(),
  scan_code text not null unique default ('SCAN-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 8))),
  company_id uuid references public.users(id) on delete set null,
  product_id uuid references public.products(id) on delete set null,
  captured_by uuid not null references public.users(id) on delete restrict,
  source_type text not null default 'field_photo' check (source_type in ('field_photo', 'ecommerce_url', 'consumer_evidence', 'batch_upload')),
  source_url text,
  image_url text,
  product_name text not null,
  company_name text,
  category text,
  region text,
  store_location text,
  ocr_text text,
  confidence_score integer not null default 0 check (confidence_score between 0 and 100),
  status text not null default 'completed' check (status in ('queued', 'processing', 'completed', 'failed')),
  captured_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.declaration_checks (
  id uuid primary key default gen_random_uuid(),
  scan_id uuid not null references public.regulator_scans(id) on delete cascade,
  field_name text not null,
  extracted_value text not null default '',
  confidence_percent integer not null default 0 check (confidence_percent between 0 and 100),
  status text not null check (status in ('Compliant', 'Warning', 'Violation', 'Unable to Verify')),
  rule_citation text not null,
  rule_description text not null default '',
  top_percent numeric(6, 5),
  left_percent numeric(6, 5),
  width_percent numeric(6, 5),
  height_percent numeric(6, 5),
  created_at timestamptz not null default now(),
  check ((top_percent is null and left_percent is null and width_percent is null and height_percent is null)
    or (top_percent between 0 and 1 and left_percent between 0 and 1
      and width_percent between 0 and 1 and height_percent between 0 and 1))
);

create table if not exists public.regulator_violations (
  id uuid primary key default gen_random_uuid(),
  scan_id uuid not null references public.regulator_scans(id) on delete cascade,
  company_id uuid references public.users(id) on delete set null,
  product_id uuid references public.products(id) on delete set null,
  complaint_id uuid references public.consumer_complaints(id) on delete set null,
  severity text not null default 'Medium' check (severity in ('Critical', 'High', 'Medium', 'Low')),
  risk_level text not null default 'Medium Risk' check (risk_level in ('Critical Risk', 'High Risk', 'Medium Risk', 'Low Risk')),
  confidence_score integer not null default 0 check (confidence_score between 0 and 100),
  violation_type text not null,
  violation_summary text not null,
  status text not null default 'pending' check (status in ('pending', 'confirmed', 'false_positive', 'escalated', 'manual_review', 'resolved')),
  reviewed_by uuid references public.users(id) on delete set null,
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.company_timeline_events (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.users(id) on delete cascade,
  event_type text not null check (event_type in ('complaint_verified', 'complaint_rejected', 'violation', 'audit_passed', 'notice_issued', 'response_received', 'corrective_action', 're_audit', 'status_change')),
  title text not null,
  description text not null default '',
  actor_id uuid references public.users(id) on delete set null,
  actor_name text not null default 'System',
  batch_no text,
  complaint_id uuid references public.consumer_complaints(id) on delete set null,
  violation_id uuid references public.regulator_violations(id) on delete set null,
  notice_id uuid,
  occurred_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create sequence if not exists public.notice_number_sequence start 1000;

create table if not exists public.regulator_notices (
  id uuid primary key default gen_random_uuid(),
  notice_number text not null unique default ('SCN-' || to_char(current_date, 'YYYY') || '-' || lpad(nextval('public.notice_number_sequence')::text, 6, '0')),
  violation_id uuid not null references public.regulator_violations(id) on delete restrict,
  company_id uuid not null references public.users(id) on delete restrict,
  rule_violated text not null,
  rule_citation text not null,
  issue_date timestamptz not null default now(),
  deadline_date timestamptz not null,
  status text not null default 'Draft' check (status in ('Draft', 'Issued', 'Acknowledged', 'Resolved', 'Withdrawn')),
  officer_notes text not null default '',
  issued_by uuid references public.users(id) on delete set null,
  evidence_summary text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (deadline_date >= issue_date)
);

alter table public.company_timeline_events
  add constraint company_timeline_events_notice_id_fkey
  foreign key (notice_id) references public.regulator_notices(id) on delete set null;

create index if not exists regulator_scans_captured_at_idx on public.regulator_scans (captured_at desc);
create index if not exists regulator_scans_company_id_idx on public.regulator_scans (company_id, captured_at desc);
create index if not exists declaration_checks_scan_id_idx on public.declaration_checks (scan_id);
create index if not exists regulator_violations_status_idx on public.regulator_violations (status, created_at desc);
create index if not exists regulator_violations_company_id_idx on public.regulator_violations (company_id, created_at desc);
create index if not exists consumer_complaints_status_idx on public.consumer_complaints (status, created_at desc);
create index if not exists consumer_complaints_company_id_idx on public.consumer_complaints (company_id, created_at desc);
create index if not exists company_timeline_events_company_id_idx on public.company_timeline_events (company_id, occurred_at desc);
create index if not exists regulator_notices_company_id_idx on public.regulator_notices (company_id, issue_date desc);

create or replace function public.set_updated_at()
returns trigger language plpgsql set search_path = public as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_regulator_scans_updated_at on public.regulator_scans;
create trigger set_regulator_scans_updated_at before update on public.regulator_scans
for each row execute function public.set_updated_at();
drop trigger if exists set_regulator_violations_updated_at on public.regulator_violations;
create trigger set_regulator_violations_updated_at before update on public.regulator_violations
for each row execute function public.set_updated_at();
drop trigger if exists set_regulator_notices_updated_at on public.regulator_notices;
create trigger set_regulator_notices_updated_at before update on public.regulator_notices
for each row execute function public.set_updated_at();

create or replace function public.guard_consumer_complaint_insert()
returns trigger
language plpgsql
security definer
set search_path = public, auth
as $$
begin
  if auth.uid() is not null and not public.is_regulator() then
    if not exists (select 1 from public.users where id = auth.uid() and role = 'consumer'::public.user_role) then
      raise exception 'Only consumer accounts can submit complaints';
    end if;
    if new.consumer_id is distinct from auth.uid() then
      raise exception 'Consumers can only submit their own complaints';
    end if;
    if new.status <> 'Submitted'
      or new.verified_by is not null or new.verified_at is not null
      or new.rejected_by is not null or new.rejected_at is not null
      or new.assigned_regulator_id is not null then
      raise exception 'Consumer complaints must start as Submitted without regulatory fields';
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists guard_consumer_complaint_insert on public.consumer_complaints;
create trigger guard_consumer_complaint_insert before insert on public.consumer_complaints
for each row execute function public.guard_consumer_complaint_insert();

create or replace function public.log_complaint_status_change()
returns trigger
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  event_title text;
  event_description text;
  event_type text;
begin
  if new.status is not distinct from old.status or new.company_id is null then
    return new;
  end if;
  event_type := case new.status
    when 'Forwarded' then 'complaint_verified'
    when 'Verified' then 'complaint_verified'
    when 'Rejected' then 'complaint_rejected'
    else 'status_change'
  end;
  event_title := case new.status
    when 'Forwarded' then 'Consumer complaint verified and forwarded'
    when 'Verified' then 'Consumer complaint verified'
    when 'Rejected' then 'Consumer complaint rejected'
    else 'Complaint status changed to ' || new.status
  end;
  event_description := coalesce(new.title, new.issue_category, 'Consumer complaint') || ' (' || coalesce(new.complaint_code, new.id::text) || ')';
  insert into public.company_timeline_events (
    company_id, event_type, title, description, actor_id, actor_name, complaint_id, occurred_at
  ) values (
    new.company_id, event_type, event_title, event_description,
    auth.uid(), coalesce(public.current_actor_name(), 'System'), new.id, now()
  );
  return new;
end;
$$;

drop trigger if exists log_complaint_status_change on public.consumer_complaints;
create trigger log_complaint_status_change after update of status on public.consumer_complaints
for each row execute function public.log_complaint_status_change();

create or replace function public.log_violation_status_change()
returns trigger
language plpgsql
security definer
set search_path = public, auth
as $$
begin
  if new.company_id is null or new.status is not distinct from old.status then
    return new;
  end if;
  insert into public.company_timeline_events (
    company_id, event_type, title, description, actor_id, actor_name, violation_id, occurred_at
  ) values (
    new.company_id,
    case when new.status = 'confirmed' then 'violation' else 'status_change' end,
    case when new.status = 'confirmed' then 'Violation confirmed' else 'Violation status changed to ' || new.status end,
    new.violation_summary, auth.uid(), coalesce(public.current_actor_name(), 'System'), new.id, now()
  );
  return new;
end;
$$;

drop trigger if exists log_violation_status_change on public.regulator_violations;
create trigger log_violation_status_change after update of status on public.regulator_violations
for each row execute function public.log_violation_status_change();

create or replace function public.log_notice_status_change()
returns trigger
language plpgsql
security definer
set search_path = public, auth
as $$
begin
  if new.status = 'Issued' and (tg_op = 'INSERT' or old.status is distinct from new.status) then
    insert into public.company_timeline_events (
      company_id, event_type, title, description, actor_id, actor_name, violation_id, notice_id, occurred_at
    ) values (
      new.company_id, 'notice_issued', 'Statutory notice issued',
      new.notice_number || ': ' || new.rule_violated,
      coalesce(new.issued_by, auth.uid()), coalesce(public.current_actor_name(), 'System'),
      new.violation_id, new.id, new.issue_date
    );
  end if;
  return new;
end;
$$;

drop trigger if exists log_notice_status_change on public.regulator_notices;
create trigger log_notice_status_change after insert or update of status on public.regulator_notices
for each row execute function public.log_notice_status_change();

create or replace function public.notify_consumer_complaint_update()
returns trigger
language plpgsql
security definer
set search_path = public, auth
as $$
begin
  if new.status is distinct from old.status then
    insert into public.consumer_notifications (consumer_id, title, message, type, related_complaint_id)
    values (
      new.consumer_id,
      'Complaint status updated',
      coalesce(new.complaint_code, 'Your complaint') || ' is now ' || new.status || '.',
      'complaint_update', new.id
    );
  end if;
  return new;
end;
$$;

drop trigger if exists notify_consumer_complaint_update on public.consumer_complaints;
create trigger notify_consumer_complaint_update after update of status on public.consumer_complaints
for each row execute function public.notify_consumer_complaint_update();

create or replace view public.company_compliance_overview
with (security_invoker = true)
as
select
  u.id as company_id,
  coalesce(lb.company_name, sb.business_name, u.full_name, u.email) as company_name,
  coalesce(lb.registered_address, concat_ws(', ', sb.address, sb.city, sb.state, sb.pincode), '') as address,
  coalesce(sb.state, '') as region,
  case when u.role = 'large_business'::public.user_role then 'Enterprise' else 'Small business' end as category,
  greatest(0, (100 - 8 * (select count(*) from public.regulator_violations rv where rv.company_id = u.id and rv.status not in ('false_positive', 'resolved'))
                  - 4 * (select count(*) from public.regulator_notices rn where rn.company_id = u.id and rn.status in ('Draft', 'Issued', 'Acknowledged')))::integer) as compliance_score,
  (select count(*) from public.regulator_violations rv where rv.company_id = u.id and rv.status not in ('false_positive', 'resolved'))::integer as open_violations_count,
  (select count(*) from public.regulator_notices rn where rn.company_id = u.id and rn.status <> 'Withdrawn')::integer as notices_issued_count,
  coalesce((select max(rs.captured_at) from public.regulator_scans rs where rs.company_id = u.id), u.created_at) as last_audit_date,
  case
    when exists (select 1 from public.regulator_violations rv where rv.company_id = u.id and rv.status = 'escalated') then 'Under Investigation'
    when exists (select 1 from public.regulator_notices rn where rn.company_id = u.id and rn.status in ('Draft', 'Issued', 'Acknowledged')) then 'Action Required'
    when exists (select 1 from public.regulator_violations rv where rv.company_id = u.id and rv.status not in ('false_positive', 'resolved')) then 'Active'
    else 'Compliant'
  end as status
from public.users u
left join public.large_businesses lb on lb.id = u.id
left join public.small_businesses sb on sb.id = u.id
where u.role in ('large_business'::public.user_role, 'small_business'::public.user_role);

create or replace function public.verify_and_forward_complaint(p_complaint_id uuid)
returns void
language plpgsql
security definer
set search_path = public, auth
as $$
begin
  if not public.is_regulator() then
    raise exception 'Only regulators can verify complaints';
  end if;
  update public.consumer_complaints
  set status = 'Forwarded', verified_by = auth.uid(), verified_at = now(), assigned_regulator_id = auth.uid()
  where id = p_complaint_id and company_id is not null;
  if not found then
    raise exception 'Complaint must be linked to a company before verification';
  end if;
end;
$$;

create or replace function public.reject_complaint(p_complaint_id uuid)
returns void
language plpgsql
security definer
set search_path = public, auth
as $$
begin
  if not public.is_regulator() then
    raise exception 'Only regulators can reject complaints';
  end if;
  update public.consumer_complaints
  set status = 'Rejected', rejected_by = auth.uid(), rejected_at = now(), assigned_regulator_id = auth.uid()
  where id = p_complaint_id;
  if not found then raise exception 'Complaint not found'; end if;
end;
$$;

create or replace function public.generate_notice_draft(p_violation_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v record;
  notice_no text;
  actor text;
  citations text;
begin
  if not public.is_regulator() then raise exception 'Only regulators can draft notices'; end if;
  select rv.id, rv.company_id, rv.violation_summary, rv.violation_type, rs.scan_code,
         rs.product_name, rs.store_location, rs.confidence_score, c.company_name
    into v
  from public.regulator_violations rv
  join public.regulator_scans rs on rs.id = rv.scan_id
  left join public.company_compliance_overview c on c.company_id = rv.company_id
  where rv.id = p_violation_id;
  if not found then raise exception 'Violation not found'; end if;
  select string_agg(distinct rule_citation, '; ' order by rule_citation) into citations
  from public.declaration_checks where scan_id = (select scan_id from public.regulator_violations where id = p_violation_id) and status = 'Violation';
  notice_no := 'SCN-' || to_char(current_date, 'YYYY') || '-' || lpad(nextval('public.notice_number_sequence')::text, 6, '0');
  actor := coalesce(public.current_actor_name(), 'Regulator');
  return jsonb_build_object(
    'id', '', 'notice_number', notice_no, 'violation_id', v.id, 'company_id', v.company_id,
    'company_name', coalesce(v.company_name, 'Unlinked company'), 'product_name', v.product_name,
    'rule_violated', v.violation_summary, 'rule_citation', coalesce(citations, v.violation_type),
    'issue_date', now(), 'deadline_date', now() + interval '15 days', 'status', 'Draft',
    'officer_notes', 'Audit ' || v.scan_code || ' recorded ' || v.violation_summary || coalesce(' at ' || nullif(v.store_location, ''), '') || '.',
    'officer_name', actor,
    'evidence_summary', 'Scan ' || v.scan_code || '; confidence ' || v.confidence_score || '%',
    'history', '[]'::jsonb
  );
end;
$$;

create or replace function public.get_regulator_dashboard_metrics()
returns jsonb
language sql
stable
security definer
set search_path = public, auth
as $$
  select case when public.is_regulator() then jsonb_build_object(
    'items_scanned', (select count(*) from public.regulator_scans),
    'active_violations', (select count(*) from public.regulator_violations where status in ('pending', 'manual_review', 'escalated', 'confirmed')),
    'priority_complaints', (select count(*) from public.consumer_complaints where status in ('Submitted', 'Under Review')),
    'scan_trend_percent', coalesce((select round(100.0 * (count(*) filter (where captured_at >= now() - interval '7 days') - count(*) filter (where captured_at >= now() - interval '14 days' and captured_at < now() - interval '7 days')) / nullif(count(*) filter (where captured_at >= now() - interval '14 days' and captured_at < now() - interval '7 days'), 0)) from public.regulator_scans), 0)
  ) else null end;
$$;

alter table public.regulator_scans enable row level security;
alter table public.declaration_checks enable row level security;
alter table public.regulator_violations enable row level security;
alter table public.company_timeline_events enable row level security;
alter table public.regulator_notices enable row level security;

create policy "Regulators can view all user profiles" on public.users for select using (public.is_regulator());
create policy "Regulators can view consumer profiles" on public.consumers for select using (public.is_regulator());
create policy "Regulators can view small business profiles" on public.small_businesses for select using (public.is_regulator());
create policy "Regulators can view large business profiles" on public.large_businesses for select using (public.is_regulator());
create policy "Regulators can view regulator profiles" on public.regulators for select using (public.is_regulator());

drop policy if exists "Consumers can insert own complaints" on public.consumer_complaints;
create policy "Consumers submit their own complaints" on public.consumer_complaints for insert with check (
  auth.uid() = consumer_id and exists (select 1 from public.users where id = auth.uid() and role = 'consumer'::public.user_role)
);
drop policy if exists "Consumers can view own complaints" on public.consumer_complaints;
create policy "Consumers view own complaints" on public.consumer_complaints for select using (auth.uid() = consumer_id);
create policy "Regulators view all complaints" on public.consumer_complaints for select using (public.is_regulator());
drop policy if exists "Regulators can update complaints" on public.consumer_complaints;
create policy "Regulators act on complaints" on public.consumer_complaints for update using (public.is_regulator()) with check (public.is_regulator());
create policy "Companies view linked complaints" on public.consumer_complaints for select using (public.is_business_user() and auth.uid() = company_id);

create policy "Regulators manage scans" on public.regulator_scans for all using (public.is_regulator()) with check (public.is_regulator());
create policy "Companies view own scans" on public.regulator_scans for select using (public.is_business_user() and auth.uid() = company_id);
create policy "Regulators manage declaration checks" on public.declaration_checks for all using (public.is_regulator()) with check (public.is_regulator());
create policy "Companies view declaration checks for own scans" on public.declaration_checks for select using (
  public.is_business_user() and exists (select 1 from public.regulator_scans rs where rs.id = scan_id and rs.company_id = auth.uid())
);
create policy "Regulators manage violations" on public.regulator_violations for all using (public.is_regulator()) with check (public.is_regulator());
create policy "Companies view own violations" on public.regulator_violations for select using (public.is_business_user() and auth.uid() = company_id);
create policy "Regulators view company timelines" on public.company_timeline_events for select using (public.is_regulator());
create policy "Companies view own timeline" on public.company_timeline_events for select using (public.is_business_user() and auth.uid() = company_id);
create policy "Regulators manage notices" on public.regulator_notices for all using (public.is_regulator()) with check (public.is_regulator());
create policy "Companies view own notices" on public.regulator_notices for select using (public.is_business_user() and auth.uid() = company_id);

do $$
begin
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'consumer_complaints') then
    execute 'alter publication supabase_realtime add table public.consumer_complaints';
  end if;
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'regulator_violations') then
    execute 'alter publication supabase_realtime add table public.regulator_violations';
  end if;
end;
$$;

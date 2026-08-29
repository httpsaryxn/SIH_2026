-- Keep policy helpers out of the exposed REST schema and remove direct access
-- to trigger-only SECURITY DEFINER functions.
create schema if not exists private;
revoke all on schema private from public;
grant usage on schema private to authenticated;

create or replace function private.is_regulator()
returns boolean language sql stable security definer set search_path = public, auth as $$
  select exists (select 1 from public.users where id = auth.uid() and role = 'regulator'::public.user_role);
$$;
create or replace function private.is_business_user()
returns boolean language sql stable security definer set search_path = public, auth as $$
  select exists (select 1 from public.users where id = auth.uid() and role in ('small_business'::public.user_role, 'large_business'::public.user_role));
$$;
create or replace function private.current_actor_name()
returns text language sql stable security definer set search_path = public, auth as $$
  select coalesce(full_name, email, 'System') from public.users where id = auth.uid();
$$;
grant execute on function private.is_regulator(), private.is_business_user(), private.current_actor_name() to authenticated;

drop policy if exists "Regulators can view all user profiles" on public.users;
create policy "Regulators can view all user profiles" on public.users for select using (private.is_regulator());
drop policy if exists "Regulators can view consumer profiles" on public.consumers;
create policy "Regulators can view consumer profiles" on public.consumers for select using (private.is_regulator());
drop policy if exists "Regulators can view small business profiles" on public.small_businesses;
create policy "Regulators can view small business profiles" on public.small_businesses for select using (private.is_regulator());
drop policy if exists "Regulators can view large business profiles" on public.large_businesses;
create policy "Regulators can view large business profiles" on public.large_businesses for select using (private.is_regulator());
drop policy if exists "Regulators can view regulator profiles" on public.regulators;
create policy "Regulators can view regulator profiles" on public.regulators for select using (private.is_regulator());
drop policy if exists "Regulators view all complaints" on public.consumer_complaints;
create policy "Regulators view all complaints" on public.consumer_complaints for select using (private.is_regulator());
drop policy if exists "Regulators act on complaints" on public.consumer_complaints;
create policy "Regulators act on complaints" on public.consumer_complaints for update using (private.is_regulator()) with check (private.is_regulator());
drop policy if exists "Companies view linked complaints" on public.consumer_complaints;
create policy "Companies view linked complaints" on public.consumer_complaints for select using (private.is_business_user() and auth.uid() = company_id);
drop policy if exists "Regulators manage scans" on public.regulator_scans;
create policy "Regulators manage scans" on public.regulator_scans for all using (private.is_regulator()) with check (private.is_regulator());
drop policy if exists "Companies view own scans" on public.regulator_scans;
create policy "Companies view own scans" on public.regulator_scans for select using (private.is_business_user() and auth.uid() = company_id);
drop policy if exists "Regulators manage declaration checks" on public.declaration_checks;
create policy "Regulators manage declaration checks" on public.declaration_checks for all using (private.is_regulator()) with check (private.is_regulator());
drop policy if exists "Companies view declaration checks for own scans" on public.declaration_checks;
create policy "Companies view declaration checks for own scans" on public.declaration_checks for select using (private.is_business_user() and exists (select 1 from public.regulator_scans rs where rs.id = scan_id and rs.company_id = auth.uid()));
drop policy if exists "Regulators manage violations" on public.regulator_violations;
create policy "Regulators manage violations" on public.regulator_violations for all using (private.is_regulator()) with check (private.is_regulator());
drop policy if exists "Companies view own violations" on public.regulator_violations;
create policy "Companies view own violations" on public.regulator_violations for select using (private.is_business_user() and auth.uid() = company_id);
drop policy if exists "Regulators view company timelines" on public.company_timeline_events;
create policy "Regulators view company timelines" on public.company_timeline_events for select using (private.is_regulator());
drop policy if exists "Companies view own timeline" on public.company_timeline_events;
create policy "Companies view own timeline" on public.company_timeline_events for select using (private.is_business_user() and auth.uid() = company_id);
drop policy if exists "Regulators manage notices" on public.regulator_notices;
create policy "Regulators manage notices" on public.regulator_notices for all using (private.is_regulator()) with check (private.is_regulator());
drop policy if exists "Companies view own notices" on public.regulator_notices;
create policy "Companies view own notices" on public.regulator_notices for select using (private.is_business_user() and auth.uid() = company_id);

create or replace function public.guard_consumer_complaint_insert() returns trigger language plpgsql security definer set search_path = public, auth as $$
begin
  if auth.uid() is not null and not private.is_regulator() then
    if not exists (select 1 from public.users where id = auth.uid() and role = 'consumer'::public.user_role) then raise exception 'Only consumer accounts can submit complaints'; end if;
    if new.consumer_id is distinct from auth.uid() then raise exception 'Consumers can only submit their own complaints'; end if;
    if new.status <> 'Submitted' or new.verified_by is not null or new.verified_at is not null or new.rejected_by is not null or new.rejected_at is not null or new.assigned_regulator_id is not null then raise exception 'Consumer complaints must start as Submitted without regulatory fields'; end if;
  end if;
  return new;
end;
$$;
create or replace function public.log_complaint_status_change() returns trigger language plpgsql security definer set search_path = public, auth as $$
declare event_title text; event_description text; event_type text;
begin
  if new.status is not distinct from old.status or new.company_id is null then return new; end if;
  event_type := case new.status when 'Forwarded' then 'complaint_verified' when 'Verified' then 'complaint_verified' when 'Rejected' then 'complaint_rejected' else 'status_change' end;
  event_title := case new.status when 'Forwarded' then 'Consumer complaint verified and forwarded' when 'Verified' then 'Consumer complaint verified' when 'Rejected' then 'Consumer complaint rejected' else 'Complaint status changed to ' || new.status end;
  event_description := coalesce(new.title, new.issue_category, 'Consumer complaint') || ' (' || coalesce(new.complaint_code, new.id::text) || ')';
  insert into public.company_timeline_events (company_id,event_type,title,description,actor_id,actor_name,complaint_id,occurred_at) values (new.company_id,event_type,event_title,event_description,auth.uid(),coalesce(private.current_actor_name(),'System'),new.id,now());
  return new;
end;
$$;
create or replace function public.log_violation_status_change() returns trigger language plpgsql security definer set search_path = public, auth as $$
begin
  if new.company_id is null or new.status is not distinct from old.status then return new; end if;
  insert into public.company_timeline_events (company_id,event_type,title,description,actor_id,actor_name,violation_id,occurred_at) values (new.company_id,case when new.status = 'confirmed' then 'violation' else 'status_change' end,case when new.status = 'confirmed' then 'Violation confirmed' else 'Violation status changed to ' || new.status end,new.violation_summary,auth.uid(),coalesce(private.current_actor_name(),'System'),new.id,now());
  return new;
end;
$$;
create or replace function public.log_notice_status_change() returns trigger language plpgsql security definer set search_path = public, auth as $$
begin
  if new.status = 'Issued' and (tg_op = 'INSERT' or old.status is distinct from new.status) then
    insert into public.company_timeline_events (company_id,event_type,title,description,actor_id,actor_name,violation_id,notice_id,occurred_at) values (new.company_id,'notice_issued','Statutory notice issued',new.notice_number || ': ' || new.rule_violated,coalesce(new.issued_by,auth.uid()),coalesce(private.current_actor_name(),'System'),new.violation_id,new.id,new.issue_date);
  end if;
  return new;
end;
$$;
create or replace function public.notify_consumer_complaint_update() returns trigger language plpgsql security definer set search_path = public, auth as $$
begin
  if new.status is distinct from old.status then insert into public.consumer_notifications (consumer_id,title,message,type,related_complaint_id) values (new.consumer_id,'Complaint status updated',coalesce(new.complaint_code,'Your complaint') || ' is now ' || new.status || '.','complaint_update',new.id); end if;
  return new;
end;
$$;

create or replace function public.verify_and_forward_complaint(p_complaint_id uuid) returns void language plpgsql security definer set search_path = public, auth as $$
begin
  if not private.is_regulator() then raise exception 'Only regulators can verify complaints'; end if;
  update public.consumer_complaints set status = 'Forwarded', verified_by = auth.uid(), verified_at = now(), assigned_regulator_id = auth.uid() where id = p_complaint_id and company_id is not null;
  if not found then raise exception 'Complaint must be linked to a company before verification'; end if;
end;
$$;
create or replace function public.reject_complaint(p_complaint_id uuid) returns void language plpgsql security definer set search_path = public, auth as $$
begin
  if not private.is_regulator() then raise exception 'Only regulators can reject complaints'; end if;
  update public.consumer_complaints set status = 'Rejected', rejected_by = auth.uid(), rejected_at = now(), assigned_regulator_id = auth.uid() where id = p_complaint_id;
  if not found then raise exception 'Complaint not found'; end if;
end;
$$;
create or replace function public.generate_notice_draft(p_violation_id uuid) returns jsonb language plpgsql security definer set search_path = public, auth as $$
declare v record; notice_no text; actor text; citations text;
begin
  if not private.is_regulator() then raise exception 'Only regulators can draft notices'; end if;
  select rv.id,rv.company_id,rv.violation_summary,rv.violation_type,rs.scan_code,rs.product_name,rs.store_location,rs.confidence_score,c.company_name into v from public.regulator_violations rv join public.regulator_scans rs on rs.id=rv.scan_id left join public.company_compliance_overview c on c.company_id=rv.company_id where rv.id=p_violation_id;
  if not found then raise exception 'Violation not found'; end if;
  select string_agg(distinct rule_citation,'; ' order by rule_citation) into citations from public.declaration_checks where scan_id=(select scan_id from public.regulator_violations where id=p_violation_id) and status='Violation';
  notice_no := 'SCN-' || to_char(current_date,'YYYY') || '-' || lpad(nextval('public.notice_number_sequence')::text,6,'0'); actor := coalesce(private.current_actor_name(),'Regulator');
  return jsonb_build_object('id','','notice_number',notice_no,'violation_id',v.id,'company_id',v.company_id,'company_name',coalesce(v.company_name,'Unlinked company'),'product_name',v.product_name,'rule_violated',v.violation_summary,'rule_citation',coalesce(citations,v.violation_type),'issue_date',now(),'deadline_date',now()+interval '15 days','status','Draft','officer_notes','Audit ' || v.scan_code || ' recorded ' || v.violation_summary || coalesce(' at ' || nullif(v.store_location,''), '') || '.','officer_name',actor,'evidence_summary','Scan ' || v.scan_code || '; confidence ' || v.confidence_score || '%','history','[]'::jsonb);
end;
$$;
create or replace function public.get_regulator_dashboard_metrics() returns jsonb language sql stable security definer set search_path = public, auth as $$
  select case when private.is_regulator() then jsonb_build_object('items_scanned',(select count(*) from public.regulator_scans),'active_violations',(select count(*) from public.regulator_violations where status in ('pending','manual_review','escalated','confirmed')),'priority_complaints',(select count(*) from public.consumer_complaints where status in ('Submitted','Under Review')),'scan_trend_percent',coalesce((select round(100.0*(count(*) filter(where captured_at>=now()-interval '7 days')-count(*) filter(where captured_at>=now()-interval '14 days' and captured_at<now()-interval '7 days'))/nullif(count(*) filter(where captured_at>=now()-interval '14 days' and captured_at<now()-interval '7 days'),0)) from public.regulator_scans),0)) else null end;
$$;

revoke all on function public.guard_consumer_complaint_insert(), public.log_complaint_status_change(), public.log_violation_status_change(), public.log_notice_status_change(), public.notify_consumer_complaint_update() from public, anon, authenticated;
revoke all on function public.verify_and_forward_complaint(uuid), public.reject_complaint(uuid), public.generate_notice_draft(uuid), public.get_regulator_dashboard_metrics() from public, anon;
grant execute on function public.verify_and_forward_complaint(uuid), public.reject_complaint(uuid), public.generate_notice_draft(uuid), public.get_regulator_dashboard_metrics() to authenticated;

drop function public.is_regulator();
drop function public.is_business_user();
drop function public.current_actor_name();

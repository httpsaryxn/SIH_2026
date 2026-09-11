import logging
from typing import Optional, Dict, Any
from supabase import create_client, Client
from config import settings

logger = logging.getLogger(__name__)

_supabase_client: Optional[Client] = None

def get_supabase() -> Optional[Client]:
    global _supabase_client
    if _supabase_client is not None:
        return _supabase_client
    
    if not settings.SUPABASE_URL or not settings.SUPABASE_KEY:
        logger.warning("Supabase URL or Key not set. DB caching and storage uploads will be skipped.")
        return None
        
    try:
        _supabase_client = create_client(settings.SUPABASE_URL, settings.SUPABASE_KEY)
        return _supabase_client
    except Exception as e:
        logger.error(f"Failed to initialize Supabase client: {e}")
        return None

def get_cached_consumer_summary(scan_id: str) -> Optional[Dict[str, Any]]:
    client = get_supabase()
    if not client or not scan_id:
        return None
    try:
        res = client.from_("consumer_scans").select(
            "id, product_type, consumer_summary_text, health_score, medicinal_safety_summary, summary_generated_at"
        ).eq("id", scan_id).execute()
        if res.data and len(res.data) > 0:
            row = res.data[0]
            if row.get("consumer_summary_text"):
                return {
                    "scan_id": row["id"],
                    "product_type": row.get("product_type") or "unclassified",
                    "consumer_summary_text": row["consumer_summary_text"],
                    "health_score": row.get("health_score"),
                    "medicinal_safety_summary": row.get("medicinal_safety_summary"),
                    "summary_generated_at": row.get("summary_generated_at"),
                    "cached": True,
                }
    except Exception as e:
        logger.warning(f"Error checking cached consumer summary for {scan_id}: {e}")
    return None

def update_consumer_summary(
    scan_id: str,
    product_type: str,
    summary_text: str,
    health_score: Optional[int],
    medicinal_safety: Optional[str]
) -> bool:
    client = get_supabase()
    if not client or not scan_id:
        return False
    try:
        from datetime import datetime, timezone
        payload = {
            "product_type": product_type,
            "consumer_summary_text": summary_text,
            "health_score": health_score,
            "medicinal_safety_summary": medicinal_safety,
            "summary_generated_at": datetime.now(timezone.utc).isoformat(),
        }
        client.from_("consumer_scans").update(payload).eq("id", scan_id).execute()
        return True
    except Exception as e:
        logger.error(f"Failed to persist consumer summary to DB for {scan_id}: {e}")
        return False

def get_cached_regulator_summary(scan_id: str) -> Optional[Dict[str, Any]]:
    client = get_supabase()
    if not client or not scan_id:
        return None
    try:
        res = client.from_("regulator_scans").select(
            "id, product_type, regulator_summary_text, regulator_pdf_url, summary_generated_at"
        ).eq("id", scan_id).execute()
        if res.data and len(res.data) > 0:
            row = res.data[0]
            if row.get("regulator_summary_text") and row.get("regulator_pdf_url"):
                return {
                    "scan_id": row["id"],
                    "product_type": row.get("product_type") or "general",
                    "regulator_summary_text": row["regulator_summary_text"],
                    "regulator_pdf_url": row["regulator_pdf_url"],
                    "summary_generated_at": row.get("summary_generated_at"),
                    "cached": True,
                }
    except Exception as e:
        logger.warning(f"Error checking cached regulator summary for {scan_id}: {e}")
    return None

def update_regulator_summary(
    scan_id: str,
    product_type: str,
    summary_text: str,
    pdf_url: str
) -> bool:
    client = get_supabase()
    if not client or not scan_id:
        return False
    try:
        from datetime import datetime, timezone
        payload = {
            "product_type": product_type,
            "regulator_summary_text": summary_text,
            "regulator_pdf_url": pdf_url,
            "summary_generated_at": datetime.now(timezone.utc).isoformat(),
        }
        client.from_("regulator_scans").update(payload).eq("id", scan_id).execute()
        return True
    except Exception as e:
        logger.error(f"Failed to persist regulator summary to DB for {scan_id}: {e}")
        return False

def upload_report_pdf(scan_id: str, user_id: str, pdf_bytes: bytes) -> Optional[str]:
    """
    Uploads generated PDF to compliance-images storage bucket following RLS convention:
    regulator_reports/{user_id}/{scan_id}/compliance_report_{scan_id}.pdf
    Returns the signed URL (or storage path).
    """
    client = get_supabase()
    if not client:
        return None
        
    storage_path = f"regulator_reports/{user_id or 'regulator'}/{scan_id}/compliance_report_{scan_id}.pdf"
    bucket_name = "compliance-images"
    
    try:
        # Upload or overwrite
        try:
            client.storage.from_(bucket_name).upload(
                path=storage_path,
                file=pdf_bytes,
                file_options={"content-type": "application/pdf", "upsert": "true"}
            )
        except Exception:
            # If upload fails because it exists, try update
            client.storage.from_(bucket_name).update(
                path=storage_path,
                file=pdf_bytes,
                file_options={"content-type": "application/pdf"}
            )
            
        # Create a signed URL valid for 1 year (31536000 seconds)
        signed_res = client.storage.from_(bucket_name).create_signed_url(storage_path, 31536000)
        if isinstance(signed_res, dict) and "signedURL" in signed_res:
            return signed_res["signedURL"]
        elif hasattr(signed_res, "signed_url"):
            return signed_res.signed_url
        return f"{settings.SUPABASE_URL}/storage/v1/object/public/{bucket_name}/{storage_path}"
    except Exception as e:
        logger.error(f"Failed to upload PDF to Supabase Storage: {e}")
        return None

import logging
from typing import Optional
from app.core.config import settings

logger = logging.getLogger(__name__)

_supabase_client = None


def get_supabase_client():
    """
    Returns singleton instance of Supabase Client.
    Gracefully handles missing or uninitialized environments.
    """
    global _supabase_client
    if _supabase_client is not None:
        return _supabase_client

    try:
        from supabase import create_client, Client
        _supabase_client = create_client(settings.SUPABASE_URL, settings.SUPABASE_KEY)
        return _supabase_client
    except Exception as e:
        logger.warning(f"Could not initialize Supabase Client: {e}")
        return None


def check_supabase_connection() -> dict:
    """
    Verifies live connectivity to Supabase Cloud.
    """
    client = get_supabase_client()
    if client is None:
        return {
            "status": "offline",
            "url": settings.SUPABASE_URL,
            "error": "Client not initialized",
        }

    try:
        # Perform quick select query on small_business_labels
        res = client.table("small_business_labels").select("id").limit(1).execute()
        return {
            "status": "connected",
            "url": settings.SUPABASE_URL,
            "healthy": True,
            "sample_records_present": len(res.data) > 0,
        }
    except Exception as e:
        return {
            "status": "error",
            "url": settings.SUPABASE_URL,
            "error": str(e),
        }

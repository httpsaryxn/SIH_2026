import logging
from typing import Dict, Any, List, Optional
from fastapi import APIRouter, HTTPException, Response
from pydantic import BaseModel, Field

from .config import settings
from .groq_client import classify_and_summarize_consumer, generate_regulator_summary
from .pdf_generator import generate_compliance_pdf
from . import supabase_client

logger = logging.getLogger(__name__)

router = APIRouter(tags=["AI Summary & PDF Reports"])

# In-memory buffer for local streaming fallback
_local_pdf_cache: Dict[str, bytes] = {}

class ConsumerSummaryRequest(BaseModel):
    scan_id: Optional[str] = Field(None, description="UUID of the consumer_scans record for DB caching")
    product_name: str = Field(..., description="Declared or extracted commodity/product name")
    manufacturer: Optional[str] = Field(None, description="Declared manufacturer/packer name")
    extracted_declarations: Optional[Dict[str, Any]] = Field(default_factory=dict)
    rules: Optional[Dict[str, Any]] = Field(default_factory=dict)
    ocr_text: Optional[str] = Field(None, description="Raw label OCR text")
    force_regenerate: bool = Field(False, description="Bypass cache and force Groq LLM regeneration")

class RegulatorSummaryRequest(BaseModel):
    scan_id: str = Field(..., description="UUID of the regulator_scans record")
    product_name: str = Field(..., description="Commodity name")
    company_name: Optional[str] = Field(None, description="Company / Manufacturer name")
    category: Optional[str] = Field(None, description="Product category")
    declaration_checks: List[Dict[str, Any]] = Field(default_factory=list, description="Array of declaration audit checks")
    image_urls: Optional[Dict[str, Optional[str]]] = Field(default_factory=dict, description="Front, curved, and scale image URLs")
    user_id: Optional[str] = Field(None, description="Inspector / Regulator user ID")
    force_regenerate: bool = Field(False, description="Bypass cache and force regeneration")


@router.get("/summarize/health")
async def summary_health():
    return {
        "status": "ok",
        "module": "summary-gen",
        "groq_configured": bool(settings.GROQ_API_KEY),
        "primary_model": settings.GROQ_MODEL,
        "supabase_configured": bool(settings.SUPABASE_KEY),
    }


@router.post("/summarize/consumer")
async def summarize_consumer(req: ConsumerSummaryRequest):
    """
    Classifies the product into food / medicinal / general and generates
    plain-language nutritional insights, health scoring, or medicinal safety instructions.
    """
    try:
        # Check cache if scan_id provided and not force_regenerate
        if req.scan_id and not req.force_regenerate:
            cached = supabase_client.get_cached_consumer_summary(req.scan_id)
            if cached:
                logger.info(f"Returning cached consumer summary for scan {req.scan_id}")
                return cached

        # Generate via Groq LLM (with multi-model fallback and heuristic backup)
        result = classify_and_summarize_consumer(
            product_name=req.product_name,
            manufacturer=req.manufacturer,
            declarations=req.extracted_declarations,
            rules=req.rules,
            ocr_text=req.ocr_text,
        )

        product_type = result.get("product_type", "unclassified")
        summary_text = result.get("summary_text", "")
        health_score = result.get("health_score")
        medicinal_safety = result.get("medicinal_safety_summary")

        # Persist to Supabase if scan_id provided
        if req.scan_id:
            supabase_client.update_consumer_summary(
                scan_id=req.scan_id,
                product_type=product_type,
                summary_text=summary_text,
                health_score=health_score,
                medicinal_safety=medicinal_safety,
            )

        result["scan_id"] = req.scan_id
        result["cached"] = False
        return result

    except Exception as e:
        logger.exception("Error in consumer summary generation")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/summarize/regulator")
async def summarize_regulator(req: RegulatorSummaryRequest):
    """
    Generates an executive regulatory analysis and compiles a formal tabular
    PDF audit report comparing declared vs required declarations under PCR 2011.
    """
    try:
        # Check cache if not force_regenerate
        if not req.force_regenerate:
            cached = supabase_client.get_cached_regulator_summary(req.scan_id)
            if cached:
                logger.info(f"Returning cached regulator summary & PDF for scan {req.scan_id}")
                return cached

        # 1. Generate Regulatory Summary Text via Groq
        summary_text = generate_regulator_summary(
            product_name=req.product_name,
            company_name=req.company_name,
            declaration_checks=req.declaration_checks,
            metadata={
                "category": req.category,
                "scan_id": req.scan_id,
            }
        )

        # 2. Generate Tabular PDF via ReportLab
        pdf_bytes = generate_compliance_pdf(
            scan_id=req.scan_id,
            product_name=req.product_name,
            company_name=req.company_name,
            declaration_checks=req.declaration_checks,
            summary_text=summary_text,
            metadata={
                "status": "Potential Violation" if any(c.get("status") in ["Violation", "FAIL"] for c in req.declaration_checks) else "Compliant",
            },
            image_urls=req.image_urls,
        )

        # Store in memory cache
        _local_pdf_cache[req.scan_id] = pdf_bytes

        # Persist to disk
        try:
            import tempfile
            from pathlib import Path
            report_dir = Path(tempfile.gettempdir()) / "lmc_reports"
            report_dir.mkdir(parents=True, exist_ok=True)
            (report_dir / f"{req.scan_id}.pdf").write_bytes(pdf_bytes)
        except Exception as disk_err:
            logger.warning(f"Could not persist PDF to disk: {disk_err}")

        # 3. Upload PDF to Supabase Storage if configured
        pdf_url = supabase_client.upload_report_pdf(
            scan_id=req.scan_id,
            user_id=req.user_id or "regulator",
            pdf_bytes=pdf_bytes,
        )

        # Fallback server endpoint if Supabase upload unavailable
        if not pdf_url:
            pdf_url = f"/report/{req.scan_id}/download"

        # 4. Persist to Supabase regulator_scans if valid UUID
        supabase_client.update_regulator_summary(
            scan_id=req.scan_id,
            product_type=req.category or "general",
            summary_text=summary_text,
            pdf_url=pdf_url,
        )

        return {
            "scan_id": req.scan_id,
            "product_type": req.category or "general",
            "regulator_summary_text": summary_text,
            "regulator_pdf_url": pdf_url,
            "cached": False,
        }

    except Exception as e:
        logger.exception("Error in regulator summary generation")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/report/{scan_id}/download")
async def download_pdf(scan_id: str):
    """Directly stream generated PDF for in-app or browser preview."""
    if scan_id in _local_pdf_cache:
        return Response(
            content=_local_pdf_cache[scan_id],
            media_type="application/pdf",
            headers={"Content-Disposition": f"inline; filename=audit_report_{scan_id}.pdf", "Cache-Control": "public, max-age=3600"}
        )
    import tempfile
    from pathlib import Path
    disk_path = Path(tempfile.gettempdir()) / "lmc_reports" / f"{scan_id}.pdf"
    if disk_path.exists():
        return Response(
            content=disk_path.read_bytes(),
            media_type="application/pdf",
            headers={"Content-Disposition": f"inline; filename=audit_report_{scan_id}.pdf", "Cache-Control": "public, max-age=3600"}
        )
    raise HTTPException(status_code=404, detail="PDF report not found.")

"""
FastAPI service wrapping the Legal Metrology ML compliance pipeline.

Provides the same analysis endpoints as the source repo's Flask app.py,
but using FastAPI with async support and automatic OpenAPI docs.

Run with:
    uv run uvicorn server:app --host 0.0.0.0 --port 8000 --reload
"""
from __future__ import annotations

import base64
import logging
import os
import tempfile
import traceback
import uuid
from pathlib import Path
from typing import Optional

from dotenv import load_dotenv
from fastapi import FastAPI, File, Form, Header, Request, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, JSONResponse

# ---------------------------------------------------------------------------
# Load .env before anything else
# ---------------------------------------------------------------------------
load_dotenv()

# ---------------------------------------------------------------------------
# Pipeline import (verbatim ML code)
# ---------------------------------------------------------------------------
from legal_metrology_ml.main import run_pipeline
from legal_metrology_ml.layer1_feature_extraction.ocr_engine import OCREngine

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s — %(message)s",
)
logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# App setup
# ---------------------------------------------------------------------------
app = FastAPI(
    title="Legal Metrology ML Scanner",
    description="Compliance analysis for packaged commodity labels under LM(PC) Rules 2011",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

UPLOAD_DIR = Path(tempfile.gettempdir()) / "lmc_uploads"
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)

REPORT_DIR = Path(tempfile.gettempdir()) / "lmc_reports"
REPORT_DIR.mkdir(parents=True, exist_ok=True)

# ---------------------------------------------------------------------------
# Shared singleton — EasyOCR loads ~200 MB of models; build once at startup
# ---------------------------------------------------------------------------
logger.info("Loading OCREngine at startup (this takes ~30s on first run)…")
_ocr_engine = OCREngine()


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
async def _save_upload(f: Optional[UploadFile]) -> Optional[Path]:
    """Persist an uploaded file to the temp directory."""
    if f is None or f.filename is None or f.filename == "":
        return None
    ext = Path(f.filename).suffix or ".jpg"
    p = UPLOAD_DIR / f"{uuid.uuid4().hex}{ext}"
    content = await f.read()
    p.write_bytes(content)
    return p


def _save_b64(data_url: Optional[str]) -> Optional[Path]:
    """Decode a base64 data-URL string and save to disk."""
    if not data_url:
        return None
    if "," in data_url:
        data_url = data_url.split(",", 1)[1]
    p = UPLOAD_DIR / f"{uuid.uuid4().hex}.jpg"
    p.write_bytes(base64.b64decode(data_url))
    return p


def _cleanup(*paths: Optional[Path]) -> None:
    for p in paths:
        if p and p.exists():
            try:
                p.unlink()
            except OSError:
                pass


def _serialise_results(results):
    return [
        {
            "rule_id": r.rule_id,
            "rule_name": r.rule_name,
            "status": r.status,
            "severity": r.severity,
            "detail": r.detail,
            "evidence": getattr(r, "evidence", None),
            "legal_reference": getattr(r, "legal_reference", None),
        }
        for r in results
    ]


# ---------------------------------------------------------------------------
# Routes
# ---------------------------------------------------------------------------
@app.get("/ping")
@app.get("/healthz")
async def ping():
    """Ultra-lightweight ping endpoint for keep-alive cron jobs."""
    return "pong"


@app.get("/health")
async def health():
    """Health check endpoint."""
    return {"status": "ok", "service": "ml-scanner", "version": "1.0.0"}


@app.post("/analyze")
async def analyze(
    front: Optional[UploadFile] = File(None),
    back: Optional[UploadFile] = File(None),
    ruler: Optional[UploadFile] = File(None),
    barcode: Optional[UploadFile] = File(None),
    image: Optional[UploadFile] = File(None),
    front_label: Optional[UploadFile] = File(None),
    curved_surface: Optional[UploadFile] = File(None),
    scale_reference: Optional[UploadFile] = File(None),
    barcode_number: Optional[str] = Form(None),
    package_height_mm: Optional[str] = Form(None),
    gemini_api_key: Optional[str] = Form(None),
    x_gemini_api_key: Optional[str] = Header(None, alias="X-Gemini-Api-Key"),
):
    """
    Analyze packaging label images for Legal Metrology compliance.

    Accepts multipart/form-data with:
        front / front_label          — required front label image
        back / curved_surface        — optional back/side label image
        ruler / scale_reference      — optional ruler calibration image
        barcode                      — optional barcode image
        image                        — alias for front (fallback)
        barcode_number               — optional manual barcode digits
        package_height_mm            — optional package height for calibration
        gemini_api_key               — optional Gemini API key (also via X-Gemini-Api-Key header)
    """
    front_path: Optional[Path] = None
    back_path: Optional[Path] = None
    ruler_path: Optional[Path] = None
    barcode_path: Optional[Path] = None

    try:
        api_key = x_gemini_api_key or gemini_api_key

        # Save uploaded files (supporting both original names and Flutter canonical names)
        front_file = front or front_label or image
        back_file = back or curved_surface
        ruler_file = ruler or scale_reference

        front_path = await _save_upload(front_file)
        back_path = await _save_upload(back_file)
        ruler_path = await _save_upload(ruler_file)
        barcode_path = await _save_upload(barcode)

        # Fallback: if only back provided, treat as front
        if front_path is None and back_path is not None:
            front_path = back_path
            back_path = None

        has_image = front_path is not None
        has_barcode = bool(barcode_number) or barcode_path is not None

        if not has_image and not has_barcode:
            return JSONResponse(
                status_code=400,
                content={"error": "Please provide either a packaging label photo or a product barcode to analyze."},
            )

        # Parse height
        height_mm = None
        if package_height_mm:
            try:
                height_mm = float(package_height_mm)
            except ValueError:
                pass

        # Run the pipeline
        report_path = str(REPORT_DIR / f"{uuid.uuid4().hex}.pdf")
        report = run_pipeline(
            front_image=str(front_path) if front_path else None,
            back_image=str(back_path) if back_path else None,
            ruler_image=str(ruler_path) if ruler_path else None,
            barcode_image=str(barcode_path) if barcode_path else None,
            barcode_number=barcode_number,
            package_height_mm=height_mm,
            output_path=report_path,
            ocr_engine=_ocr_engine,
            api_key=api_key,
        )

        # Serialise results (same structure as source repo's app.py)
        score = report.compliance_score
        rd = report.rulebook_diff

        fc = getattr(report.ebm_prediction, "feature_contributions", {}) or {}
        pd_obj = report.package_data

        if "barcode_registry_analysis" in fc:
            analysis_mode = "barcode_registry"
            srcs = ", ".join(getattr(pd_obj, "product_data_sources", []) or []) or "GS1 structural checks only"
            engine_desc = f"Bar Code / GS1 Registry Verification + LM(PC) Rules 2011 Rulebook — sources: {srcs}"
            if "llm_barcode_analysis" in fc:
                engine_desc += " (Gemini-enriched)"
        elif "llm_barcode_analysis" in fc:
            analysis_mode = "llm_barcode"
            engine_desc = "Gemini LLM Barcode Verification & GS1 Registry"
        elif "llm_vision_analysis" in fc:
            analysis_mode = "llm_vision"
            engine_desc = "Gemini Multimodal Vision (Front & Back Label Photos)"
        else:
            analysis_mode = "local_ocr"
            engine_desc = "Local OCR & Rulebook Engine"

        payload = {
            "scan_id": report.scan_id,
            "timestamp": report.scan_timestamp,
            "analysis_mode": analysis_mode,
            "engine_description": engine_desc,
            "score": {
                "final_score": round(score.final_score * 100, 1),
                "star_rating": score.star_rating,
                "star_label": score.star_label,
                "ebm_score": round(score.ebm_score * 100, 1),
                "rule_score": round(score.rule_score * 100, 1),
                "passed_rules": score.passed_rules,
                "failed_rules": score.failed_rules,
            },
            "rules": {
                "passed": _serialise_results(rd.passed),
                "failed": _serialise_results(rd.failed),
                "warnings": _serialise_results(rd.warnings),
                "not_applicable": _serialise_results(rd.not_applicable),
                "inconclusive": _serialise_results(rd.inconclusive),
            },
            "barcode": {
                "has_barcode": pd_obj.has_barcode,
                "value": pd_obj.barcode_value,
                "type": pd_obj.barcode_type,
                "gtin_format": pd_obj.barcode_gtin_format,
                "is_valid": pd_obj.barcode_valid,
                "checksum_valid": pd_obj.barcode_checksum_valid,
                "country": pd_obj.barcode_country,
                "is_gs1_india": pd_obj.barcode_is_gs1_india,
                "is_restricted": pd_obj.barcode_is_restricted,
                "registered_owner": pd_obj.barcode_registered_owner,
            },
            "product": {
                "identified": getattr(pd_obj, "product_identified", False),
                "sources": getattr(pd_obj, "product_data_sources", []) or [],
                "name": pd_obj.commodity_name,
                "manufacturer": pd_obj.manufacturer_name,
                "address": pd_obj.manufacturer_address,
                "net_quantity": (
                    f"{pd_obj.net_quantity_value} {pd_obj.net_quantity_unit}".strip()
                    if pd_obj.net_quantity_value is not None
                    else None
                ),
                "mrp": pd_obj.mrp_value,
                "country_of_origin": pd_obj.country_of_origin,
                "mfg_date": pd_obj.manufacture_date,
                "fssai": pd_obj.fssai_license_number,
                "provenance": getattr(pd_obj, "data_provenance", {}) or {},
            },
            "recommendations": report.recommendations,
            "report_id": Path(report_path).stem,
            "images_used": {
                "front": True,
                "back": back_path is not None,
                "ruler": ruler_path is not None,
                "barcode": barcode_path is not None or barcode_number is not None,
            },
        }
        return payload

    except Exception as exc:
        logger.exception("Pipeline error")
        return JSONResponse(
            status_code=500,
            content={"error": str(exc), "traceback": traceback.format_exc()},
        )
    finally:
        _cleanup(front_path, back_path, ruler_path, barcode_path)


@app.post("/scan-barcode")
async def scan_barcode_endpoint(request: Request):
    """Decode a bar code / QR code and structurally verify it as a GS1 GTIN."""
    from legal_metrology_ml.layer1_feature_extraction.barcode_scanner import BarcodeScanner
    from legal_metrology_ml.layer1_feature_extraction.gs1 import classify_gtin

    temp_path: Optional[Path] = None
    try:
        body = await request.json() if request.headers.get("content-type", "").startswith("application/json") else {}
        do_lookup = bool(body.get("lookup"))
        manual_code = (body.get("barcode_number") or body.get("code") or "").strip() or None

        data_url = body.get("image_b64") or body.get("barcode_b64") or body.get("image")
        if data_url:
            temp_path = _save_b64(data_url)

        barcodes = []
        if temp_path is not None:
            barcodes = BarcodeScanner().scan(temp_path)
        elif manual_code:
            from legal_metrology_ml.layer1_feature_extraction.barcode_scanner import BarcodeInfo
            gi = classify_gtin(manual_code)
            barcodes = [BarcodeInfo(
                code=gi.digits or manual_code,
                type=gi.fmt or "BARCODE",
                is_valid=gi.is_valid,
                country=gi.issuing_country,
                source="manual",
            )]
        else:
            return JSONResponse(
                status_code=400,
                content={"error": "Provide a bar code image or a barcode_number."},
            )

        results = []
        for b in barcodes:
            d = b.to_dict()
            gi = classify_gtin(b.code)
            d["gtin"] = gi.to_dict()
            d["is_valid"] = gi.is_valid if gi.is_gtin_length else d.get("is_valid")
            if gi.issuing_country and not d.get("country"):
                d["country"] = gi.issuing_country
            results.append(d)

        product = None
        if do_lookup and results:
            try:
                from legal_metrology_ml.data_sources.product_lookup import lookup_product
                rec = lookup_product(results[0]["code"])
                product = rec.to_dict()
            except Exception as e:
                logger.warning("Registry lookup failed: %s", e)

        return {
            "success": True,
            "count": len(results),
            "barcodes": results,
            "product": product,
        }
    except Exception as exc:
        logger.exception("Barcode scanning endpoint error")
        return JSONResponse(
            status_code=500,
            content={"error": str(exc), "traceback": traceback.format_exc()},
        )
    finally:
        _cleanup(temp_path)


@app.get("/download/{report_id}")
async def download_report(report_id: str):
    """Stream a generated PDF report."""
    if not report_id.replace("-", "").isalnum():
        return JSONResponse(status_code=400, content={"error": "Invalid report ID"})
    path = REPORT_DIR / f"{report_id}.pdf"
    if not path.exists():
        return JSONResponse(status_code=404, content={"error": "Report not found"})
    return FileResponse(str(path), filename="compliance_report.pdf")


# ---------------------------------------------------------------------------
# Entry-point
# ---------------------------------------------------------------------------
def main():
    import uvicorn
    print("\n  Legal Metrology ML Scanner (FastAPI)")
    print("  ➜  API docs at http://localhost:8000/docs\n")
    uvicorn.run("server:app", host="0.0.0.0", port=8000, reload=True)


if __name__ == "__main__":
    main()

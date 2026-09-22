"""LLM-Powered Compliance Engine for Legal Metrology.

Uses Google Gemini (gemini-2.0-flash / gemini-1.5-flash) to:
1. Check product compliance from barcode with database lookup + LLM reasoning.
2. Check product compliance from label photos (Multimodal Vision) when no barcode is present.
"""
from __future__ import annotations

import base64
import json
import logging
import os
import re
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

import requests

from ..layer1_feature_extraction.barcode_scanner import lookup_gs1_country, validate_ean13_checksum
from ..layer2_data_normalization.schema import (
    ComplianceDiff,
    ComplianceScore,
    PackageData,
    RuleResult,
)

logger = logging.getLogger(__name__)

GEMINI_API_URL = "https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={key}"
MODELS_TO_TRY = [
    "gemini-3.8-flash",       # Flagship Google Vision & Reasoning
    "gemini-3.5-flash-lite",  # High-efficiency fallback
    "gemini-3.1-flash-lite",  # Low-latency fallback
]


def _optimize_image_for_vision(path: str, max_size: int = 1024, quality: int = 75) -> Tuple[str, str]:
    """Resize and compress phone camera images to prevent massive base64 payloads and timeouts."""
    try:
        from PIL import Image  # type: ignore[import-not-found]
        import io
        with Image.open(path) as img:
            if img.mode in ("RGBA", "P"):
                img = img.convert("RGB")
            w, h = img.size
            if max(w, h) > max_size:
                ratio = max_size / float(max(w, h))
                new_w = int(w * ratio)
                new_h = int(h * ratio)
                img = img.resize((new_w, new_h), Image.Resampling.LANCZOS)
            buf = io.BytesIO()
            img.save(buf, format="JPEG", quality=quality, optimize=True)
            b64 = base64.b64encode(buf.getvalue()).decode("utf-8")
            return "image/jpeg", b64
    except Exception as e:
        logger.warning("PIL optimization failed for %s: %s, attempting OpenCV resize...", path, e)
        try:
            import cv2
            img_cv = cv2.imread(path)
            if img_cv is not None:
                h, w = img_cv.shape[:2]
                if max(w, h) > max_size:
                    ratio = max_size / float(max(w, h))
                    img_cv = cv2.resize(img_cv, (int(w * ratio), int(h * ratio)), interpolation=cv2.INTER_AREA)
                _, enc = cv2.imencode(".jpg", img_cv, [int(cv2.IMWRITE_JPEG_QUALITY), quality])
                b64 = base64.b64encode(enc.tobytes()).decode("utf-8")
                return "image/jpeg", b64
        except Exception as cv_err:
            logger.warning("OpenCV resize also failed: %s", cv_err)
        raw = Path(path).read_bytes()
        mime = "image/png" if path.lower().endswith(".png") else "image/jpeg"
        return mime, base64.b64encode(raw).decode("utf-8")


def get_api_key(api_key: Optional[str] = None) -> Optional[str]:
    """Resolve Gemini API key from parameter, environment, or .env file."""
    if api_key and api_key.strip():
        return api_key.strip()

    # Check env vars
    for k in ["GEMINI_API_KEY", "GOOGLE_API_KEY"]:
        val = os.environ.get(k)
        if val and val.strip():
            return val.strip()

    # Check .env file in workspace
    env_paths = [
        Path(".env"),
        Path(__file__).resolve().parents[2] / ".env",
    ]
    for p in env_paths:
        if p.is_file():
            try:
                for line in p.read_text(encoding="utf-8").splitlines():
                    line = line.strip()
                    if line.startswith("GEMINI_API_KEY=") or line.startswith("GOOGLE_API_KEY="):
                        key_val = line.split("=", 1)[1].strip("\'\" ")
                        if key_val:
                            return key_val
            except Exception:
                pass
    return None


class LLMComplianceEngine:
    """Performs intelligent Legal Metrology compliance checks via Google Gemini."""

    def __init__(self, api_key: Optional[str] = None):
        self.api_key = get_api_key(api_key)

    def is_available(self, api_key: Optional[str] = None) -> bool:
        """Check if an API key is available."""
        return bool(get_api_key(api_key or self.api_key))

    def fetch_barcode_metadata(self, barcode: str) -> Dict[str, Any]:
        """Fetch publicly available product metadata from Open Food Facts & GS1 registry."""
        meta: Dict[str, Any] = {
            "barcode": barcode,
            "country": lookup_gs1_country(barcode),
            "checksum_valid": validate_ean13_checksum(barcode) if len(barcode) == 13 else True,
            "product_name": None,
            "brand": None,
            "quantity": None,
            "manufacturer": None,
            "categories": None,
            "found_in_db": False,
        }

        try:
            url = f"https://world.openfoodfacts.org/api/v0/product/{barcode}.json"
            headers = {"User-Agent": "LegalMetrologyComplianceApp/2.0"}
            resp = requests.get(url, headers=headers, timeout=6)
            if resp.status_code == 200:
                d = resp.json()
                if d.get("status") == 1:
                    p = d.get("product", {})
                    meta["found_in_db"] = True
                    meta["product_name"] = p.get("product_name") or p.get("product_name_en")
                    meta["brand"] = p.get("brands")
                    meta["quantity"] = p.get("quantity")
                    meta["manufacturer"] = p.get("manufacturing_places") or p.get("brands")
                    meta["categories"] = p.get("categories")
                    meta["packaging"] = p.get("packaging")
                    meta["ingredients"] = p.get("ingredients_text")
                    meta["countries"] = p.get("countries")
        except Exception as e:
            logger.warning("Error querying Open Food Facts for %s: %s", barcode, e)

        return meta

    def analyze_from_barcode(
        self,
        barcode: str,
        api_key: Optional[str] = None,
    ) -> Tuple[PackageData, ComplianceScore, ComplianceDiff, List[str]]:
        """Audit Legal Metrology compliance starting from a barcode."""
        key = get_api_key(api_key or self.api_key)
        if not key:
            raise ValueError("Gemini API key is required for LLM analysis. Please set GEMINI_API_KEY.")

        meta = self.fetch_barcode_metadata(barcode)

        prompt = f"""
You are a senior Legal Metrology Inspector in India.
Evaluate this packaged commodity under the Legal Metrology (Packaged Commodities) Rules, 2011 (India).

Product Barcode Information:
- Barcode / GTIN: {meta['barcode']}
- GS1 Country of Origin: {meta.get('country') or 'Unknown'}
- Barcode Checksum Valid: {meta.get('checksum_valid')}
- Product Name in Database: {meta.get('product_name') or 'Not in public database'}
- Brand: {meta.get('brand') or 'Not in public database'}
- Declared Net Quantity: {meta.get('quantity') or 'Not in public database'}
- Manufacturer / Packaging Place: {meta.get('manufacturer') or 'Not in public database'}
- Categories: {meta.get('categories') or 'Not in public database'}
- Ingredients: {meta.get('ingredients') or 'Not in public database'}

Task:
1. If the product is known or identified from the barcode, verify whether all mandatory declarations required under Indian Legal Metrology Rules 2011 are expected or met.
2. Evaluate these statutory rules:
   - R10_MFR_NAME: Name of manufacturer / packer / importer
   - R10_ADDRESS: Complete address of manufacturer with PIN code
   - R06_MRP: Maximum Retail Price with '(inclusive of all taxes)'
   - R06_DATE: Month and Year of manufacture or packaging
   - R06_CONSUMER: Consumer care details (name/designation, address, telephone, email)
   - R06_GENERIC_NAME: Common or generic name of the commodity
   - R06_NET_QTY: Net quantity declared in standard SI units (g, kg, ml, l)
   - R13_STANDARD_UNITS: Compliance with standard metric units
   - R06_COUNTRY: Country of origin declaration
   - R06_VEG_SYMBOL: Vegetarian / Non-Vegetarian symbol if applicable
3. Return a JSON response conforming EXACTLY to this schema:
{{
  "product_name": "...",
  "brand": "...",
  "declarations": {{
    "manufacturer_name": "... or null",
    "manufacturer_address": "... or null",
    "mrp_value": 0.0 or null,
    "mrp_includes_tax": true,
    "net_quantity_value": 0.0 or null,
    "net_quantity_unit": "g/ml/kg/l/units or null",
    "dates": "month-year or null",
    "consumer_care": "... or null",
    "country_of_origin": "... or null",
    "veg_non_veg": "VEG/NON_VEG or null"
  }},
  "rules": [
    {{
      "rule_id": "R10_MFR_NAME",
      "rule_name": "Manufacturer Name Declaration",
      "status": "PASS",
      "detail": "Explanation of status",
      "severity": "CRITICAL",
      "weight": 1.0
    }}
  ],
  "compliance_score": 75.0,
  "summary": "Concise inspection summary",
  "recommendations": ["Recommendation 1", "Recommendation 2"]
}}
Respond ONLY with the JSON object. No surrounding markdown fences.
"""
        json_resp = self._call_gemini_text(prompt, key)
        return self._build_compliance_result(json_resp, barcode_info=meta)

    def analyze_from_images(
        self,
        front_path: str,
        back_path: Optional[str] = None,
        api_key: Optional[str] = None,
        package_height_mm: Optional[float] = None,
    ) -> Tuple[PackageData, ComplianceScore, ComplianceDiff, List[str]]:
        """Audit Legal Metrology compliance directly from packaging label photos using Vision LLM."""
        key = get_api_key(api_key or self.api_key)
        if not key:
            raise ValueError("Gemini API key is required for LLM analysis. Please set GEMINI_API_KEY.")

        image_parts = []
        for path in [front_path, back_path]:
            if path and Path(path).is_file():
                mime, b64 = _optimize_image_for_vision(path)
                image_parts.append({"mime_type": mime, "data": b64})

        if not image_parts:
            raise ValueError("No valid packaging images could be loaded for Vision analysis.")

        prompt = f"""
You are an expert Legal Metrology Officer in India.
Inspect the provided product packaging images (Front, Back, Side, or Curved labels) under the Legal Metrology (Packaged Commodities) Rules, 2011.

Packaging dimension hint: Package height is ~{package_height_mm or 'standard'} mm.

Instructions:
1. Carefully read and transcribe all text, tables, and marks printed on all provided panels.
2. Extract all statutory declarations required by Indian Law:
   - Commodity Name: Generic/Common/Commodity name of the product (e.g., 'soya snacks', 'roasted snacks', 'snack food')
   - Net Quantity: Magnitude and standard SI unit (e.g., 160g, 160 g, 200g, 500ml)
   - Maximum Retail Price (MRP): Numerical value in INR (e.g., 90.0, 'Rs. 90/-') and whether '(incl. of all taxes)' or 'inclusive of all taxes' is declared
   - Month and Year of manufacture, packaging, or import (e.g., '08-2026', '22-08-2026', 'August 2026')
   - Name and complete postal address of the manufacturer, packer, or marketer (including city, state, and 6-digit PIN code)
   - Consumer care contact details: Telephone/mobile number, email address, and postal address for consumer complaints
   - Country of origin: Country name (e.g. 'India', 'Made in India')
   - Veg / Non-Veg symbol: Green dot inside a green square for vegetarian, or brown triangle for non-vegetarian
   - FSSAI License Number: 14-digit FSSAI number (e.g., '12218026000064')
   - Barcode Number: Digits printed under or beside the barcode lines (e.g., '8904377511553')
3. Audit each statutory rule:
   - R10_MFR_NAME: Manufacturer / Packer / Marketer Name (PASS if clearly stated, FAIL if missing)
   - R10_ADDRESS: Complete postal address with PIN code (PASS if complete with PIN code, WARNING if PIN missing, FAIL if omitted)
   - R06_MRP: Maximum Retail Price with taxes inclusion (PASS if MRP and '(incl. of all taxes)' present, FAIL if missing)
   - R06_DATE: Manufacturing / Packaging date (PASS if month/year or date present, FAIL if absent)
   - R06_CONSUMER: Customer care phone/email (PASS if telephone or email present, FAIL if missing)
   - R06_GENERIC_NAME: Generic/Common product name (PASS if identified anywhere on the pack or label, FAIL if completely absent)
   - R06_NET_QTY: Net quantity declaration (PASS if clear magnitude and metric unit, FAIL if missing)
   - R13_STANDARD_UNITS: Correct metric units used without non-standard symbols (PASS if standard units, FAIL otherwise)
   - R06_COUNTRY: Country of origin declared (PASS if stated or domestic Indian manufacturer address present, FAIL if absent)
   - R06_VEG_SYMBOL: Veg/Non-Veg symbol present if food or nutraceutical (PASS if symbol present, FAIL if absent on food pack)
4. Return a JSON response conforming EXACTLY to this schema:
{{
  "product_name": "Generic or brand name found",
  "brand": "Brand name",
  "declarations": {{
    "manufacturer_name": "... or null",
    "manufacturer_address": "... or null",
    "mrp_value": 0.0 or null,
    "mrp_currency": "INR",
    "mrp_includes_tax": true,
    "net_quantity_value": 0.0 or null,
    "net_quantity_unit": "g/ml/kg/l or null",
    "dates": "month-year or null",
    "consumer_care": "... or null",
    "country_of_origin": "... or null",
    "veg_non_veg": "VEG/NON_VEG or null",
    "fssai_license": "... or null",
    "barcode_printed": "... or null"
  }},
  "rules": [
    {{
      "rule_id": "R10_MFR_NAME",
      "rule_name": "Manufacturer Name Declaration",
      "status": "PASS",
      "detail": "Citation of what was found or why it violates the rule",
      "severity": "CRITICAL",
      "weight": 1.0
    }}
  ],
  "compliance_score": 95.0,
  "summary": "Detailed summary of compliance findings for this specific label",
  "recommendations": ["Specific fix 1", "Specific fix 2"]
}}
Respond ONLY with the JSON object. No markdown backticks.
"""
        try:
            json_resp = self._call_gemini_vision(prompt, image_parts, key)
            return self._build_compliance_result(json_resp)
        except Exception as gemini_err:
            logger.warning("Gemini Vision failed (%s). Attempting Groq Vision fallback...", gemini_err)
            groq_resp = self._call_groq_vision(prompt, image_parts)
            if groq_resp:
                logger.info("Successfully completed compliance analysis using Groq Vision fallback!")
                return self._build_compliance_result(groq_resp)
            raise gemini_err

    def _call_groq_vision(self, prompt: str, image_parts: List[Dict[str, str]]) -> Optional[Dict[str, Any]]:
        """Ultra-fast vision fallback using Groq Vision (llama-3.2-11b-vision-preview)."""
        groq_key = os.environ.get("GROQ_API_KEY", "")
        if not groq_key:
            return None
        try:
            from groq import Groq  # type: ignore[import-not-found]
            client = Groq(api_key=groq_key)
            content_items: List[Dict[str, Any]] = [{"type": "text", "text": prompt}]
            for part in image_parts:
                content_items.append({
                    "type": "image_url",
                    "image_url": {
                        "url": f"data:{part['mime_type']};base64,{part['data']}"
                    }
                })
            for v_model in ["llama-3.2-11b-vision-preview", "llama-3.2-90b-vision-preview"]:
                try:
                    resp = client.chat.completions.create(
                        model=v_model,
                        messages=[{"role": "user", "content": content_items}],
                        response_format={"type": "json_object"},
                        temperature=0.1,
                        timeout=25,
                    )
                    ans = resp.choices[0].message.content
                    if ans:
                        cleaned = re.sub(r"^```json\s*", "", ans.strip())
                        cleaned = re.sub(r"^```\s*", "", cleaned)
                        cleaned = re.sub(r"\s*```$", "", cleaned)
                        return json.loads(cleaned)
                except Exception as inner_e:
                    logger.warning("Groq model %s failed: %s", v_model, inner_e)
        except Exception as e:
            logger.warning("Groq Vision fallback error: %s", e)
        return None

    def _call_gemini_text(self, prompt: str, key: str) -> Dict[str, Any]:
        """Send text prompt to Gemini models with fallback."""
        payload = {
            "contents": [{"parts": [{"text": prompt}]}],
            "generationConfig": {
                "temperature": 0.1,
                "responseMimeType": "application/json",
            },
        }
        return self._post_to_gemini(payload, key)

    def _call_gemini_vision(self, prompt: str, image_parts: List[Dict[str, str]], key: str) -> Dict[str, Any]:
        """Send multimodal image + text payload to Gemini models with fallback."""
        parts: List[Dict[str, Any]] = [{"text": prompt}]
        for part in image_parts:
            parts.append({
                "inlineData": {
                    "mimeType": part["mime_type"],
                    "data": part["data"],
                }
            })

        payload = {
            "contents": [{"parts": parts}],
            "generationConfig": {
                "temperature": 0.1,
                "responseMimeType": "application/json",
            },
        }
        return self._post_to_gemini(payload, key)

    def _post_to_gemini(self, payload: Dict[str, Any], key: str) -> Dict[str, Any]:
        """Execute HTTP POST to Gemini API across candidate models."""
        last_error = None
        for model in MODELS_TO_TRY:
            url = GEMINI_API_URL.format(model=model, key=key)
            try:
                # 35s timeout gives the vision model adequate time to inspect photos and output JSON
                resp = requests.post(url, json=payload, headers={"Content-Type": "application/json"}, timeout=35)
                if resp.status_code == 200:
                    data = resp.json()
                    candidates = data.get("candidates", [])
                    if candidates:
                        text = candidates[0].get("content", {}).get("parts", [{}])[0].get("text", "").strip()
                        # Clean markdown json fences if present
                        text = re.sub(r"^```json\s*", "", text)
                        text = re.sub(r"^```\s*", "", text)
                        text = re.sub(r"\s*```$", "", text)
                        return json.loads(text)
                elif resp.status_code == 503:
                    last_error = f"HTTP 503 Service Unavailable (Google Gemini capacity limit / high traffic)"
                    logger.warning("Model %s returned 503 (Gemini service unavailable/overloaded)", model)
                else:
                    last_error = f"HTTP {resp.status_code}: {resp.text}"
                    logger.warning("Model %s failed: %s", model, last_error)
            except requests.exceptions.Timeout:
                last_error = f"Timeout calling {model} (read timeout=35s)"
                logger.warning("Model %s timed out after 35s", model)
            except Exception as e:
                last_error = str(e)
                logger.warning("Error calling %s: %s", model, e)

        raise RuntimeError(f"Gemini API request failed across candidate models: {last_error}")

    def _build_compliance_result(
        self,
        json_data: Dict[str, Any],
        barcode_info: Optional[Dict[str, Any]] = None,
    ) -> Tuple[PackageData, ComplianceScore, ComplianceDiff, List[str]]:
        """Map Gemini JSON output to standard PackageData, ComplianceScore, and ComplianceDiff objects."""
        pkg = PackageData()

        # Populate package declarations
        decls = json_data.get("declarations", {})
        pkg.commodity_name = json_data.get("product_name") or decls.get("generic_name")
        pkg.manufacturer_name = decls.get("manufacturer_name")
        pkg.manufacturer_address = decls.get("manufacturer_address")
        pkg.mrp_value = float(decls["mrp_value"]) if decls.get("mrp_value") is not None else None
        pkg.mrp_includes_tax = bool(decls.get("mrp_includes_tax", False))
        pkg.net_quantity_value = float(decls["net_quantity_value"]) if decls.get("net_quantity_value") is not None else None
        pkg.net_quantity_unit = decls.get("net_quantity_unit")
        pkg.manufacture_date = decls.get("manufacture_date") or decls.get("dates")
        pkg.expiry_date = decls.get("expiry_date")
        pkg.best_before = decls.get("best_before")
        pkg.consumer_care_name = decls.get("consumer_care_name")
        pkg.consumer_care_phone = decls.get("consumer_care_phone")
        pkg.consumer_care_email = decls.get("consumer_care_email") or decls.get("consumer_care")
        pkg.consumer_care_address = decls.get("consumer_care_address")
        pkg.country_of_origin = decls.get("country_of_origin")
        pkg.has_veg_nonveg_symbol = bool(decls.get("veg_non_veg"))
        pkg.fssai_license_number = decls.get("fssai_license")

        # Barcode fields
        if barcode_info:
            pkg.has_barcode = True
            pkg.barcode_value = barcode_info.get("barcode")
            pkg.barcode_type = "EAN-13" if len(str(pkg.barcode_value)) == 13 else "BARCODE"
            pkg.barcode_valid = barcode_info.get("checksum_valid", True)
            pkg.barcode_country = barcode_info.get("country")
            if str(pkg.barcode_value).startswith("890"):
                pkg.barcode_is_gs1_india = True
        elif decls.get("barcode_printed"):
            raw_bc = str(decls.get("barcode_printed", "")).strip()
            clean_bc = re.sub(r"\D", "", raw_bc)
            if clean_bc:
                pkg.has_barcode = True
                pkg.barcode_value = clean_bc
                pkg.barcode_type = "EAN-13" if len(clean_bc) == 13 else "BARCODE"
                pkg.barcode_valid = validate_ean13_checksum(clean_bc) if len(clean_bc) == 13 else True
                pkg.barcode_country = lookup_gs1_country(clean_bc) or "India"
                if clean_bc.startswith("890"):
                    pkg.barcode_is_gs1_india = True

        # Build RuleResults
        passed: List[RuleResult] = []
        failed: List[RuleResult] = []
        warnings: List[RuleResult] = []
        not_applicable: List[RuleResult] = []
        inconclusive: List[RuleResult] = []

        rules_list = json_data.get("rules", [])
        for r in rules_list:
            rr = RuleResult(
                rule_id=r.get("rule_id", "RULE"),
                rule_name=r.get("rule_name", r.get("rule_id", "Rule")),
                status=r.get("status", "INCONCLUSIVE").upper(),
                detail=r.get("detail", ""),
                severity=r.get("severity", "MINOR").upper(),
                weight=float(r.get("weight", 1.0)),
            )
            st = rr.status
            if st == "PASS":
                passed.append(rr)
            elif st == "FAIL":
                failed.append(rr)
            elif st == "WARNING":
                warnings.append(rr)
            elif st == "NOT_APPLICABLE":
                not_applicable.append(rr)
            else:
                inconclusive.append(rr)

        total_rules = len(passed) + len(failed) + len(warnings) + len(not_applicable) + len(inconclusive)
        diff = ComplianceDiff(
            total_rules=total_rules,
            passed=passed,
            failed=failed,
            warnings=warnings,
            not_applicable=not_applicable,
            inconclusive=inconclusive,
        )

        # Score calculation: 0.0 to 1.0 scale
        raw_score = float(json_data.get("compliance_score", 0.0))
        if raw_score > 1.0:
            final_score = raw_score / 100.0
        elif raw_score <= 0.0 and (passed or failed):
            total_applicable = len(passed) + len(failed) + len(warnings)
            final_score = (len(passed) / total_applicable) if total_applicable > 0 else 1.0
        else:
            final_score = raw_score

        pct = final_score * 100.0
        star_rating = 5 if pct >= 85 else 4 if pct >= 70 else 3 if pct >= 50 else 2 if pct >= 35 else 1
        star_labels = {5: "Fully Compliant", 4: "Substantially Compliant", 3: "Partially Compliant", 2: "Non-Compliant", 1: "Critical Violations"}

        score = ComplianceScore(
            final_score=round(final_score, 3),
            ebm_score=round(final_score, 3),
            rule_score=round(final_score, 3),
            star_rating=star_rating,
            star_label=star_labels.get(star_rating, "Compliant"),
            total_applicable_rules=len(passed) + len(failed) + len(warnings),
            passed_rules=len(passed),
            failed_rules=len(failed),
            critical_failures=sum(1 for f in failed if f.severity == "CRITICAL"),
            major_failures=sum(1 for f in failed if f.severity == "MAJOR"),
            minor_failures=sum(1 for f in failed if f.severity == "MINOR"),
        )

        recommendations = json_data.get("recommendations", [])
        return pkg, score, diff, recommendations

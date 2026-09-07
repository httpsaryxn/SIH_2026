import json
import logging
import re
from typing import Dict, Any, List, Optional
from groq import Groq
from .config import settings

logger = logging.getLogger(__name__)

MANDATORY_MEDICINAL_DISCLAIMER = "Informational summary of declared label content only. Not medical advice."

_groq_client: Optional[Groq] = None


def get_groq_client() -> Optional[Groq]:
    global _groq_client
    if _groq_client is not None:
        return _groq_client
    if not settings.GROQ_API_KEY:
        logger.warning("GROQ_API_KEY not configured.")
        return None
    try:
        _groq_client = Groq(api_key=settings.GROQ_API_KEY)
        return _groq_client
    except Exception as e:
        logger.error(f"Failed to initialize Groq client: {e}")
        return None


def get_candidate_models(client: Groq) -> List[str]:
    """
    Returns an ordered list of candidate models to try.
    Prioritizes configured model, then known robust models,
    then dynamically discovered models from Groq API.
    """
    candidates: List[str] = []
    
    # 1. Primary configured model
    if settings.GROQ_MODEL and settings.GROQ_MODEL.strip():
        candidates.append(settings.GROQ_MODEL.strip())
        
    # 2. Known robust fallbacks
    for m in getattr(settings, "GROQ_FALLBACK_MODELS", ["qwen/qwen3.8-27b", "groq/compound", "groq/compound-mini"]):
        if m not in candidates:
            candidates.append(m)

    # 3. Dynamic discovery from client.models.list()
    try:
        models_data = client.models.list()
        for model_obj in getattr(models_data, "data", []):
            m_id = getattr(model_obj, "id", "")
            is_active = getattr(model_obj, "active", True)
            if not is_active:
                continue
            # Filter for text/chat models
            if any(k in m_id.lower() for k in ["qwen", "compound", "llama", "gpt-oss"]):
                if "guard" not in m_id.lower() and "safeguard" not in m_id.lower() and "whisper" not in m_id.lower():
                    if m_id not in candidates:
                        candidates.append(m_id)
    except Exception as e:
        logger.debug(f"Dynamic Groq model discovery notice: {e}")

    return candidates


def extract_json_robust(text: str) -> Dict[str, Any]:
    """
    Extracts and parses JSON object from LLM response,
    handling markdown code blocks, preamble text, or trailing commentary.
    """
    cleaned = text.strip()
    # 1. Try direct parse
    try:
        return json.loads(cleaned)
    except Exception:
        pass

    # 2. Try markdown fence: ```json { ... } ``` or ``` { ... } ```
    match = re.search(r"```(?:json)?\s*(\{.*?\})\s*```", cleaned, re.DOTALL)
    if match:
        try:
            return json.loads(match.group(1))
        except Exception:
            pass

    # 3. Try finding outermost { ... }
    first_brace = cleaned.find("{")
    last_brace = cleaned.rfind("}")
    if first_brace != -1 and last_brace != -1 and last_brace > first_brace:
        candidate_json = cleaned[first_brace : last_brace + 1]
        try:
            return json.loads(candidate_json)
        except Exception:
            pass

    raise ValueError(f"Could not parse JSON from model output: {text[:200]}")


def classify_and_summarize_consumer(
    product_name: str,
    manufacturer: Optional[str] = None,
    declarations: Optional[Dict[str, Any]] = None,
    rules: Optional[Dict[str, Any]] = None,
    ocr_text: Optional[str] = None,
) -> Dict[str, Any]:
    """
    Calls Groq LLM to classify product type and produce consumer-friendly insights.
    Tries candidate models in order, falling back gracefully.
    """
    declarations = declarations or {}
    rules = rules or {}

    client = get_groq_client()
    if not client:
        return _fallback_consumer_summary(product_name, declarations, rules)

    system_prompt = """You are an expert consumer protection, food safety, and legal metrology assistant for the LabelLens application.
Your goal is to inspect declared packaging label data and provide transparent, helpful, plain-language summaries for everyday consumers.

You must follow these strict rules:
1. CLASSIFY the product into exactly one of: "food", "medicinal", "general".
   - "food": Edible items, drinks, snacks, spices, dairy, confectionery, grocery. Key indicators: FSSAI license, nutritional facts, ingredient list.
   - "medicinal": Drugs, pharmaceuticals, ayurvedic medicines, syrups, supplements, topical ointments, schedule drugs, dosage guidelines.
   - "general": Non-food/non-medicinal items (e.g. detergents, cosmetics, electronics, stationery, apparel, hardware).

2. IF FOOD:
   - Provide a plain-language summary of key ingredients and nutritional highlights.
   - Outline health benefits and any concerns (e.g. high sugar, sodium, palm oil, artificial additives).
   - Assign a "health_score" from 0 to 100 based strictly on nutritional balance and ingredient wholesomeness:
     * 80–100: Wholesome, nutrient-dense, low additives/sugar.
     * 50–79: Moderate; balanced but with processed elements or moderate sugar/sodium.
     * 0–49: Highly processed, excessive sugar/salt/saturated fat, or concerning synthetic additives.
   - Explain why this health score was given in 1 sentence.

3. IF MEDICINAL:
   - Provide a plain-language summary of what the medicine/product is used for.
   - Provide a medicinal safety summary highlighting dosage directions, warnings, storage conditions, and consumer care info.
   - MUST include the exact disclaimer: "Informational summary of declared label content only. Not medical advice."
   - Set health_score to null.

4. IF GENERAL:
   - Provide a clean, plain-language declaration summary (commodity name, quantity, price, manufacturer, warranty/support).
   - Set health_score to null and medicinal_safety_summary to null.

Output ONLY valid JSON with this schema:
{
  "product_type": "food" | "medicinal" | "general",
  "classification_reasoning": "string explaining why this classification was chosen",
  "summary_text": "string (plain language consumer summary with markdown formatting)",
  "health_score": integer (0-100) or null,
  "health_score_rationale": "string or null",
  "medicinal_safety_summary": "string or null",
  "mandatory_disclaimer": "string or null"
}
"""

    user_content = f"""Product Name: {product_name}
Manufacturer: {manufacturer or 'Not specified'}
Declared Information:
{json.dumps(declarations, indent=2)}

Legal Metrology Rule Status:
Passed Rules: {len(rules.get('passed', []))}
Failed Rules: {len(rules.get('failed', []))}
Warnings: {len(rules.get('warnings', []))}

OCR Text Sample:
{(ocr_text or '')[:1000]}
"""

    candidates = get_candidate_models(client)
    last_error = None

    for model_name in candidates:
        try:
            logger.info(f"Invoking Groq consumer summary with model: {model_name}")
            
            try:
                completion = client.chat.completions.create(
                    model=model_name,
                    messages=[
                        {"role": "system", "content": system_prompt},
                        {"role": "user", "content": user_content}
                    ],
                    temperature=0.2,
                    response_format={"type": "json_object"},
                    max_tokens=800,
                )
            except Exception as json_err:
                logger.debug(f"json_object mode failed on {model_name}, retrying standard: {json_err}")
                completion = client.chat.completions.create(
                    model=model_name,
                    messages=[
                        {"role": "system", "content": system_prompt + "\nReturn ONLY the JSON object, no explanation."},
                        {"role": "user", "content": user_content}
                    ],
                    temperature=0.2,
                    max_tokens=800,
                )

            raw_text = completion.choices[0].message.content or "{}"
            parsed = extract_json_robust(raw_text)

            # Enforce medicinal disclaimer
            if parsed.get("product_type") == "medicinal":
                parsed["mandatory_disclaimer"] = MANDATORY_MEDICINAL_DISCLAIMER
                if MANDATORY_MEDICINAL_DISCLAIMER not in (parsed.get("summary_text") or ""):
                    parsed["summary_text"] = f"{parsed.get('summary_text', '')}\n\n*⚠️ {MANDATORY_MEDICINAL_DISCLAIMER}*"

            logger.info(f"Groq consumer summary successfully generated with model: {model_name}")
            return parsed

        except Exception as e:
            logger.warning(f"Groq model {model_name} failed: {e}")
            last_error = e
            continue

    logger.error(f"All Groq models failed. Last error: {last_error}. Using heuristic fallback.")
    return _fallback_consumer_summary(product_name, declarations, rules)


def generate_regulator_summary(
    product_name: str,
    company_name: Optional[str],
    declaration_checks: list,
    metadata: Optional[Dict[str, Any]] = None,
) -> str:
    """
    Calls Groq LLM to synthesize a thorough regulatory compliance audit summary.
    Tries candidate models in order, falling back gracefully.
    """
    client = get_groq_client()
    if not client:
        return _fallback_regulator_summary(product_name, declaration_checks)

    system_prompt = """You are a senior Legal Metrology Enforcement Officer and Packaging Compliance Analyst under the Legal Metrology Act, 2009 and the Legal Metrology (Packaged Commodities) Rules, 2011 (PCR 2011).

Review the label verification audit findings and write a formal, authoritative, and concise regulatory inspection summary.
Include:
1. Executive Assessment: Overall compliance status (Compliant, Warning, or Potential Violation).
2. Detailed Breakdown:
   - Mandatory Declarations that PASSED (Name, Net Quantity, MRP, Manufacturer details, Consumer Care, etc.).
   - Violations or Warnings with exact Rule references (e.g. Rule 6(1)(a) Commodity Name, Rule 6(1)(b) Net Qty & font height, Rule 6(1)(e) MRP format, Rule 6(1)(d) Date of packaging).
3. Recommended Action: Clear enforcement recommendations (Issue Show Cause Notice, verify manufacturing records, or grant clearance).

Format using clean GitHub-flavored Markdown. Do not include markdown code fences (```markdown).
"""

    user_content = f"""Commodity / Product: {product_name}
Manufacturer / Packer: {company_name or 'Unknown'}
Metadata: {json.dumps(metadata or {}, indent=2)}

Declaration Checks Table:
{json.dumps(declaration_checks, indent=2)}
"""

    candidates = get_candidate_models(client)
    last_error = None

    for model_name in candidates:
        try:
            logger.info(f"Invoking Groq regulator summary with model: {model_name}")
            completion = client.chat.completions.create(
                model=model_name,
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_content}
                ],
                temperature=0.2,
                max_tokens=900,
            )
            text = completion.choices[0].message.content or ""
            if text.strip():
                logger.info(f"Groq regulator summary successfully generated with model: {model_name}")
                return text.strip()
        except Exception as e:
            logger.warning(f"Groq model {model_name} failed: {e}")
            last_error = e
            continue

    logger.error(f"All Groq models failed. Last error: {last_error}. Using heuristic fallback.")
    return _fallback_regulator_summary(product_name, declaration_checks)


# ── Deterministic Fallbacks (if Groq is unreachable or key not provided) ──

def _fallback_consumer_summary(
    product_name: str,
    declarations: Dict[str, Any],
    rules: Dict[str, Any],
) -> Dict[str, Any]:
    name_lower = product_name.lower()
    has_fssai = bool(declarations.get("fssai") or declarations.get("fssai_license_no"))
    is_pharma = any(w in name_lower for w in ["syrup", "tablet", "capsule", "ointment", "mg", "pharma", "medicine"])

    if is_pharma:
        product_type = "medicinal"
        reasoning = "Detected pharmaceutical / medicinal terminology in product description."
        summary = (
            f"### {product_name} — Medicinal Label Summary\n\n"
            f"- **Declared Use / Purpose**: Packaged pharmaceutical or wellness commodity.\n"
            f"- **Manufacturer**: {declarations.get('manufacturer', 'Declared on package')}\n"
            f"- **Net Volume / Quantity**: {declarations.get('net_quantity', 'Refer package')}\n"
            f"- **Storage & Safety**: Check package for recommended storage temperature and batch dates."
        )
        safety = "Verify batch number and expiry date before consumption. Keep out of reach of children."
        disclaimer = MANDATORY_MEDICINAL_DISCLAIMER
        return {
            "product_type": product_type,
            "classification_reasoning": reasoning,
            "summary_text": f"{summary}\n\n*⚠️ {disclaimer}*",
            "health_score": None,
            "health_score_rationale": None,
            "medicinal_safety_summary": safety,
            "mandatory_disclaimer": disclaimer,
        }
    elif has_fssai or any(w in name_lower for w in ["food", "snack", "drink", "chocolate", "chips", "biscuit", "tea", "coffee"]):
        product_type = "food"
        reasoning = "Identified FSSAI compliance declaration or standard packaged food category."
        summary = (
            f"### {product_name} — Food & Nutrition Overview\n\n"
            f"- **Net Contents**: {declarations.get('net_quantity', 'Standard retail pack')}\n"
            f"- **Max Retail Price (MRP)**: ₹{declarations.get('mrp', 'Inclusive of all taxes')}\n"
            f"- **FSSAI License**: {declarations.get('fssai') or 'Declared on packaging'}\n"
            f"- **Nutritional Note**: Balanced packaged consumer commodity. Check declared allergen details on label."
        )
        return {
            "product_type": product_type,
            "classification_reasoning": reasoning,
            "summary_text": summary,
            "health_score": 75,
            "health_score_rationale": "Standard packaged commodity meeting mandatory packaging declaration norms.",
            "medicinal_safety_summary": None,
            "mandatory_disclaimer": None,
        }
    else:
        product_type = "general"
        reasoning = "General consumer packaged goods classification."
        summary = (
            f"### {product_name} — Packaging Declarations\n\n"
            f"- **Commodity Name**: {product_name}\n"
            f"- **Net Quantity**: {declarations.get('net_quantity', 'Declared')}\n"
            f"- **Manufacturer / Packer**: {declarations.get('manufacturer', 'Declared')}\n"
            f"- **Customer Care**: {declarations.get('consumer_care', 'Declared on label')}"
        )
        return {
            "product_type": product_type,
            "classification_reasoning": reasoning,
            "summary_text": summary,
            "health_score": None,
            "health_score_rationale": None,
            "medicinal_safety_summary": None,
            "mandatory_disclaimer": None,
        }


def _fallback_regulator_summary(product_name: str, declaration_checks: list) -> str:
    violations = [c for c in declaration_checks if c.get("status") in ["Violation", "FAIL"]]
    warnings = [c for c in declaration_checks if c.get("status") in ["Warning", "WARN"]]
    passed = [c for c in declaration_checks if c.get("status") in ["Compliant", "PASS"]]

    status_str = "POTENTIAL VIOLATION" if violations else ("WARNING" if warnings else "COMPLIANT")

    lines = [
        f"## Legal Metrology Compliance Inspection: {product_name}",
        f"**Audit Finding**: `{status_str}` | Passed: {len(passed)} | Warnings: {len(warnings)} | Violations: {len(violations)}\n",
        "### Key Findings:",
    ]
    for v in violations:
        lines.append(f"- ❌ **Violation**: {v.get('field_name')} — {v.get('rule_citation', 'PCR 2011')}: {v.get('rule_description', 'Declaration discrepancy detected.')}")
    for w in warnings:
        lines.append(f"- ⚠️ **Warning**: {w.get('field_name')} — {w.get('rule_citation', 'PCR 2011')}: {w.get('rule_description', 'Review recommended.')}")
    for p in passed:
        lines.append(f"- ✅ **Pass**: {p.get('field_name')}: {p.get('extracted_value', 'Found')}")

    return "\n".join(lines)

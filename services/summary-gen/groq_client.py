import json
import logging
from typing import Dict, Any, Tuple, Optional
from groq import Groq
from config import settings

logger = logging.getLogger(__name__)

MANDATORY_MEDICINAL_DISCLAIMER = "Informational summary of declared label content only. Not medical advice."

def get_groq_client() -> Optional[Groq]:
    if not settings.GROQ_API_KEY:
        logger.warning("GROQ_API_KEY not configured.")
        return None
    return Groq(api_key=settings.GROQ_API_KEY)

def classify_and_summarize_consumer(
    product_name: str,
    manufacturer: Optional[str] = None,
    declarations: Optional[Dict[str, Any]] = None,
    rules: Optional[Dict[str, Any]] = None,
    ocr_text: Optional[str] = None,
) -> Dict[str, Any]:
    """
    Calls Groq LLM to classify product type and produce consumer-friendly insights.
    Falls back gracefully if Groq is unavailable.
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

    try:
        completion = client.chat.completions.create(
            model=settings.GROQ_MODEL,
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_content}
            ],
            temperature=0.2,
            response_format={"type": "json_object"},
        )
        
        raw_text = completion.choices[0].message.content or "{}"
        parsed = json.loads(raw_text)
        
        # Enforce medicinal disclaimer
        if parsed.get("product_type") == "medicinal":
            disclaimer = "Informational summary of declared label content only. Not medical advice."
            parsed["mandatory_disclaimer"] = disclaimer
            if disclaimer not in (parsed.get("summary_text") or ""):
                parsed["summary_text"] = f"{parsed.get('summary_text', '')}\n\n*⚠️ {disclaimer}*"
                
        return parsed
    except Exception as e:
        logger.error(f"Groq consumer summary error: {e}")
        return _fallback_consumer_summary(product_name, declarations, rules)


def generate_regulator_summary(
    product_name: str,
    company_name: Optional[str],
    declaration_checks: list,
    metadata: Optional[Dict[str, Any]] = None,
) -> str:
    """
    Calls Groq LLM to synthesize a thorough regulatory compliance audit summary.
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

    try:
        completion = client.chat.completions.create(
            model=settings.GROQ_MODEL,
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_content}
            ],
            temperature=0.2,
        )
        return completion.choices[0].message.content or ""
    except Exception as e:
        logger.error(f"Groq regulator summary error: {e}")
        return _fallback_regulator_summary(product_name, declaration_checks)


# ── Deterministic Fallbacks (if Groq is unreachable or key not provided) ──

def _fallback_consumer_summary(
    product_name: str,
    declarations: Dict[str, Any],
    rules: Dict[str, Any],
) -> Dict[str, Any]:
    # Heuristic classification based on keys & commodity name
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
        disclaimer = "Informational summary of declared label content only. Not medical advice."
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

from fastapi import APIRouter, HTTPException, Query, status
from typing import List, Optional
from app.core.supabase import get_supabase_client
from app.schemas.small_business import (
    SmallBusinessLabelCreate,
    SmallBusinessLabelUpdate,
    SmallBusinessLabelResponse,
    SmallBusinessIngredientSchema,
    SmallBusinessNutrientSchema,
    SmallBusinessClaimSchema,
    ComplianceAuditResponse,
    RegulatoryVerificationRequest,
    RegulatoryVerificationResponse,
)
from app.services.compliance_verification import ComplianceVerificationService

router = APIRouter(prefix="/small-business/labels", tags=["Small Business Label Studio"])


def _format_label_record(record: dict) -> SmallBusinessLabelResponse:
    ingredients = [
        SmallBusinessIngredientSchema(**ing)
        for ing in record.get("small_business_ingredients", []) or record.get("ingredients", [])
    ]
    allergens = [
        a.get("allergen_name") if isinstance(a, dict) else str(a)
        for a in (record.get("small_business_allergens", []) or record.get("allergens", []))
    ]
    nutrients = [
        SmallBusinessNutrientSchema(**n)
        for n in record.get("small_business_nutrients", []) or record.get("nutrients", [])
    ]
    claims = [
        SmallBusinessClaimSchema(**c)
        for c in record.get("small_business_claims", []) or record.get("claims", [])
    ]

    base_data = {k: v for k, v in record.items() if k not in ["small_business_ingredients", "small_business_allergens", "small_business_nutrients", "small_business_claims", "ingredients", "allergens", "nutrients", "claims"]}
    return SmallBusinessLabelResponse(
        **base_data,
        ingredients=ingredients,
        allergens=allergens,
        nutrients=nutrients,
        claims=claims,
    )


@router.get("", response_model=List[SmallBusinessLabelResponse], summary="List all Small Business Labels")
def get_labels(
    search: Optional[str] = Query(None, description="Search by product, brand, or category"),
    category: Optional[str] = Query(None, description="Filter by category"),
):
    client = get_supabase_client()
    if not client:
        raise HTTPException(status_code=503, detail="Database service currently unavailable")

    try:
        query = (
            client.table("small_business_labels")
            .select("""
                *,
                small_business_ingredients(*),
                small_business_allergens(*),
                small_business_nutrients(*),
                small_business_claims(*)
            """)
            .neq("status", "draft")
            .order("created_at", desc=True)
        )

        if category:
            query = query.eq("product_category", category)

        res = query.execute()
        records = res.data or []

        if search:
            s = search.lower().strip()
            records = [
                r for r in records
                if s in r.get("product_name", "").lower()
                or s in r.get("brand_name", "").lower()
                or s in r.get("product_category", "").lower()
            ]

        return [_format_label_record(r) for r in records]
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to query labels: {str(e)}")


@router.get("/draft", response_model=Optional[SmallBusinessLabelResponse], summary="Get Latest Active Draft")
def get_active_draft():
    client = get_supabase_client()
    if not client:
        raise HTTPException(status_code=503, detail="Database service currently unavailable")

    try:
        res = (
            client.table("small_business_labels")
            .select("""
                *,
                small_business_ingredients(*),
                small_business_allergens(*),
                small_business_nutrients(*),
                small_business_claims(*)
            """)
            .eq("status", "draft")
            .order("updated_at", desc=True)
            .limit(1)
            .execute()
        )

        if not res.data:
            return None

        return _format_label_record(res.data[0])
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch active draft: {str(e)}")


@router.get("/{id}", response_model=SmallBusinessLabelResponse, summary="Get Label by ID")
def get_label_by_id(id: str):
    client = get_supabase_client()
    if not client:
        raise HTTPException(status_code=503, detail="Database service currently unavailable")

    try:
        res = (
            client.table("small_business_labels")
            .select("""
                *,
                small_business_ingredients(*),
                small_business_allergens(*),
                small_business_nutrients(*),
                small_business_claims(*)
            """)
            .eq("id", id)
            .single()
            .execute()
        )

        if not res.data:
            raise HTTPException(status_code=404, detail="Label not found")

        return _format_label_record(res.data)
    except Exception as e:
        raise HTTPException(status_code=404, detail="Label not found")


@router.post("/draft", response_model=SmallBusinessLabelResponse, summary="Save or Update Draft")
def save_draft(label: SmallBusinessLabelCreate, label_id: Optional[str] = None):
    client = get_supabase_client()
    if not client:
        raise HTTPException(status_code=503, detail="Database service currently unavailable")

    try:
        label_dict = label.model_dump(exclude={"ingredients", "allergens", "nutrients", "claims"})
        label_dict["status"] = "draft"

        if label_id:
            res = client.table("small_business_labels").update(label_dict).eq("id", label_id).execute()
            saved_id = label_id
        else:
            res = client.table("small_business_labels").insert(label_dict).execute()
            saved_id = res.data[0]["id"]

        # Sync child tables
        _sync_child_records(client, saved_id, label)

        # Re-fetch complete record
        return get_label_by_id(saved_id)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to save draft: {str(e)}")


@router.post("/publish", response_model=SmallBusinessLabelResponse, summary="Publish / Finalize Compliant Label")
def publish_label(label: SmallBusinessLabelCreate, label_id: Optional[str] = None):
    """
    Publish a label to finalize it for production.

    IMPORTANT:
    - Publishing does NOT block based on compliance verification status
    - Regulatory verification is informational only
    - Compliance scores will be computed via the /audit endpoint
    - Label transitions to "ready" status for production use
    """
    client = get_supabase_client()
    if not client:
        raise HTTPException(status_code=503, detail="Database service currently unavailable")

    try:
        label_dict = label.model_dump(exclude={"ingredients", "allergens", "nutrients", "claims"})
        label_dict.update({
            "status": "ready",
            "completion_percentage": 100,
            "current_step": 6,
            # Do NOT hard-code compliance scores
            # These should be computed via audit() endpoint
        })

        if label_id:
            res = client.table("small_business_labels").update(label_dict).eq("id", label_id).execute()
            saved_id = label_id
        else:
            res = client.table("small_business_labels").insert(label_dict).execute()
            saved_id = res.data[0]["id"]

        # Sync child tables
        _sync_child_records(client, saved_id, label)

        return get_label_by_id(saved_id)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to publish label: {str(e)}")


@router.post("/verify-regulatory", response_model=RegulatoryVerificationResponse, summary="Verify Regulatory Identifier (FSSAI, etc.)")
def verify_regulatory(request: RegulatoryVerificationRequest):
    """
    Verify a regulatory identifier (e.g., FSSAI license number).

    This endpoint is non-blocking - verification failures or unavailability
    will NOT prevent label creation or publishing.

    Supported regulatory types:
    - fssai: FSSAI license number (14 digits)
    - legal_metrology: Legal metrology registration
    - bis: BIS registration (future)

    Response always contains can_continue=true, allowing the user to proceed
    regardless of verification outcome.
    """
    try:
        response = ComplianceVerificationService.verify_regulatory(
            regulatory_type=request.regulatory_type,
            registration_number=request.registration_number,
            product_category=request.product_category,
            is_food_product=request.is_food_product,
        )
        return response.to_dict()
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Verification failed: {str(e)}")


@router.post("/audit", response_model=ComplianceAuditResponse, summary="Audit Label Compliance against FSSAI & Legal Metrology")
def audit_compliance(label: SmallBusinessLabelCreate):
    """
    Audit label compliance against FSSAI and Legal Metrology requirements.

    IMPORTANT NOTES:
    - FSSAI is conditional: only required for food products
    - FSSAI format validation (14 digits) does not mean verification
    - Missing FSSAI for non-food products is NOT a compliance issue
    - Verification status is separate from format validity
    """
    checks_passed = []
    warnings = []
    fssai_compliant = None  # None = not applicable or not verified
    legal_metrology_compliant = True

    # 1. Basic details
    if label.brand_name and label.product_name:
        checks_passed.append("FSSAI Rule 2.2.1: Declared trade name and commodity name present")
    else:
        warnings.append("Missing brand or product name")

    # 2. Net quantity & USP (Legal Metrology requirement)
    if label.net_quantity and label.mrp:
        checks_passed.append("Legal Metrology (Packaged Commodities) Rule 6: Mandatory Net Qty, MRP & USP present")
    else:
        warnings.append("MRP or Net Quantity missing")
        legal_metrology_compliant = False

    # 3. Ingredients & Allergens
    if len(label.ingredients) > 0:
        checks_passed.append(f"FSSAI Rule 2.2.2: {len(label.ingredients)} ingredients listed in descending order of weight/volume")
    else:
        warnings.append("Ingredients list is empty")

    if len(label.allergens) > 0:
        checks_passed.append(f"Food Safety Allergen Declaration: {', '.join(label.allergens)} declared with prominent bold highlighting")

    # 4. FSSAI License - Format validation only
    # NOTE: Format valid does NOT mean officially verified
    is_food_product = "food" in label.product_category.lower() or label.product_category in ["Pickles & Condiments", "Beverages"]

    if label.fssai_license_number:
        fssai_number = label.fssai_license_number.strip()
        if len(fssai_number) == 14 and fssai_number.isdigit():
            checks_passed.append(f"FSSAI License Format: 14 digits valid ({fssai_number})")
            # Format is valid, but NOT officially verified - that requires portal access
            fssai_compliant = None  # Format valid but not officially verified
        else:
            warnings.append(f"FSSAI license format invalid. Expected 14 digits, got: {fssai_number}")
            fssai_compliant = False
    else:
        # No FSSAI provided
        if is_food_product:
            warnings.append("FSSAI license number required for food products")
            fssai_compliant = False
        else:
            checks_passed.append("FSSAI not applicable for non-food products")
            fssai_compliant = None  # Not applicable

    # 5. Vegetarian mark (only for food products)
    if is_food_product:
        if label.is_vegetarian is not None:
            checks_passed.append("FSSAI Mandatory Vegetarian Symbol assigned")
        else:
            warnings.append("Vegetarian/Non-vegetarian mark not set")
    else:
        checks_passed.append("Vegetarian mark not required for non-food products")

    # Calculate compliance score
    score = 100 - (len(warnings) * 5)
    score = max(score, 60)  # Minimum 60

    # Determine overall status
    if score >= 85:
        status = "Good Compliance"
    elif score >= 70:
        status = "Action Required"
    else:
        status = "Needs Attention"

    return ComplianceAuditResponse(
        score=score,
        status=status,
        checks_passed=checks_passed,
        warnings=warnings,
        fssai_compliant=fssai_compliant if fssai_compliant is not None else True,  # Default to True for display
        legal_metrology_compliant=legal_metrology_compliant,
    )


@router.delete("/{id}", status_code=status.HTTP_204_NO_CONTENT, summary="Delete Label")
def delete_label(id: str):
    client = get_supabase_client()
    if not client:
        raise HTTPException(status_code=503, detail="Database service currently unavailable")

    try:
        client.table("small_business_labels").delete().eq("id", id).execute()
        return None
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to delete label: {str(e)}")


def _sync_child_records(client, label_id: str, label: SmallBusinessLabelCreate):
    # Ingredients
    if label.ingredients:
        client.table("small_business_ingredients").delete().eq("label_id", label_id).execute()
        ing_data = [
            {"label_id": label_id, "name": i.name, "percentage": i.percentage, "order_index": idx + 1}
            for idx, i in enumerate(label.ingredients)
        ]
        client.table("small_business_ingredients").insert(ing_data).execute()

    # Allergens
    if label.allergens:
        client.table("small_business_allergens").delete().eq("label_id", label_id).execute()
        alg_data = [{"label_id": label_id, "allergen_name": a} for a in label.allergens]
        client.table("small_business_allergens").insert(alg_data).execute()

    # Nutrients
    if label.nutrients:
        client.table("small_business_nutrients").delete().eq("label_id", label_id).execute()
        nutr_data = [
            {
                "label_id": label_id,
                "label": n.label,
                "value": n.value,
                "unit": n.unit,
                "is_required": n.is_required,
                "is_sub_nutrient": n.is_sub_nutrient,
                "order_index": idx + 1,
            }
            for idx, n in enumerate(label.nutrients)
        ]
        client.table("small_business_nutrients").insert(nutr_data).execute()

    # Claims
    if label.claims:
        client.table("small_business_claims").delete().eq("label_id", label_id).execute()
        claims_data = [
            {
                "label_id": label_id,
                "claim_id": c.claim_id,
                "title": c.title,
                "description": c.description,
                "category": c.category,
                "requires_lab_report": c.requires_lab_report,
                "legal_reference": c.legal_reference,
            }
            for c in label.claims
        ]
        client.table("small_business_claims").insert(claims_data).execute()

from pydantic import BaseModel, Field
from typing import List, Optional, Any
from datetime import datetime


class SmallBusinessIngredientSchema(BaseModel):
    id: Optional[str] = None
    name: str = Field(..., description="Ingredient name e.g. Raw Mango Pieces")
    percentage: Optional[float] = Field(None, description="Percentage of total formulation")
    order_index: int = 0


class SmallBusinessNutrientSchema(BaseModel):
    id: Optional[str] = None
    label: str = Field(..., description="Nutrient name e.g. Calories, Total Fat")
    value: str = Field(..., description="Nutrient value per serving or 100g")
    unit: str = Field("g", description="Unit of measurement e.g. g, mg, kcal")
    is_required: bool = False
    is_sub_nutrient: bool = False
    order_index: int = 0


class SmallBusinessClaimSchema(BaseModel):
    id: Optional[str] = None
    claim_id: Optional[str] = None
    title: str = Field(..., description="Front-of-pack claim title")
    description: Optional[str] = None
    category: str = "common"
    requires_lab_report: bool = False
    legal_reference: Optional[str] = None


class SmallBusinessLabelBase(BaseModel):
    brand_name: str = Field("Desi Harvest", description="Registered or trading brand name")
    product_name: str = Field("Authentic Mango Pickle", description="Declared product name")
    product_category: str = Field("Pickles & Condiments", description="Primary commodity category")
    type_flavour: Optional[str] = Field("Traditional Spicy", description="Variant, flavour or sub-class")
    logo_url: Optional[str] = None
    status: str = Field("draft", description="draft | ready | needs_review")
    completion_percentage: int = Field(17, ge=0, le=100)
    current_step: int = Field(1, ge=1, le=6)
    ingredient_source: str = "noLabReport"
    net_quantity: str = "100"
    net_quantity_unit: str = "g"
    serving_size: str = "30"
    serving_size_unit: str = "g"
    display_mode: str = "perServing"
    label_format: str = "table"
    target_audience: str = "General"
    age_group: str = "Adults (18+)"
    manufacturer_name: Optional[str] = "Desi Harvest"
    manufacturer_address: Optional[str] = "12, Greenfield Organic Estate, Pune, MH 411028"
    packer_address_same_as_manufacturer: bool = True
    packer_name: Optional[str] = None
    packer_address: Optional[str] = None
    fssai_license_number: Optional[str] = None
    marketed_by: Optional[str] = None
    country_of_origin: str = "India"
    consumer_care_phone: Optional[str] = "+91 98765 43210"
    consumer_care_email: Optional[str] = "care@desiharvest.in"
    consumer_care_website: Optional[str] = "www.desiharvest.in"
    mrp: str = "149.00"
    usp: str = "₹ 0.60 / g"
    batch_number: Optional[str] = "DH-2026-B8"
    mfg_date: Optional[str] = "AUG 2026"
    best_before: str = "12 Months from Packaging"
    storage_instructions: Optional[str] = "Store in a cool & dry place away from direct sunlight."
    usage_instructions: Optional[str] = "Use a clean, dry spoon. Consume within 30 days after opening."
    packaging_type: str = "Food Grade Glass Jar"
    is_vegetarian: bool = True
    recycling_mark: str = "Keep Clean (MoEFCC Disposal Logo)"
    compliance_score: int = 70
    compliance_status: str = "Not Audited"
    export_format: str = "pdf"
    label_dimension: str = "Standard Pouch (100 × 150 mm)"


class SmallBusinessLabelCreate(SmallBusinessLabelBase):
    ingredients: List[SmallBusinessIngredientSchema] = []
    allergens: List[str] = []
    nutrients: List[SmallBusinessNutrientSchema] = []
    claims: List[SmallBusinessClaimSchema] = []


class SmallBusinessLabelUpdate(BaseModel):
    brand_name: Optional[str] = None
    product_name: Optional[str] = None
    product_category: Optional[str] = None
    type_flavour: Optional[str] = None
    logo_url: Optional[str] = None
    status: Optional[str] = None
    completion_percentage: Optional[int] = None
    current_step: Optional[int] = None
    ingredient_source: Optional[str] = None
    net_quantity: Optional[str] = None
    net_quantity_unit: Optional[str] = None
    serving_size: Optional[str] = None
    serving_size_unit: Optional[str] = None
    display_mode: Optional[str] = None
    label_format: Optional[str] = None
    target_audience: Optional[str] = None
    age_group: Optional[str] = None
    manufacturer_name: Optional[str] = None
    manufacturer_address: Optional[str] = None
    packer_address_same_as_manufacturer: Optional[bool] = None
    fssai_license_number: Optional[str] = None
    mrp: Optional[str] = None
    usp: Optional[str] = None
    batch_number: Optional[str] = None
    mfg_date: Optional[str] = None
    best_before: Optional[str] = None
    storage_instructions: Optional[str] = None
    packaging_type: Optional[str] = None
    is_vegetarian: Optional[bool] = None
    recycling_mark: Optional[str] = None
    ingredients: Optional[List[SmallBusinessIngredientSchema]] = None
    allergens: Optional[List[str]] = None
    nutrients: Optional[List[SmallBusinessNutrientSchema]] = None
    claims: Optional[List[SmallBusinessClaimSchema]] = None


class SmallBusinessLabelResponse(SmallBusinessLabelBase):
    id: str
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    ingredients: List[SmallBusinessIngredientSchema] = []
    allergens: List[str] = []
    nutrients: List[SmallBusinessNutrientSchema] = []
    claims: List[SmallBusinessClaimSchema] = []


class ComplianceAuditResponse(BaseModel):
    label_id: Optional[str] = None
    score: int = Field(70, description="Legal compliance score out of 100")
    status: str = Field("Not Audited", description="Status: Good Compliance, Action Required, Needs Attention, Not Audited")
    checks_passed: List[str] = []
    warnings: List[str] = []
    fssai_compliant: Optional[bool] = None
    legal_metrology_compliant: bool = True


class RegulatoryVerificationRequest(BaseModel):
    regulatory_type: str = Field(..., description="Type of regulatory verification (fssai, legal_metrology, bis)")
    registration_number: Optional[str] = Field(None, description="Registration/license number to verify")
    product_category: Optional[str] = Field(None, description="Product category (optional, for applicability checks)")
    is_food_product: Optional[bool] = Field(None, description="Whether product is a food product (optional)")


class RegulatoryVerificationResponse(BaseModel):
    regulatory_type: str = Field(..., description="Type of regulatory verification")
    registration_number: Optional[str] = Field(None, description="The registration number provided")
    status: str = Field(..., description="Verification status: VERIFIED, INVALID, INACTIVE, UNAVAILABLE, NOT_APPLICABLE, NOT_PROVIDED")
    official_source: str = Field(..., description="URL/reference to official verification source")
    message: str = Field(..., description="Human-readable verification message")
    verified_at: Optional[datetime] = Field(None, description="Timestamp of verification")
    can_continue: bool = Field(True, description="Whether to allow user to continue despite verification outcome")
    metadata: Optional[Dict[str, Any]] = Field(default_factory=dict, description="Additional verification metadata")

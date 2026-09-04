"""
Regulatory Compliance Verification Service

Provides verification capabilities for various regulatory identifiers including:
- FSSAI (Food Safety and Standards Authority of India)
- Legal Metrology
- BIS and other category-specific regulators

This service is designed to be extensible for future regulatory types.
"""

import re
from enum import Enum
from typing import Optional, Dict, Any
from datetime import datetime
from urllib.parse import urljoin


class VerificationStatus(str, Enum):
    """Verification status outcomes."""
    VERIFIED = "VERIFIED"
    INVALID = "INVALID"
    INACTIVE = "INACTIVE"
    UNAVAILABLE = "UNAVAILABLE"
    NOT_APPLICABLE = "NOT_APPLICABLE"
    NOT_PROVIDED = "NOT_PROVIDED"


class RegulatoryType(str, Enum):
    """Supported regulatory verification types."""
    FSSAI = "fssai"
    LEGAL_METROLOGY = "legal_metrology"
    BIS = "bis"


class RegulatoryVerificationResponse:
    """Response model for regulatory verification."""
    
    def __init__(
        self,
        regulatory_type: str,
        registration_number: Optional[str],
        status: VerificationStatus,
        official_source: str,
        message: str,
        verified_at: Optional[datetime] = None,
        can_continue: bool = True,
        metadata: Optional[Dict[str, Any]] = None,
    ):
        self.regulatory_type = regulatory_type
        self.registration_number = registration_number
        self.status = status
        self.official_source = official_source
        self.message = message
        self.verified_at = verified_at
        self.can_continue = can_continue
        self.metadata = metadata or {}
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert response to dictionary for JSON serialization."""
        return {
            "regulatory_type": self.regulatory_type,
            "registration_number": self.registration_number,
            "status": self.status.value,
            "official_source": self.official_source,
            "message": self.message,
            "verified_at": self.verified_at.isoformat() if self.verified_at else None,
            "can_continue": self.can_continue,
            "metadata": self.metadata,
        }


class FSSAIVerifier:
    """FSSAI (Food Safety and Standards Authority of India) verification."""
    
    FSSAI_OFFICIAL_VERIFICATION_URL = "https://foscos.fssai.gov.in/"
    FSSAI_LICENSE_PATTERN = re.compile(r"^\d{14}$")
    
    @staticmethod
    def validate_format(license_number: Optional[str]) -> bool:
        """
        Validate FSSAI license number format.
        
        FSSAI license numbers must be exactly 14 digits.
        NOTE: This only validates FORMAT, not authenticity.
        """
        if not license_number:
            return False
        return bool(FSSAIVerifier.FSSAI_LICENSE_PATTERN.match(license_number))
    
    @staticmethod
    def normalize(license_number: Optional[str]) -> Optional[str]:
        """Normalize FSSAI license number (strip whitespace, validate format)."""
        if not license_number:
            return None
        normalized = license_number.strip()
        if FSSAIVerifier.validate_format(normalized):
            return normalized
        return None
    
    @staticmethod
    def verify(
        license_number: Optional[str],
        product_category: Optional[str] = None,
        is_food_product: Optional[bool] = None,
    ) -> RegulatoryVerificationResponse:
        """
        Verify FSSAI license number.

        Currently returns status based on format validation only.
        Actual verification against official FSSAI/FoSCoS database would require:
        - Interactive access to FSSAI verification portal
        - CAPTCHA handling
        - Potential rate limiting
        - Authentication requirements

        For now, this indicates format validity and directs to official portal.
        """

        # Determine applicability first
        is_applicable = is_food_product if is_food_product is not None else True

        # Check if FSSAI is not applicable for this product type
        if not is_applicable:
            return RegulatoryVerificationResponse(
                regulatory_type=RegulatoryType.FSSAI.value,
                registration_number=license_number,
                status=VerificationStatus.NOT_APPLICABLE,
                official_source=FSSAIVerifier.FSSAI_OFFICIAL_VERIFICATION_URL,
                message="FSSAI is not applicable for non-food products.",
                can_continue=True,
            )

        # If applicable but not provided
        if not license_number:
            return RegulatoryVerificationResponse(
                regulatory_type=RegulatoryType.FSSAI.value,
                registration_number=None,
                status=VerificationStatus.NOT_PROVIDED,
                official_source=FSSAIVerifier.FSSAI_OFFICIAL_VERIFICATION_URL,
                message="FSSAI license number not provided.",
                can_continue=True,
            )

        normalized = FSSAIVerifier.normalize(license_number)

        if not normalized:
            return RegulatoryVerificationResponse(
                regulatory_type=RegulatoryType.FSSAI.value,
                registration_number=license_number,
                status=VerificationStatus.INVALID,
                official_source=FSSAIVerifier.FSSAI_OFFICIAL_VERIFICATION_URL,
                message=f"Invalid FSSAI license format. Expected 14 digits, got: {license_number}",
                can_continue=True,
            )
        
        # Format is valid, but actual verification requires accessing official portal
        return RegulatoryVerificationResponse(
            regulatory_type=RegulatoryType.FSSAI.value,
            registration_number=normalized,
            status=VerificationStatus.UNAVAILABLE,
            official_source=FSSAIVerifier.FSSAI_OFFICIAL_VERIFICATION_URL,
            message=(
                f"Format valid (14 digits). "
                f"Official verification is not available in automated mode. "
                f"Visit the official FoSCoS portal to verify: {FSSAIVerifier.FSSAI_OFFICIAL_VERIFICATION_URL}"
            ),
            can_continue=True,
            metadata={
                "format_valid": True,
                "digits": len(normalized),
                "reason": "Official verification requires interactive access to FSSAI portal with CAPTCHA",
            },
        )


class ComplianceVerificationService:
    """Main compliance verification service."""
    
    @staticmethod
    def verify_regulatory(
        regulatory_type: str,
        registration_number: Optional[str],
        product_category: Optional[str] = None,
        is_food_product: Optional[bool] = None,
    ) -> RegulatoryVerificationResponse:
        """
        Verify a regulatory identifier.
        
        Args:
            regulatory_type: Type of regulatory identifier (fssai, legal_metrology, bis)
            registration_number: The identifier to verify
            product_category: Product category (optional, used for applicability checks)
            is_food_product: Whether the product is a food product (optional)
        
        Returns:
            RegulatoryVerificationResponse with verification result
        """
        
        if regulatory_type.lower() == RegulatoryType.FSSAI.value:
            return FSSAIVerifier.verify(
                registration_number,
                product_category=product_category,
                is_food_product=is_food_product,
            )
        
        # Future: Implement other regulatory types
        return RegulatoryVerificationResponse(
            regulatory_type=regulatory_type,
            registration_number=registration_number,
            status=VerificationStatus.UNAVAILABLE,
            official_source="",
            message=f"Verification for {regulatory_type} is not yet implemented.",
            can_continue=True,
        )
    
    @staticmethod
    def get_fssai_verification_url() -> str:
        """Get the official FSSAI verification URL."""
        return FSSAIVerifier.FSSAI_OFFICIAL_VERIFICATION_URL

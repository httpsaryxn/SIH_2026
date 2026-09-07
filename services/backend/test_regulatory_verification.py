#!/usr/bin/env python3
"""
Test script for regulatory verification service.
Verifies that:
1. FSSAI format validation works correctly
2. Verification is non-blocking (can_continue always True)
3. Non-food products are not required to have FSSAI
4. Format validation ≠ official verification
"""

import sys
sys.path.insert(0, '/c/Users/swanandi/sih26/SIH_2026/services/backend')

from app.services.compliance_verification import (
    ComplianceVerificationService,
    FSSAIVerifier,
    VerificationStatus,
)

def test_fssai_format_validation():
    """Test FSSAI format validation."""
    print("\n✓ TEST 1: FSSAI Format Validation")
    print("=" * 60)

    # Valid format: 14 digits
    valid_license = "12345678901234"
    result = FSSAIVerifier.verify(valid_license)
    assert result.status == VerificationStatus.UNAVAILABLE, "Valid format should return UNAVAILABLE (not officially verified)"
    assert "Format valid" in result.message, "Message should indicate format is valid"
    assert "FoSCoS" in result.message or "portal" in result.message.lower(), "Message should direct to official portal"
    print(f"  ✓ Valid 14-digit format: {result.message}")

    # Invalid format: too short
    short_license = "123456789"
    result = FSSAIVerifier.verify(short_license)
    assert result.status == VerificationStatus.INVALID, "Short format should return INVALID"
    print(f"  ✓ Invalid short format: {result.message}")

    # Invalid format: wrong characters
    bad_license = "1234567890123a"
    result = FSSAIVerifier.verify(bad_license)
    assert result.status == VerificationStatus.INVALID, "Non-numeric should return INVALID"
    print(f"  ✓ Invalid format (non-numeric): {result.message}")

    # Not provided
    result = FSSAIVerifier.verify(None)
    assert result.status == VerificationStatus.NOT_PROVIDED, "None should return NOT_PROVIDED"
    print(f"  ✓ Not provided: {result.message}")

def test_food_vs_non_food():
    """Test that FSSAI is optional for non-food products."""
    print("\n✓ TEST 2: Food vs Non-Food Product Handling")
    print("=" * 60)

    # Food product without FSSAI
    result = FSSAIVerifier.verify(
        license_number=None,
        is_food_product=True
    )
    assert result.status == VerificationStatus.NOT_PROVIDED, "Food product without FSSAI should NOT_PROVIDED"
    print(f"  ✓ Food product without FSSAI: {result.message}")

    # Non-food product without FSSAI
    result = FSSAIVerifier.verify(
        license_number=None,
        is_food_product=False
    )
    assert result.status == VerificationStatus.NOT_APPLICABLE, "Non-food product should NOT_APPLICABLE"
    print(f"  ✓ Non-food product without FSSAI: {result.message}")

    # Non-food product with FSSAI (shouldn't be required)
    result = FSSAIVerifier.verify(
        license_number="12345678901234",
        is_food_product=False
    )
    assert result.status == VerificationStatus.NOT_APPLICABLE, "Non-food product with FSSAI should NOT_APPLICABLE"
    print(f"  ✓ Non-food product with FSSAI: {result.message}")

def test_verification_is_non_blocking():
    """Test that can_continue is always True."""
    print("\n✓ TEST 3: Verification is Non-Blocking")
    print("=" * 60)

    test_cases = [
        ("12345678901234", True, "Valid format"),
        ("invalid", True, "Invalid format"),
        (None, False, "Not provided for food"),
        ("", True, "Empty for non-food"),
    ]

    for license_num, is_food, description in test_cases:
        result = ComplianceVerificationService.verify_regulatory(
            regulatory_type="fssai",
            registration_number=license_num,
            is_food_product=is_food,
        )
        assert result.can_continue == True, f"can_continue should always be True ({description})"
        print(f"  ✓ {description}: can_continue={result.can_continue}, status={result.status.value}")

def test_format_validation_not_official_verification():
    """Test that format validation doesn't mean official verification."""
    print("\n✓ TEST 4: Format Validation ≠ Official Verification")
    print("=" * 60)

    # 14-digit number passes format check but is UNAVAILABLE for official verification
    result = FSSAIVerifier.verify("12345678901234")
    assert result.status == VerificationStatus.UNAVAILABLE, "Format valid should return UNAVAILABLE"
    assert result.metadata.get("format_valid") == True, "Metadata should show format_valid=True"
    assert "officially" not in result.message.lower() or "official verification" in result.message.lower(), \
        "Message should clarify this is format check only"
    print(f"  ✓ Format valid (14 digits) returns UNAVAILABLE: {result.message}")
    print(f"  ✓ Metadata: {result.metadata}")

def test_official_source_url():
    """Test that official FSSAI verification URL is provided."""
    print("\n✓ TEST 5: Official Source URL")
    print("=" * 60)

    result = FSSAIVerifier.verify("12345678901234")
    expected_url = "https://foscos.fssai.gov.in/"
    assert result.official_source == expected_url, f"Should point to official FoSCoS portal"
    print(f"  ✓ Official source URL: {result.official_source}")

def test_response_structure():
    """Test that response has all required fields."""
    print("\n✓ TEST 6: Response Structure")
    print("=" * 60)

    result = ComplianceVerificationService.verify_regulatory(
        regulatory_type="fssai",
        registration_number="12345678901234",
        is_food_product=True,
    )

    response_dict = result.to_dict()
    required_fields = [
        "regulatory_type",
        "registration_number",
        "status",
        "official_source",
        "message",
        "can_continue",
        "verified_at",
        "metadata",
    ]

    for field in required_fields:
        assert field in response_dict, f"Missing field: {field}"
    print(f"  ✓ All required fields present: {list(response_dict.keys())}")
    print(f"  ✓ Full response: {response_dict}")

if __name__ == "__main__":
    print("\n" + "=" * 60)
    print("REGULATORY VERIFICATION SERVICE TESTS")
    print("=" * 60)

    try:
        test_fssai_format_validation()
        test_food_vs_non_food()
        test_verification_is_non_blocking()
        test_format_validation_not_official_verification()
        test_official_source_url()
        test_response_structure()

        print("\n" + "=" * 60)
        print("✓ ALL TESTS PASSED")
        print("=" * 60)
        print("\nKEY FINDINGS:")
        print("1. FSSAI format validation works correctly (14 digits)")
        print("2. Verification never blocks label creation/publishing")
        print("3. 14-digit format validation ≠ official verification")
        print("4. Official FoSCoS portal URL is provided")
        print("5. Food products need FSSAI, non-food don't")
        print("6. Response always has can_continue=true")
    except Exception as e:
        print(f"\n✗ TEST FAILED: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

import unittest
from groq_client import (
    classify_and_summarize_consumer,
    generate_regulator_summary,
    _fallback_consumer_summary,
    _fallback_regulator_summary,
    MANDATORY_MEDICINAL_DISCLAIMER,
)
from pdf_generator import generate_compliance_pdf
from fastapi.testclient import TestClient
from main import app


class TestSummaryGen(unittest.TestCase):
    def test_fallback_consumer_summary_food(self):
        result = _fallback_consumer_summary(
            "Haldiram Bhujia Sev 200g Snack",
            {"net_quantity": "200 g", "mrp": "55.00", "fssai": "10012022000123"},
            {"net_quantity": "PASS"},
        )
        self.assertEqual(result["product_type"], "food")
        self.assertIsNotNone(result["health_score"])
        self.assertTrue(0 <= result["health_score"] <= 100)
        self.assertIn("Bhujia", result["summary_text"])

    def test_fallback_consumer_summary_medicinal_disclaimer(self):
        result = _fallback_consumer_summary(
            "Paracetamol 500mg Tablets IP",
            {"dosage": "500mg thrice daily", "manufacturer": "Cipla"},
            {},
        )
        self.assertEqual(result["product_type"], "medicinal")
        self.assertEqual(result["mandatory_disclaimer"], MANDATORY_MEDICINAL_DISCLAIMER)
        self.assertIsNotNone(result["medicinal_safety_summary"])
        self.assertIn("Informational summary of declared label content only. Not medical advice.", result["mandatory_disclaimer"])

    def test_fallback_regulator_summary(self):
        checks = [
            {"field_name": "Net Quantity", "extracted_value": "450g", "status": "Compliant", "rule_citation": "Rule 13"},
            {"field_name": "MRP", "extracted_value": "", "status": "Violation", "rule_citation": "Rule 6(1)(e)", "rule_description": "MRP declaration missing from principal display panel."}
        ]
        summary = _fallback_regulator_summary(
            "Masala Chips",
            checks
        )
        self.assertIn("1", summary)
        self.assertIn("MRP", summary)

    def test_pdf_generation(self):
        checks = [
            {
                "field_name": "Maximum Retail Price (MRP)",
                "extracted_value": "Rs. 75.00 (inclusive of all taxes)",
                "status": "Compliant",
                "rule_citation": "Rule 6(1)(e)",
                "rule_description": "Inclusive of all taxes clause required",
                "confidence_percent": 95,
            },
            {
                "field_name": "Consumer Care Details",
                "extracted_value": "",
                "status": "Violation",
                "rule_citation": "Rule 6(1)(h)",
                "rule_description": "Helpline, address and email required on package",
                "confidence_percent": 88,
            }
        ]

        pdf_bytes = generate_compliance_pdf(
            scan_id="test-scan-001",
            product_name="Crispy Potato Chips",
            company_name="Snack Foods Ltd.",
            declaration_checks=checks,
            summary_text="Audit finding: 1 compliant declaration, 1 statutory violation under Rule 6(1)(h).",
            metadata={"category": "Snacks & Confectionery"},
            image_urls={"front_label": "https://example.com/front.jpg"},
        )

        self.assertIsInstance(pdf_bytes, bytes)
        self.assertTrue(len(pdf_bytes) > 1000)
        self.assertTrue(pdf_bytes.startswith(b"%PDF-"))

    def test_fastapi_endpoints(self):
        client = TestClient(app)

        # Health endpoint
        res = client.get("/health")
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertEqual(data["status"], "ok")
        self.assertIn("groq_configured", data)

        # Consumer summarize endpoint
        c_res = client.post("/summarize/consumer", json={
            "product_name": "Digestive Biscuits",
            "manufacturer": "Britannia",
            "extracted_declarations": {"mrp": "30.00", "net_quantity": "100 g"},
            "ocr_text": "Whole wheat flour, sugar, edible vegetable oil",
        })
        self.assertEqual(c_res.status_code, 200)
        c_data = c_res.json()
        self.assertIn("product_type", c_data)
        self.assertIn("summary_text", c_data)


if __name__ == "__main__":
    unittest.main()

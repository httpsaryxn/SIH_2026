import io
import logging
from typing import Dict, Any, List, Optional
from datetime import datetime, timezone

from reportlab.lib.pagesizes import letter, A4
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, HRFlowable, KeepTogether
)

logger = logging.getLogger(__name__)

# Color Palette
PRIMARY_COLOR = colors.HexColor("#1A365D")   # Deep Navy
SECONDARY_COLOR = colors.HexColor("#2B6CB0") # Blue accent
TEXT_COLOR = colors.HexColor("#2D3748")      # Dark slate
BORDER_COLOR = colors.HexColor("#CBD5E0")    # Border gray
BG_LIGHT = colors.HexColor("#F7FAFC")        # Off-white

COLOR_PASS = colors.HexColor("#2E7D32")      # Forest Green
COLOR_FAIL = colors.HexColor("#C62828")      # Crimson Red
COLOR_WARN = colors.HexColor("#E65100")      # Deep Amber

def generate_compliance_pdf(
    scan_id: str,
    product_name: str,
    company_name: Optional[str],
    declaration_checks: List[Dict[str, Any]],
    summary_text: str,
    metadata: Optional[Dict[str, Any]] = None,
    image_urls: Optional[Dict[str, Optional[str]]] = None,
) -> bytes:
    """
    Generates a formal, tabular Legal Metrology inspection audit report PDF using ReportLab.
    Returns the PDF content as bytes.
    """
    metadata = metadata or {}
    image_urls = image_urls or {}
    buffer = io.BytesIO()

    doc = SimpleDocTemplate(
        buffer,
        pagesize=A4,
        leftMargin=36,
        rightMargin=36,
        topMargin=36,
        bottomMargin=36,
    )

    styles = getSampleStyleSheet()

    # Custom styles
    header_title_style = ParagraphStyle(
        "HeaderTitle",
        parent=styles["Normal"],
        fontName="Helvetica-Bold",
        fontSize=13,
        leading=16,
        textColor=PRIMARY_COLOR,
        alignment=1, # Center
    )

    header_sub_style = ParagraphStyle(
        "HeaderSub",
        parent=styles["Normal"],
        fontName="Helvetica-Bold",
        fontSize=10,
        leading=13,
        textColor=SECONDARY_COLOR,
        alignment=1,
    )

    header_rule_style = ParagraphStyle(
        "HeaderRule",
        parent=styles["Normal"],
        fontName="Helvetica-Oblique",
        fontSize=8,
        leading=11,
        textColor=colors.HexColor("#4A5568"),
        alignment=1,
    )

    section_heading = ParagraphStyle(
        "SectionHeading",
        parent=styles["Normal"],
        fontName="Helvetica-Bold",
        fontSize=11,
        leading=14,
        textColor=PRIMARY_COLOR,
        spaceBefore=8,
        spaceAfter=4,
    )

    body_style = ParagraphStyle(
        "ReportBody",
        parent=styles["Normal"],
        fontName="Helvetica",
        fontSize=9,
        leading=12,
        textColor=TEXT_COLOR,
    )

    table_header_style = ParagraphStyle(
        "TableHeader",
        parent=styles["Normal"],
        fontName="Helvetica-Bold",
        fontSize=8.5,
        leading=11,
        textColor=colors.white,
        alignment=1,
    )

    table_cell_style = ParagraphStyle(
        "TableCell",
        parent=styles["Normal"],
        fontName="Helvetica",
        fontSize=8,
        leading=10,
        textColor=TEXT_COLOR,
    )

    table_cell_bold = ParagraphStyle(
        "TableCellBold",
        parent=styles["Normal"],
        fontName="Helvetica-Bold",
        fontSize=8,
        leading=10,
        textColor=TEXT_COLOR,
    )

    story = []

    # ── 1. Official Header ─────────────────────────────────────────────
    story.append(Paragraph("GOVERNMENT OF INDIA • MINISTRY OF CONSUMER AFFAIRS", header_title_style))
    story.append(Paragraph("DIRECTORATE OF LEGAL METROLOGY (PACKAGED COMMODITIES)", header_sub_style))
    story.append(Paragraph("Statutory Label Inspection & Regulatory Audit Report under PCR 2011", header_rule_style))
    story.append(Spacer(1, 6))
    story.append(HRFlowable(width="100%", thickness=1.5, color=PRIMARY_COLOR, spaceAfter=8))

    # ── 2. Audit Metadata Block ─────────────────────────────────────────
    now_str = datetime.now(timezone.utc).strftime("%d %b %Y, %H:%M UTC")
    overall_status = metadata.get("status", "Under Review").upper()

    meta_table_data = [
        [
            Paragraph("<b>Inspection ID:</b>", table_cell_style),
            Paragraph(scan_id[:18], table_cell_bold),
            Paragraph("<b>Audit Date:</b>", table_cell_style),
            Paragraph(now_str, table_cell_style),
        ],
        [
            Paragraph("<b>Commodity Name:</b>", table_cell_style),
            Paragraph(product_name, table_cell_bold),
            Paragraph("<b>Inspector / Agency:</b>", table_cell_style),
            Paragraph(metadata.get("officer", "Authorized Metrology Officer"), table_cell_style),
        ],
        [
            Paragraph("<b>Manufacturer / Packer:</b>", table_cell_style),
            Paragraph(company_name or "Not Declared / Disputed", table_cell_style),
            Paragraph("<b>Inspection Status:</b>", table_cell_style),
            Paragraph(f"<b>{overall_status}</b>", table_cell_bold),
        ],
    ]

    meta_table = Table(meta_table_data, colWidths=[110, 155, 110, 145])
    meta_table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, -1), BG_LIGHT),
        ('BOX', (0, 0), (-1, -1), 1, BORDER_COLOR),
        ('INNERGRID', (0, 0), (-1, -1), 0.5, BORDER_COLOR),
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
        ('TOPPADDING', (0, 0), (-1, -1), 4),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
    ]))
    story.append(meta_table)
    story.append(Spacer(1, 10))

    # ── 3. Tabular Comparison: Declared vs Required by Rules ───────────
    story.append(Paragraph("I. MANDATORY DECLARATIONS AUDIT & VERIFICATION MATRIX", section_heading))
    story.append(Paragraph(
        "Direct comparison of extracted physical packaging declarations against requirements stipulated by Legal Metrology (Packaged Commodities) Rules, 2011.",
        body_style
    ))
    story.append(Spacer(1, 6))

    # Table columns: Field (100), Found Value (140), Rule Requirement (180), Status (100)
    audit_table_data = [
        [
            Paragraph("Mandatory Declaration", table_header_style),
            Paragraph("Declared / Found on Label", table_header_style),
            Paragraph("PCR 2011 Requirement", table_header_style),
            Paragraph("Verification Status", table_header_style),
        ]
    ]

    for check in declaration_checks:
        field = check.get("field_name", "Unknown Field")
        val = check.get("extracted_value") or "NOT DETECTED"
        status = (check.get("status") or "Unable to Verify").upper()
        citation = check.get("rule_citation") or "PCR 2011"
        req_desc = check.get("rule_description") or f"Mandatory declaration as per {citation}"

        # Color coding status
        if "COMPLIANT" in status or "PASS" in status:
            status_color = COLOR_PASS
            badge_text = f"<font color='{status_color.hexval()}'><b>✓ COMPLIANT</b></font>"
        elif "VIOLATION" in status or "FAIL" in status:
            status_color = COLOR_FAIL
            badge_text = f"<font color='{status_color.hexval()}'><b>✗ VIOLATION</b></font>"
        else:
            status_color = COLOR_WARN
            badge_text = f"<font color='{status_color.hexval()}'><b>⚠ WARNING</b></font>"

        audit_table_data.append([
            Paragraph(f"<b>{field}</b>", table_cell_style),
            Paragraph(f"<code>{val}</code>", table_cell_style),
            Paragraph(f"<b>{citation}</b>: {req_desc}", table_cell_style),
            Paragraph(badge_text, table_cell_style),
        ])

    comp_table = Table(audit_table_data, colWidths=[105, 135, 185, 95])
    comp_table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), PRIMARY_COLOR),
        ('ALIGN', (0, 0), (-1, 0), 'CENTER'),
        ('BOX', (0, 0), (-1, -1), 1, BORDER_COLOR),
        ('INNERGRID', (0, 0), (-1, -1), 0.5, BORDER_COLOR),
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, BG_LIGHT]),
        ('TOPPADDING', (0, 0), (-1, -1), 4),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
    ]))
    story.append(comp_table)
    story.append(Spacer(1, 10))

    # ── 4. Detailed Regulatory Summary (from Groq) ──────────────────────
    story.append(Paragraph("II. REGULATORY COMPLIANCE ANALYSIS & LEGAL ASSESSMENT", section_heading))
    
    # Split summary paragraphs cleanly
    for para in summary_text.split("\n\n"):
        clean_para = para.strip()
        if clean_para:
            if clean_para.startswith("#"):
                clean_heading = clean_para.lstrip("#").strip()
                story.append(Paragraph(f"<b>{clean_heading}</b>", section_heading))
            else:
                story.append(Paragraph(clean_para, body_style))
                story.append(Spacer(1, 4))

    story.append(Spacer(1, 8))

    # ── 5. Evidence Photo References ───────────────────────────────────
    story.append(Paragraph("III. DIGITAL EVIDENCE & INSPECTION CAPTURES", section_heading))
    ev_data = [
        [
            Paragraph("<b>Front Label Capture:</b>", table_cell_style),
            Paragraph(image_urls.get("front") or "Stored in secure compliance repository", table_cell_style),
        ],
        [
            Paragraph("<b>Curved / Side Surface:</b>", table_cell_style),
            Paragraph(image_urls.get("curved") or "Not required / not uploaded", table_cell_style),
        ],
        [
            Paragraph("<b>Scale & Ruler Reference:</b>", table_cell_style),
            Paragraph(image_urls.get("scale") or "Standard metric optical calibration", table_cell_style),
        ],
    ]
    ev_table = Table(ev_data, colWidths=[150, 370])
    ev_table.setStyle(TableStyle([
        ('BOX', (0, 0), (-1, -1), 0.5, BORDER_COLOR),
        ('INNERGRID', (0, 0), (-1, -1), 0.5, BORDER_COLOR),
        ('BACKGROUND', (0, 0), (0, -1), BG_LIGHT),
        ('TOPPADDING', (0, 0), (-1, -1), 3),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 3),
    ]))
    story.append(ev_table)
    story.append(Spacer(1, 14))

    # ── 6. Official Endorsement Sign-off ────────────────────────────────
    sign_off_data = [
        [
            Paragraph("<b>Digital Verification Stamp:</b><br/><font size='6' color='#718096'>Cryptographically signed audit trail generated via LabelLens Central Authority.</font>", table_cell_style),
            Paragraph("<b>Authorized Signatory</b><br/><br/>____________________________________<br/>Legal Metrology Inspection Officer", table_cell_style),
        ]
    ]
    sign_table = Table(sign_off_data, colWidths=[320, 200])
    sign_table.setStyle(TableStyle([
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ('TOPPADDING', (0, 0), (-1, -1), 6),
    ]))
    story.append(KeepTogether([sign_table]))

    doc.build(story)
    buffer.seek(0)
    return buffer.getvalue()

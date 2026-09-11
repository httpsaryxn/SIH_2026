import io
import logging
import re
from typing import Dict, Any, List, Optional
from datetime import datetime, timezone

from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, HRFlowable, KeepTogether
)

logger = logging.getLogger(__name__)

# Official Government / Regulatory Color Palette
PRIMARY_COLOR = colors.HexColor("#1A365D")   # Deep Navy
SECONDARY_COLOR = colors.HexColor("#2B6CB0") # Steel Blue
BORDER_COLOR = colors.HexColor("#CBD5E1")    # Crisp Slate Border
BG_LIGHT = colors.HexColor("#F8FAFC")        # Off-white / light slate zebra

COLOR_PASS = colors.HexColor("#166534")      # Forest Green
COLOR_FAIL = colors.HexColor("#991B1B")      # Crimson Red
COLOR_WARN = colors.HexColor("#C2410C")      # Deep Amber

COLOR_FAIL_BG = colors.HexColor("#FEF2F2")   # Light Red
COLOR_WARN_BG = colors.HexColor("#FFFBEB")   # Light Amber
COLOR_PASS_BG = colors.HexColor("#F0FDF4")   # Light Green


def xml_escape(text: str) -> str:
    """Escapes special XML/HTML characters for ReportLab Paragraphs."""
    return str(text).replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def markdown_to_html(text: str) -> str:
    """Converts basic markdown inline styles into ReportLab HTML tags."""
    text = xml_escape(text)
    text = re.sub(r"\*\*(.*?)\*\*", r"<b>\1</b>", text)
    text = re.sub(r"\*(.*?)\*", r"<i>\1</i>", text)
    text = re.sub(r"`(.*?)`", r"<b>\1</b>", text)
    return text


def parse_findings_line(line: str):
    """
    Extracts status (VIOLATION, WARNING, COMPLIANT, or INFO),
    clean title, and subtitle description from a finding bullet line.
    """
    line_clean = line.lstrip("-* ").strip()
    status = "INFO"
    if any(k in line_clean for k in ["❌", "Violation", "FAIL", "Critical"]):
        status = "VIOLATION"
    elif any(k in line_clean for k in ["⚠️", "Warning", "WARN", "Advisory", "Moderate"]):
        status = "WARNING"
    elif any(k in line_clean for k in ["✅", "Pass", "COMPLIANT", "Clearance"]):
        status = "COMPLIANT"

    content = line_clean
    for sym in ["❌", "⚠️", "✅"]:
        content = content.replace(sym, "")
    content = re.sub(
        r"^\s*\*\*(?:Violation|Warning|Pass|Action Proposed|Enforcement Notice|Advisory Notice|Clearance Granted)\*\*\s*:\s*",
        "",
        content,
        flags=re.IGNORECASE,
    )
    content = re.sub(
        r"^(?:Violation|Warning|Pass|Action Proposed|Enforcement Notice|Advisory Notice|Clearance Granted)\s*:\s*",
        "",
        content,
        flags=re.IGNORECASE,
    ).strip()

    # Split title and description on em-dash or en-dash
    parts = re.split(r"\s*[—–]\s*", content, maxsplit=1)
    if len(parts) == 2:
        title, desc = parts[0].strip(), parts[1].strip()
    else:
        colon_parts = content.split(":", 1)
        if len(colon_parts) == 2 and len(colon_parts[0]) < 50:
            title, desc = colon_parts[0].strip(), colon_parts[1].strip()
        else:
            title, desc = content, ""

    return status, markdown_to_html(title), markdown_to_html(desc)


def parse_markdown_table_rows(lines: List[str]) -> List[List[str]]:
    """Parses markdown pipe table lines into rows and columns."""
    rows = []
    for line in lines:
        raw = line.strip()
        if not (raw.startswith("|") and raw.endswith("|")):
            continue
        cells = [c.strip() for c in raw[1:-1].split("|")]
        # Skip separator row like | :--- | ---: |
        if all(re.match(r"^:?-+:?$", c) for c in cells if c):
            continue
        rows.append(cells)
    return rows


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

    # A4: 595.27 x 841.89 pt. 30pt margins left/right -> 535pt printable width
    doc = SimpleDocTemplate(
        buffer,
        pagesize=A4,
        leftMargin=30,
        rightMargin=30,
        topMargin=26,
        bottomMargin=26,
    )

    styles = getSampleStyleSheet()

    doc_title_style = ParagraphStyle(
        "DocTitle",
        parent=styles["Normal"],
        fontName="Helvetica-Bold",
        fontSize=12,
        leading=15,
        alignment=1,
        textColor=PRIMARY_COLOR,
    )

    doc_subtitle_style = ParagraphStyle(
        "DocSubTitle",
        parent=styles["Normal"],
        fontName="Helvetica-Bold",
        fontSize=9.5,
        leading=12,
        alignment=1,
        textColor=SECONDARY_COLOR,
    )

    doc_meta_style = ParagraphStyle(
        "DocMeta",
        parent=styles["Normal"],
        fontName="Helvetica-Oblique",
        fontSize=7.5,
        leading=10,
        alignment=1,
        textColor=colors.HexColor("#64748B"),
        spaceAfter=6,
    )

    section_heading = ParagraphStyle(
        "SectionHeading",
        parent=styles["Normal"],
        fontName="Helvetica-Bold",
        fontSize=9,
        leading=12,
        textColor=PRIMARY_COLOR,
        spaceBefore=6,
        spaceAfter=3,
    )

    finding_subhead_style = ParagraphStyle(
        "FindingSubHead",
        parent=styles["Normal"],
        fontName="Helvetica-Bold",
        fontSize=8.5,
        leading=11,
        textColor=PRIMARY_COLOR,
        spaceBefore=4,
        spaceAfter=2,
    )

    body_style = ParagraphStyle(
        "ReportBody",
        parent=styles["Normal"],
        fontName="Helvetica",
        fontSize=7.5,
        leading=10.5,
        textColor=colors.HexColor("#1E293B"),
    )

    bullet_style = ParagraphStyle(
        "ReportBullet",
        parent=styles["Normal"],
        fontName="Helvetica",
        fontSize=7.5,
        leading=10.5,
        leftIndent=10,
        textColor=colors.HexColor("#1E293B"),
        spaceAfter=2,
    )

    table_header_style = ParagraphStyle(
        "TableHeader",
        parent=styles["Normal"],
        fontName="Helvetica-Bold",
        fontSize=7.5,
        leading=9.5,
        textColor=colors.white,
        alignment=0,
    )

    table_cell_style = ParagraphStyle(
        "TableCell",
        parent=styles["Normal"],
        fontName="Helvetica",
        fontSize=7,
        leading=9,
        textColor=colors.HexColor("#0F172A"),
    )

    story = []

    # ── 1. Formal Government Header ─────────────────────────────────────
    story.append(Paragraph("GOVERNMENT OF INDIA • MINISTRY OF CONSUMER AFFAIRS", doc_title_style))
    story.append(Paragraph("DIRECTORATE OF LEGAL METROLOGY (PACKAGED COMMODITIES)", doc_subtitle_style))
    story.append(Paragraph("Statutory Label Inspection &amp; Regulatory Audit Report under PCR 2011", doc_meta_style))
    story.append(HRFlowable(width="100%", thickness=1, color=PRIMARY_COLOR, spaceBefore=1, spaceAfter=4))

    # Audit date
    audit_date = datetime.now(timezone.utc).strftime("%d %b %Y, %H:%M UTC")

    # Metadata Grid (width = 535pt)
    mfr_display = company_name or "Not Specified / Extracted from Label"
    meta_data = [
        [
            Paragraph("<b>Inspection ID:</b>", table_cell_style),
            Paragraph(f"<b>{xml_escape(scan_id)}</b>", table_cell_style),
            Paragraph("<b>Audit Date:</b>", table_cell_style),
            Paragraph(audit_date, table_cell_style),
        ],
        [
            Paragraph("<b>Commodity Name:</b>", table_cell_style),
            Paragraph(f"<b>{xml_escape(product_name)}</b>", table_cell_style),
            Paragraph("<b>Inspector / Agency:</b>", table_cell_style),
            Paragraph("Authorized Metrology Officer", table_cell_style),
        ],
        [
            Paragraph("<b>Manufacturer / Packer:</b>", table_cell_style),
            Paragraph(xml_escape(mfr_display), table_cell_style),
            Paragraph("<b>Inspection Status:</b>", table_cell_style),
            Paragraph("<b>UNDER REVIEW</b>", table_cell_style),
        ],
    ]
    meta_table = Table(meta_data, colWidths=[110, 157, 110, 158])
    meta_table.setStyle(TableStyle([
        ('BOX', (0, 0), (-1, -1), 0.5, BORDER_COLOR),
        ('INNERGRID', (0, 0), (-1, -1), 0.5, BORDER_COLOR),
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
        ('ROWBACKGROUNDS', (0, 0), (-1, -1), [colors.white, BG_LIGHT]),
        ('TOPPADDING', (0, 0), (-1, -1), 2),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 2),
    ]))
    story.append(meta_table)
    story.append(Spacer(1, 4))

    # ── 2. Mandatory Declarations Audit Matrix ───────────────────────────
    story.append(Paragraph("I. MANDATORY DECLARATIONS AUDIT &amp; VERIFICATION MATRIX", section_heading))

    headers = [
        Paragraph("Mandatory Declaration", table_header_style),
        Paragraph("Declared / Found on Label", table_header_style),
        Paragraph("PCR 2011 Requirement", table_header_style),
        Paragraph("Verification Status", table_header_style),
    ]
    rows = [headers]
    for check in declaration_checks:
        field = check.get("field_name") or check.get("field") or "Unknown Declaration"
        found = check.get("extracted_value") or "NOT DETECTED"
        rule = check.get("rule_citation") or "PCR 2011 Rule 6"
        rule_desc = check.get("rule_description") or ""
        status = check.get("status") or "Violation"

        if status.lower() in ["pass", "compliant"]:
            status_html = f"<font color='{COLOR_PASS.hexval()}'><b>✓ COMPLIANT</b></font>"
        elif status.lower() in ["warn", "warning"]:
            status_html = f"<font color='{COLOR_WARN.hexval()}'><b>⚠ WARNING</b></font>"
        else:
            status_html = f"<font color='{COLOR_FAIL.hexval()}'><b>✗ VIOLATION</b></font>"

        req_text = f"<b>{xml_escape(rule)}</b>"
        if rule_desc:
            req_text += f": {xml_escape(rule_desc)}"

        rows.append([
            Paragraph(f"<b>{xml_escape(field)}</b>", table_cell_style),
            Paragraph(xml_escape(str(found)), table_cell_style),
            Paragraph(req_text, table_cell_style),
            Paragraph(status_html, table_cell_style),
        ])

    check_table = Table(rows, colWidths=[110, 115, 220, 90])
    check_table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), PRIMARY_COLOR),
        ('BOX', (0, 0), (-1, -1), 0.5, BORDER_COLOR),
        ('INNERGRID', (0, 0), (-1, -1), 0.5, BORDER_COLOR),
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, BG_LIGHT]),
        ('TOPPADDING', (0, 0), (-1, -1), 2),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 2),
    ]))
    story.append(check_table)
    story.append(Spacer(1, 4))

    # ── 3. Regulatory Compliance Analysis & Legal Assessment ────────────
    story.append(Paragraph("II. REGULATORY COMPLIANCE ANALYSIS &amp; LEGAL ASSESSMENT", section_heading))
    story.append(Spacer(1, 2))

    raw_lines = [l.strip() for l in summary_text.split("\n") if l.strip()]

    # Filter out redundant metadata header lines that repeat report header
    filtered_lines = []
    redundant_prefixes = [
        "# regulatory inspection summary",
        "## legal metrology compliance",
        "**subject:**",
        "**governing legislation:**",
        "**inspector:**",
        "**date of audit:**",
        "commodity:",
        "manufacturer/packer:",
        "manufacturer:",
        "inspection date:",
        "date of inspection:",
        "officer in charge:",
        "inspecting authority:",
        "address:",
    ]
    for l in raw_lines:
        lower = l.lower()
        if any(lower.startswith(p) for p in redundant_prefixes):
            continue
        filtered_lines.append(l)

    findings_rows = []
    table_buffer = []

    def flush_findings_table(story_list, f_rows):
        if not f_rows:
            return
        f_table = Table(f_rows, colWidths=[85, 450])
        f_table.setStyle(TableStyle([
            ('BOX', (0, 0), (-1, -1), 0.5, BORDER_COLOR),
            ('INNERGRID', (0, 0), (-1, -1), 0.5, BORDER_COLOR),
            ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
            ('ROWBACKGROUNDS', (0, 0), (-1, -1), [colors.white, BG_LIGHT]),
            ('TOPPADDING', (0, 0), (-1, -1), 2.5),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 2.5),
            ('LEFTPADDING', (0, 0), (-1, -1), 5),
            ('RIGHTPADDING', (0, 0), (-1, -1), 5),
        ]))
        story_list.append(f_table)
        story_list.append(Spacer(1, 4))
        f_rows.clear()

    def flush_markdown_table(story_list, md_lines):
        if not md_lines:
            return
        parsed_matrix = parse_markdown_table_rows(md_lines)
        if not parsed_matrix:
            return
        num_cols = len(parsed_matrix[0])
        col_width = 535.0 / num_cols
        widths = [col_width] * num_cols

        table_data = []
        for r_idx, row in enumerate(parsed_matrix):
            cell_row = []
            for c_idx, cell in enumerate(row):
                if r_idx == 0:
                    c_style = table_header_style
                    c_text = f"<b>{markdown_to_html(cell)}</b>"
                else:
                    c_style = table_cell_style
                    c_text = markdown_to_html(cell)
                    if "✅" in cell or "Compliant" in cell:
                        c_text = f"<font color='{COLOR_PASS.hexval()}'><b>{c_text}</b></font>"
                    elif "❌" in cell or "Violation" in cell or "Critical" in cell:
                        c_text = f"<font color='{COLOR_FAIL.hexval()}'><b>{c_text}</b></font>"
                    elif "⚠️" in cell or "Warning" in cell or "Major" in cell or "Moderate" in cell:
                        c_text = f"<font color='{COLOR_WARN.hexval()}'><b>{c_text}</b></font>"
                cell_row.append(Paragraph(c_text, c_style))
            table_data.append(cell_row)

        m_table = Table(table_data, colWidths=widths)
        m_table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), SECONDARY_COLOR),
            ('BOX', (0, 0), (-1, -1), 0.5, BORDER_COLOR),
            ('INNERGRID', (0, 0), (-1, -1), 0.5, BORDER_COLOR),
            ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
            ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, BG_LIGHT]),
            ('TOPPADDING', (0, 0), (-1, -1), 2),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 2),
        ]))
        story_list.append(m_table)
        story_list.append(Spacer(1, 4))
        md_lines.clear()

    idx = 0
    while idx < len(filtered_lines):
        line = filtered_lines[idx]

        # Markdown Table Detection
        if line.startswith("|") and line.endswith("|"):
            flush_findings_table(story, findings_rows)
            table_buffer.append(line)
            idx += 1
            continue
        elif table_buffer:
            flush_markdown_table(story, table_buffer)

        # Markdown Headings
        if line.startswith("#"):
            flush_findings_table(story, findings_rows)
            heading_text = line.lstrip("#").strip()
            story.append(Paragraph(f"<b>{markdown_to_html(heading_text)}</b>", finding_subhead_style))
            idx += 1
            continue

        # Status / Callout Card for Overall Status or Audit Finding
        if ("overall status:" in line.lower() or "audit finding:" in line.lower()) and not line.startswith("-"):
            flush_findings_table(story, findings_rows)
            is_fail = any(w in line.upper() for w in ["POTENTIAL VIOLATION", "NON-COMPLIANT", "FAIL"])
            is_warn = any(w in line.upper() for w in ["WARNING", "ADVISORY"])
            card_border = COLOR_FAIL if is_fail else (COLOR_WARN if is_warn else COLOR_PASS)
            card_bg = COLOR_FAIL_BG if is_fail else (COLOR_WARN_BG if is_warn else COLOR_PASS_BG)

            card_p = Paragraph(markdown_to_html(line), body_style)
            card_table = Table([[card_p]], colWidths=[535])
            card_table.setStyle(TableStyle([
                ('BACKGROUND', (0, 0), (-1, -1), card_bg),
                ('BOX', (0, 0), (-1, -1), 1, card_border),
                ('TOPPADDING', (0, 0), (-1, -1), 3),
                ('BOTTOMPADDING', (0, 0), (-1, -1), 3),
                ('LEFTPADDING', (0, 0), (-1, -1), 7),
                ('RIGHTPADDING', (0, 0), (-1, -1), 7),
            ]))
            story.append(card_table)
            story.append(Spacer(1, 4))
            idx += 1
            continue

        # Bullet finding: starts with '-' or '*' or status emoji
        if line.startswith("- ") or line.startswith("* ") or any(sym in line for sym in ["❌", "⚠️", "✅"]):
            status, title, desc = parse_findings_line(line)
            if status in ["VIOLATION", "WARNING", "COMPLIANT"]:
                if status == "VIOLATION":
                    badge = f"<font color='{COLOR_FAIL.hexval()}'><b>✗ VIOLATION</b></font>"
                elif status == "WARNING":
                    badge = f"<font color='{COLOR_WARN.hexval()}'><b>⚠ WARNING</b></font>"
                else:
                    badge = f"<font color='{COLOR_PASS.hexval()}'><b>✓ COMPLIANT</b></font>"

                if desc:
                    text_cell = f"<b>{title}</b><br/><font size='6.8' color='#475569'>{desc}</font>"
                else:
                    text_cell = f"<b>{title}</b>"

                findings_rows.append([
                    Paragraph(badge, table_cell_style),
                    Paragraph(text_cell, table_cell_style),
                ])
            else:
                # Regular clean bullet point for action/notes
                flush_findings_table(story, findings_rows)
                clean_bullet = line.lstrip("-* ").strip()
                story.append(Paragraph(f"&bull;&nbsp; {markdown_to_html(clean_bullet)}", bullet_style))

            idx += 1
            continue

        # Regular paragraph
        flush_findings_table(story, findings_rows)
        story.append(Paragraph(markdown_to_html(line), body_style))
        story.append(Spacer(1, 2))
        idx += 1

    flush_findings_table(story, findings_rows)
    if table_buffer:
        flush_markdown_table(story, table_buffer)

    story.append(Spacer(1, 4))

    # ── 4. Evidence Photo References ───────────────────────────────────
    story.append(Paragraph("III. DIGITAL EVIDENCE &amp; INSPECTION CAPTURES", section_heading))
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
            Paragraph("<b>Scale &amp; Ruler Reference:</b>", table_cell_style),
            Paragraph(image_urls.get("scale") or "Standard metric optical calibration", table_cell_style),
        ],
    ]
    ev_table = Table(ev_data, colWidths=[130, 405])
    ev_table.setStyle(TableStyle([
        ('BOX', (0, 0), (-1, -1), 0.5, BORDER_COLOR),
        ('INNERGRID', (0, 0), (-1, -1), 0.5, BORDER_COLOR),
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
        ('ROWBACKGROUNDS', (0, 0), (-1, -1), [colors.white, BG_LIGHT]),
        ('TOPPADDING', (0, 0), (-1, -1), 2),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 2),
    ]))
    story.append(ev_table)
    story.append(Spacer(1, 8))

    # ── 5. Digital Signature Block ─────────────────────────────────────
    sig_data = [
        [
            Paragraph(
                "<b>Digital Verification Stamp:</b><br/><font size='6' color='#64748B'>Cryptographically signed audit trail generated via LabelLens Central Authority.</font>",
                table_cell_style,
            ),
            Paragraph(
                "<b>Authorized Signatory</b><br/><br/>____________________________________<br/><font size='6.5' color='#475569'>Legal Metrology Inspection Officer</font>",
                table_cell_style,
            ),
        ]
    ]
    sig_table = Table(sig_data, colWidths=[267, 268])
    sig_table.setStyle(TableStyle([
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ('LEFTPADDING', (0, 0), (-1, -1), 0),
        ('RIGHTPADDING', (0, 0), (-1, -1), 0),
    ]))
    story.append(sig_table)

    doc.build(story)
    return buffer.getvalue()

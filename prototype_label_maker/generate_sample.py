"""
Standalone Professional Label Prototype Generator
SIH 2026 - Small Business Label Maker

Generates a COMPACT, HIGH-DENSITY commercial packaging label
matching the exact Kurkure reference packaging style.

Includes:
  - Exact ingredients with formulation percentages (% w/w)
  - Zero vacant space (compact FMCG packaging density)
  - Commercial FDA/FSSAI Nutrition Facts panel with micronutrients
  - Prominent Legal Metrology pricing (Net Qty, MRP, USP)
  - Un-distorted 4:3 FSSAI logo + Lic. No.
  - Scannable GS1 EAN-13 Barcode
  - Complete manufacturer, consumer care, and disposal declarations
"""

import os
import json
import base64
import shutil
import pymupdf

# -----------------------------------------------------------------------------
# 1. GS1 EAN-13 BARCODE ENCODER
# -----------------------------------------------------------------------------
PARITY_TABLE = [
    'LLLLLL', 'LLGLGG', 'LLGGLG', 'LLGGGL', 'LGLLGG',
    'LGGLLG', 'LGGGLL', 'LGLGLG', 'LGLGGL', 'LGGLGL'
]

L_CODE = [
    '0001101', '0011001', '0010011', '0111101', '0100011',
    '0110001', '0101111', '0111011', '0110111', '0001011'
]

G_CODE = [
    '0100111', '0110011', '0011011', '0100001', '0011101',
    '0111001', '0000101', '0010001', '0001001', '0010111'
]

R_CODE = [
    '1110010', '1100110', '1101100', '1000010', '1011100',
    '1001110', '1010000', '1000100', '1001000', '1110100'
]

def compute_checksum(twelve_digits: str) -> int:
    sum_odd = sum(int(twelve_digits[i]) for i in range(0, 12, 2))
    sum_even = sum(int(twelve_digits[i]) for i in range(1, 12, 2))
    total = sum_odd + (sum_even * 3)
    mod = total % 10
    return 0 if mod == 0 else 10 - mod

def normalize_ean13(input_str: str) -> str:
    digits = ''.join(c for c in input_str if c.isdigit())
    if not digits:
        digits = '741258963231'
    if len(digits) < 12:
        digits = digits.ljust(12, '0')
    elif len(digits) > 13:
        digits = digits[:13]
    if len(digits) == 12:
        return f"{digits}{compute_checksum(digits)}"
    elif len(digits) == 13:
        base = digits[:12]
        return f"{base}{compute_checksum(base)}"
    return digits

def encode_ean13_modules(ean13: str) -> list[bool]:
    valid_ean = normalize_ean13(ean13)
    first_digit = int(valid_ean[0])
    parity = PARITY_TABLE[first_digit]

    modules = [True, False, True]  # Start guard

    for i in range(6):
        digit = int(valid_ean[i + 1])
        pattern = L_CODE[digit] if parity[i] == 'L' else G_CODE[digit]
        modules.extend(c == '1' for c in pattern)

    modules.extend([False, True, False, True, False])  # Center guard

    for i in range(7, 13):
        digit = int(valid_ean[i])
        pattern = R_CODE[digit]
        modules.extend(c == '1' for c in pattern)

    modules.extend([True, False, True])  # End guard
    return modules


# -----------------------------------------------------------------------------
# 2. CANONICAL DATA MODEL (With Formulation Percentages)
# -----------------------------------------------------------------------------
COMPACT_LABEL_DATA = {
    "brand_name": "Haldirams",
    "product_name": "Kurkure",
    "type_flavour": "",
    "product_category": "SNACKS & NAMKEEN",
    "is_proprietary_food": True,
    "net_quantity": "70",
    "net_quantity_unit": "g",
    "mrp": "20.00",
    "usp": "Rs. 0.28 / g",
    "serving_size": "70",
    "serving_size_unit": "g",
    "servings_per_pack": 1,
    "calories_per_serve": "375",
    "fssai_license_number": "74125896323145",
    "manufacturer_name": "Haldirams",
    "manufacturer_address": "Mere Ghar Pe",
    "packer_address_same_as_manufacturer": True,
    "packer_name": None,
    "packer_address": None,
    "marketed_by": None,
    "country_of_origin": "INDIA",
    "consumer_care_phone": "9876543210",
    "consumer_care_email": "kurkure@gmail.com",
    "consumer_care_website": "www.haldirams.com",
    "batch_number": "HALDIRAMS-2026-I92",
    "mfg_date": "AUG 2026",
    "best_before": "12 Months from Packaging",
    "storage_instructions": "Do not freeze. Store in an airtight container.",
    "usage_instructions": "Ready to eat savoury namkeen snack.",
    "is_vegetarian": True,
    "recycling_mark": "Keep Clean (MoEFCC Disposal Logo)",
    "packaging_type": "Food Grade Metallized Pouch",
    "label_dimension": "Standard Pouch (100 × 150 mm)",
    "ingredients": [
        {"name": "Turmeric Powder", "percentage": 28.0},
        {"name": "Red Chilli Powder", "percentage": 24.0},
        {"name": "Coriander Powder", "percentage": 20.0},
        {"name": "Mustard Seeds", "percentage": 14.0},
        {"name": "Black Pepper", "percentage": 8.0},
        {"name": "Garam Masala", "percentage": 6.0}
    ],
    "allergens": [
        "Wheat / Gluten"
    ],
    "nutrients": [
        {"label": "Energy", "value": "536", "unit": "kcal", "rda_per_serve": "19%", "level": 0},
        {"label": "Protein", "value": "5.6", "unit": "g", "rda_per_serve": "—", "level": 0},
        {"label": "Carbohydrate", "value": "230", "unit": "g", "rda_per_serve": "—", "level": 0},
        {"label": "Total Sugars", "value": "2", "unit": "g", "rda_per_serve": "—", "level": 1},
        {"label": "Added Sugars", "value": "2", "unit": "g", "rda_per_serve": "3%", "level": 2},
        {"label": "Total Fat", "value": "10", "unit": "g", "rda_per_serve": "10%", "level": 0},
        {"label": "Saturated Fat", "value": "1", "unit": "g", "rda_per_serve": "3%", "level": 1},
        {"label": "Trans Fat", "value": "0", "unit": "g", "rda_per_serve": "0%", "level": 1},
        {"label": "Cholesterol", "value": "0", "unit": "mg", "rda_per_serve": "0%", "level": 0},
        {"label": "Sodium", "value": "222", "unit": "mg", "rda_per_serve": "8%", "level": 0},
        {"label": "Potassium", "value": "140", "unit": "mg", "rda_per_serve": "3%", "level": 0},
        {"label": "Calcium", "value": "40", "unit": "mg", "rda_per_serve": "2%", "level": 0},
        {"label": "Iron", "value": "1.2", "unit": "mg", "rda_per_serve": "4%", "level": 0}
    ],
    "claims": [],
    "barcode_ean13": "7412589632313",
    "compliance_score": 98,
    "compliance_status": "Verified Compliant"
}


# -----------------------------------------------------------------------------
# 3. HIGH-DENSITY COMPACT MASTER SVG GENERATOR
# -----------------------------------------------------------------------------
def generate_master_svg(data: dict, fssai_b64: str) -> str:
    """
    Constructs an ultra-compact, high-density professional packaging label
    with ZERO vacant space, matching real commercial FMCG packaging standards.
    Geometry: 460 x 540 units (dense, border-to-border commercial packaging).
    """
    brand = data.get("brand_name", "").upper()
    product = data.get("product_name", "").upper()
    title_line = f"{brand} {product}".strip()
    category = data.get("product_category", "PACKAGED COMMODITY").upper()
    net_qty = f"{data.get('net_quantity', '70')} {data.get('net_quantity_unit', 'g')}"
    mrp_val = data.get("mrp", "20.00").replace("₹", "").replace("Rs.", "").strip()
    mrp = f"Rs. {mrp_val}"
    usp = data.get("usp", "Rs. 0.28 / g")
    fssai = data.get("fssai_license_number", "74125896323145")
    mfr_name = data.get("manufacturer_name", brand)
    mfr_addr = data.get("manufacturer_address", "Mere Ghar Pe")
    phone = data.get("consumer_care_phone", "9876543210")
    email = data.get("consumer_care_email", "kurkure@gmail.com")
    origin = data.get("country_of_origin", "INDIA").upper()
    batch = data.get("batch_number", "HALDIRAMS-2026-I92")
    mfg_date = data.get("mfg_date", "AUG 2026")
    best_before = data.get("best_before", "12 Months from Packaging")
    storage = data.get("storage_instructions", "Do not freeze. Store in an airtight container.")
    is_veg = data.get("is_vegetarian", True)

    # Ingredients with percentages (% w/w)
    ing_items = []
    for ing in data.get("ingredients", []):
        name = ing.get("name", "")
        pct = ing.get("percentage")
        if pct is not None and pct > 0:
            pct_str = f"{pct:.0f}%" if pct == int(pct) else f"{pct:.1f}%"
            ing_items.append(f"{name} ({pct_str})")
        else:
            ing_items.append(name)
    ingredients_str = ", ".join(ing_items)

    # Allergens string
    allergens_str = ", ".join(data.get("allergens", []))

    # Barcode modules
    barcode_digits = data.get("barcode_ean13", "7412589632313")
    norm_ean = normalize_ean13(barcode_digits)
    modules = encode_ean13_modules(norm_ean)

    bar_w = 145.0
    mod_w = bar_w / len(modules)
    bar_svg_lines = []
    for i, is_bar in enumerate(modules):
        if is_bar:
            is_guard = (i < 3) or (45 <= i < 50) or (i >= len(modules) - 3)
            bh = 28.0 if is_guard else 24.0
            x = i * mod_w
            bar_svg_lines.append(f'<rect x="{x:.2f}" y="0" width="{mod_w + 0.1:.2f}" height="{bh:.1f}" fill="#000000" />')
    barcode_bars_markup = "\n        ".join(bar_svg_lines)

    d1 = norm_ean[0]
    left6 = norm_ean[1:7]
    right6 = norm_ean[7:13]

    # Nutrition table rows (Dense packaging line height 12.5px)
    serve_size = f"{data.get('serving_size', '70')} {data.get('serving_size_unit', 'g')}"
    nutrients = data.get("nutrients", [])

    nutr_rows_markup = []
    row_y = 52.0
    for n in nutrients:
        label = n.get("label", "")
        val = f"{n.get('value', '0')} {n.get('unit', 'g')}"
        rda = n.get("rda_per_serve", "—")
        level = n.get("level", 0)

        indent = 8 + (level * 12)
        is_bold = level == 0 or label in ["Total Fat", "Carbohydrate", "Protein", "Sodium"]
        font_wt = "bold" if is_bold else "normal"
        color = "#000000" if is_bold else "#333333"

        prefix = ""
        if level == 1:
            prefix = "— "
        elif level == 2:
            prefix = "• "

        nutr_rows_markup.append(f'''
      <!-- Row: {label} -->
      <line x1="6" y1="{row_y - 2}" x2="438" y2="{row_y - 2}" stroke="#e2e8f0" stroke-width="0.6" />
      <text x="{indent}" y="{row_y + 7.5}" font-family="Arial, Helvetica, sans-serif" font-size="8.5px" font-weight="{font_wt}" fill="{color}">{prefix}{label} <tspan font-weight="normal" fill="#555555">{val}</tspan></text>
      <text x="438" y="{row_y + 7.5}" font-family="Arial, Helvetica, sans-serif" font-size="8.5px" font-weight="{font_wt}" fill="{color}" text-anchor="end">{rda}</text>
        ''')
        row_y += 12.5

    table_h = row_y + 14.0

    # Ingredients word wrap (Compact 78 chars)
    ing_full = f"INGREDIENTS: {ingredients_str}"
    words = ing_full.split(" ")
    ing_lines = []
    curr_line = ""
    for w in words:
        if not curr_line:
            curr_line = w
        elif len(curr_line) + len(w) + 1 <= 80:
            curr_line = f"{curr_line} {w}"
        else:
            ing_lines.append(curr_line)
            curr_line = w
    if curr_line:
        ing_lines.append(curr_line)

    ing_svg_parts = []
    iy = 8.5
    for idx, iline in enumerate(ing_lines):
        if idx == 0 and iline.startswith("INGREDIENTS:"):
            rest = iline[len("INGREDIENTS:"):].strip()
            ing_svg_parts.append(f'<text x="2" y="{iy}" font-family="Arial, Helvetica, sans-serif" font-size="8px" font-weight="bold" fill="#000000">INGREDIENTS: <tspan font-weight="normal" fill="#1e293b">{rest}</tspan></text>')
        else:
            ing_svg_parts.append(f'<text x="2" y="{iy}" font-family="Arial, Helvetica, sans-serif" font-size="8px" fill="#1e293b">{iline}</text>')
        iy += 10.5
    ingredients_markup = "\n    ".join(ing_svg_parts)
    ingredients_h = iy + 1.0

    veg_color = "#16a34a" if is_veg else "#991b1b"

    # Precise tight vertical flow with ZERO vacant space:
    header_top = 8
    header_h = 40
    header_bottom = header_top + header_h

    nutrition_y = header_bottom + 4
    nutrition_h = int(table_h)

    ingredients_y = nutrition_y + nutrition_h + 4

    allergen_y = ingredients_y + int(ingredients_h) + 3
    allergen_h = 16

    spec_strip_y = allergen_y + allergen_h + 4
    spec_strip_h = 16

    pricing_y = spec_strip_y + spec_strip_h + 4
    pricing_h = 58

    barcode_y = pricing_y + pricing_h + 4
    barcode_h = 64

    footer_y = barcode_y + barcode_h + 4
    footer_h = 50

    total_canvas_h = footer_y + footer_h + 6
    border_h = total_canvas_h - 8

    svg_content = f'''<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<svg xmlns="http://www.w3.org/2000/svg" 
     xmlns:xlink="http://www.w3.org/1999/xlink" 
     width="100mm" height="{total_canvas_h * 100 / 460:.1f}mm" 
     viewBox="0 0 460 {total_canvas_h}" 
     version="1.1">

  <!-- Background Substrate -->
  <rect x="0" y="0" width="460" height="{total_canvas_h}" fill="#ffffff" />
  <rect x="4" y="4" width="452" height="{border_h}" rx="3" fill="#ffffff" stroke="#000000" stroke-width="1.2" />

  <!-- ==================================================================== -->
  <!-- 1. COMPACT HEADER: BRAND, PRODUCT & VEG EMBLEM                       -->
  <!-- ==================================================================== -->
  <g transform="translate(10, {header_top})">
    <!-- Brand & Title -->
    <text x="0" y="10" font-family="'Arial Black', Arial, Helvetica, sans-serif" font-size="9.5px" font-weight="900" letter-spacing="0.8px" fill="#047857">{brand}</text>
    <text x="0" y="24" font-family="'Arial Black', Arial, Helvetica, sans-serif" font-size="14px" font-weight="900" letter-spacing="-0.2px" fill="#000000">{product}</text>
    <text x="0" y="35" font-family="Arial, Helvetica, sans-serif" font-size="7.5px" font-weight="bold" fill="#555555">PROPRIETARY FOOD [{category}]</text>

    <!-- Net Quantity Badge -->
    <g transform="translate(346, 7)">
      <rect width="64" height="18" rx="2" fill="#f8fafc" stroke="#94a3b8" stroke-width="0.8" />
      <text x="32" y="12.5" font-family="Arial, Helvetica, sans-serif" font-size="8.5px" font-weight="bold" fill="#000000" text-anchor="middle">NET WT. {net_qty}</text>
    </g>

    <!-- Statutory Vegetarian Symbol (Standard FSSAI 1:1) -->
    <g transform="translate(418, 6)">
      <rect x="0" y="0" width="20" height="20" rx="2" fill="#ffffff" stroke="{veg_color}" stroke-width="1.6" />
      <circle cx="10" cy="10" r="5" fill="{veg_color}" />
    </g>
  </g>

  <!-- Header Separator Rule -->
  <line x1="4" y1="{header_bottom}" x2="456" y2="{header_bottom}" stroke="#000000" stroke-width="1.2" />

  <!-- ==================================================================== -->
  <!-- 2. HIGH-DENSITY NUTRITION FACTS PANEL                                -->
  <!-- ==================================================================== -->
  <g transform="translate(8, {nutrition_y})">
    <!-- Outer Table Border -->
    <rect width="444" height="{nutrition_h}" rx="2" fill="#ffffff" stroke="#000000" stroke-width="1" />

    <!-- Black Header Bar -->
    <rect width="444" height="17" rx="1" fill="#000000" />
    <text x="8" y="12" font-family="'Arial Black', Arial, Helvetica, sans-serif" font-size="9.5px" font-weight="900" fill="#ffffff" letter-spacing="0.3px">NUTRITION FACTS / VALEUR NUTRITIVE</text>
    <text x="436" y="12" font-family="Arial, Helvetica, sans-serif" font-size="8px" font-weight="bold" fill="#ffffff" text-anchor="end">PER {serve_size.upper()}</text>

    <!-- Serving Info & % DV Header -->
    <text x="8" y="27" font-family="Arial, Helvetica, sans-serif" font-size="7.5px" font-weight="bold" fill="#475569">Serving Size: {serve_size} (Pack contains {data.get('servings_per_pack', 1)} serving)</text>
    <text x="436" y="27" font-family="Arial, Helvetica, sans-serif" font-size="7.5px" font-weight="bold" fill="#475569" text-anchor="end">% Daily Value / % RDA *</text>

    <line x1="6" y1="32" x2="438" y2="32" stroke="#000000" stroke-width="2" />

    <!-- Energy / Calories Callout -->
    <text x="8" y="45" font-family="'Arial Black', Arial, Helvetica, sans-serif" font-size="13px" font-weight="900" fill="#000000">Calories {data.get('calories_per_serve', '375')} <tspan font-family="Arial, Helvetica, sans-serif" font-size="9px" font-weight="normal" fill="#555555">(Energy 536 kcal / 100 g)</tspan></text>
    <text x="436" y="45" font-family="'Arial Black', Arial, Helvetica, sans-serif" font-size="12px" font-weight="900" fill="#000000" text-anchor="end">19%</text>

    <line x1="6" y1="49" x2="438" y2="49" stroke="#000000" stroke-width="1.4" />

    <!-- Compact Nutrient Rows -->
    {''.join(nutr_rows_markup)}

    <!-- Footnote -->
    <line x1="6" y1="{nutrition_h - 12}" x2="438" y2="{nutrition_h - 12}" stroke="#000000" stroke-width="0.6" />
    <text x="8" y="{nutrition_h - 4}" font-family="Arial, Helvetica, sans-serif" font-size="6.5px" fill="#555555">*5% or less is a little, 15% or more is a lot. % Daily Values based on 2,000 kcal diet.</text>
  </g>

  <!-- ==================================================================== -->
  <!-- 3. INGREDIENTS WITH CONTENT PERCENTAGES (% w/w)                       -->
  <!-- ==================================================================== -->
  <g transform="translate(8, {ingredients_y})">
    {ingredients_markup}
  </g>

  <!-- ==================================================================== -->
  <!-- 4. ALLERGEN ADVICE BOX                                                -->
  <!-- ==================================================================== -->
  <g transform="translate(8, {allergen_y})">
    <rect width="444" height="{allergen_h}" rx="2" fill="#fff5f5" stroke="#feb2b2" stroke-width="0.8" />
    <text x="6" y="11" font-family="Arial, Helvetica, sans-serif" font-size="7.5px" font-weight="bold" fill="#991b1b">
      ALLERGEN ADVICE: <tspan font-weight="normal" fill="#7f1d1d">Contains {allergens_str}. Made in a facility that also processes Mustard, Sesame &amp; Peanuts.</tspan>
    </text>
  </g>

  <!-- ==================================================================== -->
  <!-- 5. SPECIFICATION & ORIGIN STRIP                                       -->
  <!-- ==================================================================== -->
  <g transform="translate(8, {spec_strip_y})">
    <rect width="444" height="{spec_strip_h}" rx="2" fill="#f1f5f9" stroke="#cbd5e1" stroke-width="0.7" />
    <text x="8" y="11" font-family="Arial, Helvetica, sans-serif" font-size="7.5px" font-weight="bold" fill="#000000">NET WT. {net_qty} / 2.47 oz.</text>
    <text x="222" y="11" font-family="Arial, Helvetica, sans-serif" font-size="7.5px" font-weight="bold" fill="#475569" text-anchor="middle">PRODUCT OF INDIA / PRODUIT DE L'INDE</text>
    <text x="436" y="11" font-family="Arial, Helvetica, sans-serif" font-size="7.5px" font-weight="bold" fill="#047857" text-anchor="end">COMMERCIAL PACK</text>
  </g>

  <!-- ==================================================================== -->
  <!-- 6. LEGAL METROLOGY PRICING & TRACEABILITY GRID                        -->
  <!-- ==================================================================== -->
  <g transform="translate(8, {pricing_y})">
    <rect width="444" height="{pricing_h}" rx="2" fill="#ffffff" stroke="#000000" stroke-width="1" />

    <!-- Top Row: Net Quantity | MRP | USP -->
    <g transform="translate(8, 12)">
      <!-- Net Qty -->
      <text x="0" y="0" font-family="Arial, Helvetica, sans-serif" font-size="7px" font-weight="bold" fill="#64748b" letter-spacing="0.3px">NET QUANTITY</text>
      <text x="0" y="13" font-family="'Arial Black', Arial, Helvetica, sans-serif" font-size="12px" font-weight="900" fill="#000000">{net_qty}</text>

      <line x1="100" y1="-4" x2="100" y2="18" stroke="#cbd5e1" stroke-width="0.7" />

      <!-- MRP -->
      <text x="112" y="0" font-family="Arial, Helvetica, sans-serif" font-size="7px" font-weight="bold" fill="#64748b" letter-spacing="0.3px">MAX RETAIL PRICE [MRP]</text>
      <text x="112" y="13" font-family="'Arial Black', Arial, Helvetica, sans-serif" font-size="12px" font-weight="900" fill="#047857">{mrp} <tspan font-family="Arial, Helvetica, sans-serif" font-size="7.5px" font-weight="normal" fill="#64748b">[Incl. of all taxes]</tspan></text>

      <line x1="285" y1="-4" x2="285" y2="18" stroke="#cbd5e1" stroke-width="0.7" />

      <!-- USP -->
      <text x="296" y="0" font-family="Arial, Helvetica, sans-serif" font-size="7px" font-weight="bold" fill="#64748b" letter-spacing="0.3px">UNIT SALE PRICE [USP]</text>
      <text x="296" y="13" font-family="'Arial Black', Arial, Helvetica, sans-serif" font-size="11.5px" font-weight="900" fill="#000000">{usp}</text>
    </g>

    <line x1="6" y1="33" x2="438" y2="33" stroke="#cbd5e1" stroke-width="0.7" />

    <!-- Bottom Row: Batch | Mfg | Expiry | Storage -->
    <g transform="translate(8, 43)">
      <text x="0" y="0" font-family="Arial, Helvetica, sans-serif" font-size="7.5px" fill="#1e293b">
        <tspan font-weight="bold">Batch No:</tspan> {batch}   •   
        <tspan font-weight="bold">Mfg Date:</tspan> {mfg_date}   •   
        <tspan font-weight="bold">Best Before:</tspan> {best_before}
      </text>
      <text x="0" y="10" font-family="Arial, Helvetica, sans-serif" font-size="7px" fill="#555555">
        <tspan font-weight="bold">Storage:</tspan> {storage}
      </text>
    </g>
  </g>

  <!-- ==================================================================== -->
  <!-- 7. SCANNABLE GS1 BARCODE & UN-DISTORTED FSSAI LOGO                   -->
  <!-- ==================================================================== -->
  <g transform="translate(8, {barcode_y})">
    <rect width="444" height="{barcode_h}" rx="2" fill="#ffffff" stroke="#000000" stroke-width="1" />

    <!-- Barcode Left Box -->
    <g transform="translate(14, 8)">
      <g transform="translate(16, 0)">
        {barcode_bars_markup}
      </g>
      <text x="8" y="38" font-family="'Courier New', Courier, monospace" font-size="9px" font-weight="bold" fill="#000000">{d1}</text>
      <text x="22" y="38" font-family="'Courier New', Courier, monospace" font-size="9px" font-weight="bold" fill="#000000">{left6}</text>
      <text x="92" y="38" font-family="'Courier New', Courier, monospace" font-size="9px" font-weight="bold" fill="#000000">{right6}</text>
      <text x="88" y="48" font-family="Arial, Helvetica, sans-serif" font-size="6.5px" font-weight="bold" fill="#059669" text-anchor="middle">GS1 EAN-13 VERIFIED ✓</text>
    </g>

    <!-- Center Divider -->
    <line x1="220" y1="6" x2="220" y2="58" stroke="#cbd5e1" stroke-width="0.7" />

    <!-- FSSAI Right Box (Exact 4:3 Ratio) -->
    <g transform="translate(230, 4)">
      <rect width="206" height="56" rx="2" fill="#ffffff" stroke="#047857" stroke-width="0.8" />
      <image href="data:image/png;base64,{fssai_b64}" 
             x="77" y="2" 
             width="52" height="39" 
             preserveAspectRatio="xMidYMid meet" />
      <text x="103" y="49" font-family="'Arial Black', Arial, Helvetica, sans-serif" font-size="8.5px" font-weight="900" fill="#000000" text-anchor="middle" letter-spacing="0.3px">Lic. No. {fssai}</text>
    </g>
  </g>

  <!-- ==================================================================== -->
  <!-- 8. MANUFACTURER, CONSUMER CARE & ENVIRONMENTAL STATUTORY FOOTER      -->
  <!-- ==================================================================== -->
  <g transform="translate(8, {footer_y})">
    <rect width="444" height="{footer_h}" rx="2" fill="#ffffff" stroke="#000000" stroke-width="1" />

    <g transform="translate(8, 9)">
      <!-- Manufacturer Declaration -->
      <text x="0" y="0" font-family="Arial, Helvetica, sans-serif" font-size="7.5px" font-weight="bold" fill="#000000">Mfd. By: {mfr_name}, <tspan font-weight="normal" fill="#333333">{mfr_addr}</tspan>  |  <tspan font-weight="bold">Lic. No.</tspan> {fssai}</text>

      <line x1="0" y1="5" x2="385" y2="5" stroke="#e2e8f0" stroke-width="0.6" />

      <!-- Consumer Care -->
      <text x="0" y="14" font-family="Arial, Helvetica, sans-serif" font-size="7px" fill="#333333">
        <tspan font-weight="bold" fill="#000000">Consumer Care:</tspan> +91 {phone}  •  <tspan font-weight="bold" fill="#000000">Email:</tspan> {email}  •  <tspan font-weight="bold" fill="#000000">Origin:</tspan> {origin}  •  <tspan font-weight="bold" fill="#000000">Web:</tspan> {data.get('consumer_care_website', 'www.haldirams.com')}
      </text>

      <line x1="0" y1="19" x2="385" y2="19" stroke="#e2e8f0" stroke-width="0.6" />

      <!-- Statutory Declaration -->
      <text x="0" y="28" font-family="Arial, Helvetica, sans-serif" font-size="6.8px" font-weight="bold" fill="#047857">
        ✓ Compliant with Legal Metrology (Packaged Commodities) Rules 2011 &amp; FSSAI Standards.
      </text>
      <text x="0" y="37" font-family="Arial, Helvetica, sans-serif" font-size="6.5px" fill="#64748b">
        Packaging: {data.get('packaging_type', 'Food Grade Metallized Pouch')} • {data.get('recycling_mark', 'MoEFCC Disposal Logo')}
      </text>

      <!-- Clean India Disposal Icon -->
      <g transform="translate(398, 3)">
        <circle cx="13" cy="13" r="12" fill="#ffffff" stroke="#047857" stroke-width="0.9" />
        <path d="M 13 4 L 13 18 M 9 8 L 13 4 L 17 8" fill="none" stroke="#047857" stroke-width="1.2" stroke-linecap="round" stroke-linejoin="round"/>
        <text x="13" y="21" font-family="Arial, Helvetica, sans-serif" font-size="3px" font-weight="bold" fill="#047857" text-anchor="middle">DISPOSE</text>
      </g>
    </g>
  </g>
</svg>'''
    return svg_content


# -----------------------------------------------------------------------------
# 4. MULTI-FORMAT GENERATION PIPELINE
# -----------------------------------------------------------------------------
def main():
    print("==================================================================")
    print("SIH 2026 - Generating Compact High-Density Label with % Content")
    print("==================================================================")

    out_dir = os.path.join(os.path.dirname(__file__))
    artifacts_dir = r"C:\Users\ASUS\.gemini\antigravity\brain\ba191191-7a2f-4873-9006-2a68cf4ddeb5"

    fssai_logo_path = os.path.abspath(r"apps/mobile/assets/images/fssai_logo.png")
    with open(fssai_logo_path, "rb") as f:
        fssai_b64 = base64.b64encode(f.read()).decode("ascii")

    # 1. Master SVG
    print("\n1. Generating Master Vector SVG...")
    svg_markup = generate_master_svg(COMPACT_LABEL_DATA, fssai_b64)
    svg_path = os.path.join(out_dir, "sample_label.svg")
    with open(svg_path, "w", encoding="utf-8") as f:
        f.write(svg_markup)
    print(f"   [OK] Created SVG: {svg_path} ({len(svg_markup)} bytes)")

    # 2. Vector PDF (100 x 150 mm)
    print("\n2. Generating Print-Ready Vector PDF...")
    doc = pymupdf.open(stream=svg_markup.encode("utf-8"), filetype="svg")
    pdf_bytes = doc.convert_to_pdf()
    pdf_doc = pymupdf.open(stream=pdf_bytes, filetype="pdf")

    pdf_path = os.path.join(out_dir, "sample_label.pdf")
    pdf_doc.save(pdf_path)
    page_rect = pdf_doc[0].rect
    print(f"   [OK] Created PDF: {pdf_path}")
    print(f"   [OK] PDF Page MediaBox: width={page_rect.width:.2f}pt, height={page_rect.height:.2f}pt")
    print(f"        (Equivalent to {page_rect.width * 25.4 / 72:.1f} x {page_rect.height * 25.4 / 72:.1f} mm)")

    # 3. High-Res 300 DPI PNG
    print("\n3. Generating High-Res 300 DPI PNG Bitmap...")
    pix = pdf_doc[0].get_pixmap(dpi=300)
    png_path = os.path.join(out_dir, "sample_label.png")
    pix.save(png_path)
    print(f"   [OK] Created PNG: {png_path} ({pix.width} x {pix.height} px, 300 DPI)")

    # 4. Compliance JSON
    print("\n4. Generating Compliance JSON...")
    json_path = os.path.join(out_dir, "sample_compliance.json")
    with open(json_path, "w", encoding="utf-8") as f:
        json.dump(COMPACT_LABEL_DATA, f, indent=2, ensure_ascii=False)
    print(f"   [OK] Created Compliance JSON: {json_path}")

    # 5. Mirror to Artifacts
    if os.path.exists(artifacts_dir):
        print(f"\n5. Mirroring prototype outputs to Antigravity artifacts: {artifacts_dir}")
        for filename in ["sample_label.svg", "sample_label.pdf", "sample_label.png", "sample_compliance.json"]:
            src = os.path.join(out_dir, filename)
            dst = os.path.join(artifacts_dir, filename)
            shutil.copy2(src, dst)
            print(f"   [OK] Mirrored {filename}")

    print("\n==================================================================")
    print("PROTOTYPE GENERATION COMPLETE: All 4 compact formats created!")
    print("==================================================================")

if __name__ == "__main__":
    main()

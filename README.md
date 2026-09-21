<div align="center">

<img src="apps/mobile/assets/images/labellens_logo.png" alt="LabelLens Logo" width="180" />

# LabelLens — Legal Metrology Compliance Platform
### Smart India Hackathon (SIH 2026)

**AI-powered packaged commodity auditing and compliance automation under the Legal Metrology (Packaged Commodities) Rules, 2011.**

[![Flutter](https://img.shields.io/badge/Flutter-3.24+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.12+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.115+-009688?logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com)
[![Python](https://img.shields.io/badge/Python-3.11_|_3.14-3776AB?logo=python&logoColor=white)](https://python.org)
[![InterpretML](https://img.shields.io/badge/ML-Explainable_Boosting_Machine-FF6F00)](https://interpret.ml)
[![Gemini](https://img.shields.io/badge/Vision_AI-Google_Gemini-4285F4?logo=google&logoColor=white)](https://ai.google.dev)
[![Groq](https://img.shields.io/badge/LLM_Summary-Groq_Cloud-F55036)](https://groq.com)
[![Supabase](https://img.shields.io/badge/Backend-Supabase_PostgreSQL-3ECF8E?logo=supabase&logoColor=white)](https://supabase.com)

<p align="center">
  <b>Bridging the Gap Between Consumers, Small Businesses, Enterprise Manufacturers, and Regulatory Enforcement Officers.</b>
</p>

</div>

---

## 💻 Tech Stack

<table>
  <tr>
    <td width="50%" valign="top">
      <h3>📱 Mobile & Cross-Platform Client</h3>
      <ul>
        <li><b>Framework:</b> Flutter 3.24+ (Dart 3.12+)</li>
        <li><b>Design System:</b> Material Design 3 with custom Design Tokens</li>
        <li><b>Edge OCR / Scanner:</b> Google ML Kit (Text Recognition & Barcode Scanning)</li>
        <li><b>Camera Engine:</b> CameraX integration with multi-angle capture guide</li>
        <li><b>Networking & State:</b> <code>http</code>, <code>shared_preferences</code>, auto LAN probing</li>
        <li><b>Backend Integration:</b> <code>supabase_flutter</code> (Auth, Storage, RLS, DB)</li>
      </ul>
    </td>
    <td width="50%" valign="top">
      <h3>⚡ Backend & Microservices</h3>
      <ul>
        <li><b>Web Framework:</b> FastAPI (High-performance async Python)</li>
        <li><b>Server Gateway:</b> Uvicorn (ASGI)</li>
        <li><b>Package & Env Manager:</b> Astral <code>uv</code> (deterministic lockfile <code>uv.lock</code>)</li>
        <li><b>Serialization & Validation:</b> Pydantic v2</li>
        <li><b>Cloud Storage:</b> Supabase Storage Buckets for label photos & PDFs</li>
        <li><b>Report Compilation:</b> ReportLab & FPDF2 (statutory tabular audits)</li>
      </ul>
    </td>
  </tr>
  <tr>
    <td width="50%" valign="top">
      <h3>🔬 Computer Vision & OCR</h3>
      <ul>
        <li><b>Core OCR:</b> Tesseract OCR (bilingual English + Hindi/Devanagari)</li>
        <li><b>Deep Learning OCR:</b> EasyOCR (PyTorch-based multi-pass text extraction)</li>
        <li><b>Image Preprocessing:</b> OpenCV (<code>cv2</code>), NumPy, Pillow</li>
        <li><b>Barcode & QR Decoder:</b> <code>pyzbar</code> + OpenCV with GS1 classification</li>
        <li><b>Geometry & Metrology:</b> 3-way calibration (ruler, barcode, package height) for Rule 7 font mm sizing</li>
      </ul>
    </td>
    <td width="50%" valign="top">
      <h3>🧠 Machine Learning & AI Core</h3>
      <ul>
        <li><b>Explainable ML:</b> Explainable Boosting Machine (EBM via <code>interpret</code>)</li>
        <li><b>Multimodal Vision:</b> Google Gemini 2.5 Flash / 1.5 Flash (zero-shot visual audit)</li>
        <li><b>Consumer & Regulatory AI:</b> Groq Cloud (Qwen 2.5 72B/27B, Llama 3.3 70B)</li>
        <li><b>Additive Hazard Screener:</b> Food dye (INS 102/110/129), BHA/BHT, Palm oil & Sugar/Sodium auditor</li>
        <li><b>Rule Engine:</b> 26+ deterministic checks under LM(PC) Rules 2011</li>
      </ul>
    </td>
  </tr>
</table>

---

## 🏛️ Architecture Overview

The system operates on an intelligent **hybrid dual-engine architecture**:
1. **Cloud / Vision Route**: Google Gemini Multimodal Vision executes instant end-to-end visual parsing when online.
2. **Local Fallback Route**: Fully local, air-gapped Computer Vision pipeline (Multi-pass Tesseract/EasyOCR + OpenCV + Explainable Boosting Machine + 26+ deterministic statutory rulebook checks).
3. **Barcode-First Pipeline**: Instant verification of GS1 GTIN codes against official registries without requiring image upload.

```mermaid
flowchart TD
    User([User: Consumer / Business / Regulator]) -->|Capture Label Photos / Scan Barcode| MobileApp[Mobile App: Flutter / Google ML Kit]
    
    subgraph Client ["Client Device"]
        MobileApp -->|Offline Fallback| EmbeddedEngine[packages/legal_metrology: Pure-Dart Rules & ML Kit]
        MobileApp -->|HTTP / REST| FastAPIGateway[FastAPI ML Scanner Service: Port 8000]
    end

    subgraph Backend ["ML Scanner Service (FastAPI)"]
        FastAPIGateway --> RouteCheck{Has Gemini Key & Photos?}
        
        %% Gemini Branch
        RouteCheck -->|Yes| GeminiVision[Gemini Multimodal Vision Engine]
        
        %% Local Pipeline Branch
        RouteCheck -->|No / Fallback| LocalPipeline[Local CV & Metrology Pipeline]
        
        subgraph CV_Engine ["Local Metrology Engine"]
            LocalPipeline --> MultiPassOCR[5-Pass OCR Engine: Tesseract / EasyOCR]
            LocalPipeline --> BarcodeScanner[pyzbar Barcode & QR Code Scanner]
            LocalPipeline --> FontCalib[Font Size Estimator: Ruler / Barcode / Dim Calibration]
            LocalPipeline --> SymbolDetect[Symbol Detector: FSSAI, Veg / Non-Veg Mark]
            
            MultiPassOCR --> TextParser[TextParser: NLP & Regex Entity Extraction]
            BarcodeScanner --> GS1Module[GS1 GTIN Classifier & Registry Lookup]
            
            TextParser --> Normalizer[Data Normalizer: PackageData Schema]
            GS1Module --> Normalizer
            FontCalib --> Normalizer
            SymbolDetect --> Normalizer
            
            Normalizer --> EBM[Explainable Boosting Machine: EBM Model]
            Normalizer --> RuleEngine[26+ Rulebook Engine: LM(PC) Rules 2011]
            
            EBM --> Aggregator[Compliance Scorer & Star Rating]
            RuleEngine --> Aggregator
        end
        
        GeminiVision --> Aggregator
        
        %% AI Summary & PDF
        Aggregator --> AISummary[Groq LLM Engine: summary_gen]
        AISummary --> HealthScore[Food Health Scoring & Additive Screening]
        AISummary --> PDFGen[ReportLab Formal Tabular Audit PDF]
    end

    subgraph DataCloud ["Cloud & Database"]
        FastAPIGateway <-->|Cache & Store| Supabase[(Supabase: PostgreSQL, Auth, Storage)]
        GS1Module <-->|Corroborate| ExternalRegistries[(Open Food Facts / GS1 India / UPCItemDB)]
    end

    PDFGen --> FastAPIGateway
    HealthScore --> FastAPIGateway
    FastAPIGateway --> MobileApp
```

---

## 🔬 How Label Scanning Works (ML Models, OCR & Metrology Pipeline)

The compliance auditing system implements a 10-stage pipeline to evaluate product packages against the **Legal Metrology (Packaged Commodities) Rules, 2011**:

```
[1. Image Capture & Downscaling]
           │
           ▼
[2. Barcode & GS1 GTIN Verification] ──► (Validates EAN-13 Checksum, Country 890, Registries)
           │
           ▼
[3. Multi-Pass Adaptive OCR] ──────────► (5 Preprocessing Passes + Spatial IOU Deduplication)
           │
           ▼
[4. Physical Scale & Font Height] ─────► (Ruler / Barcode Calibration for Rule 7 Font mm)
           │
           ▼
[5. Semantic Text & Symbol Parsing] ───► (Regex/NLP for MRP, USP, Dates, FSSAI, Address)
           │
           ▼
[6. Explainable Boosting Machine (EBM)]► (Glass-Box GAM evaluates feature weights & risk factors)
           │
           ▼
[7. Deterministic 26+ Rulebook] ───────► (Exact statutory checks: Rule 6, 7, 9, MPE tolerances)
           │
           ▼
[8. Gemini Multimodal Vision Route] ───► (Dual-engine zero-shot cross-validation)
           │
           ▼
[9. Groq AI Health & Hazard Audit] ────► (Food Additive Screening: INS 102/110/129, Sodium/Sugar)
           │
           ▼
[10. Executive Audit Report & PDF] ────► (ReportLab formal tabular audit persisted to Supabase)
```

### 1. Multi-Angle Ingestion & Adaptive Preprocessing
- **Evidence Capture**: Accepts four package angles:
  - **Front Label** (Mandatory): Principal Display Panel (PDP) containing commodity name, veg/non-veg marks, and net quantity.
  - **Back / Side Label** (Recommended): Detailed declarations (manufacturer address, MRP, batch number, customer care).
  - **Ruler / Calibration Scale** (Optional): A physical metric ruler placed alongside the package for millimeter-exact font measurement.
  - **Barcode Crop** (Optional): High-resolution crop of the 1D/2D barcode or QR code.
- **Payload Optimization**: Mobile photos are automatically downscaled to a max dimension of 1600px with 85% JPEG compression (`_optimize_image_for_vision`), preventing multi-megabyte payloads from causing network timeouts.

### 2. Barcode Decoding & GS1 Integrity Verification
- **Decoding**: Utilizes `pyzbar` and OpenCV for omnidirectional barcode and QR detection.
- **GS1 Structural Classification**: Classifies GTIN format (`EAN-13`, `UPC-A`, `ITF-14`, `GTIN-14`).
- **Checksum Algorithm**: Evaluates modulo-10 check digits with alternating $3\times$ and $1\times$ weighting.
- **National Prefix Resolution**: Validates country prefixes (e.g., prefix `890` confirms issuance by GS1 India).
- **Live Registry Corroboration**: Cross-references Open Food Facts, GS1 India DataKart, and UPCItemDB to fetch canonical manufacturer declarations.
- **QR Code Verification**: Extracts URL endpoints from packaging QR codes, validates reachability via HTTP HEAD/GET probes, and extracts the target page title for consumer transparency.

### 3. Advanced 5-Pass Adaptive OCR Engine
Standard OCR struggles with real-world Indian packaged goods due to metallic foils, plastic gloss, curved bottles, motion blur, and tiny 1mm font sizes. LabelLens implements an **adaptive 5-pass preprocessing pipeline**:
- **Pass 1 (Baseline Greyscale)**: Plain greyscale image for clean, high-contrast studio labels.
- **Pass 2 (CLAHE + Bilateral Filtering + Tophat)**:
  - Converts image to LAB color space and applies CLAHE (Contrast Limited Adaptive Histogram Equalization) on the L-channel.
  - Morphological Top-Hat filtering suppresses specular glare from glossy plastic and foil pouches.
  - Bilateral filtering smooths packaging texture while keeping character edges crisp.
  - Otsu automated binarization extracts high-clarity text masks.
- **Pass 3 (2× Bicubic Upscale + Unsharp Masking)**:
  - Upscales the image $2\times$ with bicubic interpolation.
  - Applies unsharp masking ($1.8 \times \text{sharp} - 0.8 \times \text{blur}$) and Gaussian adaptive thresholding.
  - **Purpose**: Recovers tiny 1mm font required for FSSAI numbers, batch codes, and packer addresses.
- **Pass 4 (Inverted Binarization)**:
  - Inverts color channels for light text printed on dark backgrounds (common in spices, confectioneries, and coffee packets).
- **Pass 5 (Wiener-Style Deblur + High-Contrast CLAHE)**:
  - Applies an aggressive sharpening kernel ($2.5 \times \text{orig} - 1.5 \times \text{blur}$) and median filtering to eliminate motion and focus blur.
- **Spatial IOU Deduplication**:
  - Detections across all 5 passes are clustered using Intersection over Union (IOU threshold 0.40).
  - The reading with the highest confidence score is preserved, eliminating duplicates.
- **Engines**: Primary engine is native **Tesseract OCR** (with bilingual English + Devanagari/Hindi traineddata), with seamless fallback to **EasyOCR** (PyTorch CRAFT + CRNN architecture).

### 4. Physical Geometry & Rule 7 Font Height Calibration
Under **Rule 7 of the Legal Metrology (Packaged Commodities) Rules, 2011**, mandatory declarations must satisfy minimum numeral and letter heights (ranging from 1.0mm to 6.0mm depending on Principal Display Panel area):
- **Calibration Engine (`FontEstimator`)**:
  1. *Ruler Calibration*: Detects millimeter ticks on a physical ruler via Hough Line Transform to establish exact $\text{pixels}/\text{mm}$.
  2. *Barcode Calibration*: Uses standard EAN-13 nominal dimensions ($37.29\text{ mm}$ width including quiet zones) to calculate real-world scale.
  3. *Package Dimension Calibration*: Converts package height (entered by user or regulator) against bounding box pixel height.
- **Area Calculation**: OpenCV contour convex hulls determine the surface area of the Principal Display Panel (PDP) in $\text{cm}^2$.
- **Statutory Comparison**: Compares the estimated font height in millimeters against the statutory table under Rule 7.

### 5. Semantic Parsing & Entity Extraction
The `TextParser` module extracts structured fields from OCR bounding boxes using specialized regex and NLP entity models:
- **Commodity Name**: Generic nomenclature (Rule 6(1)(b)).
- **Manufacturer / Packer / Importer Details**: Extracts name, complete address, and 6-digit Indian PIN code (Rule 6(1)(a)).
- **Net Quantity & Units**: Numerical value and standardized metric unit ($\text{g}$, $\text{kg}$, $\text{ml}$, $\text{l}$, $\text{m}$, number) under Rule 6(1)(c).
- **Maximum Retail Price (MRP)**: Extracts numerical currency value and verifies the mandatory statutory suffix `"inclusive of all taxes"` (Rule 6(1)(da)).
- **Unit Sale Price (USP)**: Computes price per gram or per milliliter for packages exceeding 100g/100ml (Rule 6(1)(e)).
- **Date Declarations**: Formats of month and year of manufacture, packing, or import (Rule 6(1)(d)).
- **Consumer Care Details**: Toll-free helpline number, official email address, and physical contact address (Rule 6(1)(n)).
- **FSSAI License**: 14-digit statutory license number validation.

### 6. Explainable Boosting Machine (EBM) ML Model
Unlike opaque black-box neural networks, regulatory enforcement requires **complete auditability and legal explainability**:
- **Algorithm**: `ExplainableBoostingClassifier` from Microsoft's **InterpretML**.
- **Architecture**: Tree-based Generalized Additive Model (GAM) with automatic pairwise interaction terms:
  $$g(E[y]) = \beta_0 + \sum f_i(x_i) + \sum f_{ij}(x_i, x_j)$$
- **Features Analyzed**: Presence/absence flags for mandatory declarations, normalized font height ratios, unit validity flags, barcode checksum validity, country prefix alignment, and symbol presence.
- **Explainability Output**: Generates local feature contributions (`feature_contributions`) indicating the exact numeric penalty or credit each label feature contributed to the compliance probability.
- **Model Training**: Trained on synthetic and real packaging datasets (`train_on_real_images.py`), serialized into `compliance_ebm.pkl`.

### 7. Deterministic 26+ Rulebook Engine
The `RulebookEngine` applies strict deterministic legal validation under the LM(PC) Rules 2011:
- **Rule 6(1)(a)**: Name and complete address of the manufacturer, packer, or importer.
- **Rule 6(1)(b)**: Generic or common name of the commodity.
- **Rule 6(1)(c)**: Net quantity in terms of standard unit of weight or measure.
- **Rule 6(1)(d)**: Month and year of manufacture, packing, or import.
- **Rule 6(1)(da)**: Retail sale price as MRP inclusive of all taxes.
- **Rule 6(1)(e)**: Unit Sale Price (USP) declaration in Rs. per g/ml.
- **Rule 6(1)(n)**: Name, address, phone number, and email of person or office for consumer complaints.
- **Rule 7**: Minimum font height based on area of Principal Display Panel.
- **Rule 9**: Placement of declarations on the Principal Display Panel.
- **Second Schedule**: Standard quantities in which commodities must be packed.
- **Fifth Schedule**: Maximum Permissible Error (MPE) thresholds on declared net quantity.
- **Barcode Integrity (B01–B06)**: Valid GTIN structure, correct check digit, GS1 country prefix alignment, and registry consistency.

### 8. Google Gemini Multimodal Vision LLM (Dual-Engine Route)
When a Gemini API key is present:
- Both front and back images are sent to Google Gemini (`gemini-2.5-flash` / `gemini-1.5-flash`).
- Prompts instruct the model to execute end-to-end multimodal label extraction and visual inspection.
- The results are corroborated with the barcode registry and deterministic rulebook engine for total reliability.

### 9. Groq Cloud AI: Health Scoring & Food Additive Screening
Mounted under `/summarize/consumer` and `/summarize/regulator`:
- **Model Fallback Chain**: `qwen/qwen3.8-27b` $\rightarrow$ `llama-3.3-70b-versatile` $\rightarrow$ `openai/gpt-oss-120b`.
- **Classification**: Categorizes items into `food`, `medicinal`, or `general`.
- **Food Health Score (0–100) & Additive Audit**:
  - *Synthetic Dyes*: Detects harmful artificial colors: Tartrazine (INS 102), Sunset Yellow (INS 110), Allura Red (INS 129), Brilliant Blue (INS 133), Carmoisine (INS 122), Ponceau 4R (INS 124).
  - *Chemical Preservatives*: Flags BHA (INS 320), BHT (INS 321), Sodium Benzoate (INS 211), Potassium Sorbate (INS 202).
  - *Fats & Oils*: Flags Palm Oil, industrial palm olein, hydrogenated vegetable fats, and trans fats.
  - *Excessive Thresholds*: Warns on excessive Sodium ($>600\text{ mg}/100\text{g}$) and excessive Sugar ($>15\text{ g}/100\text{g}$).
- **Medicinal Safety**: Generates plain-language dosage instructions, storage warnings, and mandatory statutory disclaimers.

### 10. Regulatory Audit PDF Generation
- Compiles formal legal audit certificates using **ReportLab**.
- Generates side-by-side tabular matrices: *Field Name*, *Declared Value*, *Statutory Requirement*, *Legal Rule Citation*, and *Audit Verdict* (`COMPLIANT`, `WARNING`, `VIOLATION`).
- Embeds front, back, and ruler evidence thumbnails.
- Automatically uploaded to Supabase Storage and made downloadable via signed URLs or streamed via `/report/{scan_id}/download`.

---

## ⚙️ Environment Configuration (`.env`) Setup

### 1. ML Scanner Backend (`services/ml-scanner/.env`)

Create your environment file:
```bash
cp services/ml-scanner/.env.example services/ml-scanner/.env
```

Configure the following variables in `services/ml-scanner/.env`:

| Variable | Description | Required | Default / Example |
|---|---|:---:|---|
| `GEMINI_API_KEY` | Google Gemini API key for Multimodal Vision & zero-shot label analysis | Recommended | `AIzaSy...` |
| `GROQ_API_KEY` | Groq API key for consumer health summaries, food additive auditing, and regulator reports | Recommended | `gsk_...` |
| `GROQ_MODEL` | Primary LLM model on Groq Cloud | Optional | `llama-3.3-70b-versatile` or `qwen/qwen3.8-27b` |
| `SUPABASE_URL` | Supabase project URL for caching scan summaries and PDF report storage | Recommended | `https://tyshfugxmwvhbmoydlnl.supabase.co` |
| `SUPABASE_KEY` | Supabase Anon or Service Role key | Recommended | `eyJhbGciOi...` |
| `PORT` | Local server port | Optional | `8000` |

> [!NOTE]
> If `GEMINI_API_KEY` is not provided, the server automatically executes the local OCR (Tesseract / EasyOCR) and EBM rulebook engine without failing.
> If `GROQ_API_KEY` is not provided, the consumer summary endpoint falls back to a deterministic rule-based summary.

---

### 2. Mobile Client (`apps/mobile/.env` or compile-time config)

A template is provided at `apps/mobile/.env.example`:
```bash
cp apps/mobile/.env.example apps/mobile/.env
```

| Variable | Description | Default / Example |
|---|---|---|
| `SUPABASE_URL` | Supabase Project URL | Built-in via `lib/core/config/supabase_config.dart` |
| `SUPABASE_ANON_KEY` | Supabase Anon Key | Built-in via `lib/core/config/supabase_config.dart` |
| `SUPABASE_PUBLISHABLE_KEY` | Supabase Publishable Key | Built-in via `lib/core/config/supabase_config.dart` |
| `BACKEND_BASE_URL` | ML Scanner FastAPI endpoint | Default: `https://labellens-ml-scanner.onrender.com` (Cloud) with auto LAN probing |
| `GEMINI_API_KEY` | Optional compile-time Gemini key | `--dart-define=GEMINI_API_KEY=...` |
| `GROQ_API_KEY` | Optional compile-time Groq key | `--dart-define=GROQ_API_KEY=...` |

> [!TIP]
> **Intelligent Network Probing**: The mobile app dynamically probes candidate endpoints upon launch (trying `http://127.0.0.1:8000`, Android emulator `http://10.0.2.2:8000`, local Wi-Fi LAN IPs, and finally the cloud Render endpoint), connecting to whichever server responds fastest.

---

## 🚀 Running the Services

### System Prerequisites

- **Python**: `>= 3.11` (Pinned to `3.14` in `.python-version`)
- **[Astral uv](https://docs.astral.sh/uv/)**: High-speed Python package manager (`curl -LsSf https://astral.sh/uv/install.sh | sh` or `winget install astral-sh.uv`)
- **Native Metrology Libraries**:
  - **Ubuntu / Debian**:
    ```bash
    sudo apt update && sudo apt install -y libzbar-dev tesseract-ocr tesseract-ocr-hin
    ```
  - **macOS**:
    ```bash
    brew install zbar tesseract tesseract-lang
    ```
  - **Windows**:
    - Install [Tesseract OCR for Windows](https://github.com/UB-Mannheim/tesseract/wiki) (default path: `C:\Program Files\Tesseract-OCR\tesseract.exe`).
    - The ZBar native DLL is bundled or installable via standard packages.
- **Flutter SDK**: `>= 3.24.0` with Android Studio / Xcode / Chrome.

---

### Step 1: Start the ML Scanner FastAPI Backend

1. Navigate to the backend directory:
   ```bash
   cd services/ml-scanner
   ```

2. Synchronize locked dependencies deterministically:
   ```bash
   uv sync --locked
   ```

3. Ensure `.env` is configured:
   ```bash
   cp .env.example .env
   ```

4. Launch the FastAPI server:
   ```bash
   uv run uvicorn server:app --host 0.0.0.0 --port 8000 --reload
   ```

   **Interactive Endpoints & Documentation:**
   - **Health Status**: [http://localhost:8000/health](http://localhost:8000/health)
   - **Interactive Swagger Docs**: [http://localhost:8000/docs](http://localhost:8000/docs)
   - **ReDoc Documentation**: [http://localhost:8000/redoc](http://localhost:8000/redoc)

---

### Step 2: Run the Flutter Mobile App

1. Navigate to the mobile application directory:
   ```bash
   cd apps/mobile
   ```

2. Fetch Flutter packages:
   ```bash
   flutter pub get
   ```

3. **If running on a physical Android device over USB**:
   Forward port `8000` to allow the mobile device to communicate with your workstation's local FastAPI server:
   ```bash
   adb reverse tcp:8000 tcp:8000
   ```

4. Launch the application:
   ```bash
   # Run on connected device or emulator
   flutter run

   # Or run specifically targeting Web / Chrome
   flutter run -d chrome

   # Run with compile-time Gemini/Groq keys (optional)
   flutter run --dart-define=GEMINI_API_KEY=your_key --dart-define=GROQ_API_KEY=your_key
   ```

---

### Step 3: Supabase Database Setup & Migrations (Optional / Self-Hosted)

Database schemas, Row-Level Security (RLS) policies, and tables are defined in `supabase/migrations/`:
- `20260829090000_regulator_compliance_contract.sql`: Creates consumer scans, regulator scans, complaints, and declaration audit tables.
- `20260829093000_harden_regulator_function_access.sql`: Hardens regulator security policies and stored procedures.

To apply migrations using the Supabase CLI:
```bash
supabase db push
```
Or paste the migration SQL scripts directly into the **SQL Editor** of your Supabase project dashboard.

---

### Step 4: Prototype Label Maker (Optional)

The repository includes a standalone prototype generator for creating synthetic packaging labels compliant with the Legal Metrology (Packaged Commodities) Rules:
```bash
python prototype_label_maker/generate_sample.py
```
This generates compliant sample labels in PDF, SVG, and PNG formats in `prototype_label_maker/`.

---

## 🧪 Testing & Verification

### Mobile App Static Analysis & Tests
```bash
cd apps/mobile

# Run Flutter linter and static analysis
flutter analyze lib/

# Run Flutter widget & unit test suite
flutter test

# Run pure-Dart legal metrology parity tests
cd packages/legal_metrology
flutter test
```

### ML Scanner Service Verification
```bash
cd services/ml-scanner

# Test OCR extraction, bounding boxes, and parsing on a sample image
uv run python test_ocr.py product.jpeg

# Run standalone CLI compliance pipeline
uv run python -m legal_metrology_ml.main --front sample_front.jpg --back sample_back.jpg --output report.pdf

# Train / evaluate EBM model on real packaging samples
uv run python train_on_real_images.py
```

---

## 📡 API Reference Summary

| Method | Endpoint | Description |
|:---:|---|---|
| `GET` | `/health` | Service health status |
| `GET` | `/ping` / `/healthz` | Lightweight keep-alive probe for cloud hosting |
| `POST` | `/analyze` | Multi-image label compliance analysis (`multipart/form-data`) |
| `POST` | `/scan-barcode` | GS1 barcode verification and registry lookup (`application/json`) |
| `GET` | `/download/{report_id}` | Download generated compliance audit PDF |
| `GET` | `/summarize/health` | Health status of Groq LLM and Supabase summary engine |
| `POST` | `/summarize/consumer` | Generates plain-language consumer summary, health score & dye screening |
| `POST` | `/summarize/regulator` | Generates executive regulatory audit summary & formal tabular PDF |
| `GET` | `/report/{scan_id}/download`| Direct stream of regulator tabular audit PDF |
| `GET` | `/docs` | Interactive Swagger / OpenAPI documentation UI |

---

<div align="center">
  <b>Built for Smart India Hackathon 2026 | Legal Metrology Compliance Platform</b>
</div>

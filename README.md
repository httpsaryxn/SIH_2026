<div align="center">

<img src="apps/mobile/assets/images/labellens_logo.png" alt="LabelLens Logo" width="160" />

# LabelLens — Legal Metrology Compliance Platform
### Smart India Hackathon (SIH 2026)

**AI-powered packaged commodity auditing and statutory compliance automation under the Legal Metrology (Packaged Commodities) Rules, 2011.**

[![Flutter](https://img.shields.io/badge/Flutter-3.24+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.115+-009688?logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com)
[![Python](https://img.shields.io/badge/Python-3.11+-3776AB?logo=python&logoColor=white)](https://python.org)
[![Gemini](https://img.shields.io/badge/Vision_AI-Google_Gemini-4285F4?logo=google&logoColor=white)](https://ai.google.dev)
[![Groq](https://img.shields.io/badge/LLM-Groq_Cloud-F55036)](https://groq.com)
[![Supabase](https://img.shields.io/badge/Backend-Supabase-3ECF8E?logo=supabase&logoColor=white)](https://supabase.com)

</div>

---

## ⚡ Tech Stack

| Layer | Technologies |
|---|---|
| **Mobile Client** | Flutter 3.24+, Material Design 3, Google ML Kit (Text & Barcode), CameraX |
| **Backend Service** | FastAPI (async Python), Uvicorn, Astral `uv`, Pydantic v2 |
| **Computer Vision** | 5-Pass Adaptive OCR (Tesseract & EasyOCR), OpenCV, `pyzbar` |
| **Metrology & ML** | 26+ Rulebook Engine (LM(PC) Rules 2011), Explainable Boosting Machine (EBM) |
| **AI Intelligence** | Google Gemini Multimodal Vision, Groq LLM (Consumer Summaries & Food Health Audit) |
| **Storage & Data** | Supabase (PostgreSQL, Auth, Storage), GS1 India / Open Food Facts |

---

## 🏛️ System Architecture

LabelLens uses a **hybrid dual-engine architecture**:
- **Cloud Route**: Google Gemini Multimodal Vision for instant end-to-end visual parsing.
- **Local Route**: Air-gapped fallback with 5-pass OCR, physical font calibration, Explainable Boosting Machine (EBM), and 26+ deterministic statutory rule checks.
- **Barcode-First**: Instant GS1 GTIN verification against official registries without uploading photos.

```mermaid
flowchart TD
    User["User: Consumer / Regulator / Business"] -->|Capture / Scan| MobileApp["Flutter Mobile App (Google ML Kit)"]
    
    subgraph Client ["Client Device"]
        MobileApp -->|Offline Fallback| EmbeddedEngine["Pure-Dart Rules & ML Kit"]
        MobileApp -->|REST API| FastAPIGateway["FastAPI ML Scanner (:8000)"]
    end

    subgraph Backend ["Backend ML Scanner"]
        FastAPIGateway --> RouteCheck{"Has Gemini Key?"}
        
        RouteCheck -->|Yes| GeminiVision["Google Gemini Multimodal Vision"]
        RouteCheck -->|No / Offline| LocalPipeline["Local CV & Metrology Pipeline"]
        
        subgraph CV_Engine ["Local Metrology Engine"]
            LocalPipeline --> OCR["5-Pass OCR (Tesseract / EasyOCR)"]
            LocalPipeline --> Barcode["pyzbar Barcode & GS1 Decoder"]
            LocalPipeline --> FontCalib["Font Sizing (Rule 7 mm Calibration)"]
            
            OCR & Barcode & FontCalib --> Normalizer["Data Normalizer"]
            Normalizer --> EBM["Explainable Boosting Machine (EBM)"]
            Normalizer --> RuleEngine["26+ Rulebook Engine: LM(PC) Rules 2011"]
        end
        
        GeminiVision --> Aggregator["Compliance & Rating Aggregator"]
        EBM & RuleEngine --> Aggregator
        
        Aggregator --> AISummary["Groq AI Engine (Health & Audit Summary)"]
        AISummary --> PDFGen["ReportLab Legal Audit PDF"]
    end

    subgraph DataCloud ["Cloud & External Services"]
        FastAPIGateway <-->|Cache & Store| Supabase[("Supabase: PostgreSQL & Storage")]
        Barcode <-->|Validate| Registries[("GS1 India / Open Food Facts")]
    end

    PDFGen --> FastAPIGateway
    FastAPIGateway --> MobileApp
```

---

## 🔬 How Label Scanning Works

The compliance pipeline evaluates product packaging through 5 streamlined stages:

1. **Multi-Angle Ingestion**: Captures front label (PDP), back declarations, barcode crop, and optional ruler calibration scale with automated image downscaling.
2. **Barcode & GS1 Verification**: Validates EAN-13 checksums, verifies GS1 India country prefix (`890`), and cross-references canonical product registries.
3. **Adaptive OCR & Font Calibration**: Runs a 5-pass preprocessing pipeline (CLAHE, tophat, unsharp masking, inverted binary) with spatial IOU deduplication. Calibrates mm font height using ruler or barcode dimensions to verify **Rule 7** minimum font heights.
4. **Dual Compliance Engine**:
   - **Deterministic Rulebook**: Validates 26+ statutory declarations under LM(PC) Rules 2011 (MRP suffix, USP, Net Qty, Dates, Packer details, Consumer Care).
   - **Explainable ML (EBM)**: Glass-box GAM providing auditable risk factor contributions.
   - **Gemini Vision**: Multimodal visual cross-validation.
5. **AI Summaries & Legal PDF**: Groq LLM generates plain-language consumer insights and screens for hazardous food additives (synthetic dyes, palm oil, high sodium/sugar). Compiles formal tabular legal audit PDFs via ReportLab.

---

## 🚀 Quickstart

### Prerequisites
- **Python >= 3.11** (pinned to `3.14` in `.python-version`) & **[Astral uv](https://docs.astral.sh/uv/)**
- **Native packages**: `tesseract-ocr`, `libzbar-dev`
- **Flutter SDK >= 3.24.0**

### 1. ML Scanner Backend
```bash
cd services/ml-scanner
cp .env.example .env
uv sync --locked
uv run uvicorn server:app --host 0.0.0.0 --port 8000 --reload
```
- API Docs: [http://localhost:8000/docs](http://localhost:8000/docs)
- Health Check: [http://localhost:8000/health](http://localhost:8000/health)

### 2. Mobile App (Flutter)
```bash
cd apps/mobile
flutter pub get
flutter run
```
*Note: If running on an Android device over USB, run `adb reverse tcp:8000 tcp:8000` to connect to your local backend.*

---

## ⚙️ Environment Variables (`.env`)

Configure in `services/ml-scanner/.env`:

| Variable | Description | Required |
|---|---|:---:|
| `GEMINI_API_KEY` | Google Gemini API key for multimodal vision audit | Recommended |
| `GROQ_API_KEY` | Groq key for consumer health summaries & additive screening | Recommended |
| `SUPABASE_URL` | Supabase project URL for scan caching and PDF storage | Recommended |
| `SUPABASE_KEY` | Supabase Anon or Service Role key | Recommended |
| `PORT` | Local service port (Default: `8000`) | Optional |

> *Note: If API keys are omitted, the backend automatically falls back to local OCR, the EBM model, and deterministic rule evaluation.*

---

## 📡 Key API Endpoints

| Method | Endpoint | Description |
|:---:|---|---|
| `GET` | `/health` | Service health status |
| `POST` | `/analyze` | Multi-image label compliance analysis (`multipart/form-data`) |
| `POST` | `/scan-barcode` | GS1 barcode verification and registry lookup |
| `POST` | `/summarize/consumer` | Plain-language consumer summary, health score & additive screening |
| `POST` | `/summarize/regulator` | Executive regulatory audit summary & formal tabular PDF |
| `GET` | `/report/{scan_id}/download` | Direct stream of tabular legal audit PDF |
| `GET` | `/docs` | Interactive Swagger / OpenAPI documentation |

---

<div align="center">
  <b>Built for Smart India Hackathon 2026 | Legal Metrology Compliance Platform</b>
</div>

# ML Scanner Service

FastAPI microservice wrapping the Legal Metrology ML compliance pipeline.  
Analyzes packaged commodity labels under **LM(PC) Rules 2011** via:
- Multi-zone OCR & text extraction (Tesseract / EasyOCR)
- GS1 barcode verification & registry lookup
- EBM (Explainable Boosting Machine) ML model
- Deterministic rulebook engine (26+ rules)
- Gemini Vision LLM (for multimodal label analysis)
- Groq Cloud LLM (for consumer health scoring, food dye hazard screening & regulatory audit summaries)
- ReportLab tabular compliance PDF generator with Supabase Storage integration

## Prerequisites

| Dependency | Required Version / Package | Install Command |
|-----------|----------------------------|-----------------|
| Python | Pinned to `3.14` (`.python-version`), compatible `>=3.11` | System package or `uv python install 3.14` |
| [uv](https://docs.astral.sh/uv/) | `>=0.5` | `curl -LsSf https://astral.sh/uv/install.sh \| sh` |
| libzbar-dev | Native library for `pyzbar` | `sudo apt install libzbar-dev` (Debian/Ubuntu) or `pacman -S zbar` (Arch) |
| tesseract-ocr | Native OCR binary for `pytesseract` | `sudo apt install tesseract-ocr` (Debian/Ubuntu) or `pacman -S tesseract` (Arch) |

## Reproducibility & Setup

> [!IMPORTANT]
> **Strict Reproducibility**: All transitive packages and hashes are pinned in `uv.lock`.
> To guarantee an identical environment with zero version drift across team machines, you **must run `uv sync --locked`** (never run plain `uv sync` or `uv add` first).

```bash
# 1. Install locked dependencies identically (creates .venv automatically)
cd services/ml-scanner
uv sync --locked

# 2. Copy and configure environment variables
cp .env.example .env
# Edit .env and configure your GEMINI_API_KEY, GROQ_API_KEY, and SUPABASE credentials

# 3. Start the FastAPI server
uv run uvicorn server:app --host 0.0.0.0 --port 8000 --reload
```

## Environment Configuration (`.env`)

| Variable | Description | Default / Example |
|---|---|---|
| `GEMINI_API_KEY` | Google Gemini API key for multimodal vision & LLM compliance validation | `AIzaSy...` |
| `GROQ_API_KEY` | Groq API key for consumer health summaries, food dye screening & regulator summaries | `gsk_...` |
| `GROQ_MODEL` | Primary LLM model on Groq Cloud | `llama-3.3-70b-versatile` or `qwen/qwen3.8-27b` |
| `SUPABASE_URL` | Supabase project URL for summary caching & PDF storage | `https://tyshfugxmwvhbmoydlnl.supabase.co` |
| `SUPABASE_KEY` | Supabase service/anon key | `eyJhbGciOi...` |
| `PORT` | Service port | `8000` |

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/health` | Health check status (`{"status": "ok"}`) |
| `GET` | `/ping` / `/healthz` | Lightweight ping endpoint for keep-alive cron jobs |
| `POST` | `/analyze` | Analyze label images (multipart/form-data) |
| `POST` | `/scan-barcode` | Verify barcode / GTIN (JSON body) |
| `GET` | `/download/{report_id}` | Download generated PDF report |
| `GET` | `/summarize/health` | Summary generator health & config status |
| `POST` | `/summarize/consumer` | Consumer-facing health scoring & additive hazard screening |
| `POST` | `/summarize/regulator` | Executive regulatory audit summary & tabular PDF compilation |
| `GET` | `/report/{scan_id}/download` | Stream generated regulatory audit PDF |
| `GET` | `/docs` | Interactive Swagger / OpenAPI documentation |
| `GET` | `/redoc` | ReDoc API documentation |

### POST /analyze

**Form fields (multipart/form-data):**
- `front` or `front_label` — Front label image (required unless barcode_number provided)
- `back` or `curved_surface` — Back/side label image (optional, recommended)
- `ruler` or `scale_reference` — Ruler calibration image (optional)
- `barcode` — Barcode image (optional)
- `barcode_number` — Manual barcode digits (optional)
- `package_height_mm` — Package height for font calibration (optional)
- `gemini_api_key` — Gemini API key (optional; also read from `X-Gemini-Api-Key` header or `GEMINI_API_KEY` env var)

### POST /scan-barcode

**JSON body:**
```json
{
  "barcode_number": "8901234567890",
  "lookup": true
}
```

### POST /summarize/consumer

**JSON body:**
```json
{
  "product_name": "Haldiram Bhujia Sev",
  "manufacturer": "Haldiram Snacks Pvt Ltd",
  "extracted_declarations": {
    "net_quantity": "200 g",
    "mrp": "Rs. 55"
  },
  "rules": {},
  "ocr_text": "Ingredients: Gram flour, edible vegetable oil, salt, spices..."
}
```

## Testing & Quality Verification

```bash
# Test OCR extraction and parser on target image
uv run python test_ocr.py sample_image.jpg

# Train / evaluate EBM model on dataset
uv run python train_on_real_images.py

# CLI pipeline test
uv run python -m legal_metrology_ml.main --front front.jpg --back back.jpg --output test_report.pdf
```

## Architecture

```
services/ml-scanner/
├── server.py                     ← FastAPI wrapper exposing /analyze and /scan-barcode
├── pyproject.toml                ← Dependencies & project config
├── uv.lock                      ← Committed lockfile pinning exact package versions & hashes
├── .python-version               ← Python interpreter version pin (3.14)
├── .env.example                  ← Environment variable template
├── summary_gen/                  ← AI consumer summary & PDF reports
│   ├── config.py                 ← Groq and Supabase settings
│   ├── groq_client.py            ← Groq LLM consumer/regulator classifier & additive screener
│   ├── pdf_generator.py          ← ReportLab tabular compliance PDF generator
│   ├── router.py                 ← /summarize endpoints
│   └── supabase_client.py        ← Supabase Storage & DB persistence
└── legal_metrology_ml/           ← Core ML and CV metrology pipeline
    ├── main.py                   ← run_pipeline() / run_barcode_pipeline()
    ├── config.py                 ← Rule thresholds & constants
    ├── layer1_feature_extraction/← 5-pass OCR, barcode, fonts, segmentation
    ├── layer2_data_normalization/← Schema & normalizer
    ├── layer3_ml_model/          ← EBM classifier & feature builder
    ├── layer4_rulebook_engine/   ← 26+ deterministic rulebook evaluations
    ├── layer5_aggregation/       ← Scoring & report generation
    ├── llm/                      ← Gemini Vision LLM compliance engine
    └── data_sources/             ← Product registry lookup (Open Food Facts, GS1 India)
```

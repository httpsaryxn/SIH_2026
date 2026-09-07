# ML Scanner Service

FastAPI microservice wrapping the Legal Metrology ML compliance pipeline.  
Analyzes packaged commodity labels under **LM(PC) Rules 2011** via:
- Multi-zone OCR & text extraction (Tesseract / EasyOCR)
- GS1 barcode verification & registry lookup
- EBM (Explainable Boosting Machine) ML model
- Deterministic rulebook engine (26+ rules)
- Gemini Vision LLM (optional, for multimodal label analysis)

## Prerequisites

| Dependency | Required Version / Package | Install Command |
|-----------|----------------------------|-----------------|
| Python | Pinned to `3.14` (`.python-version`), compatible `>=3.11` | System package or `uv python install 3.14` |
| [uv](https://docs.astral.sh/uv/) | `>=0.5` | `curl -LsSf https://astral.sh/uv/install.sh \| sh` |
| libzbar-dev | Native library for `pyzbar` | `sudo apt install libzbar-dev` (Debian/Ubuntu) or `pacman -S zbar` (Arch) |
| tesseract-ocr | Native OCR binary for `pytesseract` | `sudo apt install tesseract-ocr` (Debian/Ubuntu) or `pacman -S tesseract` (Arch) |

## Reproducibility & Setup

> [!IMPORTANT]
> **Strict Reproducibility**: The source repo used loose `>=` bounds for its dependencies. All transitive packages and hashes have been locked in `uv.lock`.
> To guarantee an identical environment with zero version drift across team machines, you **must run `uv sync --locked`** (never run plain `uv sync` or `uv add` first).

```bash
# 1. Install locked dependencies identically (creates .venv automatically)
cd services/ml-scanner
uv sync --locked

# 2. Copy and configure environment variables
cp .env.example .env
# Edit .env and set your GEMINI_API_KEY if using LLM analysis (never commit .env)

# 3. Start the FastAPI server
uv run uvicorn server:app --host 0.0.0.0 --port 8000 --reload
```

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/health` | Health check (`{"status": "ok"}`) |
| `POST` | `/analyze` | Analyze label images (multipart/form-data) |
| `POST` | `/scan-barcode` | Verify barcode / GTIN (JSON body) |
| `GET` | `/download/{report_id}` | Download generated PDF report |
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

## Architecture

```
services/ml-scanner/
├── server.py                     ← Thin FastAPI wrapper calling verbatim pipeline
├── pyproject.toml                ← Dependencies & project config
├── uv.lock                      ← Committed lockfile pinning 142 exact package versions & hashes
├── .python-version               ← Python interpreter version pin (3.14)
├── .env.example                  ← Environment variable template (safe placeholder)
└── legal_metrology_ml/           ← ML pipeline copied VERBATIM from source repo
    ├── main.py                   ← run_pipeline() / run_barcode_pipeline()
    ├── config.py                 ← Rule thresholds & constants
    ├── layer1_feature_extraction/← OCR, barcode, fonts, segmentation
    ├── layer2_data_normalization/← Schema & normalizer
    ├── layer3_ml_model/          ← EBM classifier & feature builder
    ├── layer4_rulebook_engine/   ← Deterministic rule evaluation
    ├── layer5_aggregation/       ← Scoring & report generation
    ├── llm/                      ← Gemini LLM compliance engine
    └── data_sources/             ← Product registry lookup
```

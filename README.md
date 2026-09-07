# LabelLens — Legal Metrology Compliance Platform (SIH 2026)

Full-stack solution for packaged commodity compliance under the **Legal Metrology (Packaged Commodities) Rules, 2011**, connecting Consumers, Small Businesses, Enterprise Manufacturers, and Regulatory Authorities.

---

## Architecture Overview

- **Mobile App (`apps/mobile`)**: Cross-platform Flutter client for Android, iOS, and Web. Supports AI label scanning, Legal Metrology compliance auditing, consumer complaint filing, and small business label design studio.
- **ML Scanner Service (`services/ml-scanner`)**: High-performance FastAPI microservice wrapping the compliance evaluation pipeline (multi-zone OCR, GS1 barcode lookup, Explainable Boosting Machine (EBM) ML model, 26+ deterministic rulebook checks, and Gemini Vision LLM analysis).
- **Backend & Database (`supabase`)**: Managed Supabase backend with PostgreSQL, Row-Level Security (RLS), Supabase Auth, and Storage buckets for multi-angle label captures.

---

## Environment & Configuration (`.env`) Requirements

### 1. ML Scanner Service (`services/ml-scanner/.env`)

The ML Scanner service requires an environment file located at `services/ml-scanner/.env`.

Copy the provided template:
```bash
cp services/ml-scanner/.env.example services/ml-scanner/.env
```

Configure the following variables in `services/ml-scanner/.env`:

| Variable | Description | Required | Default / Example |
|---|---|---|---|
| `GEMINI_API_KEY` | Google Gemini API key for multimodal vision & LLM compliance validation | Recommended | `AIzaSy...` |

> [!NOTE]
> If `GEMINI_API_KEY` is not configured, the service falls back gracefully to local OCR (Tesseract / EasyOCR) and the deterministic 26+ rulebook engine.

### 2. Mobile App (`apps/mobile/.env` or compile-time config)

For local development or custom deployments, a template is provided at `apps/mobile/.env.example`:
```bash
cp apps/mobile/.env.example apps/mobile/.env
```

| Variable | Description | Default / Example |
|---|---|---|
| `SUPABASE_URL` | Supabase project URL | Configured in `lib/core/config/supabase_config.dart` |
| `SUPABASE_ANON_KEY` | Supabase public anonymous key | Configured in `lib/core/config/supabase_config.dart` |
| `SUPABASE_PUBLISHABLE_KEY` | Supabase publishable key | Configured in `lib/core/config/supabase_config.dart` |
| `BACKEND_BASE_URL` | ML Scanner FastAPI endpoint | Default: `http://127.0.0.1:8000` (auto-probed) |

> [!TIP]
> The mobile app automatically resolves and health-probes candidate backend URLs (`http://127.0.0.1:8000`, `http://10.0.2.2:8000` for Android emulator, and workstation LAN IPs for physical devices over Wi-Fi).

---

## Running the Services

### Prerequisites

- **Python**: `>= 3.11` (pinned to `3.14` in `.python-version`)
- **[uv](https://docs.astral.sh/uv/)**: Fast Python package manager (`curl -LsSf https://astral.sh/uv/install.sh | sh`)
- **Native ML Libraries**:
  - Ubuntu/Debian: `sudo apt install -y libzbar-dev tesseract-ocr`
  - macOS: `brew install zbar tesseract`
  - Arch Linux: `sudo pacman -S zbar tesseract`
- **Flutter SDK**: `>= 3.24.0` with Android SDK / Xcode / Chrome tools

---

### Step 1: Start the ML Scanner FastAPI Service

1. Navigate to the service directory:
   ```bash
   cd services/ml-scanner
   ```

2. Install pinned dependencies deterministically:
   ```bash
   uv sync --locked
   ```

3. Ensure your `.env` is configured:
   ```bash
   cp -n .env.example .env
   ```

4. Start the Uvicorn server:
   ```bash
   uv run uvicorn server:app --host 0.0.0.0 --port 8000 --reload
   ```

   - **Health Check**: [http://localhost:8000/health](http://localhost:8000/health)
   - **Interactive Swagger Docs**: [http://localhost:8000/docs](http://localhost:8000/docs)
   - **ReDoc**: [http://localhost:8000/redoc](http://localhost:8000/redoc)

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

3. **If running on a physical Android device via USB**:
   Forward port `8000` so your device can communicate with the host machine's Uvicorn server:
   ```bash
   adb reverse tcp:8000 tcp:8000
   ```

4. Launch the application:
   ```bash
   # Run on connected Android / iOS device or emulator
   flutter run

   # Or run specifically targeting a device / desktop / web
   flutter run -d chrome
   flutter run -d <device-id>
   ```

---

## Testing & Quality Verification

From `apps/mobile`:
```bash
# Run static analysis
flutter analyze lib/

# Run unit and widget test suite
flutter test
```

From `services/ml-scanner`:
```bash
# Verify OCR and pipeline imports
uv run python test_ocr.py
```

import os
from pathlib import Path
from dotenv import load_dotenv

# Try loading .env from parent directory (services/ml-scanner/.env) or local
parent_env = Path(__file__).resolve().parent.parent / ".env"
local_env = Path(__file__).resolve().parent / ".env"

if parent_env.exists():
    load_dotenv(dotenv_path=parent_env)
elif local_env.exists():
    load_dotenv(dotenv_path=local_env)
else:
    load_dotenv()

class Settings:
    GROQ_API_KEY: str = os.environ.get("GROQ_API_KEY", "")
    GROQ_MODEL: str = os.environ.get("GROQ_MODEL", "qwen/qwen3.8-27b")
    GROQ_FALLBACK_MODELS: list[str] = [
        "qwen/qwen3.8-27b",
        "groq/compound",
        "groq/compound-mini",
    ]
    
    SUPABASE_URL: str = os.environ.get("SUPABASE_URL", "https://tyshfugxmwvhbmoydlnl.supabase.co")
    SUPABASE_KEY: str = os.environ.get("SUPABASE_KEY", os.environ.get("SUPABASE_SERVICE_ROLE_KEY", ""))
    
    PORT: int = int(os.environ.get("PORT", "8000"))

settings = Settings()

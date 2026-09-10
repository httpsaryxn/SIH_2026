import os
from pathlib import Path
from dotenv import load_dotenv

# Load local .env if present
env_path = Path(__file__).parent / ".env"
if env_path.exists():
    load_dotenv(dotenv_path=env_path)
else:
    load_dotenv()

class Settings:
    GROQ_API_KEY: str = os.environ.get("GROQ_API_KEY", "")
    GROQ_MODEL: str = os.environ.get("GROQ_MODEL", "qwen/qwen3.8-27b")
    GROQ_FALLBACK_MODELS: list[str] = [
        "qwen/qwen3.8-27b",
        "openai/gpt-oss-120b",
        "llama-3.3-70b-versatile",
        "groq/compound",
    ]
    
    SUPABASE_URL: str = os.environ.get("SUPABASE_URL", "https://tyshfugxmwvhbmoydlnl.supabase.co")
    SUPABASE_KEY: str = os.environ.get("SUPABASE_KEY", os.environ.get("SUPABASE_SERVICE_ROLE_KEY", ""))
    
    PORT: int = int(os.environ.get("PORT", "8001"))

settings = Settings()

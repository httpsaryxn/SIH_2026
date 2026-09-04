import os
from pathlib import Path
from dotenv import load_dotenv

# Load .env file from project root if present
env_path = Path(__file__).resolve().parent.parent.parent / ".env"
load_dotenv(dotenv_path=env_path)


class Settings:
    PROJECT_NAME: str = "SIH 2026 Small Business API"
    VERSION: str = "1.0.0"
    API_V1_STR: str = "/api/v1"
    
    SUPABASE_URL: str = os.getenv("SUPABASE_URL", "https://tyshfugxmwvhbmoydlnl.supabase.co")
    SUPABASE_KEY: str = os.getenv(
        "SUPABASE_KEY",
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR5c2hmdWd4bXd2aGJtb3lkbG5sIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODc4NDkzMDQsImV4cCI6MjEwMzQyNTMwNH0.URx0CbCB5qqRk_S3gUTIG8h2xevzrruGwmPYQYqCAik"
    )
    SUPABASE_PUBLISHABLE_KEY: str = os.getenv(
        "SUPABASE_PUBLISHABLE_KEY",
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR5c2hmdWd4bXd2aGJtb3lkbG5sIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODc4NDkzMDQsImV4cCI6MjEwMzQyNTMwNH0.URx0CbCB5qqRk_S3gUTIG8h2xevzrruGwmPYQYqCAik"
    )


settings = Settings()

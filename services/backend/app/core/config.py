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
    
    SUPABASE_URL: str = os.getenv("SUPABASE_URL", "https://juthxodcpmlrcphnjihc.supabase.co")
    SUPABASE_KEY: str = os.getenv(
        "SUPABASE_KEY",
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp1dGh4b2RjcG1scmNwaG5qaWhjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODc5ODY1OTcsImV4cCI6MjEwMzU2MjU5N30.AypIEimyFQMZWuyMIaOtva2__BpX1WGfYBDVt7WiNoc"
    )
    SUPABASE_PUBLISHABLE_KEY: str = os.getenv(
        "SUPABASE_PUBLISHABLE_KEY",
        "sb_publishable_GHtjFJFIsAJ9OustSIMWdw_f9j1ZFxc"
    )


settings = Settings()

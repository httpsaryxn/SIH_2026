from fastapi import FastAPI
from pydantic import BaseModel, Field
from typing import Dict, Any
from app.core.supabase import check_supabase_connection
from app.api.v1.endpoints.small_business_labels import router as small_business_router

app = FastAPI(
    title="SIH 2026 Small Business API",
    description="Backend service for Smart India Hackathon 2026 - Small Business Label Studio, FSSAI & Legal Metrology Compliance, and Supabase integration.",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

# Include Small Business endpoints
app.include_router(small_business_router, prefix="/api/v1")


class RootResponse(BaseModel):
    message: str = Field(..., example="Welcome to SIH 2026 Backend API")
    status: str = Field(..., example="online")
    version: str = Field(..., example="1.0.0")
    docs: str = Field(..., example="/docs")
    redoc: str = Field(..., example="/redoc")


class HealthResponse(BaseModel):
    status: str = Field(..., example="ok")
    details: Dict[str, Any] = Field(
        default_factory=lambda: {"service": "backend", "alive": True}
    )


@app.get(
    "/",
    response_model=RootResponse,
    summary="Root Endpoint",
    tags=["General"],
)
def read_root():
    return {
        "message": "Welcome to SIH 2026 Small Business API",
        "status": "online",
        "version": "1.0.0",
        "docs": "/docs",
        "redoc": "/redoc",
    }


@app.get(
    "/health",
    response_model=HealthResponse,
    summary="Health Check",
    tags=["System"],
)
def health_check():
    supabase_status = check_supabase_connection()
    return {
        "status": "ok",
        "details": {
            "service": "backend",
            "alive": True,
            "supabase": supabase_status,
        },
    }

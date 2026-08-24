from fastapi import FastAPI
from pydantic import BaseModel, Field
from typing import Dict, Any

app = FastAPI(
    title="SIH 2026 Backend API",
    description="Backend service for Smart India Hackathon 2026 - Food & Ingredient Analysis with Barcode and OCR support.",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
)


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
        "message": "Welcome to SIH 2026 Backend API",
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
    return {
        "status": "ok",
        "details": {"service": "backend", "alive": True},
    }

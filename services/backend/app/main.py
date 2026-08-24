from fastapi import FastAPI

app = FastAPI(title="SIH 2026 Backend")

@app.get("/health")
def health_check():
    return {"status": "ok"}

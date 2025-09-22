import os
from fastapi import FastAPI
from pydantic import BaseModel

app = FastAPI()

class ReconciliationReq(BaseModel):
    settlement_date: str
    processor: str

@app.get("/health")
async def health():
    return "ok"

@app.post("/v1/reconcile", status_code=200)
async def reconcile(payload: ReconciliationReq):
    reconciled = True
    discrepancies = []
    
    return {
        "reconciled": reconciled,
        "discrepancies": discrepancies,
        "total_amount": 0.0,
        "processor_amount": 0.0
    }

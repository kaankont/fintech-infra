import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

app = FastAPI()

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class RiskAssessmentReq(BaseModel):
    user_id: str
    transaction_amount: float
    merchant_category: str

@app.get("/health")
async def health():
    return "ok"

@app.post("/v1/assess", status_code=200)
async def assess_risk(payload: RiskAssessmentReq):
    risk_score = 0.1
    approved = True
    
    return {
        "risk_score": risk_score,
        "approved": approved,
        "reason": "Low risk transaction"
    }

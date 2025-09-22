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

class ComplianceCheckReq(BaseModel):
    user_id: str
    transaction_amount: float
    transaction_type: str

@app.get("/health")
async def health():
    return "ok"

@app.post("/v1/check", status_code=200)
async def check_compliance(payload: ComplianceCheckReq):
    compliant = True
    flags = []
    
    return {
        "compliant": compliant,
        "flags": flags,
        "requires_review": False
    }

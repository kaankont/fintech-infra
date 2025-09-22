import os
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field, constr
from sqlalchemy import create_engine, text
from sqlalchemy.orm import Session

DATABASE_URL = os.getenv("DATABASE_URL", "postgresql+psycopg://postgres:postgres@postgres:5432/fintech")
engine = create_engine(DATABASE_URL, pool_pre_ping=True)

app = FastAPI()

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class PostingReq(BaseModel):
    debit_account: int
    credit_account: int
    amount: float = Field(gt=0)
    currency: constr(min_length=3, max_length=3) = "USD"
    ref: str | None = None

@app.get("/health")
def health():
    with engine.connect() as c:
        c.execute(text("select 1"))
    return "ok"

@app.post("/v1/postings", status_code=201)
def create_posting(p: PostingReq):
    with Session(engine) as s:
        # Idempotency check
        if p.ref:
            exists = s.execute(text("select 1 from postings where ref=:r limit 1"), {"r": p.ref}).first()
            if exists:
                return {"status": "already_posted"}

        s.execute(text("""
            insert into postings (debit_account, credit_account, amount, currency, ref)
            values (:d,:c,:a,:cur,:r)
        """), {"d": p.debit_account, "c": p.credit_account, "a": p.amount, "cur": p.currency, "r": p.ref})
        s.commit()
    return {"status": "posted"}

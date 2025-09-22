import os, asyncio, json
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import httpx
from aiokafka import AIOKafkaProducer

LEDGER_URL = os.getenv("LEDGER_URL", "http://ledger:8080")
KAFKA_BROKERS = os.getenv("KAFKA_BROKERS", "kafka:9092")
TOPIC = os.getenv("KAFKA_TOPIC", "postings")

app = FastAPI()

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allows all origins
    allow_credentials=True,
    allow_methods=["*"],  # Allows all methods
    allow_headers=["*"],  # Allows all headers
)

producer: AIOKafkaProducer | None = None

class IssueCardReq(BaseModel):
    user_id: str
    product_id: str

@app.on_event("startup")
async def setup():
    global producer
    try:
        producer = AIOKafkaProducer(bootstrap_servers=KAFKA_BROKERS.split(","))
        await producer.start()
    except Exception as e:
        print(f"Warning: Could not connect to Kafka: {e}")
        producer = None

@app.on_event("shutdown")
async def teardown():
    if producer:
        await producer.stop()

@app.get("/health")
async def health():
    return "ok"

@app.post("/v1/cards", status_code=201)
async def issue_card(payload: IssueCardReq):
    # Create a $5 signup posting in ledger
    async with httpx.AsyncClient(timeout=5) as client:
        await client.post(f"{LEDGER_URL}/v1/postings", json={
            "debit_account": 1,
            "credit_account": 2,
            "amount": 5.00,
            "currency": "USD",
            "ref": f"signup-{payload.user_id}"
        })

    # Emit posting event (for rewards)
    val = json.dumps({
        "debit_account": 1, "credit_account": 2,
        "amount": 5.00, "currency": "USD",
        "ref": f"signup-{payload.user_id}"
    }).encode()
    if producer:
        try:
            await producer.send_and_wait(TOPIC, key=payload.user_id.encode(), value=val)
        except Exception as e:
            print(f"Warning: Could not send to Kafka: {e}")

    return {"card_id": f"card_{payload.user_id}"}

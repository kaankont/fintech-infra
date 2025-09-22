import os, asyncio, json, logging
from aiokafka import AIOKafkaConsumer
from sqlalchemy import create_engine, text

KAFKA_BROKERS = os.getenv("KAFKA_BROKERS", "kafka:9092")
TOPIC = os.getenv("KAFKA_TOPIC", "postings")
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql+psycopg://postgres:postgres@postgres:5432/fintech")

engine = create_engine(DATABASE_URL, pool_pre_ping=True)
logging.basicConfig(level=logging.INFO)

async def consume():
    consumer = AIOKafkaConsumer(
        TOPIC,
        bootstrap_servers=KAFKA_BROKERS.split(","),
        group_id="rewards-consumer",
        enable_auto_commit=True,
    )
    await consumer.start()
    try:
        async for msg in consumer:
            user_id = (msg.key or b"").decode() or "unknown"
            p = json.loads(msg.value.decode())
            points = float(p.get("amount", 0)) * 0.01  # 1% points
            with engine.begin() as conn:
                conn.execute(
                    text("insert into rewards_ledger (user_id, points, posting_ref) values (:u,:pts,:r)"),
                    {"u": user_id, "pts": points, "r": p.get("ref")}
                )
            logging.info("accrued %.4f points for user=%s ref=%s", points, user_id, p.get("ref"))
    finally:
        await consumer.stop()

if __name__ == "__main__":
    asyncio.run(consume())

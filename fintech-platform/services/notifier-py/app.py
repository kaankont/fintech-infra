import os
from fastapi import FastAPI
from pydantic import BaseModel

app = FastAPI()

class NotificationReq(BaseModel):
    user_id: str
    event_type: str
    message: str
    channel: str  # email, sms, push

@app.get("/health")
async def health():
    return "ok"

@app.post("/v1/notify", status_code=200)
async def send_notification(payload: NotificationReq):
    sent = True
    delivery_id = f"notif_{payload.user_id}_{payload.event_type}"
    
    return {
        "sent": sent,
        "delivery_id": delivery_id,
        "channel": payload.channel
    }

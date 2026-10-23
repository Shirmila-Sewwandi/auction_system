from pydantic import BaseModel


class PaymentCreate(BaseModel):
    auction_result_id: int
    payment_method: str = "simulated"


class ConfirmReceiptRequest(BaseModel):
    received: bool

from fastapi import FastAPI
from pydantic import BaseModel
import pandas as pd
import joblib


app = FastAPI()

model = joblib.load("anomaly_model.joblib")


class Transaction(BaseModel):
    transaction_amount: float
    average_transaction_amount: float
    transactions_last_hour: int
    country_risk_score: float
    transaction_hour: int


@app.get("/health")
def health():
    return {"status": "healthy"}


@app.get("/model-info")
def model_info():
    return {
        "model": "IsolationForest",
        "features": 5
    }


@app.post("/predict-risk")
def predict_risk(transaction: Transaction):

    transaction_data = pd.DataFrame([
        {
            "transaction_amount": transaction.transaction_amount,
            "average_transaction_amount": transaction.average_transaction_amount,
            "transactions_last_hour": transaction.transactions_last_hour,
            "country_risk_score": transaction.country_risk_score,
            "transaction_hour": transaction.transaction_hour
        }
    ])

    prediction = model.predict(transaction_data)[0]

    score = model.decision_function(transaction_data)[0]

    result = "anomaly" if prediction == -1 else "normal"

    return {
        "prediction": result,
        "anomaly_score": float(score)
    }
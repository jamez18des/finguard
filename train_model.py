import pandas as pd
import joblib
from sklearn.ensemble import IsolationForest

data = pd.read_csv("transactions.csv")

features = data[
    [
        "transaction_amount",
        "average_transaction_amount",
        "transactions_last_hour",
        "country_risk_score",
        "transaction_hour",
    ]
]

model = IsolationForest(random_state=42)

model.fit(features)
joblib.dump(model, "anomaly_model.joblib")

predictions = model.predict(features)

print("Normal:", (predictions == 1).sum())
print("Anomalies:", (predictions == -1).sum())

scores = model.decision_function(features)

print("First 5 anomaly scores:")
print(scores[:5])

new_transaction = pd.DataFrame(
    [
        {
            "transaction_amount": 4500,
            "average_transaction_amount": 100,
            "transactions_last_hour": 9,
            "country_risk_score": 0.9,
            "transaction_hour": 2,
        }
    ]
)

new_prediction = model.predict(new_transaction)

print("New transaction prediction:")
print (new_prediction)
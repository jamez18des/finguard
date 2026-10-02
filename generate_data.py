import pandas as pd
import numpy as np


data = {
    "transaction_amount": np.random.uniform(5, 500, 100),
    "average_transaction_amount": np.random.uniform(10, 1000, 100),
    "transactions_last_hour": np.random.randint(1, 11, 100),
    "country_risk_score": np.random.uniform(0, 1, 100),
    "transaction_hour": np.random.randint(0, 24, 100)
}


df = pd.DataFrame(data)

df.to_csv("transactions.csv", index=False)

print(df.head())

loaded_data = pd.read_csv("transactions.csv")

print(loaded_data.head())
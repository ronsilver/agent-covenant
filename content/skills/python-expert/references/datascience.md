# Python Data Science & Notebooks (Generic)

## pandas — Vectorization over loops (100x perf)

```python
import pandas as pd

# NEVER (slow)
for idx, row in df.iterrows():
    df.at[idx, "fee"] = row["amount"] * 0.035

# ALWAYS (fast)
df["fee"] = df["amount"] * 0.035
```

## scikit-learn Pipeline

```python
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler
from sklearn.ensemble import RandomForestClassifier

pipeline = Pipeline([
    ("scaler", StandardScaler()),
    ("classifier", RandomForestClassifier(n_estimators=100)),
])
pipeline.fit(X_train, y_train)
joblib.dump(pipeline, "model.pkl")
```

## Jupyter Best Practices

```python
# First cell: version pinning
import sys; print(sys.version)

# jupytext sync: .py mirror file auto-generated
# nbconvert for CI:
# jupyter nbconvert --to script notebook.ipynb --output output.py

# NEVER secrets in notebooks:
api_key = os.environ["API_KEY"]  # env var only
```

## this project ML Projects

| Repo | Purpose |
|---|---|
| `Merlin` | Predictive models |
| `FORECAST` | Time-series forecasting |
| `correlation_model` | Correlation analysis |
| `Organizador_Met_Pago` | Payment method optimization |

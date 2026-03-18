# Life Expectancy Prediction using Linear Regression

## Mission & Problem Description
This project predicts **Life Expectancy** of countries using socioeconomic and health indicators from the WHO.
Poor healthcare investment, high disease burden, and low income are key drivers of reduced life expectancy globally.
By modeling these relationships, we aim to help policymakers identify which factors most impact population health outcomes.
Dataset source: [WHO Life Expectancy — Kaggle](https://www.kaggle.com/datasets/kumarajarshi/life-expectancy-who) — 193 countries, 2938 rows, 22 columns (2000–2015).

---

## Project Structure

```
linear_regression_model/
├── summative/
│   └── linear_regression/
│       ├── multivariate.ipynb        # notebook  
│       ├── Life Expectancy Data.csv  # the raw dataset
│       └── saved_models/
│           ├── best_model.pkl        # the saved best performing model
│           └── scaler.pkl            # StandardScaler used during training
└── README.md
```

---

## Models Used

| Model             | R² Score   | RMSE       |
|-------------------|------------|------------|
| Linear Regression | 0.8124     | 4.0313     |
| Decision Tree     | 0.9266     | 2.5219     |
| **Random Forest** | **0.9684** | **1.6548** |

**Best Model: Random Forest** — saved to `saved_models/best_model.pkl`

---

## How to Run

1. Clone the repository
2. Install dependencies:
   ```bash
   pip install pandas numpy scikit-learn matplotlib seaborn kaggle
   ```
3. Open `summative/linear_regression/multivariate.ipynb`
4. Run all cells

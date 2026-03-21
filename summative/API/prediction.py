# Libraries to be used
import pickle
import os
import io
import numpy as np
import pandas as pd
from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from sklearn.ensemble import RandomForestRegressor
from sklearn.preprocessing import StandardScaler
from sklearn.model_selection import train_test_split
from sklearn.metrics import r2_score, mean_squared_error

# Loading the ML model 
# Paths to this prediction file and trained ML model
API_DIR = os.path.dirname(os.path.abspath(__file__))
MODELS_DIR = os.path.join(API_DIR, "..", "linear_regression", "saved_models")

with open(os.path.join(MODELS_DIR, "best_model.pkl"), "rb") as file1:
    model = pickle.load(file1)

with open(os.path.join(MODELS_DIR, "scaler.pkl"), "rb") as file2:
    scaler = pickle.load(file2)

# scaler.feature_names_in_ holds the 18 column names it was trained on
feature_selected = scaler.feature_names_in_.tolist()

# initializing the app
app = FastAPI(
    title="Life Expectancy Prediction API",
    description="Predicts life expectancy (in years) based on WHO health and socioeconomic indicators using a trained Machine Learning model.",
    version="1.0.0"
)

# Pydantic input model with structure of incoming prediction requests.
# ge = greater than or equal, le = less than or equal based on dataset statistics
class PredictionInput(BaseModel):
    Adult_Mortality:      float = Field(..., ge=1.0,  le=723.0,        example=164.0,     description="Adult mortality rate per 1000 population")
    Alcohol:              float = Field(..., ge=0.0,  le=18.0,         example=4.6,       description="Alcohol consumption in litres per capita")
    Pct_Expenditure:      float = Field(..., ge=0.0,  le=19480.0,      example=738.0,     description="Health expenditure as (%) of GDP per capita")
    Hepatitis_B:          float = Field(..., ge=1.0,  le=99.0,         example=82.0,      description="Hepatitis B immunization coverage (%)")
    Measles:              int   = Field(..., ge=0,    le=212183,       example=17,        description="Reported measles cases per 1000 population")
    BMI:                  float = Field(..., ge=1.0,  le=88.0,         example=38.3,      description="Average BMI of the population")
    Under5_Deaths:        int   = Field(..., ge=0,    le=2500,         example=4,         description="Under-5 deaths per 1000 population")
    Polio:                float = Field(..., ge=3.0,  le=99.0,         example=83.0,      description="Polio immunization coverage (%)")
    Total_Exp:            float = Field(..., ge=0.0,  le=18.0,         example=5.9,       description="Total health expenditure as (%) of GDP")
    Diphtheria:           float = Field(..., ge=2.0,  le=99.0,         example=82.0,      description="Diphtheria immunization coverage (%)")
    HIV_AIDS:             float = Field(..., ge=0.1,  le=50.6,         example=0.1,       description="HIV/AIDS deaths per 1000 live births (0-4 years)")
    GDP:                  float = Field(..., ge=1.0,  le=119173.0,     example=7483.0,    description="GDP per capita in USD")
    Population:           float = Field(..., ge=34.0, le=1293859294.0, example=1386542.0, description="Country population")
    Thinness_1_19:        float = Field(..., ge=0.1,  le=27.7,         example=4.8,       description="Thinness prevalence among ages 1-19 (%)")
    Thinness_5_9:         float = Field(..., ge=0.1,  le=28.6,         example=4.9,       description="Thinness prevalence among ages 5-9 (%)")
    Income_Composition:   float = Field(..., ge=0.0,  le=0.948,        example=0.63,      description="Human Development Index income composition (0-1)")
    Schooling:            float = Field(..., ge=0.0,  le=20.7,         example=12.0,      description="Number of years of schooling")
    Status_Developing:    int   = Field(..., ge=0,    le=1,            example=1,         description="Country status: 1 = Developing, 0 = Developed")


# CORS middleware
# Allowing any browser to run the API
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# GET request for health check '/'
@app.get("/")
def health_check():
    return {
        "status": "online",
        "message": "Life Expectancy Prediction API is running",
        "model": type(model).__name__,
        "features_count": len(feature_selected)
    }

# GET request'/features' 
# Returns exact 18 features the model expects, so clients can recognise what to send
@app.get("/features")
def get_features():
    return {
        "features": feature_selected,
        "count": len(feature_selected)
    }

# POST '/predict' to Predict life expectancy
# Accepts 18 input features, scales them, runs the model, returns the prediction
@app.post("/predict")
def predict(data: PredictionInput):
    # Convert input to DataFrame to column order
    input_data = pd.DataFrame([data.model_dump()])[feature_selected]

    # Scale using the same scaler fitted during training
    input_scaled = scaler.transform(input_data)

    # Predict and clamp to realistic life expectancy range
    prediction = model.predict(input_scaled)[0]
    prediction = float(np.clip(prediction, 30, 100))

    return {
        "predicted_life_expectancy_years": round(prediction, 2),
        "model_used": type(model).__name__
    }

# POST '/retrain' , Retrain on new csv data
# Accepts a CSV file, runs the same preprocessing as the notebook, retrains the model
@app.post("/retrain")
async def retrain(file: UploadFile = File(...)):
    global model, scaler, feature_selected

    # Read uploaded CSV as DataFrame
    content = await file.read()
    data = pd.read_csv(io.StringIO(content.decode("utf-8")))

    # Preprocessing, same steps as on the notebook
    data.columns = data.columns.str.strip()
    data.rename(columns={
        'Life expectancy': 'Life_Expectancy',
        'Adult Mortality': 'Adult_Mortality',
        'infant deaths': 'Infant_Deaths',
        'percentage expenditure': 'Pct_Expenditure',
        'Hepatitis B': 'Hepatitis_B',
        'under-five deaths': 'Under5_Deaths',
        'Total expenditure': 'Total_Exp',
        'HIV/AIDS': 'HIV_AIDS',
        'thinness  1-19 years': 'Thinness_1_19',
        'thinness 5-9 years': 'Thinness_5_9',
        'Income composition of resources': 'Income_Composition',
    }, inplace=True)

    # Fill missing values with mean 
    for col in data.select_dtypes(include=np.number).columns:
        data[col] = data[col].fillna(data[col].mean())

    # Drop irrelevant columns
    data.drop(columns=['Country', 'Year'], inplace=True, errors='ignore')

    # Encode column 'Status' (1=Developing, 0=Developed)
    if 'Status' in data.columns:
        data = pd.get_dummies(data, columns=['Status'], drop_first=True, dtype=int)

    # Drop Infant_Deaths because of multicollinear with Under5_Deaths
    data.drop(columns=['Infant_Deaths'], inplace=True, errors='ignore')

    if 'Life_Expectancy' not in data.columns:
        raise HTTPException(
            status_code=400, 
            detail="CSV must contain a 'Life expectancy' column.")

    X = data.drop(columns=['Life_Expectancy'])
    y = data['Life_Expectancy']

    # Train/test split, scale, retrain
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
    new_scaler = StandardScaler()
    X_train_scaled = new_scaler.fit_transform(X_train)
    X_test_scaled  = new_scaler.transform(X_test)

    new_model = RandomForestRegressor(n_estimators=100, random_state=42)
    new_model.fit(X_train_scaled, y_train)

    # Evaluate
    y_pred = new_model.predict(X_test_scaled)
    r2   = round(float(r2_score(y_test, y_pred)), 4)
    rmse = round(float(np.sqrt(mean_squared_error(y_test, y_pred))), 4)

    # Overwrite saved model files
    with open(os.path.join(MODELS_DIR, "best_model.pkl"), "wb") as f:
        pickle.dump(new_model, f)
    with open(os.path.join(MODELS_DIR, "scaler.pkl"), "wb") as f:
        pickle.dump(new_scaler, f)

    # Update globals, '/predict' will use new model immediately
    model = new_model
    scaler = new_scaler
    feature_selected = new_scaler.feature_names_in_.tolist()

    return {
        "status": "retrain was done successfully",
        "r2_score": r2,
        "rmse": rmse,
        "trained_on_rows": len(X_train),
        "features": feature_selected
    }
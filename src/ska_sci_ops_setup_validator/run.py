import os
from typing import Dict

import uvicorn
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

from ska_sci_ops_setup_validator import validate


class ModeSettings(BaseModel):
    continuum: bool
    zoom: bool
    pss: bool
    pst: bool


class ContinuumSettings(BaseModel):
    centralFrequency: float
    bandwidth: float
    channelWidth: float
    enabled: bool


class ZoomSettings(BaseModel):
    numberOfZoomChannels: str
    zoomMode: str
    enabled: bool


class PssSettings(BaseModel):
    numberOfBeams: int
    centralFrequency: str
    bandwidth: str
    enabled: bool


class PstSettings(BaseModel):
    timingModeBeams: int
    dynamicSpectrumBeams: int
    flowthroughModeBeams: int
    centralFrequency: str
    bandwidth: str
    enabled: bool


class SubarraySettings(BaseModel):
    template: str
    band: str
    modes: Dict[str, ModeSettings]
    continuumSettings: Dict[str, ContinuumSettings]
    zoomSettings: Dict[str, ZoomSettings]
    pssSettings: Dict[str, PssSettings]
    pstSettings: Dict[str, PstSettings]


class RequestData(BaseModel):
    context: str
    telescopeType: str
    subarrays: Dict[str, SubarraySettings]


app = FastAPI()

# Set up CORS
origins = [
    "http://localhost",
    "http://localhost:8090",  # If your frontend runs on port 3000
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,  # Allows all the origins in the list
    allow_credentials=True,
    allow_methods=["*"],  # Allows all methods (GET, POST, etc.)
    allow_headers=["*"],  # Allows all headers
)


@app.post("/validate/")
async def process_data(request: RequestData):
    data = request.dict()
    response = validate.validate(data)
    return response


if __name__ == "__main__":
    # Get host and port from environment variables with defaults
    host = os.environ.get("HOST", "127.0.0.1")
    port = int(os.environ.get("PORT", 8001))

    # Run the application with uvicorn
    uvicorn.run(app, host=host, port=port)

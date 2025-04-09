# prototype_setup_validator_backend
Backend for prototype_setup_validator_ui

## Installation instruction for development

Dependencies are managed using `poetry`. You will need to the following steps to setup the development environment.

```bash
git clone git@github.com:ska-sci-ops/prototype_setup_validator_backend.git
cd prototype_setup_validator_backend
poetry env use python3.12
poetry shell
poetry install
```

You should now have a shell with all the dependencies installed. 

If you update the dependencies in `pyproject.toml`, make sure to run `poetry update` to update `poetry.lock`. 

## Running the server

```bash
uvicorn src.ska_sci_ops_setup_validator.run:app --reload --host 127.0.0.1 --port 8001
```

You can use `curl` to test locally as shown below:

```bash
curl -X POST "http://127.0.0.1:8001/validate/" -H "Content-Type: application/json" -d '{
  "context": "Cycle 0",
  "telescopeType": "SKA-Mid",
  "subarrays": {
    "1": {
      "template": "Mid_full_AAstar",
      "band": "Band 1",
      "modes": {
        "1": {
          "continuum": true,
          "zoom": false,
          "pss": false,
          "pst": false
        }
      },
      "continuumSettings": {
        "1": {
          "centralFrequency": 797.5,
          "bandwidth": 720,
          "channelWidth": 13.4,
          "enabled": true
        }
      },
      "zoomSettings": {
        "1": {
          "numberOfZoomChannels": "",
          "zoomMode": "",
          "enabled": false
        }
      },
      "pssSettings": {
        "1": {
          "numberOfBeams": 1125,
          "centralFrequency": "",
          "bandwidth": "",
          "enabled": false
        }
      },
      "pstSettings": {
        "1": {
          "timingModeBeams": 0,
          "dynamicSpectrumBeams": 0,
          "flowthroughModeBeams": 0,
          "centralFrequency": "",
          "bandwidth": "",
          "enabled": false
        }
      }
    },
    "2": {
      "template": "Mid_full_AAstar",
      "band": "Band 1",
      "modes": {
        "1": {
          "continuum": true,
          "zoom": false,
          "pss": false,
          "pst": false
        }
      },
      "continuumSettings": {
        "1": {
          "centralFrequency": 797.5,
          "bandwidth": 720,
          "channelWidth": 13.4,
          "enabled": true
        }
      },
      "zoomSettings": {
        "1": {
          "numberOfZoomChannels": "",
          "zoomMode": "",
          "enabled": false
        }
      },
      "pssSettings": {
        "1": {
          "numberOfBeams": 1125,
          "centralFrequency": "",
          "bandwidth": "",
          "enabled": false
        }
      },
      "pstSettings": {
        "1": {
          "timingModeBeams": 0,
          "dynamicSpectrumBeams": 0,
          "flowthroughModeBeams": 0,
          "centralFrequency": "",
          "bandwidth": "",
          "enabled": false
        }
      }
    }
  }
}'
```
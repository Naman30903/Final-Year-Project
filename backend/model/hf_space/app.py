"""
Hugging Face Spaces entry point.

The Space loads the model from the same repo using MODEL_NAME_OR_PATH.
Set the Space secret MODEL_NAME_OR_PATH=YOUR_HF_USERNAME/roberta-fakenews
or leave blank to use the bundled ./model directory.

All logic lives in newmodel.py — this file just imports and re-exports `app`.
"""
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from newmodel import app  # noqa: F401 — uvicorn looks for `app`

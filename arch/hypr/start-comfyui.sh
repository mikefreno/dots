#!/bin/bash

COMFYUI_DIR="/home/mike/ComfyUI"

cd "$COMFYUI_DIR"

source .venv/bin/activate

python main.py --listen 0.0.0.0

wait

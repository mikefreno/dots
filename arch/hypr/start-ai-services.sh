#!/bin/bash
OLLAMA_HOST=0.0.0.0 nohup ollama serve &>/dev/null &
nohup lms server start &>/dev/null &

#COMFYUI_DIR="/home/mike/ComfyUI"

#cd "$COMFYUI_DIR"

#source .venv/bin/activate

#python main.py --listen 0.0.0.0 > /home/mike/.local/share/ai/comfy.log

#!/bin/bash

echo "=== Ensuring System Dependencies are Installed ==="
apt-get update && apt-get install -y wget ca-certificates

echo "=== Starting Z-Image Template Setup ==="

# Define the correct ComfyUI path for runpod/comfyui:cuda12.8
COMFYUI_PATH="/workspace/runpod-slim/ComfyUI"

# If ComfyUI is not yet in the workspace (or missing main.py), copy the pre-built files first
# This self-healing check prevents directory collisions and fixes broken folders
if [ ! -f "$COMFYUI_PATH/main.py" ]; then
  echo "First time setup: Copying baked ComfyUI to workspace..."
  # Clean up any broken, empty directory from previous failed setups first
  rm -rf "$COMFYUI_PATH"
  mkdir -p /workspace/runpod-slim
  cp -r /opt/comfyui-baked "$COMFYUI_PATH"
fi

# 1. Move custom nodes to the official ComfyUI directory
echo "Installing custom nodes..."
mkdir -p "$COMFYUI_PATH/custom_nodes"
cp -r /tmp/temp_repo/custom_nodes/* "$COMFYUI_PATH/custom_nodes/"

# 2. Automatically find and install requirements for your custom nodes
echo "Installing node requirements..."
find "$COMFYUI_PATH/custom_nodes/" -name "requirements.txt" -exec pip install -r {} \;

# 3. Ensure the correct ComfyUI model folders exist
echo "Preparing model directories..."
mkdir -p "$COMFYUI_PATH/models/text_encoders"
mkdir -p "$COMFYUI_PATH/models/diffusion_models"
mkdir -p "$COMFYUI_PATH/models/vae"
mkdir -p "$COMFYUI_PATH/models/loras"

# 4. Check and download Text Encoder (Qwen 3 4B)
if [ ! -f "$COMFYUI_PATH/models/text_encoders/qwen_3_4b.safetensors" ]; then
  echo "Downloading Text Encoder (Qwen 3 4B)..."
  wget -q --show-progress -O "$COMFYUI_PATH/models/text_encoders/qwen_3_4b.safetensors" "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/text_encoders/qwen_3_4b.safetensors"
else
  echo "Text Encoder already exists, skipping."
fi

# 5. Check and download Diffusion Model (Z-Image Turbo BF16)
if [ ! -f "$COMFYUI_PATH/models/diffusion_models/z_image_turbo_bf16.safetensors" ]; then
  echo "Downloading Diffusion Model (Z-Image Turbo BF16)..."
  wget -q --show-progress -O "$COMFYUI_PATH/models/diffusion_models/z_image_turbo_bf16.safetensors" "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/diffusion_models/z_image_turbo_bf16.safetensors"
else
  echo "Diffusion Model already exists, skipping."
fi

# 6. Check and download VAE (ae.safetensors)
if [ ! -f "$COMFYUI_PATH/models/vae/ae.safetensors" ]; then
  echo "Downloading VAE (ae.safetensors)..."
  wget -q --show-progress -O "$COMFYUI_PATH/models/vae/ae.safetensors" "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/vae/ae.safetensors"
else
  echo "VAE already exists, skipping."
fi

# 7. Install LoRA files from the repo's lora/ folder
echo "Installing LoRA files..."
if [ -d /tmp/temp_repo/lora ]; then
  for f in /tmp/temp_repo/lora/*.safetensors; do
    [ -e "$f" ] || continue
    fname=$(basename "$f")
    dest="$COMFYUI_PATH/models/loras/$fname"
    if [ -f "$dest" ]; then
      echo "LoRA $fname already exists, skipping."
      continue
    fi
    # If the file is under 1MB it's likely a Git LFS pointer, not the real model
    size=$(stat -c%s "$f")
    if [ "$size" -lt 1000000 ]; then
      echo "LoRA $fname looks like an LFS pointer, downloading real file..."
      wget -q --show-progress -O "$dest" "https://media.githubusercontent.com/media/tenitsky/z-image-template-files/main/lora/$fname"
    else
      echo "Copying LoRA $fname..."
      cp "$f" "$dest"
    fi
  done
else
  echo "No lora directory found in repo, skipping."
fi

# 8. Clean up the temporary git folder
echo "Cleaning up temp files..."
rm -rf /tmp/temp_repo

# 9. Start ComfyUI using the official RunPod entrypoint
echo "Setup complete! Handing over to start script..."
exec /start.sh
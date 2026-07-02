#!/bin/bash

echo "=== Starting Z-Image Template Setup ==="

# 1. Move custom nodes to the official ComfyUI directory
echo "Installing custom nodes..."
mkdir -p /workspace/ComfyUI/custom_nodes
cp -r /tmp/temp_repo/custom_nodes/* /workspace/ComfyUI/custom_nodes/

# 2. Move workflows to the /workspace directory so users can find them easily
echo "Setting up workflows..."
cp -r /tmp/temp_repo/workflows /workspace/

# 3. Automatically find and install requirements for your custom nodes
echo "Installing node requirements..."
find /workspace/ComfyUI/custom_nodes/ -name "requirements.txt" -exec pip install -r {} \;

# 4. Ensure the correct ComfyUI model folders exist
echo "Preparing model directories..."
mkdir -p /workspace/ComfyUI/models/text_encoders
mkdir -p /workspace/ComfyUI/models/diffusion_models
mkdir -p /workspace/ComfyUI/models/vae

# 5. Check and download Text Encoder (Qwen 3 4B)
if [ ! -f /workspace/ComfyUI/models/text_encoders/qwen_3_4b.safetensors ]; then
  echo "Downloading Text Encoder (Qwen 3 4B)..."
  wget -q --show-progress -O /workspace/ComfyUI/models/text_encoders/qwen_3_4b.safetensors "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/text_encoders/qwen_3_4b.safetensors"
else
  echo "Text Encoder already exists, skipping."
fi

# 6. Check and download Diffusion Model (Z-Image Turbo BF16)
if [ ! -f /workspace/ComfyUI/models/diffusion_models/z_image_turbo_bf16.safetensors ]; then
  echo "Downloading Diffusion Model (Z-Image Turbo BF16)..."
  wget -q --show-progress -O /workspace/ComfyUI/models/diffusion_models/z_image_turbo_bf16.safetensors "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/diffusion_models/z_image_turbo_bf16.safetensors"
else
  echo "Diffusion Model already exists, skipping."
fi

# 7. Check and download VAE (ae.safetensors)
if [ ! -f /workspace/ComfyUI/models/vae/ae.safetensors ]; then
  echo "Downloading VAE (ae.safetensors)..."
  wget -q --show-progress -O /workspace/ComfyUI/models/vae/ae.safetensors "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/vae/ae.safetensors"
else
  echo "VAE already exists, skipping."
fi

# 8. Clean up the temporary git folder
echo "Cleaning up temp files..."
rm -rf /tmp/temp_repo

# 9. Start ComfyUI using the official RunPod entrypoint
echo "Setup complete! Handing over to start script..."
exec /start.sh
from diffusers import StableDiffusionPipeline
import torch
import os

model_path = os.getenv("MODEL_PATH", "/app/models/image/sdxl-turbo.safetensors")
pipe = StableDiffusionPipeline.from_pretrained(
    model_path,
    torch_dtype=torch.float16,
    safety_checker=None
).to("cpu")

def generate_image(prompt, upscale=False):
    image = pipe(prompt, num_inference_steps=15).images[0]
    return image
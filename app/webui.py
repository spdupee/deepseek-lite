from text_gen import TextGenerator
from image_gen import ImageGenerator
import gradio as gr

text_gen = TextGenerator()
image_gen = ImageGenerator()

def generate(prompt):
    text = text_gen.generate(prompt)
    image = image_gen.generate(prompt, upscale=False)
    return text, image

gr.Interface(
    fn=generate,
    inputs="text",
    outputs=["text", "image"],
    title="DEEPSEEK-Lite (CPU Mode)",
    description="Optimized for 8GB RAM + 64GB swap"
).launch(server_name="0.0.0.0")
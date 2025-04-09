from llama_cpp import Llama
import os

model_path = os.getenv("MODEL_PATH", "/app/models/text/model.gguf")
llm = Llama(
    model_path=model_path,
    n_ctx=1024,
    n_threads=int(os.getenv("THREADS", 6))
)

def generate_text(prompt):
    return llm.create_chat_completion(
        messages=[{"role": "user", "content": prompt}]
    )["choices"][0]["message"]["content"]
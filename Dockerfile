FROM ubuntu:24.04

ARG UID=1000
ARG GID=1000

# System setup
RUN apt update && apt install -y \
    python3-pip libgl1 libglib2.0-0 && \
    rm -rf /var/lib/apt/lists/* && \
    groupadd -g $GID deepseek && \
    useradd -u $UID -g $GID -m -d /app deepseek

# Python environment
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Application files
USER deepseek
COPY --chown=deepseek:deepseek app /app

# Runtime configuration
ENV OMP_NUM_THREADS=${THREADS:-6}
ENV GGML_NUM_THREADS=${THREADS:-6}

CMD ["python3", "webui.py"]
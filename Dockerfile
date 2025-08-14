# FROM ubuntu:22.04

# # Update and install wget to download caddy
# RUN apt-get update && apt-get install -y wget curl bash

# # Download and install ollama
# RUN curl -fsSL https://ollama.com/install.sh | sh

# # Download and install caddy
# RUN wget --no-check-certificate https://github.com/caddyserver/caddy/releases/download/v2.10.0/caddy_2.10.0_linux_amd64.tar.gz \
#     && tar -xvf caddy_2.10.0_linux_amd64.tar.gz \
#     && mv caddy /usr/bin/ \
#     && chown root:root /usr/bin/caddy \
#     && chmod 755 /usr/bin/caddy

# # Copy the Caddyfile to the container
# COPY Caddyfile /etc/caddy/Caddyfile

# # Set the environment variable for the ollama host
# ENV OLLAMA_HOST=0.0.0.0

# # Expose the port that caddy will listen on
# EXPOSE 80

# # Set the working directory
# WORKDIR /app

# # Copy a script to start both ollama and caddy
# COPY start_services.sh start_services.sh
# RUN chmod +x start_services.sh

# # Copy the GPU metrics Python code into the container
# COPY gpu_metrics.py /app/gpu_metrics.py


# # Install required Python packages
# # RUN apt-get update && apt-get install -y python3-pip

# RUN python -m venv /app/venv

# ENV PATH="/app/venv/bin:$PATH"

# RUN apt-get update && apt-get install -y --no-install-recommends \
#     curl jq git bash python3 python3-pip python3-venv ffmpeg libsm6 libxext6\
#     vim expect apt-transport-https ca-certificates gnupg lsb-release unzip \
#     openjdk-17-jdk && \
#     # Clean up to reduce image size
#     apt-get clean && rm -rf /var/lib/apt/lists/*

# COPY requirements.txt /app/requirements.txt

# RUN pip install --no-cache-dir --upgrade pip \
#     && pip install --no-cache-dir -r /app/requirements.txt

# # RUN pip install -r /app/requirements.txt

# # Set the entrypoint to the script
# CMD ["/bin/bash", "/app/start_services.sh"]


FROM ubuntu:22.04

# Set noninteractive to avoid tzdata prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies (including Python before venv)
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget curl bash jq git python3 python3-pip python3-venv \
    ffmpeg libsm6 libxext6 vim expect apt-transport-https \
    ca-certificates gnupg lsb-release unzip openjdk-17-jdk && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Download and install Ollama
RUN curl -fsSL https://ollama.com/install.sh | sh

# Download and install Caddy
RUN wget --no-check-certificate https://github.com/caddyserver/caddy/releases/download/v2.10.0/caddy_2.10.0_linux_amd64.tar.gz \
    && tar -xvf caddy_2.10.0_linux_amd64.tar.gz \
    && mv caddy /usr/bin/ \
    && chown root:root /usr/bin/caddy \
    && chmod 755 /usr/bin/caddy \
    && rm caddy_2.10.0_linux_amd64.tar.gz

# Copy the Caddyfile
COPY Caddyfile /etc/caddy/Caddyfile

# Set the environment variable for the Ollama host
ENV OLLAMA_HOST=0.0.0.0

# Expose Caddy port
EXPOSE 80

# Set working directory
WORKDIR /app

# Create Python virtual environment
RUN python3 -m venv /app/venv
ENV PATH="/app/venv/bin:$PATH"

# Copy requirements and install Python dependencies
COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r /app/requirements.txt

# Copy GPU metrics code and service starter script
COPY gpu_metrics.py /app/gpu_metrics.py
COPY start_services.sh /app/start_services.sh
RUN chmod +x /app/start_services.sh

# Set entrypoint to start all services
CMD ["/bin/bash", "/app/start_services.sh"]

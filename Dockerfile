FROM ubuntu:24.04

# Set non-interactive installation
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    git \
    curl \
    wget \
    sudo \
    build-essential \
    nodejs \
    npm \
    libportaudio2 \
    libgirepository1.0-dev \
    libcairo2-dev \
    python3-gi \
    python3-gi-cairo \
    libgstreamer1.0-dev \
    libgstreamer-plugins-bad1.0-dev \
    libgstreamer-plugins-base1.0-dev \
    libgstreamer-plugins-good1.0-dev \
    zip \
    libgl1 \
    && rm -rf /var/lib/apt/lists/*

# Create and activate virtual environment
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Upgrade pip in the virtual environment
RUN pip install --upgrade pip

# Set working directory
WORKDIR /workspace

# Install hf-doc-builder from the main branch as specified in the docs
RUN pip install "hf-doc-builder @ git+https://github.com/huggingface/doc-builder.git@main"

# Install optional dependencies needed for documentation build
RUN pip install "PyGObject>=3.42.2,<=3.46.0" \
    "placo==0.9.14" \
    "rerun-sdk>=0.27.2" \
    "urdf-parser-py==0.0.4" \
    "semver>=3,<4"

# Set the entrypoint to bash for interactive use
CMD ["/bin/bash"]

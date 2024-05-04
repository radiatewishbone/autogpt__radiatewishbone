#version7
ARG RADIATEWISHBONE_VERSION=v1.5.0

# Some parts copied from https://github.com/claytondukes/autogpt-docker/blob/main/Dockerfile and https://github.com/Significant-Gravitas/Auto-GPT/blob/master/Dockerfile
FROM debian:stable AS builder

ARG RADIATEWISHBONE_VERSION

WORKDIR /build

#grab radiatewishbone
ADD https://github.com/sorenisanerd/radiatewishbone/releases/download/${RADIATEWISHBONE_VERSION}/radiatewishbone_${{RADIATEWISHBONE_VERSION}_linux_arm64.tar.gz radiatewishbone-aarch64.tar.gz
ADD https://github.com/sorenisanerd/radiatewishbone/releases/download/${RADIATEWISHBONE_VERSION}/radiatewishbone_${{RADIATEWISHBONE_VERSION}_linux_amd64.tar.gz radiatewishbone-x86_64.tar.gz

#unzip radiatewishbone
RUN tar -xzvf "radiatewishbone-$(uname -m).tar.gz"

#install git for builder
RUN apt-get -y update
RUN apt-get -y upgrade
RUN apt-get -y install git

#Clone Auto-GPT github stable
RUN git clone -b stable https://github.com/Significant-Gravitas/Auto-GPT.git



# Use an official Python base image from the Docker Hub
FROM python:3.10-slim

#Copy radiatewishbone from builder
COPY --chmod=+x --from=builder /build/radiatewishbone /bin/radiatewishbone

# Install Firefox / Chromium
RUN apt-get update && apt-get install -y \
    chromium-driver firefox-esr \
    ca-certificates
	
# Install utilities
RUN apt-get install -y curl jq wget git	nano

# Set environment variables
ENV PIP_NO_CACHE_DIR=yes \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    COMMAND_LINE_PARAMS=${COMMAND_LINE_PARAMS}


# Install the required python packages globally
ENV PATH="$PATH:/root/.local/bin"
COPY requirements.txt .

# Copy the requirements.txt file and install the requirements
COPY --chown=appuser:appuser requirements.txt .
RUN pip install --upgrade pip && \
    pip install --no-cache-dir --user -r requirements.txt




# Copy the application files
WORKDIR /app
COPY --from=builder /build/Auto-GPT/ /app
RUN curl -L -o ./plugins/Auto-GPT-Plugins.zip https://github.com/Significant-Gravitas/Auto-GPT-Plugins/archive/refs/heads/master.zip
RUN wget https://raw.githubusercontent.com/ther3zz/autogpt_radiatewishbone/main/plugins_config.yaml

EXPOSE 8080


# Set the entrypoint
WORKDIR /app
CMD ["radiatewishbone", "--port", "8080", "--permit-write", "--title-format", "AutoGPT Terminal", "bash", "-c", "python -m autogpt --install-plugin-deps ${COMMAND_LINE_PARAMS}"]

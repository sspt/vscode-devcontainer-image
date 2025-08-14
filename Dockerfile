ARG SOPS_VERSION="3.10.2"
ARG TOFUENV_VERSION="1.0.7"

# Use the official Ubuntu LTS as a parent image
FROM ubuntu:24.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Update and install basic packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python3 \
        python3-pip \
        git \
        curl \
        nano \
        wget \
        fonts-powerline \
        sudo \
        ca-certificates \
        build-essential \
        lsb-release \
        gnupg \
        apt-transport-https \
        locales \
        language-pack-en-base \
        gh \
        jq \
    && rm -rf /var/lib/apt/lists/*

# Install wrangler (Cloudflare Workers CLI)
RUN curl -fsSL https://workers.cloudflare.com/get-wrangler-cli.sh | bash

# Install fonts and Oh My Bash for a better shell experience
RUN bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)" --prefix=/usr/local

# Install Docker CLI tools
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends docker-ce-cli && \
    rm -rf /var/lib/apt/lists/*
RUN apt clean all

# Add ubuntu user to sudoers without password
RUN echo "ubuntu ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ubuntu && chmod 0440 /etc/sudoers.d/ubuntu

# Set the working directory
WORKDIR /app

# Create the app dir
RUN mkdir -p /app && chown -R ubuntu:ubuntu /app

# Execute everything as ubuntu's user
USER ubuntu

# install nvm
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

# set env
ENV NVM_DIR=/home/ubuntu/.nvm

# install node
RUN bash -c "source $NVM_DIR/nvm.sh && nvm install 20"
RUN bash -c "source $NVM_DIR/nvm.sh && npm update -g npm"
RUN bash -c "source $NVM_DIR/nvm.sh && npm install wrangler --save-dev"
RUN cp /usr/local/share/oh-my-bash/bashrc ~/.bashrc

# Set up a slick Powerline-inspired prompt and some useful aliases
RUN echo '\
# Enable Powerline-like prompt\n\
OSH_THEME="powerline"\n\
# Some badass aliases\n\
alias ll="ls -alF --color=auto"\n\
alias la="ls -A --color=auto"\n\
alias l="ls -CF --color=auto"\n\
alias gs="git status"\n\
alias gd="git diff"\n\
source $NVM_DIR/nvm.sh\n\
' >> /home/ubuntu/.bashrc

# Default command (adjust as needed)
CMD ["bash"]

# Additional Tools - Azure CLI
RUN pip install azure-cli --break-system-packages --no-cache-dir

# Additional Tools - DockerInDocker
RUN curl -sSL https://raw.githubusercontent.com/devcontainers/features/refs/heads/main/src/docker-in-docker/install.sh | bash

# Additional Tools - TofuEnv
RUN curl -Lo /tmp/tofuenv.tar.gz "https://github.com/tofuutils/tofuenv/archive/refs/tags/v${TOFUENV_VERSION}.tar.gz" \
    && tar -C /tmp -xf /tmp/tofuenv.tar.gz \
    && mv "/tmp/tofuenv-${TOFUENV_VERSION}/bin"/* /usr/local/bin/ \
    && mkdir -p /usr/local/lib/tofuenv \
    && mv "/tmp/tofuenv-${TOFUENV_VERSION}/lib" /usr/local/lib/tofuenv/ \
    && mv "/tmp/tofuenv-${TOFUENV_VERSION}/libexec" /usr/local/lib/tofuenv/ \
    && mkdir -p /usr/local/share/licenses \
    && mv "/tmp/tofuenv-${TOFUENV_VERSION}/LICENSE" /usr/local/share/licenses/tofuenv \
    && rm -rf /tmp/tofuenv* \
    && export TOFUENV_ROOT=/usr/local/lib/tofuenv \
    && export TOFUENV_CONFIG_DIR=/opt/tofuenv/ \
    && export TOFUENV_TOFU_VERSION=latest

# Additional Tools - SOPS
RUN curl -LO https://github.com/getsops/sops/releases/download/v$"SOPS_VERSION"/sops-v${SOPS_VERSION}.linux.amd64 && \
	mv sops-v$"SOPS_VERSION".linux.amd64 /usr/local/bin/sops && \
	chmod +x /usr/local/bin/sops


# Install GH CLI
RUN (type -p curl >/dev/null || (apt update && apt-get install curl -y)) \
    && mkdir -p -m 755 /etc/apt/keyrings \
    && out=$(mktemp) && curl -fsSL -o "$out" https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    && cat "$out" | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
    && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt update \
    && apt install gh -y

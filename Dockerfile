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

# Add ubuntu user to sudoers without password
RUN echo "ubuntu ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ubuntu && chmod 0440 /etc/sudoers.d/ubuntu

RUN apt clean all
# Set the working directory
WORKDIR /app

# Copy the current directory contents into the container at /app
COPY . /app

# Set up a slick Powerline-inspired prompt and some useful aliases
USER ubuntu
RUN cp /usr/local/share/oh-my-bash/bashrc ~/.bashrc

RUN echo '\
# Enable Powerline-like prompt\n\
OSH_THEME="powerline"\n\
# Some badass aliases\n\
alias ll="ls -alF --color=auto"\n\
alias la="ls -A --color=auto"\n\
alias l="ls -CF --color=auto"\n\
alias gs="git status"\n\
alias gd="git diff"\n\
' >> /home/ubuntu/.bashrc

# Default command (adjust as needed)
CMD ["bash"]
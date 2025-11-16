FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        sudo \
        curl \
        git \
        ca-certificates \
        stow \
        vim-nox \
        tmux \
        shellcheck \
        python3 \
        python3-pip \
        build-essential \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m testuser \
    && echo "testuser:testuser" | chpasswd \
    && adduser testuser sudo \
    && echo "testuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER testuser
WORKDIR /workspace

CMD ["bash"]

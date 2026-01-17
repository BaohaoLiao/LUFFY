ARG BASE_IMAGE=ecr.vip.ebayc3.com/baliao/base_images:python3.10_cuda12.4
FROM ${BASE_IMAGE}

RUN apt-get update && apt-get upgrade -y --fix-broken && \
    apt-get install -y --no-install-recommends git wget && \
    apt-get clean && rm -rf /var/lib/apt/lists/*
RUN pip install --upgrade pip

# Install PyTorch (CUDA 12.4 build)
RUN pip3 install torch==2.6.0 torchvision==0.21.0 torchaudio==2.6.0 --index-url https://download.pytorch.org/whl/cu124

# Install FlashAttention + FlashInfer
RUN wget -nv https://github.com/Dao-AILab/flash-attention/releases/download/v2.7.3/flash_attn-2.7.3+cu12torch2.6cxx11abiFALSE-cp310-cp310-linux_x86_64.whl -P /tmp && \
    pip install --no-cache-dir /tmp/flash_attn-2.7.3+cu12torch2.6cxx11abiFALSE-cp310-cp310-linux_x86_64.whl && \
    rm -f /tmp/flash_attn-2.7.3+cu12torch2.6cxx11abiFALSE-cp310-cp310-linux_x86_64.whl

WORKDIR /workspace/LUFFY
COPY . /workspace/LUFFY

# Follow README "Update 9.8" install flow.
RUN pip install --no-cache-dir airports-py && \
    git clone https://github.com/dottxt-ai/outlines.git /tmp/outlines && \
    cd /tmp/outlines && \
    git checkout 0.0.46 && \
    pip install --no-cache-dir . && \
    rm -rf /tmp/outlines && \
    cd /workspace/LUFFY/luffy && \
    pip install --no-cache-dir -r requirements.v2.txt && \
    pip install --no-cache-dir -e . && \
    cd /workspace/LUFFY/luffy/verl && \
    pip install --no-cache-dir -e .

# Vulnerabilities
RUN apt-get update && \
    apt-get install -y --only-upgrade \
        python3-apt \
        python-apt-common \
        binutils \
        binutils-common \
        binutils-x86-64-linux-gnu \
        libbinutils \
        libctf0 \
        libctf-nobfd0 \
        python3.10 \
        python3.10-minimal \
        libpython3.10 \
        libpython3.10-stdlib \
        libcups2 \
        libxml2 \
        bind9-host bind9-dnsutils dnsutils \
        samba-libs libsmbclient libwbclient0 && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Aggressively remove any .git directories or symlinks
RUN find / -name ".git" -exec rm -rf {} + 2>/dev/null || true && \
    find / -name ".git" -type l -exec rm -f {} + 2>/dev/null || true

# Verify cleanup
RUN echo "🔍 Listing .git dirs..." && \
    find / -name '.git' 2>/dev/null || echo "✅ None found"

CMD ["/bin/bash"]

# syntax=docker/dockerfile:1
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive \
    CMAKE_VERSION=3.26.4 \
    CMAKE_BASE_URL=https://github.com/Kitware/CMake/releases/download

# 1) Install system tools + sudo + autotools
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    unzip zip curl tar ca-certificates \
    valgrind gdb pkg-config \
    python3 python3-venv python3-pip \
    perl wget \
    libssl-dev libcurl4-openssl-dev libjansson-dev \
    autoconf automake libtool \
    sudo \
  && rm -rf /var/lib/apt/lists/*

# 2) Install CMake from the official binary release, arch‑aware
RUN ARCH=$(uname -m) && \
    case "${ARCH}" in \
      x86_64) CMAKE_ARCH=linux-x86_64 ;; \
      aarch64) CMAKE_ARCH=linux-aarch64 ;; \
      *) echo "Unsupported arch: ${ARCH}" >&2; exit 1 ;; \
    esac && \
    wget -q "${CMAKE_BASE_URL}/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-${CMAKE_ARCH}.tar.gz" \
         -O /tmp/cmake.tgz && \
    tar --strip-components=1 -xzf /tmp/cmake.tgz -C /usr/local && \
    rm /tmp/cmake.tgz

# 3) install libjwt from source to get the newest
RUN git clone --depth=1 https://github.com/benmcollins/libjwt.git /tmp/libjwt \
 && mkdir /tmp/libjwt/build \
 && cd /tmp/libjwt/build \
 && cmake .. \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr/local \
 && make -j$(nproc) \
 && sudo make install \
 && rm -rf /tmp/libjwt

# 4) Create python venv
RUN python3 -m venv /opt/venv \
 && /opt/venv/bin/pip install --upgrade pip

# 5) Create and switch to a non-root user named "dev" with sudo
RUN useradd --create-home --shell /bin/bash dev \
 && echo "dev ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

RUN mkdir -p /workspace && chown dev:dev /workspace

USER dev
WORKDIR /workspace

ENV PATH="/opt/venv/bin:${PATH}"

# 6) Default to an interactive shell
CMD ["/bin/bash"]

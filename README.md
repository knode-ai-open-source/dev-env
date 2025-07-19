# Development Base & Extension Image

A reproducible Ubuntu 22.04 development **base image** (and example *extension*) for C/C++ + Python projects. It provides a modern CMake toolchain, common debug utilities, a fresh build of **libjwt**, and an isolated Python venv, exposing a non‑root `dev` user suitable for downstream library/service images.

---

## Contents (Base Image `dev-env`)

| Area              | Details                                                                         |
| ----------------- | ------------------------------------------------------------------------------- |
| OS                | Ubuntu 22.04 LTS                                                                |
| Compilers/Build   | `build-essential`, autotools (`autoconf` `automake` `libtool`), `pkg-config`    |
| CMake             | Version pinned via official Kitware binary (`CMAKE_VERSION` build ARG ≈ 3.26.4) |
| Debug             | `gdb`, `valgrind`                                                               |
| Crypto / Net Deps | `libssl-dev`, `libcurl4-openssl-dev`, `libjansson-dev`                          |
| JWT               | Latest **libjwt** built from source (head at build time)                        |
| Scripting         | Python 3 + venv (`/opt/venv`), `perl`                                           |
| Tools             | `git`, `curl`, `wget`, `zip`/`unzip`                                            |
| User              | Non‑root `dev` (passwordless sudo)                                              |
| Workdir           | `/workspace`                                                                    |
| Default CMD       | `/bin/bash`                                                                     |

---

## Quick Start (Base Image)

```bash
docker build -t dev-env .          # from the base Dockerfile (the one containing libjwt build)
```

Run:

```bash
docker run -it --rm -v "$PWD":/workspace dev-env
```

Python venv is auto on PATH; install packages with `pip install <pkg>`.

---

## Extension Example

Below is an *extension* Dockerfile that layers additional internal/open-source libraries plus your project.

```dockerfile
# syntax=docker/dockerfile:1
ARG GITHUB_TOKEN
FROM dev-env

# Re-declare to keep ARG available in later stages
ARG GITHUB_TOKEN
USER dev
WORKDIR /workspace

# Example dependent libraries (each provides a build_install.sh)
RUN git clone https://${GITHUB_TOKEN}@github.com/knode-ai-open-source/a-cmake-library.git a-cmake-library \
 && cd a-cmake-library && ./build_install.sh && cd .. && rm -rf a-cmake-library \
 && git clone https://${GITHUB_TOKEN}@github.com/knode-ai-open-source/the-macro-library.git the-macro-library \
 && cd the-macro-library && ./build_install.sh && cd .. && rm -rf the-macro-library \
 && git clone https://${GITHUB_TOKEN}@github.com/knode-ai-open-source/a-memory-library.git a-memory-library \
 && cd a-memory-library && ./build_install.sh && cd .. && rm -rf a-memory-library \
 && git clone https://${GITHUB_TOKEN}@github.com/knode-ai-open-source/the-lz4-library.git the-lz4-library \
 && cd the-lz4-library && ./build_install.sh && cd .. && rm -rf the-lz4-library

# Project itself
COPY --chown=dev:dev . /workspace/code
RUN cd /workspace/code && ./build_install.sh
CMD ["/bin/bash"]
```

### Build Extension

```bash
docker build \
  --build-arg GITHUB_TOKEN=$GITHUB_TOKEN \
  -t my-project:dev \
  -f Dockerfile.ext .
```

> **Security Tip:** Prefer BuildKit secrets instead of embedding tokens in image layers: `docker build --secret id=gh,env=GITHUB_TOKEN ...` and use `RUN --mount=type=secret,id=gh GITHUB_TOKEN=$(cat /run/secrets/gh) ...`. Also consider read-only deploy keys.

---

## `build_install.sh` Pattern

Typical helper (both in deps and your project):

```bash
#!/usr/bin/env bash
set -euxo pipefail
rm -rf build && mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j"$(nproc)"
sudo make install
```

Adjust flags (`-DCMAKE_INSTALL_PREFIX`, feature toggles) as needed.

---

## Customization Points

| Need                    | How                                                                              |
| ----------------------- | -------------------------------------------------------------------------------- |
| Different CMake version | Build with `--build-arg CMAKE_VERSION=3.28.3` (update if Dockerfile exposes ARG) |
| Extra system packages   | Extend image and `apt-get install` *before* adding large sources                 |
| Python deps             | `pip install -r requirements.txt` inside extension image (uses `/opt/venv`)      |
| Remove sudo             | Drop from derived image: `RUN deluser dev sudo` or create minimal non-sudo user  |
| Lock libjwt commit      | Replace shallow clone with specific commit checkout before build                 |
| Multi-arch              | Base handles `x86_64` & `aarch64`; add others by extending CMake install logic   |

---

## Caching & Layer Hygiene

* Group related `RUN` commands to minimize layers, but keep logical separation for cache hits.
* Remove cloned source dirs after install (already shown) to shrink final size.
* Pin commits / tags for deterministic builds.

---

## Testing Inside Container

```bash
# Example: run ctest after build
docker run --rm -it my-project:dev bash -lc 'cd /workspace/code/build && ctest --output-on-failure'
```

Add CI steps to build and run tests on both amd64 & arm64 (using buildx).

---

## Licensing / Attribution

* Base and extension scripts: Apache-2.0 (see `LICENSE`).
* NOTICE file retained: copyright © 2019–2025 Andy Curtis; © 2024–2025 Knode.ai.
  Include original NOTICE and LICENSE in downstream distributions and note any changes.

---

## Authors

* Andy Curtis — [contactandyc@gmail.com](mailto:contactandyc@gmail.com) — [https://linkedin.com/in/andycurtis](https://linkedin.com/in/andycurtis)

---

## Minimal FAQ

**Q:** Why build libjwt from source?
**A:** To obtain the latest fixes/features beyond distro package lag; pin commit for reproducibility.
**Q:** Why a dedicated `dev` user?
**A:** Encourages least-privilege during builds/tests and mirrors deployment best practices.
**Q:** How do I add Python packages globally?
**A:** In extension Dockerfile: `RUN pip install <pkgs>` (PATH already includes venv).

---

## Roadmap (Ideas)

* Optional build stage for static analysis (clang-tidy, cppcheck).
* Add build ARG to toggle tests on/off.
* Pre-install common Python tooling (ruff, pytest) behind ARG.

Contributions & suggestions welcome.

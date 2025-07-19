**How to use**:

1. **Build the image**

```bash
docker build -t dev-env .
```

2. **Run it with your source tree mounted**

```bash
docker run --rm -it \
  -v "$(pwd)":/workspace \
  -w /workspace \
  dev-env
```

3. **Inside the container** you’ll have:

    * `gcc`, `g++`, `cmake`
    * `python3` with a virtualenv at `/opt/venv`
    * all the common dev libs (`libssl-dev`, `libcurl4-openssl-dev`, etc.)

From there you can run `cmake .`, or any other commands your project needs.

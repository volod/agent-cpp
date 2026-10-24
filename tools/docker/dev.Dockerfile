# Clean Ubuntu development image used by `make matrix`. Build context: tools/.
#   docker build --build-arg UBUNTU=26.04 -f tools/docker/dev.Dockerfile tools
ARG UBUNTU=24.04
FROM ubuntu:${UBUNTU}

COPY setup-ubuntu.sh /tmp/setup-ubuntu.sh
RUN /tmp/setup-ubuntu.sh --yes \
    && rm -rf /var/lib/apt/lists/* /tmp/setup-ubuntu.sh \
    && git config --system --add safe.directory '*'

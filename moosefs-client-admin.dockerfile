ARG MFS_TAG="4.58.4"
ARG TTYD_VERSION="1.7.7"

# Extract mfscli from the gui image
FROM docker.io/moosefs/gui:${MFS_TAG} AS gui

FROM docker.io/moosefs/client:${MFS_TAG}
ARG TTYD_VERSION

# mfscli is a Python script; ttyd is a static binary from GitHub
RUN apt-get update \
    && apt-get install -y --no-install-recommends python3 wget ca-certificates \
    && wget -qO /usr/bin/ttyd https://github.com/tsl0922/ttyd/releases/download/${TTYD_VERSION}/ttyd.x86_64 \
    && chmod +x /usr/bin/ttyd \
    && apt-get purge -y wget \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*

COPY --from=gui /usr/bin/mfscli /usr/bin/mfscli
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

RUN echo "alias ll='ls -alF'\nalias la='ls -A'\nalias l='ls -CF'" >> /root/.bashrc

EXPOSE 7681
ENTRYPOINT ["/entrypoint.sh"]

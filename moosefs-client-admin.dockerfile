ARG MFS_TAG="v4.58.3"

# Extract mfscli from the gui image
FROM moosefs/gui:${MFS_TAG} AS gui

FROM moosefs/client:${MFS_TAG}

# mfscli is a Python script; ttyd provides a web-based terminal
RUN apt-get update \
 && apt-get install -y --no-install-recommends python3 ttyd \
 && rm -rf /var/lib/apt/lists/*

COPY --from=gui /usr/bin/mfscli /usr/bin/mfscli
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 7681
ENTRYPOINT ["/entrypoint.sh"]

FROM        ghcr.io/pterodactyl/games:source

LABEL       author="Inferno" maintainer="inferno@cloudrp"
LABEL       org.opencontainers.image.source="https://github.com/InfernoLua1337/pterodactyl-sourcegames-git"

USER        root
RUN         apt-get update --allow-releaseinfo-change \
                && apt-get install -y --no-install-recommends git openssh-client \
                && rm -rf /var/lib/apt/lists/*

# Fix: Pterodactyl Wings executes as UID 999, which OpenSSH ssh-keygen requires in /etc/passwd
RUN         echo "container:x:999:999:container:/home/container:/bin/bash" >> /etc/passwd

COPY        ./entrypoint.sh /entrypoint.sh
RUN         chmod +x /entrypoint.sh

USER        container
ENV         USER=container HOME=/home/container
WORKDIR     /home/container

CMD         [ "/bin/bash", "/entrypoint.sh" ]

FROM alpine:3.18.0

ENV PYTHONUNBUFFERED=1

ARG http_proxy=""
ARG https_proxy=""
ARG no_proxy=""

ARG USER=app
ARG GROUP=app
ARG USER_ID=1000
ARG USER_GID=1000
ARG DOCKER_GID=142
ARG PACKAGES="sudo curl openssl ca-certificates bash git zip docker openssh-client net-tools shadow vim"

# Installation des paquets apk
RUN apk add --update --no-cache $PACKAGES \
    && rm -rf /var/cache/apk/*

# Fix keep environment variables with sudo
RUN echo "Defaults env_keep += \"ftp_proxy http_proxy https_proxy no_proxy\"">>/etc/sudoers

# Installation de Python
RUN apk add --update --no-cache python3 && ln -sf python3 /usr/bin/python

# Création du user de l'image
RUN groupadd -g $USER_GID $GROUP && \
    useradd -g $USER_GID -u $USER_ID -s /bin/bash $USER && \
    usermod -a -G docker $USER && \
    groupmod --gid $DOCKER_GID docker && \
    echo "$USER ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$USER

# On se positionne sur le user créé
USER $USER
WORKDIR /home/$USER

CMD ["/bin/bash"]

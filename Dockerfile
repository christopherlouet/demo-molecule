ARG PYTHON_VERSION=3.9
ARG ALPINE_VERSION=3.18
ARG http_proxy=""
ARG https_proxy=""
ARG no_proxy=""

FROM python:$PYTHON_VERSION-alpine$ALPINE_VERSION as builder
MAINTAINER Equipe construction Rennes

ENV POETRY_NO_INTERACTION=1 \
  POETRY_VIRTUALENVS_IN_PROJECT=1 \
  POETRY_VIRTUALENVS_CREATE=1 \
  POETRY_CACHE_DIR=/tmp/poetry_cache \
  PYTHONFAULTHANDLER=1 \
  PYTHONUNBUFFERED=1 \
  PYTHONHASHSEED=random \
  PIP_DISABLE_PIP_VERSION_CHECK=on \
  PIP_DEFAULT_TIMEOUT=100 \
  POETRY_VERSION=1.5.1 \
  http_proxy="${http_proxy}" \
  https_proxy="${https_proxy}" \
  no_proxy="${no_proxy}"

RUN apk add --update --no-cache gcc libc-dev musl-dev jpeg-dev zlib-dev libffi-dev cairo-dev pango-dev gdk-pixbuf-dev
RUN pip install "poetry==$POETRY_VERSION"

WORKDIR /app
COPY pyproject.toml poetry.lock ./

RUN --mount=type=cache,target=$POETRY_CACHE_DIR poetry install --no-root --no-ansi

FROM python:$PYTHON_VERSION-alpine$ALPINE_VERSION as runtime
MAINTAINER Equipe construction Rennes

ARG http_proxy=""
ARG https_proxy=""
ARG no_proxy=""
ARG REGISTRY=""
ARG USER=app
ARG GROUP=app
ARG USER_ID=1000
ARG USER_GID=1000
ARG DOCKER_GID=142
ARG VIRTUAL_ENV="/app/.venv"
ARG WORKDIR="/app/demo-molecule"
ARG PACKAGES="bash sudo docker git openssh-client ca-certificates curl net-tools shadow vim unzip tar jq"

ENV VIRTUAL_ENV="$VIRTUAL_ENV" \
    PATH="$VIRTUAL_ENV/bin:$PATH" \
    http_proxy="${http_proxy}" \
    https_proxy="${https_proxy}" \
    no_proxy="${no_proxy}" \
    REGISTRY="${REGISTRY}"

# Installation des paquets apk
RUN apk add --update --no-cache $PACKAGES \
    && rm -rf /var/cache/apk/*

# Création du user de l'image
RUN groupadd -g $USER_GID $GROUP && \
    useradd -g $USER_GID -u $USER_ID -s /bin/bash -d $WORKDIR $USER && \
    usermod -a -G docker $USER && \
    groupmod --gid $DOCKER_GID docker && \
    echo "$USER ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$USER

# Copie de l'environnement python et des fichiers
COPY --chown=$USER:$GROUP --from=builder ${VIRTUAL_ENV} ${VIRTUAL_ENV}

# On se positionne sur le user créé
USER $USER
WORKDIR $WORKDIR

CMD ["/bin/bash"]

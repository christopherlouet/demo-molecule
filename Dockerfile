FROM python:3.12-alpine3.19 as builder
MAINTAINER Christopher LOUËT

ENV POETRY_NO_INTERACTION=1 \
  POETRY_VIRTUALENVS_IN_PROJECT=1 \
  POETRY_VIRTUALENVS_CREATE=1 \
  POETRY_CACHE_DIR=/tmp/poetry_cache \
  PYTHONFAULTHANDLER=1 \
  PYTHONUNBUFFERED=1 \
  PYTHONHASHSEED=random \
  PIP_DISABLE_PIP_VERSION_CHECK=on \
  PIP_DEFAULT_TIMEOUT=100 \
  POETRY_VERSION=1.8.2

RUN apk add --update --no-cache gcc libc-dev musl-dev jpeg-dev zlib-dev libffi-dev cairo-dev pango-dev gdk-pixbuf-dev
RUN pip install "poetry==$POETRY_VERSION"

WORKDIR /app
COPY pyproject.toml poetry.lock ./

RUN --mount=type=cache,target=$POETRY_CACHE_DIR poetry install --no-root --no-ansi

FROM python:3.12-alpine3.19 as runtime
MAINTAINER Christopher LOUËT

ARG USER=app
ARG GROUP=app
ARG USER_ID=1000
ARG USER_GID=1000
ARG DOCKER_GID=999
ARG VIRTUAL_ENV="/app/.venv"
ARG WORKDIR="/app/demo-molecule"

# Updating the Global PATH Variable
ENV PATH="$PATH:$VIRTUAL_ENV/bin"

# Installing apk packages
RUN apk add --update --no-cache bash sudo docker git openssh-client ca-certificates rsync curl net-tools shadow \
    vim unzip tar jq && \
    rm -rf /var/cache/apk/*

# Create user
RUN groupadd -g $USER_GID $GROUP && \
    useradd -g $USER_GID -u $USER_ID -s /bin/bash -d $WORKDIR $USER && \
    echo "$USER ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$USER

# Add the docker group to this user
RUN usermod -a -G $DOCKER_GID $USER

# Copy python environment and files
COPY --chown=$USER:$GROUP --from=builder ${VIRTUAL_ENV} ${VIRTUAL_ENV}

# Set user
USER $USER
WORKDIR $WORKDIR

CMD ["/bin/bash"]

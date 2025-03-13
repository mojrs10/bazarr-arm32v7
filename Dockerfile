# syntax=docker/dockerfile:1

FROM mojrapid/unrar:arm32v7-6.2.10 as unrar

# FROM mojrapid/baseimage:alpine-3.17_s6_full
# FROM mojrapid/alpine:3.18_s6_transmission-arm32v7
FROM mojrapid/baseimage:alpine-3.18_s6_full
# FROM mojrapid/baseimage:alpine-3.19_s6_full - ovaj se inače koristi u orginalu
# FROM mojrapid/baseimage:alpine-3.20_s6_full
# FROM mojrapid/baseimage:alpine-edge_s6_full

# set version label
ARG BUILD_DATE
ARG VERSION
ARG BAZARR_VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="chbmb"
# hard set UTC in case the user does not define it
ENV TZ="Etc/UTC"

RUN \
  echo "**** install build packages ****" && \
  apk add --no-cache --virtual=build-dependencies \
    build-base \
    cmake \
    jpeg-dev \
#    pkgconfig \
    ninja \
    cargo \
    libffi-dev \
    libpq-dev \
    libxml2-dev \
    libxslt-dev \
    python3-dev && \
  echo "**** install packages ****" && \
  apk add --no-cache \
    ffmpeg \
    libxml2 \
    libxslt \
    mediainfo \
    python3 && \
  echo "**** install bazarr ****" && \
  mkdir -p \
    /app/bazarr/bin && \
  if [ -z ${BAZARR_VERSION+x} ]; then \
    BAZARR_VERSION=$(curl -sX GET "https://api.github.com/repos/morpheus65535/bazarr/releases/latest" \
    | awk '/tag_name/{print $4;exit}' FS='[""]'); \
  fi && \
  curl -o \
    /tmp/bazarr.zip -L \
    "https://github.com/morpheus65535/bazarr/releases/download/${BAZARR_VERSION}/bazarr.zip" && \
  unzip \
    /tmp/bazarr.zip -d \
    /app/bazarr/bin && \
  rm -Rf /app/bazarr/bin/bin && \
  echo "UpdateMethod=docker\nBranch=master\nPackageVersion=${VERSION}\nPackageAuthor=linuxserver.io & mojrapid" > /app/bazarr/package_info && \
  curl -o \
    /app/bazarr/bin/postgres-requirements.txt -L \
    "https://raw.githubusercontent.com/morpheus65535/bazarr/${BAZARR_VERSION}/postgres-requirements.txt" && \
  echo "**** Install requirements ****" && \
  python3 -m venv /lsiopy && \
  pip install -U --no-cache-dir \
#    setuptools \
    pip \
#    ninja \
#    numpy --config-settings=setup-args="-Dallow-noblas=true" \
#    Pillow \
#    wheel && \
    wheel \
#    numpy --config-settings=setup-args="-Dallow-noblas=true" \
    Pillow && \
    pip install -U --no-cache-dir --find-links https://wheel-index.linuxserver.io/alpine-3.17/ \
#  pip install -U --no-cache-dir --find-links https://wheel-index.linuxserver.io/alpine-3.17/ \
#  pip install ninja \
#  pip install --no-cache-dir lxml==4.9.4 \
#  pip3 install -U --no-cache-dir lxml \
#  pip install -U --no-cache-dir numpy \
#  pip install -U --no-cache-dir Pillow \
#  pip install -U --no-cache-dir webrtcvad-wheels \
    -r /app/bazarr/bin/requirements.txt \
    -r /app/bazarr/bin/postgres-requirements.txt && \
  echo "**** clean up ****" && \
  apk del --purge \
    build-dependencies && \
  rm -rf \
    $HOME/.cache \
    $HOME/.cargo \
    /tmp/*

# add local files
COPY root/ /

# add unrar
COPY --from=unrar /usr/bin/unrar-alpine /usr/bin/unrar

# ports and volumes
EXPOSE 6767

VOLUME /config

# syntax=docker/dockerfile:1

FROM arago/hiro-actionhandler:v1.1.2

USER root

COPY . /scripts

RUN chown hiro:hiro /scripts/*

RUN chown hiro:hiro /scripts/*
RUN apk add --no-cache python3 py3-pip \
    && apk add --no-cache --virtual build-deps make \
    gcc musl-dev python3-dev libffi-dev openssl-dev cargo

RUN pip3 install --no-cache-dir -r /scripts/requirements.txt \
    && apk del build-deps \
    && rm -rf /root/.cargo

USER hiro

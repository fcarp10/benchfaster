FROM docker.io/library/golang:latest AS build

LABEL maintainer="Marc Michalke"

WORKDIR /app

COPY . ./
RUN make prereqs && make build

FROM docker.io/library/golang:latest AS build

LABEL maintainer="Marc Michalke"

WORKDIR /app

COPY . ./
RUN make prereqs && make build

FROM docker.io/library/alpine:latest
RUN mkdir -p /app/bin
COPY --from=build /app/bin/clusterlink /app/bin/clusterlink

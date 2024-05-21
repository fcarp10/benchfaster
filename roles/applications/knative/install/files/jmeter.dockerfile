FROM debian:trixie-slim

RUN apt update && DEBIAN_FRONTEND=noninteractive apt install curl openjdk-21-jdk wget jmeter -y
RUN wget -q -nc https://archive.apache.org/dist/jmeter/binaries/apache-jmeter-5.5.tgz && \
  tar xf apache-jmeter-5.5.tgz && \
  mv /usr/share/jmeter /usr/share/jmeter-old && \
  mv apache-jmeter-5.5 /usr/share/jmeter

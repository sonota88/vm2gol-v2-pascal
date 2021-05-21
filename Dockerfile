# docker build -t my:free-pascal .
# docker run --rm -it -v"$(pwd):/root/work" my:free-pascal fpc -h

FROM ubuntu:18.04

RUN apt-get update \
  && apt-get -y install --no-install-recommends \
    fpc \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /root/work

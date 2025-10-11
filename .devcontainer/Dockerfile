#### Base Image
# usage:
# docker build -f ./.devcontainer/Dockerfile --tag=devcontainer:latest .
FROM ubuntu:24.04 AS setup-cpp-ubuntu

RUN apt-get update -qq && \
    # install nodejs and ruby-rubygems
    apt-get install -y --no-install-recommends direnv \
        libxerces-c-dev libssl-dev libzmq3-dev libbz2-dev \
        git ruby-rubygems nodejs npm busybox symlinks \
        pipx python3-pip python-is-python3 && \
    gem install asciidoctor:2.0.23 coderay && \
    # install setup-cpp
    npm install -g setup-cpp@v1.7.1 && \
    # install the compiler and tools
    NODE_OPTIONS="--enable-source-maps" \
    setup-cpp \
        --nala true \
        --compiler gcc \
        --ninja true \
        --cmake true \
        --make true \
        --gcovr true \
        --doxygen true \
        --ccache true && \
    # cleanup
    nala autoremove -y && \
    nala autopurge -y && \
    apt-get clean && \
    nala clean --lists && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/*

#### Building (example)
FROM setup-cpp-ubuntu AS builder

# Include project
WORKDIR /axcioma
COPY . .

# Build project
RUN bash -c 'source ~/.cpprc && ./build-taox11-on-linux.sh'

ENV CC=gcc
ENV CXX=g++
ENV BRIX11_NUMBER_OF_PROCESSORS=6
ENV BRIX11_VERBOSE=2

# for interactive tests
ENTRYPOINT ["/bin/bash"]

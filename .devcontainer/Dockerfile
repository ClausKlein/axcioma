#### Base Image
# usage:
# docker build -f ./.devcontainer/Dockerfile --tag=devcontainer:latest .
FROM ubuntu:22.04 as setup-cpp-ubuntu

RUN apt-get update -qq && \
    # install nodejs and ruby-rubygems
    apt-get install -y --no-install-recommends direnv \
        libxerces-c-dev libssl-dev libzmq3-dev libbz2-dev \
        git ruby-rubygems nodejs npm busybox symlinks && \
    gem install asciidoctor:2.0.15 coderay && \
    # install setup-cpp
    npm install -g setup-cpp@v0.37.0 && \
    # install the compiler and tools
    setup-cpp \
        --nala true \
        --compiler llvm \
        --python true \
        --make true \
        --gcovr true \
        --doxygen true \
        --ccache true && \
    pip install cmake ninja builddriver && \
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

ENV CC clang
ENV CXX clang++
ENV BRIX11_NUMBER_OF_PROCESSORS 6
ENV BRIX11_VERBOSE 2

# for interactive tests
ENTRYPOINT ["/bin/bash"]

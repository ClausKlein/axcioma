#### Base Image
FROM ubuntu:22.04 as setup-cpp-ubuntu

RUN apt-get update -qq && \
    # install nodejs and ruby-rubygems
    apt-get install -y --no-install-recommends \
        libxerces-c-dev libssl-dev libzmq3-dev libbz2-dev \
        git ruby-rubygems nodejs npm vim symlinks && \
    gem install asciidoctor:2.0.15 coderay && \
    # install setup-cpp
    npm install -g setup-cpp@v0.35.1 && \
    # install the compiler and tools
    setup-cpp \
        --nala true \
        --compiler llvm \
        --task true \
        --python true \
        --make true \
        --cppcheck true \
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

RUN git clone https://github.com/ClausKlein/axcioma.git && \
    cd axcioma && git switch feature/build-on-osx && git pull && \
    bin/brix11 bootstrap taox11

ENV CC gcc
ENV CXX g++
ENV BRIX11_NUMBER_OF_PROCESSORS 6
ENV BRIX11_VERBOSE 2

WORKDIR /axcioma

ENTRYPOINT ["/bin/bash"]

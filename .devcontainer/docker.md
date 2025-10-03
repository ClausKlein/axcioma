## Docker Instructions

If you have [Docker](https://www.docker.com/) installed, you can run this
in your terminal, when the Dockerfile is inside the `.devcontainer` directory:

```bash
docker build -f ./.devcontainer/Dockerfile --tag=devcontainer:latest .
docker run -it devcontainer:latest
```

This command will put you in a `bash` session in a Ubuntu 22.04 Docker container,
with all of the tools listed in the [Dependencies](#dependencies) section already installed.
Additionally, you will have `g++-13` and `clang++-17` installed as the default
versions of `g++` and `clang++`.

You will be logged in as root, so you will see the `#` symbol as your prompt.
You will be in a directory that contains a copy of the `axcioma`;
any changes you make to your local copy will not be updated in the Docker image
until you rebuild it.
If you need to mount your local copy directly in the Docker image, see
[Docker volumes docs](https://docs.docker.com/storage/volumes/).
TLDR:

```bash
mkdir -p /tmp/devcontainer
docker run -it \
	-v /tmp/devcontainer:/tmp/hostdir \
	devcontainer:latest
```

You can configure and build using these command:

```bash
/axcioma# ./build-taox11-on-linux.sh
```

All of the tools needed to build this project are installed in the Docker image.


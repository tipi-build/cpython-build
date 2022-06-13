Python 3.10+ build for Tipi
===========================

In [tipi](https://tipi.build)'s release we ship a number of tools requiring recent versions of Python (that is 3.9+ at time of writing) to be available on the executing system (among other `emsdk`). 

On the other hand `tipi-cli` should remain compatible with older releases of supported Linux distributions (Ubunt 16.04 we're looking at you) for which no official Python package has been released.

For this reason we package & ship our own recent, relocatable build of Python 3.10+ bundled with OpenSSL 1.1.1o 

Build it
--------

```sh
export OPENSSL_VERSION="1.1.1o"
export PYTHON_VERSION="3.10.5"
docker build . --progress=plain
...

# create a container instance (not running is enough)
docker create $docker_image_id

# exctract the build
docker cp  $docker_container_id:/tipi-py/tipi-python-$PYTHON_VERSION-w-openssl-$OPENSSL_VERSION.zip .

# delete the container
docker rm $docker_container_id
```

Licence
-------

The content of this repository is Licensed under [MIT Licence](./LICENCE).

Use the packaged binaries as you wish - no guarantees though.
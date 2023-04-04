FROM tipibuild/tipi-ubuntu-1604-staging-694

ENV OPENSSL_VERSION="1.1.1o"
ENV PYTHON_VERSION="3.10.5"
ENV INSTALL_DIR="/tipi-py/sysroot"
ENV OUTPUT_DIR="/tipi-py"

ENV CFLAGS="-O3 -pipe"
ENV CXXFLAGS="-O3 -pipe"

# all we need to do the build
RUN apt update \
 && apt install -y build-essential git curl wget zip unzip chrpath\
 && apt install -y zlib1g-dev libbz2-dev uuid-dev tk-dev liblzma-dev libgdbm-dev libsqlite3-dev libbz2-dev libreadline-dev zlib1g-dev libncursesw5-dev libffi-dev
 
# openssl from source -_-
ENV ORIGIN="\$ORIGIN"
RUN wget --no-check-certificate https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz \
 && tar xzvf openssl-$OPENSSL_VERSION.tar.gz \
 && cd openssl-$OPENSSL_VERSION \
 && ./config -Wl,--enable-new-dtags  -Wl,-rpath,\$\$ORIGIN/../lib -Wl,-rpath,\$\$ORIGIN/../../lib -Wl,-rpath,\$\$ORIGIN --prefix=$INSTALL_DIR --libdir=lib --openssldir=/etc/ssl \
 && make -j1 depend \
 && make -j$(expr $(nproc) + 1) \
 && make install_sw

RUN tipi --dont-upgrade bundle $INSTALL_DIR $INSTALL_DIR/lib 0 

# python from source
RUN wget https://www.python.org/ftp/python/$PYTHON_VERSION/Python-$PYTHON_VERSION.tgz \
 && tar xzvf Python-$PYTHON_VERSION.tgz \
 && cd Python-$PYTHON_VERSION 

WORKDIR Python-$PYTHON_VERSION

# some of the magic that makes python "movable"
# NOTE: by setting the RUNPATH (instead of RPATH) we still allow for monkeypatching
# NOTE: we define $ORIGIN so that double-escaping-and-then-interpolation doesn't break everything... thanks many levels of autoconf+makefiles
ENV LDFLAGS_NODIST="-L$INSTALL_DIR/lib -Wl,--enable-new-dtags -Wl,-z,origin -Wl,-rpath='\$\$ORIGIN/../lib' -Wl,-rpath='\$\$ORIGIN'"

# we enable PGO :top:
RUN ./configure -C --with-openssl=$INSTALL_DIR --with-openssl-rpath=auto --enable-ipv6 --prefix=$INSTALL_DIR --enable-optimizations

RUN make -j$(expr $(nproc) + 1)

RUN make install

# a small homegrown script to bend the dynamic-module's RPATH so they find their own dependencies
# ...why oh why
WORKDIR $INSTALL_DIR
COPY patch_so_rpaths.sh /patch_so_rpaths.sh
RUN chmod +x /patch_so_rpaths.sh \
 && /patch_so_rpaths.sh $INSTALL_DIR
# Ensure RPATH is working relatively and doesn't rely on absolute RPATHs
RUN mv $INSTALL_DIR $INSTALL_DIR-moved
RUN tipi --dont-upgrade bundle $INSTALL_DIR-moved $INSTALL_DIR-moved/lib 0  

# archive stuff so we can extract it easily
RUN mkdir -p $OUTPUT_DIR \
 && cd $INSTALL_DIR-moved \
 && zip -r $OUTPUT_DIR/tipi-python-$PYTHON_VERSION-w-openssl-$OPENSSL_VERSION.zip .  

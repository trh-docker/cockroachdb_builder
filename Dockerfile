FROM quay.io/spivegin/golang:v1.12.5

WORKDIR $GOPATH

RUN chmod -R a+w $(go env GOTOOLDIR)

# Allow Go support files in gdb.
RUN echo "add-auto-load-safe-path $(go env GOROOT)/src/runtime/runtime-gdb.py" > ~/.gdbinit

RUN apt-get update && apt-get install -y gnupg2 tar git curl wget apt-transport-https ca-certificates build-essential &&\
    curl -s https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add && echo 'deb https://deb.nodesource.com/node_10.x stretch main' > /etc/apt/sources.list.d/nodesource.list && echo "deb-src https://deb.nodesource.com/node_10.x stretch main" >> /etc/apt/sources.list.d/nodesource.list &&\
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - &&\
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list &&\
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg  add - &&\
    curl -s https://dl.google.com/linux/linux_signing_key.pub | apt-key add - &&\
    echo "deb http://dl.google.com/linux/chrome/deb/ stable main" | tee /etc/apt/sources.list.d/google-chrome.list

# RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add - \
#     && echo 'deb https://deb.nodesource.com/node_10.x stretch main' | tee /etc/apt/sources.list.d/nodesource.list \
#     && curl -fsSL https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
#     && echo 'deb https://dl.yarnpkg.com/debian/ stable main' | tee /etc/apt/sources.list.d/yarn.list \
#     && curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - \
#     && echo 'deb https://packages.cloud.google.com/apt cloud-sdk-stretch main' | tee /etc/apt/sources.list.d/gcloud.list \
#     && curl -fsSL https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
#     && echo "deb [arch=amd64] https://dl.google.com/linux/chrome/deb/ stable main" | tee /etc/apt/sources.list.d/google.list \
#     && apt-get update

# ccache - speed up C and C++ compilation
# lsof - roachprod monitor
# netcat - roachprod monitor
# netbase - /etc/services etc
# nodejs - ui
# openjdk-8-jre - railroad diagram generation
# google-cloud-sdk - roachprod acceptance tests
# yarn - ui
# chrome - ui
# unzip - for installing awscli
RUN mkdir -p /usr/share/man/man1mkdir -p /usr/share/man/man1
RUN  apt-get update && apt-get install -y --no-install-recommends \
    ccache \
    google-cloud-sdk \
    lsof \
    netcat \
    netbase \
    nodejs \
    openjdk-8-jre-headless \
    openssh-client \
    yarn \
    google-chrome-stable \
    gnutls-bin \
    unzip &&\
    gperf &&\
    apt-get autoclean && apt-get autoremove &&\
    rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/*

# awscli - roachtests
# NB: we don't use apt-get because we need an up to date version of awscli
# RUN curl -fsSL "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip" && \
#     unzip awscli-bundle.zip && \
#     ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws && \
#     rm -rf awscli-bundle.zip awscli-bundle

# ENV PATH /opt/backtrace/bin:$PATH
RUN apt-get update && apt-get install gperf &&\
    apt-get autoclean && apt-get autoremove &&\
    rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/*

RUN mkdir crosstool-ng \
    && curl -fsSL http://crosstool-ng.org/download/crosstool-ng/crosstool-ng-1.23.0.tar.xz | tar --strip-components=1 -C crosstool-ng -xJ \
    && cd crosstool-ng \
    && ./configure --prefix /usr/local/ct-ng \
    && make -j$(nproc) \
    && make install \
    && cp ct-ng.comp /etc/bash_completion.d/ \
    && cd .. \
    && rm -rf crosstool-ng

COPY x86_64-unknown-linux-gnu.defconfig x86_64-unknown-linux-musl.defconfig x86_64-w64-mingw.defconfig aarch64-unknown-linux-gnueabi.defconfig ./
RUN mkdir src \
    && mkdir build && (cd build && DEFCONFIG=../x86_64-unknown-linux-gnu.defconfig      /usr/local/ct-ng/bin/ct-ng defconfig && /usr/local/ct-ng/bin/ct-ng build) && rm -rf build \
    && mkdir build && (cd build && DEFCONFIG=../x86_64-unknown-linux-musl.defconfig     /usr/local/ct-ng/bin/ct-ng defconfig && /usr/local/ct-ng/bin/ct-ng build) && rm -rf build \
    && mkdir build && (cd build && DEFCONFIG=../x86_64-w64-mingw.defconfig              /usr/local/ct-ng/bin/ct-ng defconfig && /usr/local/ct-ng/bin/ct-ng build) && rm -rf build \
    && mkdir build && (cd build && DEFCONFIG=../aarch64-unknown-linux-gnueabi.defconfig /usr/local/ct-ng/bin/ct-ng defconfig && /usr/local/ct-ng/bin/ct-ng build) && rm -rf build \
    && rm -rf src

RUN mkdir -p /usr/local/lib/ccache \
    && ln -s /usr/bin/ccache /usr/local/lib/ccache/x86_64-unknown-linux-gnu-cc \
    && ln -s /usr/bin/ccache /usr/local/lib/ccache/x86_64-unknown-linux-gnu-c++ \
    && ln -s /usr/bin/ccache /usr/local/lib/ccache/x86_64-unknown-linux-musl-cc \
    && ln -s /usr/bin/ccache /usr/local/lib/ccache/x86_64-unknown-linux-musl-c++ \
    && ln -s /usr/bin/ccache /usr/local/lib/ccache/x86_64-w64-mingw32-cc \
    && ln -s /usr/bin/ccache /usr/local/lib/ccache/x86_64-w64-mingw32-c++ \
    && ln -s /usr/bin/ccache /usr/local/lib/ccache/aarch64-unknown-linux-gnueabi-cc \
    && ln -s /usr/bin/ccache /usr/local/lib/ccache/aarch64-unknown-linux-gnueabi-c++

ENV PATH $PATH:/x-tools/x86_64-unknown-linux-gnu/bin:/x-tools/x86_64-unknown-linux-musl/bin:/x-tools/x86_64-w64-mingw32/bin:/x-tools/aarch64-unknown-linux-gnueabi/bin

# Build an msan-enabled build of libc++, following instructions from
# https://github.com/google/sanitizers/wiki/MemorySanitizerLibcxxHowTo
RUN mkdir llvm                    && curl -sfSL http://releases.llvm.org/3.9.1/llvm-3.9.1.src.tar.xz      | tar --strip-components=1 -C llvm -xJ \
    && mkdir llvm/projects/libcxx    && curl -sfSL http://releases.llvm.org/3.9.1/libcxx-3.9.1.src.tar.xz    | tar --strip-components=1 -C llvm/projects/libcxx -xJ \
    && mkdir llvm/projects/libcxxabi && curl -sfSL http://releases.llvm.org/3.9.1/libcxxabi-3.9.1.src.tar.xz | tar --strip-components=1 -C llvm/projects/libcxxabi -xJ \
    && curl -fsSL https://github.com/llvm-mirror/libcxx/commit/b640da0b315ead39690d4d65c76938ab8aeb5449.patch | git -C llvm/projects/libcxx apply \
    && mkdir libcxx_msan && (cd libcxx_msan && cmake ../llvm -DCMAKE_BUILD_TYPE=Release -DLLVM_USE_SANITIZER=Memory && make cxx -j$(nproc)) \
    && rm -rf llvm

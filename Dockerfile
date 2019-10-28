FROM quay.io/spivegin/golang:v1.12.5

WORKDIR $GOPATH

RUN chmod -R a+w $(go env GOTOOLDIR)

# Allow Go support files in gdb.
RUN echo "add-auto-load-safe-path $(go env GOROOT)/src/runtime/runtime-gdb.py" > ~/.gdbinit
RUN apt-get install gnupg2

RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add - \
    && echo 'deb https://deb.nodesource.com/node_10.x xenial main' | tee /etc/apt/sources.list.d/nodesource.list \
    && curl -fsSL https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
    && echo 'deb https://dl.yarnpkg.com/debian/ stable main' | tee /etc/apt/sources.list.d/yarn.list \
    && curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - \
    && echo 'deb https://packages.cloud.google.com/apt cloud-sdk-xenial main' | tee /etc/apt/sources.list.d/gcloud.list \
    && curl -fsSL https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && echo "deb [arch=amd64] https://dl.google.com/linux/chrome/deb/ stable main" | tee /etc/apt/sources.list.d/google.list \
    && apt-get update

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
RUN apt-get install -y --no-install-recommends \
    ccache \
    google-cloud-sdk \
    lsof \
    netcat \
    netbase \
    nodejs \
    openjdk-8-jre \
    openssh-client \
    yarn \
    google-chrome-stable \
    gnutls-bin \
    unzip \
    git

# awscli - roachtests
# NB: we don't use apt-get because we need an up to date version of awscli
RUN curl -fsSL "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip" && \
    unzip awscli-bundle.zip && \
    ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws && \
    rm -rf awscli-bundle.zip awscli-bundle

ENV PATH /opt/backtrace/bin:$PATH

RUN apt-get purge -y \
    apt-transport-https \
    automake \
    autopoint \
    bzip2 \
    file \
    flex \
    gawk \
    gettext \
    golang \
    gperf \
    help2man \
    python \
    rsync \
    texinfo \
    && apt-get autoremove -y


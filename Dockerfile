FROM php:8.1.2-cli-bullseye
ENV TERM=xterm \
    TZ=UTC \
    USER=app
WORKDIR /app
RUN --mount=type=tmpfs,target=/tmp \
    apt update && apt-get install -y curl vim less bash locales dumb-init unzip cmake git && \
    rm -rf /var/lib/apt/lists/* && \
    groupadd -g 3000 $USER && \
    useradd -d /app -u 3000 -g 3000 -ms /bin/bash $USER && \
    chown -R $USER:$USER /app && \
    curl -o /usr/local/bin/supercronic -L https://github.com/aptible/supercronic/releases/download/v0.2.27/supercronic-linux-amd64 && \
    chmod +x /usr/local/bin/supercronic && \
    curl -o /usr/local/bin/install-php-extensions -L https://github.com/mlocati/docker-php-extension-installer/releases/download/2.1.61/install-php-extensions && \
    chmod +x /usr/local/bin/install-php-extensions && \
    echo "ru_RU.UTF-8 UTF-8" >> /etc/locale.gen && \
    locale-gen en_US.UTF-8 && \
    locale-gen ru_RU.UTF-8 && \
    update-locale  && \
    pecl channel-update pecl.php.net && \
    cd /tmp && \
    curl -L https://github.com/protocolbuffers/protobuf/releases/download/v3.15.7/protoc-3.15.7-linux-x86_64.zip -o protoc.zip && \
    unzip protoc.zip -d protoc && \
    mv ./protoc/bin/protoc /usr/bin/protoc && \
    mv ./protoc/include/* /usr/include/ && \
    chmod +x /usr/bin/protoc && \
    chmod -R 755 /usr/include/google && \
    git clone -b v1.53.0 https://github.com/grpc/grpc && cd ./grpc && \
    git submodule update --init && \
    mkdir -p ./cmake/build && cd ./cmake/build && \
    cmake ../.. && make grpc_php_plugin && mv ./grpc_php_plugin /usr/bin/grpc_php_plugin && \
    apt-get remove -y cmake git && apt-get autoremove -y && apt-get clean
COPY --from=ghcr.io/roadrunner-server/roadrunner:2023.3.3 /usr/bin/rr /usr/local/bin/rr
RUN IPE_LZF_BETTERCOMPRESSION=1 install-php-extensions pgsql gd bcmath opcache pdo pdo_pgsql zip imap sockets protobuf-3.25.1 grpc-1.53.0
STOPSIGNAL SIGTERM
CMD rr serve -c /app/.rr.yaml

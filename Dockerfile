FROM ubuntu:20.04

RUN export DEBIAN_FRONTEND=noninteractive \ 
    && apt update \
    && apt install -y --no-install-recommends --no-install-suggests \
    sudo \
    python3-minimal \
    python3-setuptools \
    python3-pip \
    python3-dev \
    mariadb-client \
    libmysqlclient-dev \
    gcc \
    g++ \
    git \
    curl \
    cron \
    libfontconfig \
    xvfb \
    wkhtmltopdf \
    nginx \
    supervisor \
    && curl -sL https://deb.nodesource.com/setup_12.x | bash - \
    && apt install -y --no-install-recommends --no-install-suggests nodejs \
    && npm install -g yarn \
    && apt clean \
    && update-alternatives --install /usr/bin/python python /usr/bin/python3 99 \
    && update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 99 \
    && useradd frappe -m -d /data \
    && echo "frappe     ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/frappe \
    && pip3 install frappe-bench
COPY entrypoint.sh /
COPY wait-for-it.sh /usr/local/bin/
USER frappe
WORKDIR /data
EXPOSE 80
VOLUME [ "/data" ]
ENV FRAPPE_VERSION=version-12 \
    ERPNEXT_VERSION=version-12 \
    SITE=erpnext.example.com \
    MARIADB_ROOT_PASSWORD=admin \
    MARIADB_ROOT_USER=root \
    ADMIN_PASSWORD=admin \
    MARIADB_HOST=mariadb \
    REDIS_CACHE_HOST=redis-cache \
    REDIS_QUEUE_HOST=redis-queue \
    REDIS_SOCKETIO_HOST=redis-socketio \
    MARIADB_PORT=3306 \
    REDIS_CACHE_PORT=6379 \
    REDIS_QUEUE_PORT=6379 \
    REDIS_SOCKETIO_PORT=6379 \
    WORKERS=2 \
    DEVELOPER_MODE=0

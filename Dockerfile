FROM debian:10-slim

RUN apt-get update && apt-get install -y --no-install-suggests --no-install-recommends \
    sudo \
    cron \
    git \
    python3-dev \
    python3-setuptools \
    python3-pip \
    supervisor \
    mariadb-server \
    mariadb-client \
    libmariadb-dev \    
    redis \
    nodejs \
    npm \
    nginx \
    wget \
    && wget -q https://downloads.wkhtmltopdf.org/0.12/0.12.5/wkhtmltox_0.12.5-1.stretch_amd64.deb -O /tmp/wkhtmltox.deb \
    && apt-get install -y /tmp/wkhtmltox.deb \
    && rm -f /tmp/wkhtmltox.deb \
    && rm -rf /var/lib/apt/lists/* \
    && npm install -g yarn \
    && update-alternatives --install /usr/bin/python python /usr/bin/python3 3 \
    && update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 3
RUN pip install -e git+https://github.com/frappe/bench.git#egg=bench --no-cache
COPY ./my.cnf /etc/mysql/mariadb.cnf 
COPY ./wait-for-it.sh /wait-for-it.sh
RUN useradd frappe -m -d /data && echo "frappe ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
USER frappe
WORKDIR /data
VOLUME [ "/data" ]
ENV FRAPPE_BRANCH="version-12"
ENV ERPNEXT_BRANCH="version-12"
ENV MYSQL_ROOT_PASSWORD="erpnext"
ENV ADMIN_PASSWORD="erpnext"
ENV FRAPPE_SITE="erpnext"
ENV DB_NAME="erpnext"
ENV GUNICORN_WORKERS="4"
ENV MODE="production"
ENV DEVELOPER_MODE=""
ENV MAIL_SERVER=""
ENV MAIL_PORT=""
ENV MAIL_USE_SSL=""
ENV MAIL_LOGIN=""
ENV MAIL_PASSWORD=""
ENV MAIL_AUTO_EMAIL_ID=""
ENV HOSTNAME=""
EXPOSE 80 8000 9000
COPY ./entrypoint.sh /
CMD [ "bash", "/entrypoint.sh" ]

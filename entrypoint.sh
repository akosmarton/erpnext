#!/bin/bash
set -e

if [ ! -d /data/bench ]; then
    sudo chown frappe:frappe /data
    bench init --skip-redis-config-generation --frappe-branch "$FRAPPE_VERSION" /data/bench
fi
cd /data/bench

wait-for-it.sh "$MARIADB_HOST:$MARIADB_PORT" -t 60
wait-for-it.sh "$REDIS_CACHE_HOST:$REDIS_CACHE_PORT" -t 60
wait-for-it.sh "$REDIS_QUEUE_HOST:$REDIS_QUEUE_PORT" -t 60
wait-for-it.sh "$REDIS_SOCKETIO_HOST:$REDIS_SOCKETIO_PORT" -t 60

if [ ! -d /data/bench/apps/erpnext ]; then
    ./env/bin/pip install numpy==1.18.5
    ./env/bin/pip install pandas==0.24.2
    bench set-config -g db_host "$MARIADB_HOST"
    bench set-config -g --as-dict db_port $MARIADB_PORT
    bench set-config -g mariadb_root_username "$MARIADB_ROOT_USER"
    bench set-config -g mariadb_root_password "$MARIADB_ROOT_PASSWORD"
    bench set-config -g --as-dict restart_supervisor_on_update 0
    bench set-config -g --as-dict restart_systemd_on_update 0    
    bench get-app --branch "$ERPNEXT_VERSION" erpnext
fi

if [ ! -d /data/bench/sites/$SITE ]; then
    bench new-site --no-mariadb-socket --db-host "$MARIADB_HOST" --db-port "$MARIADB_PORT" --mariadb-root-username "$MARIADB_ROOT_USER" --mariadb-root-password "$MARIADB_ROOT_PASSWORD" --admin-password "$ADMIN_PASSWORD" --install-app erpnext "$SITE"
    bench set-default-site $SITE
fi

bench use $SITE

bench set-config -g db_host "$MARIADB_HOST"
bench set-config -g --as-dict db_port $MARIADB_PORT
bench set-config -g mariadb_root_username "$MARIADB_ROOT_USER"
bench set-config -g mariadb_root_password "$MARIADB_ROOT_PASSWORD"
bench set-config -g redis_cache "redis://$REDIS_CACHE_HOST:$REDIS_CACHE_PORT"
bench set-config -g redis_queue "redis://$REDIS_QUEUE_HOST:$REDIS_QUEUE_PORT"
bench set-config -g redis_socketio "redis://$REDIS_SOCKETIO_HOST:$REDIS_SOCKETIO_PORT"
bench set-config -g --as-dict gunicorn_workers $WORKERS
bench set-config -g --as-dict restart_supervisor_on_update 0
bench set-config -g --as-dict restart_systemd_on_update 0
bench set-admin-password "$ADMIN_PASSWORD"

bench enable-scheduler

bench setup backups
bench setup nginx --yes
sudo rm -rf /etc/nginx/sites-enabled/*
sudo ln -sf $PWD/config/nginx.conf /etc/nginx/conf.d/bench.conf
bench setup supervisor --yes
sudo ln -sf $PWD/config/supervisor.conf /etc/supervisor/conf.d/bench.conf

sudo cron

if (($DEVELOPER_MODE)); then
    bench set-config -g --as-dict developer_mode 1
    bench start
else
    bench set-config -g --as-dict developer_mode 0
    sudo nginx
    sudo supervisord -n -u root
fi
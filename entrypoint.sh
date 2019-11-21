#!/bin/bash
set -e
sudo cron
if [ ! -d /var/lib/mysql/mysql ]; then
    sudo mysql_install_db --user mysql --skip-test-db
fi 
sudo mysqld_safe --skip-grant-tables &
/wait-for-it.sh -t 30 localhost:3306
sudo mysql -u root -e "FLUSH PRIVILEGES; ALTER USER 'root'@'localhost' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD'; FLUSH PRIVILEGES;"
sudo killall -w mysqld
sudo mysqld_safe &
/wait-for-it.sh -t 30 localhost:3306
if [ ! -d $PWD/bench ]; then
    sudo chmod a+w /$PWD
    bench init --skip-redis-config-generation --frappe-branch $FRAPPE_BRANCH $PWD/bench
fi
cd $PWD/bench
bench set-config -g root_password $MYSQL_ROOT_PASSWORD
bench set-config -g gunicorn_workers $GUNICORN_WORKERS
if [ ! -d $PWD/apps/erpnext ]; then
    bench get-app --branch $ERPNEXT_BRANCH erpnext
fi
bench setup redis
if [ ! -d $PWD/sites/$FRAPPE_SITE ]; then
    redis-server $PWD/config/redis_queue.conf &>/dev/null &
    redis-server $PWD/config/redis_socketio.conf &>/dev/null &
    redis-server $PWD/config/redis_cache.conf &>/dev/null &
    bench new-site --db-name $DB_NAME --admin-password $ADMIN_PASSWORD $FRAPPE_SITE
    bench use $FRAPPE_SITE
    bench install-app erpnext
    bench enable-scheduler
    killall -w redis-server
fi
bench use $FRAPPE_SITE
bench set-admin-password $ADMIN_PASSWORD
if [ ! -z "$MAIL_SERVER" ]; then
    bench set-config mail_server $MAIL_SERVER
fi
if [ ! -z "$MAIL_PORT" ]; then
    bench set-config mail_port $MAIL_PORT
fi
if [ ! -z "$MAIL_USE_SSL" ]; then
    bench set-config use_ssl $MAIL_USE_SSL
fi
if [ ! -z "$MAIL_LOGIN" ]; then
    bench set-config mail_login $MAIL_LOGIN
fi
if [ ! -z "$MAIL_PASSWORD" ]; then
    bench set-config mail_password $MAIL_PASSWORD
fi
if [ ! -z "$MAIL_AUTO_EMAIL_ID" ]; then
    bench set-config auto_email_id $MAIL_AUTO_EMAIL_ID
fi
if [ ! -z "$DEVELOPER_MODE" ]; then
    bench set-config developer_mode $DEVELOPER_MODE
fi
bench set-url-root $FRAPPE_SITE "$HOSTNAME"
if [ "$MODE" == "production" ]; then
    bench setup backups
    bench setup nginx --yes
    sudo rm -rf /etc/nginx/sites-enabled/*
    sudo ln -s $PWD/config/nginx.conf /etc/nginx/sites-enabled/erpnext.conf
    sudo nginx
    bench setup supervisor --yes
    sudo ln -sf $PWD/config/supervisor.conf /etc/supervisor/conf.d/erpnext.conf
    sudo supervisord -n -u root
else
    bench start
fi
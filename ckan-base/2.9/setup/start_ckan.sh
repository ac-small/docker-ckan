#!/bin/bash

echo "STARTING CKAN ... "
# Run the prerun script to init CKAN and create the default admin user

python3 prerun.py
	
mkdir -p /var/lib/ckan/storage/uploads/user && \
chown -R root:root $CKAN_STORAGE_PATH/storage

# Run any startup scripts provided by images extending this one
if [[ -d "/docker-entrypoint.d" ]]
then
    for f in /docker-entrypoint.d/*; do
        case "$f" in
            *.sh)     echo "$0: Running init file $f"; . "$f" ;;
            *.py)     echo "$0: Running init file $f"; python3 "$f"; echo ;;
            *)        echo "$0: Ignoring $f (not an sh or py file)" ;;
        esac
        echo
    done
fi

# Set the common uwsgi options
UWSGI_OPTS="--plugins http,python \
            --socket /tmp/uwsgi.sock \
            --pyhome /srv/app \
            --wsgi-file /srv/app/wsgi.py \
            --module wsgi:application \
            --uid 92 --gid 92 \
            --http 0.0.0.0:5000 \
            --master --enable-threads \
            --lazy-apps \
            -p 2 -L -b 32768 \
            --harakiri $UWSGI_HARAKIRI"


if [ $? -eq 0 ]
then
    # Start supervisord
    supervisord --configuration /etc/supervisord.conf &
    # Start uwsgi
    sudo -u ckan -EH uwsgi $UWSGI_OPTS
else
  echo "[prerun] failed...not starting CKAN."
fi

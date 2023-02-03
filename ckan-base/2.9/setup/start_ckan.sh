#!/bin/bash


echo "Loading the following plugins: $CKAN__PLUGINS"
. $APP_DIR/bin/activate && cd $APP_DIR/src && \
        ckan config-tool $CKAN_INI "ckan.site_url = os.environ['CKAN_SITE_URL']" && \
        ckan config-tool $CKAN_INI "release.aafc.registry = os.environ['CKAN___REGISTRY__RELEASE__VERSION']" && \
        ckan config-tool $CKAN_INI "ckan.redis.url = os.environ['CKAN_REDIS_URL']" && \
        ckan config-tool $CKAN_INI "ckan.solr_url = os.environ['CKAN_SOLR_URL']" && \
        ckan config-tool $CKAN_INI "ckan.datapusher.url = os.environ['CKAN_DATAPUSHER_URL']" && \
        ckan config-tool $CKAN_INI "who.timeout = os.environ['CKAN_WHO_TIMEOUT']" && \
        ckan config-tool $CKAN_INI "who.httponly = os.environ['CKAN_WHO_SECURE']" && \
        ckan config-tool $CKAN_INI "who.secure = os.environ['CKAN_WHO_SECURE']" && \
		ckan config-tool $CKAN_INI "sqlalchemy.url = os.environ['DB_STRING']"


# Run the prerun script to init CKAN and create the default admin user
. $APP_DIR/bin/activate && cd $APP_DIR && \
    #ckan -c $CKAN_INI db upgrade && \
    python3 prerun.py
	
mkdir -p /var/lib/ckan/storage/uploads/user && \
chown -R root:root $CKAN_STORAGE_PATH/storage
    
# Set up crontab to collect tracking information hourly
# Note: "hourly_tasks.sh" refers to an executable script within the ckanext-aafc
#        extension located under the contrib/etl folder. 
service cron start
chmod +x /srv/app/src/ckanext-aafc/contrib/etl/hourly_tasks.sh
echo "CKAN_SQLALCHEMY_URL=$CKAN_SQLALCHEMY_URL
CKAN_DATASTORE_READ_URL=$CKAN_DATASTORE_READ_URL
CKAN_DATASTORE_WRITE_URL=$CKAN_DATASTORE_WRITE_URL
CKAN_SOLR_URL=$CKAN_SOLR_URL
0 * * * * /srv/app/src/ckanext-aafc/contrib/etl/hourly_tasks.sh" >> temp_cron.txt
cat temp_cron.txt | crontab -
rm temp_cron.txt

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

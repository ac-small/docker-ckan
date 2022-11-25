#!/bin/bash


echo "Loading the following plugins: $CKAN__PLUGINS"
. $APP_DIR/bin/activate && cd $APP_DIR/src && \
        ckan config-tool $CKAN_INI "ckan.plugins = $CKAN__PLUGINS" && \
        ckan config-tool $CKAN_INI "ckan.site_url=$CKAN_SITE_URL" && \
        ckan config-tool $CKAN_INI "ckan.site_title=$CKAN_SITE_TITLE" && \
        ckan config-tool $CKAN_INI "ckan.locale_order=$CKAN__LOCALE_ORDER" && \
        ckan config-tool $CKAN_INI "ckan.locales_offered=$CKAN__LOCALES_OFFERED" && \
        ckan config-tool $CKAN_INI "scheming.dataset_schemas=$CKAN___SCHEMING__DATASET_SCHEMAS" && \
        ckan config-tool $CKAN_INI "scheming.presets=$CKAN___SCHEMING__PRESETS" && \
        ckan config-tool $CKAN_INI "scheming.dataset_fallback=$CKAN___SCHEMING__DATASET_FALLBACK"
        ckan config-tool $CKAN_INI "ckan.search.show_all_types=$CKAN__SEARCH__SHOW_ALL_TYPES" && \
        ckan config-tool $CKAN_INI "licenses_group_url=$CKAN___LICENSES_GROUP_URL" && \
        ckan config-tool $CKAN_INI "ckan.views.default_views=$CKAN__VIEWS__DEFAULT_VIEWS" && \
        ckan config-tool $CKAN_INI "ckanext.geoview.ol_viewer.formats=$CKAN___CKANEXT__GEOVIEW__OL_VIEWER__FORMATS" && \
        ckan config-tool $CKAN_INI "search.facets.default = $CKAN___SEARCH__FACETS__DEFAULT" && \
        ckan config-tool $CKAN_INI "release.aafc.registry = $CKAN___REGISTRY__RELEASE__VERSION" && \
        ckan config-tool $CKAN_INI "ckan.storage_server = $CKAN__STORAGE_PATH" && \
        ckan config-tool $CKAN_INI "ckan.activity_streams_email_notifications = $CKAN_EMAIL_NOTIFICATIONS" && \
        ckan config-tool $CKAN_INI "smtp.server = $CKAN_SMTP_SERVER" && \
        ckan config-tool $CKAN_INI "smtp.starttls = $CKAN_SMTP_STARTTLS" && \
        ckan config-tool $CKAN_INI "smtp.user = $CKAN_SMTP_USER" && \
        ckan config-tool $CKAN_INI "smtp.password = $CKAN_SMTP_PASSWORD" && \
        ckan config-tool $CKAN_INI "smtp.mail_from = $CKAN_SMTP_MAIL_FROM" && \
        ckan config-tool $CKAN_INI "ckan.redis.url = $CKAN_REDIS_URL" && \
        ckan config-tool $CKAN_INI "ckan.solr_url = $CKAN_SOLR_URL" && \
        ckan config-tool $CKAN_INI "ckan.datapusher.url = $CKAN_DATAPUSHER_URL" && \
        ckan config-tool $CKAN_INI "who.timeout = $CKAN__WHO_TIMEOUT" && \
        ckan config-tool $CKAN_INI "who.httponly = $CKAN__WHO_HTTPONLY" && \
        ckan config-tool $CKAN_INI "who.secure = $CKAN__WHO_SECURE" && \
        ckan config-tool $CKAN_INI "ckan.tracking_enabled = $CKAN__TRACKING_ENABLED" && \
        ckan config-tool $CKAN_INI "ckan.cors.origin_allow_all = $CKAN__CORS_ORIGIN_ALLOW_ALL" && \
        ckan config-tool $CKAN_INI "ckan.cors.origin_whitelist = $CKAN__CORS_ORIGIN_WHITELIST" && \
        ckan config-tool $CKAN_INI "ckan.valid_url_schemes = $CKAN__VALID_URL_SCHEMES"

# Run the prerun script to init CKAN and create the default admin user
. $APP_DIR/bin/activate && cd $APP_DIR && \
    #ckan -c $CKAN_INI db upgrade && \
    python3 prerun.py
    
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

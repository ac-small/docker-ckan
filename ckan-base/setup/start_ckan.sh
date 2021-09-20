#!/bin/bash

# Update the plugins setting in the ini file with the values defined in the env var
echo "Loading the following plugins: $CKAN__PLUGINS"
. $APP_DIR/bin/activate && cd $APP_DIR/src && \	
	paster --plugin=ckan config-tool $CKAN_INI "ckan.plugins = $CKAN__PLUGINS" && \
	paster --plugin=ckan config-tool $CKAN_INI "ckan.site_url=$CKAN_SITE_URL" && \
	paster --plugin=ckan config-tool $CKAN_INI "ckan.site_title=$CKAN_SITE_TITLE" && \
	paster --plugin=ckan config-tool $CKAN_INI "ckan.locale_order=$CKAN__LOCALE_ORDER" && \
	paster --plugin=ckan config-tool $CKAN_INI "ckan.locales_offered=$CKAN__LOCALES_OFFERED" && \
	paster --plugin=ckan config-tool $CKAN_INI "scheming.dataset_schemas=$CKAN___SCHEMING__DATASET_SCHEMAS" && \
	paster --plugin=ckan config-tool $CKAN_INI "scheming.presets=$CKAN___SCHEMING__PRESETS" && \
	paster --plugin=ckan config-tool $CKAN_INI "scheming.dataset_fallback=$CKAN___SCHEMING__DATASET_FALLBACK"
	paster --plugin=ckan config-tool $CKAN_INI "ckan.search.show_all_types=$CKAN__SEARCH__SHOW_ALL_TYPES" && \
	paster --plugin=ckan config-tool $CKAN_INI "licenses_group_url=$CKAN___LICENSES_GROUP_URL" && \
	paster --plugin=ckan config-tool $CKAN_INI "ckan.views.default_views=$CKAN__VIEWS__DEFAULT_VIEWS" && \
	paster --plugin=ckan config-tool $CKAN_INI "ckanext.geoview.ol_viewer.formats=$CKAN___CKANEXT__GEOVIEW__OL_VIEWER__FORMATS" && \
	paster --plugin=ckan config-tool $CKAN_INI "search.facets.default = $CKAN___SEARCH__FACETS__DEFAULT" && \
	paster --plugin=ckan config-tool $CKAN_INI "release.aafc.registry = $CKAN___REGISTRY__RELEASE__VERSION" && \
	paster --plugin=ckan config-tool $CKAN_INI "ckan.storage_server = $CKAN__STORAGE_PATH" && \
	paster --plugin=ckan config-tool $CKAN_INI "ckan.activity_streams_email_notifications = $CKAN_EMAIL_NOTIFICATIONS" && \
	paster --plugin=ckan config-tool $CKAN_INI "smtp.server = $CKAN_SMTP_SERVER" && \
	paster --plugin=ckan config-tool $CKAN_INI "smtp.starttls = $CKAN_SMTP_STARTTLS" && \
	paster --plugin=ckan config-tool $CKAN_INI "smtp.user = $CKAN_SMTP_USER" && \
	paster --plugin=ckan config-tool $CKAN_INI "smtp.password = $CKAN_SMTP_PASSWORD" && \
	paster --plugin=ckan config-tool $CKAN_INI "smtp.mail_from = $CKAN_SMTP_MAIL_FROM" && \
	paster --plugin=ckan config-tool $CKAN_INI "ckan.redis.url = $CKAN_REDIS_URL" && \
	paster --plugin=ckan config-tool $CKAN_INI "ckan.solr_url = $CKAN_SOLR_URL" && \
	paster --plugin=ckan config-tool $CKAN_INI "ckan.datapusher.url = $CKAN_DATAPUSHER_URL" && \
	paster --plugin=ckan config-tool $CKAN_INI "who.timeout = $CKAN__WHO_TIMEOUT" && \
	paster --plugin=ckan config-tool $CKAN_INI "who.httponly = $CKAN__WHO_HTTPONLY" && \
	paster --plugin=ckan config-tool $CKAN_INI "who.secure = $CKAN__WHO_SECURE" && \
	paster --plugin=ckan config-tool $CKAN_INI "ckan.tracking_enabled = $CKAN__TRACKING_ENABLED" && \
	paster --plugin=ckan config-tool $CKAN_INI "ckan.cors.origin_allow_all = $CKAN__CORS_ORIGIN_ALLOW_ALL" && \
	paster --plugin=ckan config-tool $CKAN_INI "ckan.cors.origin_whitelist = $CKAN__CORS_ORIGIN_WHITELIST"

# Run the prerun script to init CKAN and create the default admin user
. $APP_DIR/bin/activate && cd $APP_DIR && \
    python prerun.py

# Set up crontab to collect tracking information hourly
# Note: "hourly_tasks.sh" refers to an executable script within the ckanext-aafc
#        extension located under the contrib/etl folder. 
sudo service cron start
sudo chmod +x /srv/app/src/ckanext-aafc/contrib/etl/hourly_tasks.sh
echo  "0 * * * * . /srv/app/src/ckanext-aafc/contrib/etl/hourly_tasks.sh" | crontab -

# Run any startup scripts provided by images extending this one
if [[ -d "/docker-entrypoint.d" ]]
then
    for f in /docker-entrypoint.d/*; do
        case "$f" in
            *.sh)     echo "$0: Running init file $f"; . "$f" ;;
            *.py)     echo "$0: Running init file $f"; python "$f"; echo ;;
            *)        echo "$0: Ignoring $f (not an sh or py file)" ;;
        esac
        echo
    done
fi

# Set the common uwsgi options
UWSGI_OPTS="--plugins http,python,gevent_python --socket /tmp/uwsgi.sock --uid 92 --gid 92 --http :5000 --master --enable-threads --pyhome /srv/app --paste config:/srv/app/production.ini --paste-logger --lazy-apps --gevent 2000 -p 2 -L -b 32768"

if [ $? -eq 0 ]
then
    # Start supervisord
    . $APP_DIR/bin/activate && cd $APP_DIR/src && \
    supervisord --configuration /etc/supervisord.conf &
    # Start uwsgi
    . $APP_DIR/bin/activate && cd $APP_DIR/src && \
    sudo -u ckan -EH uwsgi $UWSGI_OPTS
else
  echo "[prerun] failed...not starting CKAN."
fi

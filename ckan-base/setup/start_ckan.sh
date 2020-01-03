#!/bin/bash

# Update the plugins setting in the ini file with the values defined in the env var
echo "Loading the following plugins: $CKAN__PLUGINS"
. $APP_DIR/bin/activate && cd $APP_DIR/src && \	
	paster --plugin=ckan config-tool $CKAN_INI "ckan.plugins = $CKAN__PLUGINS" && \
	paster --plugin=ckan config-tool $CKAN_INI "ckan.site_url=$CKAN_SITE_URL" && \
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
	paster --plugin=ckan config-tool $CKAN_INI "release.aafc.registry = $CKAN___REGISTRY__RELEASE__VERSION"

# Run the prerun script to init CKAN and create the default admin user
. $APP_DIR/bin/activate && cd $APP_DIR && \
    python prerun.py

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
UWSGI_OPTS="--plugins http,python,gevent_python --socket /tmp/uwsgi.sock --uid 92 --gid 92 --http :5000 --master --enable-threads --pyhome /srv/app --paste config:/srv/app/production.ini --paste-logger --lazy-apps --gevent 2000 -p 2 -L"

# Check whether http basic auth password protection is enabled and enable basicauth routing on uwsgi respecfully
if [ $? -eq 0 ]
then
  if [ "$PASSWORD_PROTECT" = true ]
  then
    if [ "$HTPASSWD_USER" ] || [ "$HTPASSWD_PASSWORD" ]
    then
      # Generate htpasswd file for basicauth
      htpasswd -d -b -c /srv/app/.htpasswd $HTPASSWD_USER $HTPASSWD_PASSWORD
      # Start supervisord
      supervisord --configuration /etc/supervisord.conf &
      # Start uwsgi with basicauth
      sudo -u ckan -EH uwsgi --ini /srv/app/uwsgi.conf --pcre-jit $UWSGI_OPTS
    else
      echo "Missing HTPASSWD_USER or HTPASSWD_PASSWORD environment variables. Exiting..."
      exit 1
    fi
  else
    # Start supervisord
    . $APP_DIR/bin/activate && cd $APP_DIR/src && \
    supervisord --configuration /etc/supervisord.conf &
    # Start uwsgi
#    sudo -u ckan -EH uwsgi $UWSGI_OPTS
    . $APP_DIR/bin/activate && cd $APP_DIR/src && \
#    uwsgi $UWSGI_OPTS
     sudo -u ckan -EH uwsgi $UWSGI_OPTS
  fi
else
  echo "[prerun] failed...not starting CKAN."
fi

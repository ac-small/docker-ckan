#!/bin/bash

# Install any local extensions in the src_extensions volume
echo "Looking for local extensions to install..."
echo "Extension dir contents:"
ls -la $SRC_EXTENSIONS_DIR
for i in $SRC_EXTENSIONS_DIR/*
do
    if [ -d $i ];
    then

        if [ -f $i/pip-requirements.txt ];
        then
            . $APP_DIR/bin/activate && cd $SRC_EXTENSIONS_DIR && \
            pip install -r $i/pip-requirements.txt
            echo "Found requirements file in $i"
        fi
        if [ -f $i/requirements.txt ];
        then
            . $APP_DIR/bin/activate && cd $SRC_EXTENSIONS_DIR && \
            pip install -r $i/requirements.txt
            echo "Found requirements file in $i"
        fi
        if [ -f $i/dev-requirements.txt ];
        then
            . $APP_DIR/bin/activate && cd $SRC_EXTENSIONS_DIR && \
            pip install -r $i/dev-requirements.txt
            echo "Found dev-requirements file in $i"
        fi
        if [ -f $i/setup.py ];
        then
            cd $i
            . $APP_DIR/bin/activate && cd $SRC_EXTENSIONS_DIR && \
            python $i/setup.py develop
            echo "Found setup.py file in $i"
            cd $APP_DIR
        fi

        # Point `use` in test.ini to location of `test-core.ini`
        if [ -f $i/test.ini ];
        then
            echo "Updating \`test.ini\` reference to \`test-core.ini\` for plugin $i"
            . $APP_DIR/bin/activate && cd $SRC_EXTENSIONS_DIR && \
            paster --plugin=ckan config-tool $i/test.ini "use = config:../../src/ckan/test-core.ini"
        fi
    fi
done

# Set debug to true
echo "Enabling debug mode"
. $APP_DIR/bin/activate && cd $APP_DIR/src && \
	paster --plugin=ckan config-tool $CKAN_INI -s DEFAULT "debug = true"

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
paster --plugin=ckan config-tool $CKAN_INI "release.aafc.registry = $CKAN___REGISTRY__RELEASE__VERSION" && \
paster --plugin=ckan config-tool $CKAN_INI "ckan.storage_server = $CKAN__STORAGE_PATH" && \
paster --plugin=ckan config-tool $CKAN_INI "ckan.activity_streams_email_notifications = $CKAN_EMAIL_NOTIFICATIONS" && \
paster --plugin=ckan config-tool $CKAN_INI "smtp.server = $CKAN_SMTP_SERVER" && \
paster --plugin=ckan config-tool $CKAN_INI "smtp.starttls = $CKAN_SMTP_STARTTLS" && \
paster --plugin=ckan config-tool $CKAN_INI "smtp.user = $CKAN_SMTP_USER" && \
paster --plugin=ckan config-tool $CKAN_INI "smtp.password = $CKAN_SMTP_PASSWORD" && \
paster --plugin=ckan config-tool $CKAN_INI "smtp.mail_from = $CKAN_SMTP_MAIL_FROM" && \
paster --plugin=ckan config tool $CKAN_INI "ckan.redis.url = $CKAN_REDIS_URL" && \
paster --plugin=ckan config tool $CKAN_INI "ckan.solr_url = $CKAN_SOLR_URL" && \
paster --plugin=ckan config tool $CKAN_INI "ckan.datapusher.url = $CKAN_DATAPUSHER_URL"


# Update test-core.ini DB, SOLR & Redis settings
echo "Loading test settings into test-core.ini"
. $APP_DIR/bin/activate && cd $APP_DIR/src && \
paster --plugin=ckan config-tool $SRC_DIR/ckan/test-core.ini \
    "sqlalchemy.url = $TEST_CKAN_SQLALCHEMY_URL" \
    "ckan.datstore.write_url = $TEST_CKAN_DATASTORE_WRITE_URL" \
    "ckan.datstore.read_url = $TEST_CKAN_DATASTORE_READ_URL" \
    "solr_url = $TEST_CKAN_SOLR_URL" \
    "ckan.redis_url = $TEST_CKAN_REDIS_URL"

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

# Start supervisord
. $APP_DIR/bin/activate && cd $APP_DIR/src && \
supervisord --configuration /etc/supervisord.conf &

# Start the development server with automatic reload
. $APP_DIR/bin/activate && cd $APP_DIR/src && \
	paster serve --reload $CKAN_INI

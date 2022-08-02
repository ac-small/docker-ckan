FROM debian:stretch

# Internals, you probably don't need to change these
ENV APP_DIR=/srv/app
ENV SRC_DIR=/srv/app/src
ENV CKAN_INI=${APP_DIR}/ckan.ini
ENV PIP_SRC=${SRC_DIR}
ENV CKAN_STORAGE_PATH=/var/lib/ckan
ENV GIT_URL=https://github.com/ckan/ckan.git
# CKAN version to build
ENV GIT_BRANCH=ckan-2.9.5
# Customize these on the .env file if needed
ENV CKAN_SITE_URL=${CKAN_SITE_URL}
ENV CKAN__PLUGINS=${CKAN__PLUGINS}

# UWSGI options
ENV UWSGI_HARAKIRI=50

WORKDIR ${APP_DIR}

# Install necessary packages to run CKAN
RUN apt-get -q -y update \
        && apt-get -q -y install \
		tzdata \
        git \
        gettext \
        postgresql-client \
        python3 \
        libxml2 \
        libxslt \
        musl-dev \
        uwsgi \
        uwsgi-http \
        uwsgi-corerouter \
        uwsgi-python \
        py3-gevent \
        uwsgi-gevent \
        libmagic \
        curl \
        patch \
        sudo && \
    # Packages to build CKAN requirements and plugins
        gcc \
        make \
        g++ \
        autoconf \
        automake \
    	libtool \
        python3-dev \
        libxml2-dev \
        libxslt-dev \
        linux-headers \
        openssl-dev \
        libffi-dev \
        cargo && \
		
    # Create SRC_DIR
    mkdir -p ${SRC_DIR} && \
    # Install pip, supervisord and uwsgi
    curl -o ${SRC_DIR}/get-pip.py https://bootstrap.pypa.io/get-pip.py && \
    python3 ${SRC_DIR}/get-pip.py && \
	pip3 install pastescript && \
	pip3 install pastedeploy && \
    pip3 install supervisor uwsgi && \
    mkdir /etc/supervisord.d && \
    pip3 install virtualenv && \
    #pip wheel --wheel-dir=/wheels uwsgi gevent && \
    rm -rf ${SRC_DIR}/get-pip.py

RUN virtualenv ${APP_DIR} && \
    ln -s ${APP_DIR}/bin/pip /usr/local/bin/ckan-pip && \
    ln -s ${APP_DIR}/bin/paster /usr/local/bin/ckan-paster

COPY setup/supervisord.conf /etc

# Install CKAN
RUN . ${APP_DIR}/bin/activate && cd ${APP_DIR}/src && \
    pip3 install -e git+${GIT_URL}@${GIT_BRANCH}#egg=ckan && \
    cd ${SRC_DIR}/ckan && \
    cp who.ini ${APP_DIR} && \
    pip3 install -r requirement-setuptools.txt && \
    pip3 install --no-binary :all: -r requirements.txt && \
    # Install CKAN envvars to support loading config from environment variables
    pip3 install -e git+https://github.com/okfn/ckanext-envvars.git#egg=ckanext-envvars && \
    # Create and update CKAN config
    ckan generate config ${CKAN_INI} && \
    ckan config-tool ${CKAN_INI} "ckan.plugins = ${CKAN__PLUGINS}"

# Create a local user and group to run the app
RUN addgroup -g 92 -S ckan && \
    adduser -u 92 -h /srv/app -H -D -S -G ckan ckan

# Create local storage folder
RUN mkdir -p $CKAN_STORAGE_PATH && \
    chown -R ckan:ckan $CKAN_STORAGE_PATH

# Copy Azure public Postgresql cert
RUN mkdir -p ${APP_DIR}/.postgresql && \
    chown -R ckan:ckan ${APP_DIR}
COPY setup/root.crt ${APP_DIR}/.postgresql/root.crt

COPY 2.9/setup/prerun.py ${APP_DIR}
COPY 2.9/setup/supervisor.worker.conf /etc/supervisord.d/worker.conf
COPY 2.9/setup/start_ckan.sh ${APP_DIR}
ADD https://raw.githubusercontent.com/ckan/ckan/${GIT_BRANCH}/wsgi.py ${APP_DIR}

# Create entrypoint directory for children image scripts
ONBUILD RUN mkdir /docker-entrypoint.d

RUN chown ckan -R /srv/app

EXPOSE 5000

HEALTHCHECK --interval=60s --timeout=5s --retries=5 CMD curl --fail http://localhost:5000/api/3/action/status_show || exit 1

CMD ["/srv/app/start_ckan.sh"]
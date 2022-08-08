FROM debian:buster

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
ENV CKAN_SITE_URL=http://localhost:5000
ENV CKAN__PLUGINS image_view text_view recline_view datastore datapusher envvars

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
        libxslt1.1 \
        musl-dev \
        uwsgi \
        uwsgi-core \
        uwsgi-plugin-python \
        python-gevent \
        python3-psycopg2 \
        libmagic1 \
        curl \
        patch \
        sudo \
    # Packages to build CKAN requirements and plugins
        libpq-dev \
        gcc \
        make \
        g++ \
        autoconf \
        automake \
        libtool \
        python3-dev \
        libxml2-dev \
        libxslt-dev \
        linux-headers-amd64 \
        libssl-dev \
        libffi-dev \
        cargo && \
    # Create SRC_DIR
    mkdir -p ${SRC_DIR} && \
    # Install pip, supervisord and uwsgi
    curl -o ${SRC_DIR}/get-pip.py https://bootstrap.pypa.io/get-pip.py && \
    python3 ${SRC_DIR}/get-pip.py && \
    pip3 install supervisor uwsgi && \
    mkdir /etc/supervisord.d && \
    pip3 install virtualenv && \
    #pip wheel --wheel-dir=/wheels uwsgi gevent && \
    rm -rf ${SRC_DIR}/get-pip.py

RUN virtualenv ${APP_DIR} && \
    ln -s ${APP_DIR}/bin/pip /usr/local/bin/ckan-pip

COPY setup/supervisord.conf /etc

# Install CKAN
RUN pip3 install -e git+${GIT_URL}@${GIT_BRANCH}#egg=ckan && \
    cd ${SRC_DIR}/ckan && \
    cp who.ini ${APP_DIR} && \
    pip3 install -r requirement-setuptools.txt && \
    pip3 install --ignore-installed --no-binary :all -r requirements.txt && \
    pip3 install pastescript && \
    pip3 install pastedeploy

# Install CKAN envvars to support loading config from environment variables
RUN pip3 install -e git+https://github.com/okfn/ckanext-envvars.git#egg=ckanext-envvars
# Create and update CKAN config
RUN . ${APP_DIR}/bin/activate && cd ${APP_DIR}/src && \
    pip3 install psycopg2 && \
    ckan generate config ${CKAN_INI} && \
    ckan config-tool ${CKAN_INI} "ckan.plugins = ${CKAN__PLUGINS}"

# Create a local user and group to run the app
RUN groupadd -g 92 -r ckan && \
    useradd -u 92 -d /srv/app -M -r -g ckan ckan

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
COPY setup/uwsgi.conf /srv/app/uwsgi.conf
ADD https://raw.githubusercontent.com/ckan/ckan/${GIT_BRANCH}/wsgi.py ${APP_DIR}

# Create entrypoint directory for children image scripts
ONBUILD RUN mkdir /docker-entrypoint.d

RUN chown ckan -R /srv/app

EXPOSE 5000

HEALTHCHECK --interval=60s --timeout=5s --retries=5 CMD curl --fail http://localhost:5000/api/3/action/status_show || exit 1

USER root

CMD ["/srv/app/start_ckan.sh"]

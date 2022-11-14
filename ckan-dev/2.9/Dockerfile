# Change to local ckan-base if not pulling from Azure Registry
# From ckan-base:2.9
FROM ckancontainerreg.azurecr.io/base/ckan-base:2.9

MAINTAINER Alexis Small

ENV APP_DIR=/srv/app
ENV SRC_EXTENSIONS_DIR=/srv/app/src_extensions

# Install packages needed by the dev requirements
RUN apt-get -q -y install \
    libffi-dev \
    mc \
    vim

# Install CKAN dev requirements
RUN . $APP_DIR/bin/activate && cd $APP_DIR/src && \
    pip3 install -r https://raw.githubusercontent.com/ckan/ckan/${GIT_BRANCH}/dev-requirements.txt

# Create folder for local extensions sources
RUN mkdir $SRC_EXTENSIONS_DIR

COPY 2.9/setup/start_ckan_development.sh ${APP_DIR}

USER root

CMD ["/srv/app/start_ckan_development.sh"]
# If building all from local environment change to 
#FROM ckan-base:2.8
FROM ckancontainerreg.azurecr.io/base/ckan-base:2.8.3
MAINTAINER John Kolesar

ENV APP_DIR=/srv/app

RUN chown -R ckan:ckan ${APP_DIR}/*

#USER ckan

# Install any extensions needed by your CKAN instance
# (Make sure to add the plugins to CKAN__PLUGINS in the .env file)
# For instance:
#RUN pip install -e git+https://github.com/ckan/ckanext-pages.git#egg=ckanext-pages && \
#    pip install -e git+https://github.com/ckan/ckanext-dcat.git@v0.0.6#egg=ckanext-dcat && \
#    pip install -r https://raw.githubusercontent.com/ckan/ckanext-dcat/v0.0.6/requirements.txt
RUN . $APP_DIR/bin/activate && cd $APP_DIR/src && \
    pip install PyYAML && \
    pip install ckanapi && \
    pip install geojson && \
    pip install geomet

# Add text editor
RUN apt-get -q -y install \
    mc \
    vim

RUN . $APP_DIR/bin/activate && cd $APP_DIR/src && \
    pip install -e "git+https://github.com/aafc-ckan/ckanext-scheming.git#egg=ckanext-scheming" && \
    pip install -e git+https://github.com/ckan/ckanext-fluent.git#egg=ckanext-fluent && \
    pip install -r https://raw.githubusercontent.com/ckan/ckanext-spatial/master/requirements-py2.txt && \
    pip install -e git+https://github.com/ckan/ckanext-spatial.git#egg=ckanext-spatial && \
    pip install -r https://raw.githubusercontent.com/ckan/ckanext-geoview/master/pip-requirements.txt && \
    pip install -e git+https://github.com/ckan/ckanext-geoview.git#egg=ckanext-geoview && \
    pip install -e git+https://github.com/aafc-ckan/ckanext-aafc.git#egg=ckanext-aafc && \
    pip install -e git+https://github.com/aafc-ckan/ckanext-aafcesas.git#egg=ckanext-aafcesas
# Clone the extension(s) your are writing for your own project in the `src` folder
# to get them mounted in this image at runtime

# Install the extension(s) you wrote for your own project
# RUN pip install -e git+https://github.com/your-org/ckanext-your-extension.git@v1.0.0#egg=ckanext-your-extension

# Apply any patches needed to CKAN core or any of the built extensions (not the
# runtime mounted ones)
# See https://github.com/okfn/docker-ckan#applying-patches
COPY patches ${APP_DIR}/patches

RUN for d in $APP_DIR/patches/*; do \
        if [ -d $d ]; then \
            for f in `ls $d/*.patch | sort -g`; do \
                cd $SRC_DIR/`basename "$d"` && echo "$0: Applying patch $f to $SRC_DIR/`basename $d`"; patch -p1 < "$f" ; \
            done ; \
        fi ; \
    done

# RUN chown -R ckan:ckan ${APP_DIR}/*

# Prod build fails when user is ckan at the end of this script
#USER ckan

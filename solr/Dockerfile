FROM solr:6.6.5
MAINTAINER Alexis S.

# Enviroment
ENV SOLR_CORE ckan

# Assign permissions to create directories
USER root

# Create Directories
RUN mkdir -p /opt/solr/server/solr/$SOLR_CORE/conf
RUN mkdir -p /opt/solr/server/solr/$SOLR_CORE/data

# Adding Files
ADD solrconfig.xml \
https://raw.githubusercontent.com/aafc-ckan/docker-ckan/master/solr/schema.xml \
https://raw.githubusercontent.com/apache/lucene-solr/releases/lucene-solr/6.6.5/solr/server/solr/configsets/sample_techproducts_configs/conf/currency.xml \
https://raw.githubusercontent.com/apache/lucene-solr/releases/lucene-solr/6.6.5/solr/server/solr/configsets/basic_configs/conf/synonyms.txt \
https://raw.githubusercontent.com/apache/lucene-solr/releases/lucene-solr/6.6.5/solr/server/solr/configsets/basic_configs/conf/stopwords.txt \
https://raw.githubusercontent.com/apache/lucene-solr/releases/lucene-solr/6.6.5/solr/server/solr/configsets/basic_configs/conf/protwords.txt \
https://raw.githubusercontent.com/apache/lucene-solr/releases/lucene-solr/6.6.5/solr/server/solr/configsets/data_driven_schema_configs/conf/elevate.xml \
/opt/solr/server/solr/$SOLR_CORE/conf/

RUN cd /opt/solr/server/lib/ext
RUN apt-get -y update && apt-get -y upgrade
RUN apt-get -y install liblog4j2-java

# Create Core.properties
RUN echo name=$SOLR_CORE > /opt/solr/server/solr/$SOLR_CORE/core.properties

# Giving ownership to Solr
RUN chown -R $SOLR_USER:$SOLR_USER /opt/solr/server/solr/$SOLR_CORE

# User
# USER $SOLR_USER:$SOLR_USER

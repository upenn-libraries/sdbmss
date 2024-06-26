FROM ubuntu:24.04

ENV DEBIAN_FRONTEND="noninteractive"
ENV JAVA_VERSION="openjdk-11-jre"
ENV JENA_VERSION="3.14.0"

RUN apt-get update && \
  apt-get install -y ${JAVA_VERSION} curl && \
  apt-get clean

RUN curl -fsSL "https://archive.apache.org/dist/jena/binaries/apache-jena-${JENA_VERSION}.tar.gz" | tar zxf - && \
  mv apache-jena* /jena && \
  rm -f jena.tar.gz* && \
  cd /jena && rm -rf *javadoc* *src* bat

ENV PATH="${PATH}:/jena/bin"

WORKDIR /jena-fuseki/webapp/js/app
COPY qonsole-config.js ./

# user interface of query page
WORKDIR /jena-fuseki/webapp
COPY dataset.html ./

WORKDIR /jena-fuseki

# configuring authentication
COPY shiro.ini ./
# customizing max number of resultscat
COPY yasr.min.js ./webapp/js/lib/yasr.min.js

CMD rm /fuseki/system/tdb.lock ; rm /fuseki/databases/sdbm/tdb.lock ; ./fuseki-server

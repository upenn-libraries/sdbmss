FROM stain/jena-fuseki

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
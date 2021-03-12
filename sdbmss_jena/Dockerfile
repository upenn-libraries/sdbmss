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

COPY start_jena.sh ./
RUN chmod 755 ./start_jena.sh

CMD ./start_jena.sh
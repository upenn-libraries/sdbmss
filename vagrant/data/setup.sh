#!/bin/zsh

# The SDBM relies on a number of user-managed static HTML files: docs, tooltips, and uploads. These are 
# stored in the sdbm_data.tgz file. These files should be extracted and copied into the Rails app 
#container.

tar xf sdbm_data.tgz
cd sdbm_data          # if needed
docker cp docs $(docker ps -q -f name=app):/home/app/public/static/
docker cp tooltips $(docker ps -q -f name=app):/home/app/public/static/
docker cp uploads $(docker ps -q -f name=app):/home/app/public/static/
cd ..

# Copy the database SQL gzip file to the MYSQL container, gunzip it and
# load it.

docker cp sdbm.sql.gz  $(docker ps -q -f name=mysql):/tmp/sdbm.sql.gz
docker exec -i --workdir /tmp $(docker ps -q -f name=mysql) sh -c \ "gunzip -c /tmp/sdbm.sql.gz | mysql -u sdbm --password=password sdbm"
# remove the file (it's very big)
docker exec -it $(docker ps -q -f name=mysql) rm /tmp/sdbm.sql.gz
docker exec $(docker ps -q -f name=app) bundle exec rake db:migrate


# Re-index Solr
# Solr should be running in the Solr container. The Solr configuration is in the solr directory.

docker exec $(docker ps -q -f name=app) bundle exec rake sunspot:reindex > /dev/null 

# Jena setup
# For this step the TTL file is generated from the database and then loaded into Jena.

# Generate the test.ttl file
docker exec -t $(docker ps -q -f name=app) bundle exec rake sparql:test
# Copy the test.ttl file from docker to local directory
docker cp $(docker ps -q -f name=app):/home/app/test.ttl .
# Stop the Jena service before loading the test.ttl file
docker service scale sdbmss_jena=0
# Load the test.ttl file into the Jena Fuseki triple database store
docker run --rm  --entrypoint /jena-fuseki/tdbloader  --mount source=sdbmss_rdf_data,target=/fuseki  -v "$(pwd)":/data:ro gitlab.library.upenn.edu/sdbm/jena-fuseki:0c0a566a --loc=/fuseki/databases/sdbm /data/test.ttl
# Copy the dataset configuration file into the Jena data storage:
docker run --rm --mount source=sdbmss_rdf_data,target=/fuseki -v "$(pwd)/sdbm.ttl":/tmp/sdbm.ttl:ro alpine sh -c 'mkdir -p /fuseki/configuration && cp /tmp/sdbm.ttl /fuseki/configuration/sdbm.ttl && chmod 0644 /fuseki/configuration/sdbm.ttl'
# Now start up the Jena service
docker service scale sdbmss_jena=1

#/usr/bin/env bash

set -e  # Exit on any command failure

trap 'echo "Command failed: $BASH_COMMAND"' ERR # prints any bash command that fails and exits

# This script sets up the development environment for the Schoenberg Database of Manuscripts by:
# 1. Copying static assets into the Rails app
# 2. Loading the database
# 3. Setting up Solr
# 4. Indexing the database in Solr
# 5. Setting up Jena


CMD=$(basename $0)

function timestamp() {
	date +%Y%m%dT%H%M%S-%Z
}


# Step 1: Static assets setup

# The SDBM relies on a number of user-managed static HTML files: docs, tooltips, and uploads. 
# These are stored in the sdbm_data.tgz file. These files will be extracted and copied into 
# the Rails app container. 

# Check for files
if [[ -e sdbm_data.tgz && -e sdbm.sql.gz ]]
then
 	: # do nothing
 else
	echo "ERROR -- sdbm_data.tgz and/or sdbm.sql.gz not found. Please make sure both are in the current directory."
  	exit 1
fi


echo "[$CMD] $(timestamp) Load static assets..."

tar xf sdbm_data.tgz
cd sdbm_data          # if needed
docker cp docs $(docker ps -q -f name=app):/home/app/public/static/
echo "[$CMD] $(timestamp) docs loaded."

docker cp tooltips $(docker ps -q -f name=app):/home/app/public/static/
echo "[$CMD] $(timestamp) tooltips loaded."

docker cp uploads $(docker ps -q -f name=app):/home/app/public/static/
echo "[$CMD] $(timestamp) uploads loaded."
# Change 'sdbm.library' to sdbm-dev.library' in home_text.html file
sed --in-place 's/sdbm\.library\.upenn\.edu/sdbm-dev.library.upenn.edu/g' /sdbmss/rails_app/public/static/uploads/home_text.html

cd ..

echo "[$CMD] $(timestamp) Static assets loaded."

# Step 2: Database setup

# The database SQL file `sdbm.sql.gz` will be loaded into the MYSQL database. 

echo "[$CMD] $(timestamp) Load the database..."

docker cp sdbm.sql.gz  $(docker ps -q -f name=mysql):/tmp/sdbm.sql.gz
docker exec -i --workdir /tmp $(docker ps -q -f name=mysql) sh -c "gunzip -c /tmp/sdbm.sql.gz | mysql -u sdbm --password=password sdbm"
echo "[$CMD] $(timestamp) Database loaded."

# remove the file (it's very big)
docker exec -it $(docker ps -q -f name=mysql) rm /tmp/sdbm.sql.gz
docker exec $(docker ps -q -f name=app) bundle exec rake db:migrate
echo "[$CMD] $(timestamp) Database migration completed."

# Steps 3 & 4: Solr setup

# Solr should be running in the Solr container. The Solr configuration is in the solr directory.

echo "[$CMD] $(timestamp) Set up and re-index Solr..."

docker exec $(docker ps -q -f name=app) bundle exec rake sunspot:reindex > /dev/null 
echo "[$CMD] $(timestamp) Solr re-indexed."

# Step 5: Jena setup

# For this step the TTL file is generated from the database and then loaded into Jena.

echo "[$CMD] $(timestamp) Set up Jena Fuseki triple store..."

# Generate the test.ttl file
docker exec -t $(docker ps -q -f name=app) bundle exec rake sparql:test
echo "[$CMD] $(timestamp) test.ttl generated."

# Copy the test.ttl file from docker to local directory
docker cp $(docker ps -q -f name=app):/home/app/test.ttl .
echo "[$CMD] $(timestamp) test.ttl copied to local directory."

# Stop the Jena service before loading the test.ttl file
docker service scale sdbmss_jena=0
echo "[$CMD] $(timestamp) Jena service stopped."

# Load the test.ttl file into the Jena Fuseki triple database store
docker run --rm  --entrypoint /jena-fuseki/tdbloader  --mount source=sdbmss_rdf_data,target=/fuseki  -v "$(pwd)":/data:ro gitlab.library.upenn.edu/sdbm/jena-fuseki:0c0a566a --loc=/fuseki/databases/sdbm /data/test.ttl
echo "[$CMD] $(timestamp) test.ttl loaded."

# Copy the dataset configuration file into the Jena data storage:
docker run --rm --mount source=sdbmss_rdf_data,target=/fuseki -v "$(pwd)/sdbm.ttl":/tmp/sdbm.ttl:ro alpine sh -c 'mkdir -p /fuseki/configuration && cp /tmp/sdbm.ttl /fuseki/configuration/sdbm.ttl && chmod 0644 /fuseki/configuration/sdbm.ttl'
echo "[$CMD] $(timestamp) dataset configuration copied."

# Now start up the Jena service
docker service scale sdbmss_jena=1
echo "[$CMD] $(timestamp) Jena service restarted."
echo "[$CMD] $(timestamp) Jena setup completed."
echo "Setup complete."

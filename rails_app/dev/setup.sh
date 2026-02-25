#!/usr/bin/env bash

set -e  # Exit on any command failure

trap 'echo "Command failed: $BASH_COMMAND"' ERR # prints any bash command that fails and exits

# This script sets up the development environment for the Schoenberg Database of Manuscripts by:
# 1. Copying static assets into the Rails app
# 2. Loading the database
# 3. Creating (or updating) the contributor, editor, super_editor, and admin test users (password: testpassword)
# 4. Setting up Solr
# 5. Indexing the database in Solr
# 6. Setting up Jena

CMD=$(basename $0)
# absolute path to this directory
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
DOCKER_ENV=

function usage {
  echo "Usage: ${CMD} [-h] -e {LOCAL|VAGRANT}"
}

function description {
  cat <<EOF

Description:
------------
Setup SDBM development docker instance running on the local machine in docker
compose (the default) or in vagrant as a service in a docker swarm.

Options:
-------------------
-h              Print this help message and exit.
-e DOCKER_ENV   The docker environment; LOCAL or VAGRANT [required].

EOF
}

while getopts "he:" opt; do
  case "$opt" in
    h)
      usage
      description
      exit 0
      ;;
    e)
      DOCKER_ENV=$( tr '[:lower:]' '[:upper:]' <<< "${OPTARG}")
      ;;
    ?)
      usage
      echo "Error: did not recognize option, ${OPTARG}."
      echo "Please try -h for help."
      exit 1
      ;;
  esac
done

[[ "${DOCKER_ENV}" =~ ^(LOCAL|VAGRANT)$ ]] || {
  echo "[$CMD] ERROR: Invalid DOCKER_ENV: '${DOCKER_ENV}'"
  echo
  usage
  description
  exit 1
}


if [[ ${DOCKER_ENV} = LOCAL ]]
then
  # string to prepend to name in "docker ps -q -f name=PATTERN" queries; e.g.,
  #
  #   docker ps -q -f name=${CONTAINER_PREFIX}mysql
  DOCKER_ENV_FILE=${SCRIPT_DIR}/../.docker-environment
  source ${DOCKER_ENV_FILE}
  CONTAINER_PREFIX=${COMPOSE_PROJECT_NAME:-rails_app}-
  VOLUME_PREFIX=${COMPOSE_PROJECT_NAME:-rails_app}_
  COMPOSE_FILE=${SCRIPT_DIR}/../docker-compose.dev.yml
  SDBM_HOST=sdbmss.localhost
  LOCAL_CODE_DIR=${SCRIPT_DIR}/..
else
  ##
  # Vagrant+docker swarm settings
  CONTAINER_PREFIX=
  VOLUME_PREFIX=sdbmss_
  COMPOSE_FILE= # not needed
  SDBM_HOST=sdbm-dev.library.upenn.edu
  LOCAL_CODE_DIR=/sdbmss/rails_app/

fi

function timestamp() {
  date +%Y%m%dT%H%M%S-%Z
}

##
# Command to start or stop a docker swarm service or docker compose container.
#
# Usage: start_or_start_service {start|stop} SERVICE_NAME
#
# Where SERVICE_NAME is the docker-compose file service name, 'app`, `mysql`,
# `jena`, etc.
#
# If DOCKER_ENV is LOCAL, command issues
#
#    docker compose -f ${COMPOSE_FILE} --env-file ${DOCKER_ENV_FILE} {stop|start} SERVICE_NAME
#
# Otherwise, if DOCKER_ENV is VAGRANT, command issues
#
#   docker service scale {traefik|sdbmss}_SERVICE_NAME={0|1}
#
# When DOCKER_ENV is VAGRANT; dcocker swarm is running and the correct service
# prefix `sdbmss_` or `traefik_` is added.
#
# The service name is the service name from the docker compose file; e.g.,
# `app`, `mysql`, `jena`, etc. If DOCKER_ENV is LOCAL, a docker compose
function start_or_start_service() {
    [[ "${1}" = start ]] || [[ "${1}" = stop ]] || { echo "Please provide a command: start or stop"; return 1; }
    ss_command=${1}
    ss_service=${2:?Please provide a service name}
    if [[ ${DOCKER_ENV} = LOCAL ]]
    then
      echo "[$CMD] $(timestamp) Begin ${ss_command} container ${ss_service}"
      docker compose -f ${COMPOSE_FILE} --env-file ${DOCKER_ENV_FILE} ${ss_command} ${ss_service}
      echo "[$CMD] $(timestamp) Completed ${ss_command} container ${ss_service}"
    elif [[ ${DOCKER_ENV} = VAGRANT ]]
    then
      service_prefix=$([[ $ss_service = traefik ]] && echo traefik || echo sdbmss )
      service_name=${service_prefix}_${ss_service}
      echo "[$CMD] $(timestamp) Begin ${ss_command} ${service_name}"
      scale_value=$([[ ${ss_command} = stop ]] && echo 0 || echo 1 )
      docker service scale ${service_name}=${scale_value}
      echo "[$CMD] $(timestamp) Completed ${ss_command} ${service_name}"
    fi
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
cd sdbm_data   # if needed

docker cp docs $(docker ps -q -f name=${CONTAINER_PREFIX}app):/home/app/public/static/
echo "[$CMD] $(timestamp) docs loaded."

docker cp tooltips $(docker ps -q -f name=${CONTAINER_PREFIX}app):/home/app/public/static/
echo "[$CMD] $(timestamp) tooltips loaded."

docker cp uploads $(docker ps -q -f name=${CONTAINER_PREFIX}app):/home/app/public/static/
echo "[$CMD] $(timestamp) uploads loaded."

# Change 'sdbm.library' to sdbm-dev.library' in home_text.html file
home_text=${LOCAL_CODE_DIR}/public/static/uploads/home_text.html
# MacOS and Gnu sed have different in-place options; `-I` vs `--in-place`; this
# method is more portable.
tmp=mktemp && sed "s/sdbm\.library\.upenn\.edu/${SDBM_HOST}/g" ${home_text} >"$tmp" && cmp -s ${home_text} "${tmp}" || mv "${tmp}" ${home_text}
# Make sure to remove ${tmp}
rm -rf ${tmp}

cd ..

echo "[$CMD] $(timestamp) Static assets loaded."

# Step 2: Database setup

# The database SQL file `sdbm.sql.gz` will be loaded into the MYSQL database.

echo "[$CMD] $(timestamp) Load the database..."

docker cp sdbm.sql.gz  $(docker ps -q -f name=${CONTAINER_PREFIX}mysql):/tmp/sdbm.sql.gz
docker exec -i --workdir /tmp $(docker ps -q -f name=${CONTAINER_PREFIX}mysql) sh -c "gunzip -c /tmp/sdbm.sql.gz | mysql -u sdbm --password=password sdbm"
echo "[$CMD] $(timestamp) Database loaded."

# remove the file (it's very big)
docker exec -it $(docker ps -q -f name=${CONTAINER_PREFIX}mysql) rm /tmp/sdbm.sql.gz
docker exec $(docker ps -q -f name=${CONTAINER_PREFIX}app) bundle exec rake db:migrate
echo "[$CMD] $(timestamp) Database migration completed."

echo "[$CMD] $(timestamp) Add test users."
docker exec $(docker ps -q -f name=${CONTAINER_PREFIX}app) bundle exec rake sdbmss:add_update_test_users
echo "[$CMD] $(timestamp) Test users added."



# Steps 3 & 4: Solr setup
# Solr should be running in the Solr container. The Solr configuration is in the solr directory.
echo "[$CMD] $(timestamp) Set up and re-index Solr..."

docker exec $(docker ps -q -f name=${CONTAINER_PREFIX}app) bundle exec rake sunspot:reindex > /dev/null
echo "[$CMD] $(timestamp) Solr re-indexed."

# Step 5: Jena setup
# For this step the TTL file is generated from the database and then loaded into Jena.
echo "[$CMD] $(timestamp) Set up Jena Fuseki triple store..."

# Generate the test.ttl file
docker exec -t $(docker ps -q -f name=${CONTAINER_PREFIX}app) bundle exec rake sparql:test
echo "[$CMD] $(timestamp) test.ttl generated."

# Copy the test.ttl file from docker to local directory
docker cp $(docker ps -q -f name=${CONTAINER_PREFIX}app):/home/app/test.ttl .
echo "[$CMD] $(timestamp) test.ttl copied to local directory."

# Stop the Jena service before loading the test.ttl file
#docker service scale sdbmss_jena=0
echo "[$CMD] $(timestamp) Stopping Jena service."
start_or_start_service stop jena
echo "[$CMD] $(timestamp) Jena service stopped."

# Load the test.ttl file into the Jena Fuseki triple database store
docker run --rm  --entrypoint /jena-fuseki/tdbloader  --mount source=${VOLUME_PREFIX}rdf_data,target=/fuseki  -v "$(pwd)":/data:ro gitlab.library.upenn.edu/sdbm/jena-fuseki:0c0a566a --loc=/fuseki/databases/sdbm /data/test.ttl
echo "[$CMD] $(timestamp) test.ttl loaded."

# Copy the dataset configuration file into the Jena data storage:
docker run --rm --mount source=${VOLUME_PREFIX}rdf_data,target=/fuseki -v "$(pwd)/sdbm.ttl":/tmp/sdbm.ttl:ro alpine sh -c 'mkdir -p /fuseki/configuration && cp /tmp/sdbm.ttl /fuseki/configuration/sdbm.ttl && chmod 0644 /fuseki/configuration/sdbm.ttl'
echo "[$CMD] $(timestamp) dataset configuration copied."

# Now start up the Jena service
#docker service scale sdbmss_jena=1
start_or_start_service start jena
echo "[$CMD] $(timestamp) Jena service restarted."
echo "[$CMD] $(timestamp) Jena setup completed."
echo "Setup complete."

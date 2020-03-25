
Running the SDBM
======

The Schoenberg Database of Manuscripts. This is the Ruby on Rails /
Blacklight project reboot, started in late Nov 2014.

Note that we use 'sdbmss' everywhere in the code because 'sdbm' is the
name of a package in Ruby's standard library.

The application is currently structured to be run through [Docker](https://docs.docker.com/) using a single [docker compose](https://docs.docker.com/compose/) file.

Deployment
=====

To deploy this application in development or production, consult the [sdbm-config README](https://gitlab.library.upenn.edu/emeryr/sdbm-config/blob/master/README.md) in GitLab.

Installation
=====

**1. Clone the repository**

DEPRECATED -- USING ANSIBLE

	    git clone https://github.com/upenn-libraries/sdbmss.git

**2. Create file .docker-environment in the root folder of the cloned repository.  Define the following environment variables:**

DEPRECATED -- USING ANSIBLE

  This is the password for the public access point for the Jena server, both for making updates and for downloading RDF data file

			ADMIN_PASSWORD=<jena_admin_password>

  Login for private staging server deployment, if used

			RAILS_USER=<rails_staging_username>
			RAILS_PASS=<rails_staging_password>

  MYSQL database setup.  MYSQL_HOST is the name of the docker service defined in docker-compose.yml - everything else is up to you

			MYSQL_HOST=db
			MYSQL_DATABASE=<mysql_database_name>
			MYSQL_ROOT_PASSWORD=<mysql_root_password>
			MYSQL_USER=<mysql_username>
			MYSQL_PASSWORD=<mysql_password>

  RabbitMQ user and password; used for RDF live-update messaging system.  Define here, then set the correct values when instantiating the RabitMQ service **(done later)**

			RABBIT_USER=<rabbitmq_username>
			RABBIT_PASSWORD=<rabbitmg_password>

  Rails email setup.  Depends on where the application is running and what mailing service is available

			SDBMSS_APP_HOST=<email_app_host>
			SDBMSS_SMTP_HOST=<email_smtp_host>
			SDBMSS_EMAIL_FROM=<email_sender>
			SDBMSS_NOTIFY_EMAIL=<notification_email_sender>
			SDBMSS_NOTIFY_EMAIL_PASSWORD=<notification_email_password>
			# email address
			SDBMSS_EMAIL_EXCEPTIONS_TO=<send_exceptions_to_email>

  Generate separate keys (for each) by running rails task secret.

			SDBMSS_BLACKLIGHT_SECRET_KEY=<KEY>
			SDBMSS_DEVISE_SECRET_KEY=<KEY>
			SDBMSS_SECRET_KEY_BASE=<KEY>
			SDBMSS_SECRET_TOKEN=<KEY>

  URL for SOLR server, using relative location of docker service (using name 'solr' from docker-compose.yml)

			SOLR_URL=http://solr:8983/solr/development

**3. (Optional) Create a file VERSION in the root folder of the cloned repository.**

DEPRECATED -- USING ANSIBLE

  This is used to keep track of the version number for the purpose of tagging different docker images of the source code.  It is used by the script **build.sh**.  It's entire contents should just be:

			0.0.1

**4. Build and Run (First Time)**

DEPRECATED -- USING ANSIBLE

  Run *build.sh* or the following command:

	    docker build . -t sdbm:latest

  Start everything up:

	    docker-compose up --build

  If you prefer to start it detached, run this instead:

			docker-compose up --build --detach && docker-compose start

**5. First Time Setup: Rails and SOLR**

Before you begin, have the folliwing:

- Database backup from previous version sdbm.sql.gz

- Static assets from docs, tooltips, updloads (see: `docker volume inspect sdbmss_sdbm_docs` for location of files on filesystem)




  Setup database - perform setup:

	    docker exec $(docker ps -q -f name=sdbmss_rails) bundle exec rake db:setup

  (Optional: Load data from .sql dump)

```bash
docker cp sdbm.sql.gz  $(docker ps -q -f name=sdbmss_db):/tmp/sdbm.sql.gz
docker exec -it  $(docker ps -q -f name=sdbmss_db) bash
cd /tmp
gunzip sdbm.sql.gz
mysql -u <MYSQL_USER> -p <MYSQL_DATABASE> < sdbm.sql
rm sdbm.sql # remove the sql file (it's very big)
exit # exit the MySQL container
docker exec $(docker ps -q -f name=sdbmss_rails) bundle exec rake db:migrate
```

  **NOTE**: If you are importing from a data file that includes **Page** objects, the database records will be copied, but not the page files.  You will need to move these manually to the appropriate place in the public/static folder (uploads/, tooltips/ or docs/)

```
docker cp docs $(docker ps -q -f name=sdbmss_rails):/usr/src/app/public/static/
docker cp tooltips $(docker ps -q -f name=sdbmss_rails):/usr/src/app/public/static/
docker cp uploads $(docker ps -q -f name=sdbmss_rails):/usr/src/app/public/static/
```

  Index in Solr:

	    docker exec $(docker ps -q -f name=sdbmss_rails) bundle exec rake sunspot:reindex

**8. Jena First Time Setup**

  Regenerate RDF for dataset:

```
docker exec -t $(docker ps -q -f name=sdbmss_rails) bundle exec rake sparql:test
# file should be in ~/deployments/sdbms/test.ttl; gzip it
# gzip it
gzip ~/deployments/sdbmss/test.ttl
docker cp ~/deployments/sdbmss/test.ttl.gz $(docker ps -q -f name=sdbmss_jena):/tmp/
docker exec -it $(docker ps -q -f name=sdbmss_jena) bash
cd /tmp
gunzip test.ttl.gz
cd /jena-fuseki
./tdbloader --loc=/fuseki/databases/sdbm /tmp/test.ttl
# delete the test.ttl
rm /tmp/test.ttl
# exit and delete the test.ttl.gz
exit
rm ~/deployments/sdbms/test.ttl.gz
```


  From front-end interface (https://<hostname>/sparql), create new persistent dataset "sdbm", then scale the services:

      docker service scale sdbmss_jena=0
      docker service scale sdbmss_jena=1

      docker service scale sdbmss_rabbitmq=0
      docker service scale sdbmss_rabbitmq=1

      docker service scale sdbmss_rails=0
      docker service scale sdbmss_rails=1

Run the Jena verify task to confirm that it works:

      $ /bin/bash -l -c 'docker exec -t $(docker ps -q -f name=sdbmss_rails) bundle exec rake jena:verify'
      Starting Queue Listening
      Parsed contents: {"id"=>300122, "code"=>"200", "message"=>"OK"}
      Jena Update was Successful!
      Parsed contents: {"id"=>300211, "code"=>"200", "message"=>"OK"}
      Jena Update was Successful!
      Parsed contents: {"id"=>300212, "code"=>"200", "message"=>"OK"}
      Jena Update was Successful!
      Parsed contents: {"id"=>300213, "code"=>"200", "message"=>"OK"}
      Jena Update was Successful!
      # ... etc.


**9. Logging**

DEPRECATED?

  Logging is set in [docker-compose.yml](docker-compose.yml), and may need to be altered depending on the logging drivers available on the parent device.  For the current setup (JournalCtl), the logs may be accessed as follows:

  Entire logs:

	    journalctl -u docker

  Follow logs

	    journalctl -f -u docker

  Additionally, specific containers can be specified by name:

	    journalctl -u docker CONTAINER_NAME=sdbmss_rails_1
	    journalctl -f -u docker CONTAINER_NAME=sdbmss_rails_1 @follow

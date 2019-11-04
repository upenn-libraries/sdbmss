
Running the SDBM
======

The Schoenberg Database of Manuscripts. This is the Ruby on Rails /
Blacklight project reboot, started in late Nov 2014.

Note that we use 'sdbmss' everywhere in the code because 'sdbm' is the
name of a package in Ruby's standard library.

The application is currently structured to be run through [Docker](https://docs.docker.com/) using a single [docker compose](https://docs.docker.com/compose/) file.

Installation
=====

**1. Clone the repository**

	    git clone https://github.com/upenn-libraries/sdbmss.git

**2. Create file .docker-environment in the root folder of the cloned repository.  Define the following environment variables:**

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

  This is used to keep track of the version number for the purpose of tagging different docker images of the source code.  It is used by the script **build.sh**.  It's entire contents should just be:

			0.0.1

**4. Build and Run (First Time)**

  Run *build.sh* or the following command:

	    docker build . -t sdbm:latest

  Start everything up:

	    docker-compose up --build

  If you prefer to start it detached, run this instead:

			docker-compose up --build --detach && docker-compose start

**5. First Time Setup: Rails and SOLR**

  Setup database - perform setup:

	    docker-compose exec rails bundle exec rake db:setup

  (Optional: Load data from .sql dump)

	    docker cp sdbm.sql.gz sdbm_db_1:/tmp/sdbm.sql.gz
	    docker-compose exec db /bin/bash
	    cd /tmp
	    gunzip sdbm.sql.gz
	    mysql -u <MYSQL_USER> -p <MYSQL_DATABASE> < sdbm.sql
	    docker-compose exec rails bundle exec rake db:migrate

  **NOTE**: If you are importing from a data file that includes **Page** objects, the database records will be copied, but not the page files.  You will need to move these manually to the appropriate place in the public/static folder (uploads/, tooltips/ or docs/)

	    docker cp /tmp/docs/ current_rails_1:/usr/src/app/public/static/
	    docker cp /tmp/uploads/ current_rails_1:/usr/src/app/public/static/
	    docker cp /tmp/tooltips/ current_rails_1:/usr/src/app/public/static/

  Index in Solr:

	    docker-compose exec rails bundle exec rake sunspot:reindex

**6. Precompiling Assets**

  Preocompiling assets and performing migrations must be done AFTER the container is running:

	    docker-compose exec rails bundle exec rake assets:precompile
	    docker-compose restart rails

**7. RabbitMQ First Time Setup**

  First time we need to create user and grant permissions.  Use the same values for USER/PASS as set in your .docker-environment file

	    docker-compose exec rabbitmq /bin/bash
	    service rabbitmq-server start
	    rabbitmqctl add_user <RABBIT_USER> <RABBIT_PASSWORD>
	    rabbitmqctl set_user_tags <RABBIT_USER> adminstrator
	    rabbitmqctl set_permissions -p / <RABBIT_USER> ".*" ".*" ".*"

  Then restart dependent containers:

	    docker-compose restart interface
	    docker-compose restart rails

**8. Jena First Time Setup**

  Loading RDF file as basis for dataset:

	    docker cp /tmp/output.ttl.gz sdbmss_jena_1:/tmp/output.ttl.gz
	    docker-compose exec jena /bin/bash
	    gunzip /tmp/output.ttl.gz
	    ./tdbloader --loc=/fuseki/databases/sdbm /tmp/output.ttl

  From front-end interface (/sparql), create new dataset "sdbm", then restart the service:

	    docker-compose restart jena

**9. Logging**

  Logging is set in [docker-compose.yml](docker-compose.yml), and may need to be altered depending on the logging drivers available on the parent device.  For the current setup (JournalCtl), the logs may be accessed as follows:

  Entire logs:

	    journalctl -u docker

  Follow logs

	    journalctl -f -u docker

  Additionally, specific containers can be specified by name:

	    journalctl -u docker CONTAINER_NAME=sdbmss_rails_1
	    journalctl -f -u docker CONTAINER_NAME=sdbmss_rails_1 @follow
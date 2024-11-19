Installation
=====

## 1. Clone the repository

DEPRECATED -- USING ANSIBLE

	    git clone https://github.com/upenn-libraries/sdbmss.git

## 2. Create file docker environment file `.env`

DEPRECATED -- USING ANSIBLE

Create file docker environment file `.env` in the root folder of the cloned repository.  Define the following environment variables:

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

NB: The SOLR port here and everywhere else in the code is `8983`. Previous versions
of the code had `8982` in some cases. This was wrong and created a conflict
between Jetty (which was set to `8983` and the docker-compose values, which
had `8982`).

			SOLR_URL=http://solr:8983/solr/development

## 3. Build and Run (First Time)

DEPRECATED -- USING ANSIBLE

Start everything up:

	    docker-compose up --build

## 4. RabbitMQ First Time Setup

DEPRECATED -- USING ANSIBLE

First time we need to create user and grant permissions.  Use the same values for USER/PASS as set in your .docker-environment file

           docker-compose -f docker-compose-dev.yml rabbitmq /bin/bash
           rabbitmqctl add_user <RABBIT_USER> <RABBIT_PASSWORD>
           rabbitmqctl set_user_tags <RABBIT_USER> adminstrator
           rabbitmqctl set_permissions -p / <RABBIT_USER> ".*" ".*" ".*"

Then restart dependent containers:

	    docker-compose -f docker-compose-dev.yml restart interface
	    docker-compose -f docker-compose-dev.yml restart rails


## 5. First Time Setup: Rails, database,  and SOLR

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

## 6. Jena First Time Setup


### Build TTL from the database 

```
docker exec -t $(docker ps -q -f name=sdbmss_rails) bundle exec rake sparql:test
```
File should be in `.`; gzip it.

```
gzip test.ttl
```

### Import the data into Jena

Copy file to Jena container and gunzip it

```
docker cp test.ttl.gz $(docker ps -q -f name=sdbmss_jena):/tmp/
docker exec -t $(docker ps -q -f name=sdbmss_jena) gunzip /tmp/test.ttl.gz
```

Load the data into Jena

```
docker exec -t $(docker ps -q -f name=sdbmss_jena) sh -c 'cd /jena-fuseki && ./tdbloader --loc=/fuseki/databases/sdbm /tmp/test.ttl'
```

Clean up the files.

```
$ docker exec -t $(docker ps -q -f name=sdbmss_jena) rm /tmp/test.ttl
rm ~/deployments/sdbmss/test.ttl.gz
```

### Create the datset in Jena Fuseki.

Go here and create the sdbm dataset: <https://localhost/sparql/manage.html>

- Click 'add new data set'
- Enter 'sdbm'
- Select 'Persistent – dataset will persist across Fuseki restarts'
- Click 'create dataset'

Scale the services:

```
docker-compose -f docker-compose-dev.yml restart jena
docker-compose -f docker-compose-dev.yml restart rabbitmq
docker-compose -f docker-compose-dev.yml restart rails
```

Run the Jena verify task to confirm that it works. Be sure to hide the debugging output.

```
docker-compose -f docker-compose-dev.yml exec rails bundle exec rake jena:verify | grep -v DEBUG
```

NB: You may need to run the command more than once.

```
sdbm01[~]$ docker-compose -f docker-compose-dev.yml exec rails bundle exec rake jena:verify | grep -v DEBUG
Starting Queue Listening
No more messages in queue.
Remaining responses: 764
$ docker-compose -f docker-compose-dev.yml exec rails bundle exec rake jena:verify | grep -v DEBUG
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
```

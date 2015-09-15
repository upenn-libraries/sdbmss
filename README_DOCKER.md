
Running SDBM using Docker
=========================

Things to know:

- docker-compose is
  ["not yet considered production-ready"](https://docs.docker.com/compose/production/)
  so this is only intended as a proof of concept of Docker usage for
  development.  We would need to figure out how all this would work in
  production, including how Apache would fit in.

- this setup maps the standard ports used by MySQL, Solr, Rails to the
  same ports on the host, so none of these processes should already be
  running on the host.

- for persistent storage, we map volumes to directories on the host
  (we do not use data containers).

Step 1: Initialize databases and create user accounts
----------------------------------------------------

* In your cloned repository, copy the .docker-environment-sample file
  to .docker-environment and fill in the appropriate values.

  ```
  cd ~/sdbmss
  cp .docker-environment-sample .docker-environment
  vi .docker-environment
  ```

* In separate terminal windows, start the database container, and then
  run docker ps to find out its container ID (you'll need it for the
  next step).
  
  ```
  # do this in one window
  docker-compose run db
  # do this in another
  docker ps
  ```

* Run a MySQL client in the running database container and type in
  these commands to create the databases and user account (root
  password must match what's in the .docker-environment file):

  ```
  docker exec -it CONTAINER_ID mysql -u root -P 3306 -pPASSWORD
  CREATE DATABASE sdbm_live_copy;
  CREATE DATABASE sdbm;
  CREATE USER 'sdbm'@'%' IDENTIFIED BY 'PASSWORD';
  GRANT ALL PRIVILEGES ON *.* TO 'sdbm'@'%';
  FLUSH PRIVILEGES;
  ```

  Type \q to quit the client when you're done.

Step 2: Load data into the database
-----------------------------------

You can either load data by migrating it from the legacy database
(step 2a) OR by loading a .sql file containing already-migrated data
(step 2b).

Step 2a: Migrate legacy data
----------------------------

* This step MUST be done on the development virtual machine (VM) set
  up by Libraries IT for this project's use:

  Copy the legacy data from Oracle into a MySQL database called
  sdbm_live_copy, using the
  [oracle2mysql](https://github.com/codeforkjeff/oracle2mysql) script.

  ```
  # MUST be run on the dev VM with access to Oracle!
  cd ~/oracle2mysql
  python oracle2mysql.py oracle2mysql_conf
  cd ~
  mysqldump -u root sdbm_live_copy > sdbm_live_copy_`date +%Y_%m_%d`.sql
  ```

* Now, back on your host machine, import the sdbm_live_copy database:

  ```
  # copy the file you made on the dev VM in the previous step
  scp username@dev_vm_hostname:sdbm_live_copy_2015_07_30.sql .
  # load it into MySQL running in the docker container from Step 1
  cat sdbm_live_copy_2015_07_30.sql | docker exec -i CONTAINER_ID mysql -u sdbm -pPASSWORD sdbm_live_copy
  ```

* Run the data migration tasks to create a working Rails database out
  of the data in sdbm_live_copy (this takes a long time):

  ```
  # migrate sdbm_live_copy into new Rails schema
  docker-compose run rails bundle exec rake sdbmss:migrate_legacy_data
  # OPTIONAL: create some reference data for development use
  docker-compose run rails bundle exec rake sdbmss:create_reference_data
  # populate VIAF ID field in Name records
  docker-compose run rails bundle exec rake sdbmss:update_names[seed_data/names.csv]
  # (re)index the data in Solr
  docker-compose run solr bundle exec rake sunspot:reindex
  ```

Step 2b: Load an existing database
----------------------------------

As an ALTERNATIVE to Step 2a above, if you have a copy of an
already-migrated Rails database (created by mysqldump) and want to
import it:

  ```
  # load it into MySQL running in the docker container from Step 1
  cat sdbm_dump.sql | docker exec -i CONTAINER_ID mysql -u sdbm -pPASSWORD sdbm
  ```

Step 3: Run the application
---------------------------

* Rebuild your containers. You only need to do this step when Gemfile
  dependencies change, but it doesn't hurt to run this even if it's
  not necessary.

  ```
  docker-compose build
  ```

* If you have a running database container from Step 1 or 2, shut it
  down first or it will conflict with the next command.

  ```
  docker stop CONTAINER_ID
  ```

* To run the application:

  ```
  docker-compose up
  ```

Running Rails commands and other programs
-----------------------------------------

Any commands you would normally run in a development environment need
to run in one of the containers. For example, to run the Rails
migration task ("rake db:migrate"), you can spin up a new container:

  ```
  docker-compose run rails bundle exec rake db:migrate
  ```

Note that you use docker-compose here (rather than just docker) so
that the container has the appropriate mount points and network
connections to other containerized processes.

Alternatively, you can start a shell and run commands in a more
natural way without having to 'wrap' your command using
docker-compose:

  ```
  # run a shell inside the container
  docker-compose run rails /bin/bash
  # once in the new shell, you can run your commands as normal
  bundle exec rake db:migrate
  ```

Running The Test Suite
----------------------

* Run the following (note that we do NOT use the run_tests.sh script when running in a container):

  ```
  docker-compose run -e SOLR_URL=http://solr:8983/solr/test rails bundle exec rspec
  ```

Deploying to the Staging (Dev VM) Server
----------------------------------------

See [README_STAGING.md](README_STAGING.md) for details on how the
staging environment works. The instructions here are for how to deploy
to it.

* Run "ssh-add" to add your key to your ssh agent. This key should
  already be registered with Github, so that capistrano can use it
  (via ssh forwarding) to access the Github repo from the staging
  server. This needs to happen for the next step to work.

* Run capistrano, via the container, to deploy the latest code to the
  staging server. This will perform a number of tasks on staging,
  including putting a copy of the code in /var/www/sdbmss/current,
  updating the solr configuration and restarting it, and restarting
  the unicorn server.

  ```
  cd ~/sdbmss
  docker run -it -v $(readlink -f $SSH_AUTH_SOCK):/ssh-agent -e SSH_AUTH_SOCK=/ssh-agent sdbmss_rails bundle exec cap staging deploy
  ```

  Note that we use docker rather than docker-compose to run this
  command, because docker-compose won't allow us to to mount the
  /ssh-agent file via the command line.

* Note that capistrano does not run database migrations, so if you
  created any, you'll need to run them manually on staging afterwards:
 
  ```
  # Do this on staging
  cd ~/sdbmss/current
  bundle exec rake db:migrate
  ```


Running SDBM using Docker
=========================

These are some preliminary instructions on running the SDBM app in a
multi-container configuration using docker-compose. Important notes:

- docker-compose is
  ["not yet considered production-ready"](https://docs.docker.com/compose/production/)
  so this is only intended as a proof of concept of Docker usage for
  development.  We would need to figure out how all this would work in
  production, including how Apache would fit in.

- this setup maps the standard ports used by MySQL, Solr, Rails to the
  same ports on the host, so none of these processes should already be
  running on the host.

- for persistent storage, we map volumes to directories on the host.

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

Step 2a: Migrate legacy data
----------------------------

NOTE: If you have an already migrated database that you want to load,
do step 2b instead.

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


Running The Test Suite
----------------------

* Run the following (note that we do NOT use the run_tests.sh script when running in a container):

  ```
  docker-compose run -e SOLR_URL=http://solr:8983/solr/test rails bundle exec rspec
  ```

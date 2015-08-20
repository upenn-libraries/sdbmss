
Running SDBM using Docker
=========================

These are some preliminary instructions on running the SDBM app in
multi-container configuration using docker-compose.

Important notes:

- docker-compose is
  ["not yet considered production-ready"](https://docs.docker.com/compose/production/)
  so this is only intended as a proof of concept of Docker usage for
  development.  We would need to figure out how all this would work in
  production, including how Apache would fit in.

- this setup maps the standard ports used by MySQL, Solr, Rails to the
  same ports on the host, so none of these processes should already be
  running on the host.

- for persistent storage, we map volumes to directories on the host.

Step 1: Setup
-------------

* In your cloned repository, copy the .docker-environment-sample file
  to .docker-environment and fill in the appropriate values.

* In a terminal, start up the MySQL container (Docker will need to
  build some images, that's okay):

  ```
  docker-compose run db
  ```

  Your host's port 3306 should now be routed to the MySQL process
  running inside the container, which is how we are able to use
  "127.0.0.1" in the steps below. For some reason, Docker doesn't
  always set up this mapping correctly (it won't give you any
  message), and I don't know why. If this is the case, use the IP of
  the container you just started, which you can find out by typing:

  ```
  # look for the mysql container ID in this listing
  docker ps
  # now use that container ID in this command to find the IP address
  docker inspect CONTAINER_ID | grep IPAddress
  ```

* In another terminal, connect to the database and run these commands
  to create the databases and user account (change the passwords):

  ```
  mysql -u root -h 127.0.0.1 -P 3306 -pfillthisin
  CREATE DATABASE sdbm_live_copy;
  CREATE DATABASE sdbm;
  CREATE USER 'sdbm'@'%' IDENTIFIED BY 'fillthisin';
  GRANT ALL PRIVILEGES ON *.* TO 'sdbm'@'%';
  FLUSH PRIVILEGES;
  ```

* Now copy over the legacy data:

  First, make a straight copy of the tables from Oracle to MySQL, by
  running the
  [oracle2mysql](https://github.com/codeforkjeff/oracle2mysql) script.
  This MUST be done on the development virtual machine (VM) set up by
  Libraries IT for this project's use:

  ```
  cd ~/oracle2mysql
  python oracle2mysql.py oracle2mysql_conf
  cd ~
  mysqldump -u root sdbm_live_copy > sdbm_live_copy_`date +%Y_%m_%d`.sql
  ```

* Now, on your own machine, import the sdbm_live_copy database:

  ```
  # copy the file you made on the dev VM in the previous step
  scp username@dev_vm_hostname:sdbm_live_copy_2015_07_30.sql .
  # load it into MySQL
  cat sdbm_live_copy_2015_07_30.sql | mysql -u sdbm -h 127.0.0.1 -P 3306 -pfillthisin sdbm_live_copy
  ```

* Stop the database container (the next steps will cause Docker to
  automatically start it back up, which is what you want):

  ```
  docker-compose stop db
  ```

* Run the data migration tasks (this takes a long time):

  ```
  # migrate it into new Rails schema
  docker-compose run rails bundle exec rake sdbmss:migrate_legacy_data
  # OPTIONAL: create some reference data for development use
  docker-compose run rails bundle exec rake sdbmss:create_reference_data
  # populate VIAF ID field in Name records
  docker-compose run rails bundle exec rake sdbmss:update_names[seed_data/names.csv]
  # (re)index the data in Solr
  docker-compose run solr bundle exec rake sunspot:reindex
  ```

  OR, as an alternative to doing the migration, if you have a copy of
  an already-migrated Rails database and want to import it:

  ```
  mysqldump -u root sdbm > sdbm_dump.sql
  cat sdbm_dump.sql | mysql -u sdbm -h 127.0.0.1 -pyourpassword sdbm
  ```

Step 2: Run the application
---------------------------

* Rebuild your containers. You only need to do this step when Gemfile
  dependencies change, but it never hurts to run this.

  ```
  docker-compose build
  ```

* Run:

  ```
  docker-compose up
  ```


Running The Test Suite
----------------------

For some reason, Capybara doesn't correctly display the progress of
tests when run in a container this way.

* Run the following (note that we do NOT use the run_tests.sh script when running in a container):

  ```
  docker-compose run -e SOLR_URL=http://solr:8983/solr/test rails bundle exec rspec
  ```



sdbmss
======

The Schoenberg Database of Manuscripts. This is the Ruby on Rails /
Blacklight project reboot, started in late Nov 2014.

Note that we use 'sdbmss' everywhere in the code because 'sdbm' is the
name of a package in Ruby's standard library.

Installation Notes
------------------

You only need to do the steps in this section once.

* Install Ruby 2.x on your system, preferably 2.1.5. Rails 4.x only
  requires Ruby 1.9.3, but the code here uses 2.x features like
  keyword arguments.

* Install the following libraries from the system packages. (These are
  the package names in Debian; the names will probably differ on other
  systems.)
  
  ```
  g++
  make
  ruby-dev
  mysql-server
  mysql-client-5.5
  libmysqlclient-dev
  nodejs
  ```
  
* Clone the git repository into your home directory. This will give
  you a folder called ~/sdbm

  ```
  cd ~
  git clone git@github.com:upenn-libraries/sdbmss.git
  ```

* Run this to install the Ruby gems needed by the project:

  ```
  cd ~/sdbmss
  bundle install
  ```

* Install Java 1.7 so Solr can run. Do this in whatever way makes
  sense.

* Create a MySQL account and some databases.

  ```
  mysql -u root
  CREATE DATABASE sdbm_live_copy;
  CREATE DATABASE sdbm;
  CREATE USER 'sdbm'@'localhost' IDENTIFIED BY 'xxx';
  GRANT ALL PRIVILEGES ON *.* TO 'sdbm'@'localhost';
  FLUSH PRIVILEGES
  ```

* Set environment variables in your .bashrc file (or similar shell
  init file). Generate values for the secret keys by running "bundle
  exec rake secret". Log out and log back in for them to take effect.

  ```
  # used by data migration script only
  export SDBMSS_LEGACY_DB_NAME="sdbm_live_copy"
  export SDBMSS_LEGACY_DB_USER="xxx"
  export SDBMSS_LEGACY_DB_PASSWORD="xxx"
  export SDBMSS_LEGACY_DB_HOST="xxx"
  # used by app
  export SDBMSS_DB_NAME="sdbm"
  export SDBMSS_DB_USER="xxx"
  export SDBMSS_DB_PASSWORD="xxx"
  export SDBMSS_DB_HOST="xxx"
  # secrets only used in production env
  export SDBMSS_BLACKLIGHT_SECRET_KEY="..."
  export SDBMSS_DEVISE_SECRET_KEY="..."
  export SDBMSS_SECRET_KEY_BASE="..."
  export SDBMSS_SECRET_TOKEN="..."
  # note there's no SDBMSS_ prefix here
  export SOLR_URL="http://127.0.0.1:8983/solr/development"
  ```

* Now you should be ready to run the application and its scripts.

Data Migration
--------------

Follow these steps when you want to recreate your database with newly
migrated data.

* Get a copy of the Oracle database into MySQL. You can do this one of
  two ways:

    * If your host can access the Oracle db: run [oracle2mysql](https://github.com/codeforkjeff/oracle2mysql)
    to create a copy of it. You will be prompted for the location of
    the Oracle database and credentials.

    ```
    cd ~/oracle2mysql
    python oracle2mysql.py oracle2mysql_conf
    ```

    * If you can't access Oracle, or if you've done the above before
    on another machine, get a .sql dump from it by running mysqldump,
    and import it. This method is also a lot faster.
  
    ```
    cat sdbm_live_copy_dump.sql | mysql -u user sdbm_live_copy
    ```

* Create the new database by running the data migration script.

  ```
  cd ~/sdbmss
  bundle exec rake sdbmss:migrate_legacy_data
  ```

* Start up Solr and reindex records so that searching works.

  ```
  cd ~/sdbmss
  bundle exec rake sunspot:solr:start
  bundle exec rake sunspot:reindex
  ```

Running the Development Server
---------------------------------

* Run Rails

  ```
  bundle exec rails s
  ```

* Load http://localhost:3000 in your browser.

Running the Test Suite
----------------------

* Install [PhantomJS](http://phantomjs.org/) 1.9.8 or higher. You can
  get precompiled Linux binaries
  [here](https://bitbucket.org/ariya/phantomjs/downloads/). After you
  unzip it somewhere, make sure phantomjs is in your path.

* Create a database for the tests to use. This should be the value of
  SDBMSS_DB_NAME with "_test" appended to it.

  ```
  echo "CREATE DATABASE sdbm_test;" | mysql -u root
  ```

* Run this script, which sets up a proper testing environment and
  creates fresh tables in the database.

  ```
  ./run_tests.sh
  ```

Deploying to the Staging (Dev VM) Server
----------------------------------------

Note: we use 'staging' and the 'dev VM' to refer to the same machine
and environment. We use 'development' to refer to local development
environments.

We use capistrano to automate updating the staging server with the
latest code, restarting the unicorn server, and recreating the
database.

* If Apache hasn't already been configured on the dev VM, do so:
  create a file /etc/httpd/conf.d/sdbmss.conf with the following
  contents:

  ```
  <VirtualHost *:80>

      ServerName sdbmdev.library.upenn.edu
      ServerAlias sdbmdev
      ServerAdmin jeffchiu@upenn.edu

      ProxyPass /assets !
      ProxyPass /static !
      ProxyPass / http://127.0.0.1:8080/ retry=1
      ProxyPreserveHost on
      ProxyTimeout 300

      <Proxy *>
      Order deny,allow
      Allow from all
      </Proxy> 

      <Directory "/var/www/sdbmss/current/public">
      Order allow,deny
      Allow from all
      </Directory>

      Alias /assets/ /var/www/sdbmss/current/public/assets/
      Alias /static/ /var/www/sdbmss/current/public/static/

      <IfModule mod_deflate.c>
          AddOutputFilterByType DEFLATE text/css application/x-javascript text/x-component text/html text/plain text/xml application/javascript
      </IfModule>

  </VirtualHost>
  ```

* On your local machine, run "ssh-add" to add your key to your ssh
  agent. This key should already be registered with Github, so that
  capistrano can use it (via ssh forwarding) to access the Github repo
  from the dev VM. This needs to happen for the next step to work.

* On your local machine, deploy the latest code to the dev VM using
  capistrano. This will put a copy of the code in ~/sdbmss/current on
  the dev VM, update the solr configuration and restart it, and
  restart the unicorn server. (The account on the dev VM will need the
  SDBMSS_ environment variables mentioned above; set them in .bashrc
  or some other way? TODO)

  ```
  cd ~/sdbmss
  bundle exec cap staging deploy
  ```

* On your local machine, you can run a task to refresh the database on
  staging, using a SQL file (created on your local machine--doing
  migrations from the legacy data takes way too long the VM), and
  reindex Solr. You only need to do this as necessary.

  ```
  cd ~/sdbmss
  bundle exec cap staging deploy:recreate_database[../sdbm_rails_2015_01_29.sql]
  ```

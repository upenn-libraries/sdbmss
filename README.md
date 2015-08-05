
sdbmss
======

The Schoenberg Database of Manuscripts. This is the Ruby on Rails /
Blacklight project reboot, started in late Nov 2014.

Note that we use 'sdbmss' everywhere in the code because 'sdbm' is the
name of a package in Ruby's standard library.

Basic Host Setup
----------------

This application should run on any Linux system and on MacOS.

A good way to start fresh is to begin with a clean CentOS 6
installation and do the following:

* Create a user account and give it sudo access

* Update yum and install some packages you'll need.

  ```
  yum update
  yum install screen git mysql mysql-server mysql-devel java-1.7.0-openjdk
  ```

* Configure CentOS to start up MySQL when the system boots.

  ```
  chkconfig --level 345 mysqld on
  ```

* CentOS installs iptables with strict rules by default. Edit
  /etc/sysconfig/iptables to allow traffic on the ports you want.

Installing Ruby and Other Requirements
--------------------------------------

* It's recommended that you use [rvm](https://rvm.io/) to manage your
  Ruby installation, instead of using a system package. You'll need at
  least Ruby 2.1.5 but 2.2.x is preferred.

  Run these commands as a regular user. rvm will prompt you for a
  password for sudo.

  ```
  gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
  \curl -sSL https://get.rvm.io | bash -s stable
  rvm install 2.2.1
  ```

* rvm installs an older version of bundler. You'll need to upgrade to
  at least 1.10.x to recognize the new Gemfile format.

  ```
  gem install bundler
  ```

* Install [Node](https://nodejs.org/) (Rails requires a Javascript
  runtime). The easiest way to do this is to download the latest
  tarball, unzip it somehere, and make sure its bin/node executable is
  in your PATH.

* Create a MySQL account and some databases.

  ```
  mysql -u root
  CREATE DATABASE sdbm_live_copy;
  CREATE DATABASE sdbm;
  CREATE USER 'sdbm'@'localhost' IDENTIFIED BY 'xxx';
  GRANT ALL PRIVILEGES ON *.* TO 'sdbm'@'localhost';
  FLUSH PRIVILEGES
  ```

  The application is comprised of several processes you'll need to
  run. Using 'screen' is helpful here.

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
  # hostname of app itself
  export SDBMSS_APP_HOST=somehost.somewhere.com
  export SDBMSS_SMTP_HOST=mail.somewhere.com
  # email configuration
  export SDBMSS_EMAIL_FROM="someone@mail.com"
  export SDBMSS_EMAIL_EXCEPTIONS_TO="admin@mail.com"
  # secrets only used in production env
  export SDBMSS_BLACKLIGHT_SECRET_KEY="..."
  export SDBMSS_DEVISE_SECRET_KEY="..."
  export SDBMSS_SECRET_KEY_BASE="..."
  export SDBMSS_SECRET_TOKEN="..."
  # note there's no SDBMSS_ prefix here
  export SOLR_URL="http://127.0.0.1:8983/solr/development"
  ```

* Clone the git repository into your home directory. (You'll need to
  set up <a href="https://help.github.com/articles/generating-ssh-keys/">ssh
  access</a> to github from your host.) This will give you a folder
  called ~/sdbmss

  ```
  cd ~
  git clone git@github.com:upenn-libraries/sdbmss.git
  ```

* Run this to install the Ruby gems needed by the project:

  ```
  cd ~/sdbmss
  bundle install
  ```

* Now you should be ready to create the database and run the
  application (see below).

Data Migration
--------------

You will need to migrate the data from the legacy Oracle production
database into your own locally running MySQL database that the Rails
application can use. Copying the Oracle db can ONLY be done on the
development virtual machine (VM) set up by Libraries IT for this
project's use.

This is a 3 step process.

* STEP 1: Make a straight copy of the tables from Oracle to MySQL.

  Run the [oracle2mysql](https://github.com/codeforkjeff/oracle2mysql)
  script to copy all the tables from Oracle to a MySQL database. The
  script uses the SDBMSS_LEGACY_* environment variables mentioned
  above, so be sure those are set correctly (you'll need to get that
  info from IT).

  On the development VM, run these commands:

    ```
    cd ~/oracle2mysql
    python oracle2mysql.py oracle2mysql_conf
    cd ~
    mysqldump -u root sdbm_live_copy > sdbm_live_copy_`date +%Y_%m_%d`.sql
    ```

* STEP 2: Load the MySQL file into your own locally running
  development database.

  On your own machine, run these commands:
  
    ```
    # copy the file you made in step 1, from the dev VM to your machine
    scp username@dev_vm_hostname:sdbm_live_copy_2015_06_15.sql .
    # load the data
    cat sdbm_live_copy_2015_06_15.sql | mysql -u user sdbm_live_copy
    ```

* STEP 3: Migrate the legacy data into a new database by running the
  data migration script.

  On your own machine, run these commands:

  ```
  cd ~/sdbmss
  bundle exec rake sdbmss:migrate_legacy_data
  # OPTIONAL: create some reference data for development use
  bundle exec rake sdbmss:create_reference_data
  # populate VIAF ID field in Name records
  bundle exec rake sdbmss:update_names[seed_data/names.csv]
  # index the data in Solr
  bundle exec rake sunspot:reindex
  ```

Running the Development Server
------------------------------

* Run a Solr instance (this WILL daemonize). Note that you will need
  to restart Solr whenever there are changes to the Solr configuration
  or schema files.

  ```
  bundle exec rake sunspot:solr:start
  ```

  To stop Solr:

  ```
  bundle exec rake sunspot:solr:stop
  ```

* Run Rails (this will not daemonize)

  ```
  bundle exec rails s
  ```

* Run a delayed_job worker (this will not daemonize). Note that you
  will need to kill and restart this process for jobs to pick up code
  changes.

  ```
  bundle exec rake jobs:work
  ```

* Now you should be able to load <http://localhost:3000> in your
  browser.

Running the Test Suite
----------------------

* Install [PhantomJS](http://phantomjs.org/) 1.9.8 (the poltergeist
  1.6.0 gem does NOT work with PhantomJS 2.0, so don't use that). You
  can get precompiled Linux binaries
  [here](https://bitbucket.org/ariya/phantomjs/downloads/). After you
  unzip it somewhere, make sure phantomjs is in your path.

* Create a database for the tests to use. This should be the value of
  the SDBMSS_DB_NAME environment variable with "_test" appended to it.

  ```
  echo "CREATE DATABASE sdbm_test;" | mysql -u root
  ```

* Run this script, which sets up a proper testing environment before
  running rspec.

  ```
  ./run_tests.sh
  ```

Deploying to the Staging (Dev VM) Server
----------------------------------------

Note: 'staging' aka the 'dev VM' refers to the virtual machine
provided by Libraries IT for the exclusive purpose of SDBM
development.

We use [capistrano](http://capistranorb.com/) to automate updating the
staging server with the latest code. We use [god](http://godrb.com/)
to do application process monitoring (the processes being unicorn,
solr, and a delayed_job worker).

* Your account on the dev VM will need the SDBMSS_ environment
  variables mentioned above; set them in .bashrc or some other way.

* The Apache config file /etc/httpd/conf.d/sdbmss.conf should look
  something like the following:

  ```
  <VirtualHost *:80>
      ServerName sdbmdev.library.upenn.edu
      Redirect permanent / https://sdbmdev.library.upenn.edu/
  </VirtualHost>

  <VirtualHost *:443>
      SSLEngine On

      SSLProtocol all -SSLv2
      SSLCipherSuite ALL:!ADH:!EXPORT:!SSLv2:RC4+RSA:+HIGH:+MEDIUM:+LOW
      SSLCertificateFile /path/to/file
      SSLCertificateKeyFile /path/to/file

      ServerName sdbmdev.library.upenn.edu
      ServerAlias sdbmdev
      ServerAdmin jeffchiu@upenn.edu

      ProxyPass /favicon.ico !
      ProxyPass /assets !
      ProxyPass /static !
      ProxyPass / http://127.0.0.1:8080/ retry=1
      ProxyPreserveHost on
      ProxyTimeout 300

      CustomLog /var/log/httpd/sdbmdev-access.log combined
      ErrorLog /var/log/httpd/sdbmdev-error.log
      # Possible values include: debug, info, notice, warn, error, crit,
      # alert, emerg.
      LogLevel warn

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

* On your local machine, run capistrano to deploy the latest code to
  the dev VM.  This will perform a number of tasks on the dev VM,
  including putting a copy of the code in /var/www/sdbmss/current,
  updating the solr configuration and restarting it, and restarting
  the unicorn server. 

  ```
  cd ~/sdbmss
  bundle exec cap staging deploy
  ```

* OPTIONAL: On your local machine, you can run a task to refresh the
  database on staging, using a SQL file (created on your local
  machine--doing migrations from the legacy data takes way too long
  the VM), and reindex Solr. You only need to do this as necessary.

  ```
  cd ~/sdbmss
  bundle exec cap staging deploy:recreate_database[../sdbm_rails_2015_01_29.sql]
  ```

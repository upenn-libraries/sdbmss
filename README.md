
sdbmss
======

The Schoenberg Database of Manuscripts. This is the Ruby on Rails /
Blacklight project reboot, started in late Nov 2014.

Note that 'sdbm' is the name of a built-in Ruby package; that's why we
use 'sdbmss' instead.

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

* Set some environment variables in your .bashrc file (or similar
  shell init file). Log out and log back in for them to take effect.

  ```
  export SDBMSS_DB_NAME="sdbm"
  export SDBMSS_DB_USER="xxx"
  export SDBMSS_DB_PASSWORD="xxx"
  export SDBMSS_DB_HOST="xxx"
  ```

* Now you should be ready to run the application and its scripts.

Data Migration
--------------

Follow these steps when you want to recreate your database with newly
migrated data.

* Get a copy of the Oracle database into MySQL. You can do this one of
  two ways:

    * If your host can access the Oracle db: run oracle2mysql from the
    old SDBM Python project to create a copy of it. You will be
    prompted for the location of the Oracle database and credentials.

    ```
    source ~/env_sdbm/bin/activate
    cd ~/sdbm/oracle2mysql
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

How to Run the Development Server
---------------------------------

* Run Rails

  ```
  bundle exec rails s
  ```

* Load http://localhost:3000 in your browser.

Deploying to the Staging (Dev VM) Server
----------------------------------------

Note: we call the dev VM 'staging' instead of 'development'; we use
the latter to refer to environments where programmers do their work.

* Configure Apache on the dev VM by creating a file
  /etc/httpd/conf.d/sdbmss.conf with the following contents:

  ```
  <VirtualHost *:80>

      ServerName sdbmdev.library.upenn.edu
      ServerAlias sdbmdev
      ServerAdmin jeffchiu@upenn.edu

      # we should eventually not proxy static assets
      # ProxyPass /assets !
      ProxyPass / http://127.0.0.1:8080/
      ProxyPassReverse / http://127.0.0.1:8080/
      ProxyPreserveHost on

      <Proxy *>
      Order deny,allow
      Allow from all
      </Proxy> 

      Alias /assets/ /home/jeffchiu/sdbmss/current/public/assets/

      <Directory /usr/local/www/wsgi-scripts>
      Order allow,deny
      Allow from all
      </Directory>

      <IfModule mod_deflate.c>
          AddOutputFilterByType DEFLATE text/css application/x-javascript text/x-component text/html text/plain text/xml application/javascript
      </IfModule>

  </VirtualHost>
  ```

* On your local machine, run "ssh-add" to add your key to your ssh
  agent. This key should already be registered with Github, so that
  capistrano can use it (via ssh forwarding) to access the repo on the
  dev VM.

* From your own machine, deploy the latest code to the dev VM using
  capistrano. This will put a copy of the code in ~/sdbmss/current on
  the dev VM.

  ```
  cd ~/sdbmss
  bundle exec cap staging deploy
  ```

* Start unicorn

  ```
  cd ~/sdbmss/current
  ./run_unicorn_daemon.sh
  ```

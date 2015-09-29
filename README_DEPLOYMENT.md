
Deploying the App
-----------------

These are notes on the setup and configuration of the staging and
production deployment environments.

Currently these are the only two deployment environments that
exist. These notes are intended to facilitate creating other
deployment environments or to recreate existing ones.

We use [capistrano](http://capistranorb.com/) to automate
deployment. The staging and production environments use
[god](http://godrb.com/) to do application process orchestration and
monitoring (the processes being unicorn, solr, and a delayed_job
worker).

TODO: Eventually, we should use Docker, but we don't have a virtual
machine set up for that yet.

Note: 'staging' (aka the 'dev VM' which is confusing, so we don't call
it that here) refers to the virtual machine provided by Libraries IT
for the exclusive purpose of SDBM development.

## Requirements

For both staging and production, LTS has set up virtual machines
running CentOS and installed the following:

- Apache
- MySQL
- Java
- rvm

LT has also set up an 'sdbm' user account who should run the
application.

## Ruby version

Use rvm to install a Ruby.

The current production machine is setup with Ruby version
2.2.1p85. This was installed by the `sdbm` user, which was added to
the `rvm` group. The `rvm` group has write permission on the rvm
directory, which is `/usr/local/rvm/`. This is where ruby versions are
installed.

## NodeJS

Install NodeJS using yum. Rails requires this.

## Environment variables

The 'sdbm' account will need the SDBMSS_ environment variables; set
them in .bashrc or some other way. See the `README_OLD.md` file for
these. Be sure to add `RAILS_ENV=production` to the env vars.

## Starting Apache at Boot

Apache should already be configured to start up at boot time, but in
case it's not, see:

For starting Apache on CentOS at boot, see this page:
<http://www.liquidweb.com/kb/how-to-install-apache-on-centos-7/>

## Apache Config

The Apache config file /etc/httpd/conf.d/sdbmss.conf should look
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
      ServerAdmin sdbm@pobox.upenn.edu

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

1. Change every instance of `sdbmdev` to match the correct hostname.

2. Note the correct path needs to be added for the SSL cert and key.

You'll need to restart Apache after creating this file and placing the
keys on the machine.

## Configuring Capistrano

Capistrano needs to know about the target machine to which it is
deploying.

For production, the file `config/deploy/production.rb` should look
like the following:

    ```ruby
    # Replace these lines:
    # role :app, %w{deploy@example.com}
    # role :web, %w{deploy@example.com}
    # role :db,  %w{deploy@example.com}
    # with these lines:
    role :app, %w{sdbm@sdbm.library.upenn.edu}
    role :web, %w{sdbm@sdbm.library.upenn.edu}

    # ...

    # Comment out this line:
    # server 'example.com', user: 'deploy', roles: %w{web app}, my_property: :my_value
    ```

## Set up database

Create database and user account (see `README_OLD.md`).

Upload copy of database file to server using scp.

Load database:

    ```
    mysql -u sdbm -p < databasefile.sql
    ```

### Optimizing MySQL

Production runs the stock MySQL configuration that ships with
CentOS. It should probably be tuned so it runs optimally.

For this, use mysqltuner <http://mysqltuner.com> after the database
has been running for some time.  This will generate a report and
recommend changes to make to the /etc/my.cnf file to optimize .

## Reindex solr

In the `/var/www/sdbmss/current` directory, as the `sdbm` user, run
this task (without argument):

```
rake sunspot:reindex[batch_size,models,silence]  # Drop and then reindex all solr models that are located in your application's models dir...
```

## Deploy to production

Note: Be sure to add your ssh public key to the
`~sdbmss/.ssh/authorized_keys` file of the `sdbm` user.

See the instructions in `README_OLD.md`, using the following `cap`
command:

    ```
    bundle exec cap production deploy
    ```

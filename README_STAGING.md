
Staging Server
--------------

Note: 'staging' (aka the 'dev VM' which is confusing, so we don't call
it that here) refers to the virtual machine provided by Libraries IT
for the exclusive purpose of SDBM development.

We use [capistrano](http://capistranorb.com/) to automate updating the
staging server with the latest code. The staging environment uses
[god](http://godrb.com/) to do application process monitoring (the
processes being unicorn, solr, and a delayed_job worker).

TODO: Eventually, we want staging to use Docker, but we don't have a
virtual machine set up for that yet.

## Ruby version

The current production machine is setup with Ruby version
2.2.1p85. This is installed through rvm (which was already installed
on the machine). This was installed by the `sdbm` user, which was
added to the `rvm` group. The `rvm` group has write permission on the
rvm directory, which is `/usr/local/rvm/`. This is where ruby versions
are installed.

## Environment variables

* Your account on staging will need the SDBMSS_ environment variables;
  set them in .bashrc or some other way. See the `README_OLD.md` file
  for these. Be sure to add `RAILS_ENV=production` to the env vars.

## Starting CentOS

This is probably already set up, but in case it's not, see:

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

Restart Apache.

## Capistrano

In `config/deploy/production.rb` make the following changes (if not
already made).

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

Create database (see `README_OLD.md`).

Upload copy of database to server.

Load database:

    ```
    mysql -u sdbm -p < databasefile.sql
    ```

### Optimizing MySQL

For this use mysqltuner <http://mysqltuner.com> after the database has
been running for some time.  This will generate a report and recommend
optimizations.

## Reindex solr

In the `current` directory (`/var/www/sdbmss/current`) as the `sdbm`
user, run this task (without argument):

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

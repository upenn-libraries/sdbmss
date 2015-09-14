
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

* Your account on staging will need the SDBMSS_ environment variables;
  set them in .bashrc or some other way.

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


# Very basic container that contains only Ruby/Rails gem dependencies;
# this is used not only by Rails but related processes as well
# (delayed_worker, Solr)

FROM rails:4.2.5

RUN apt-get update && apt-get install -y openjdk-7-jdk

WORKDIR /opt
#RUN curl -L -O https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-1.9.8-linux-x86_64.tar.bz2 && tar xjf phantomjs-1.9.8-linux-x86_64.tar.bz2 && ln -s phantomjs-1.9.8-linux-x86_64 phantomjs
#ENV PATH "$PATH:/opt/phantomjs/bin"

# copying Gemfiles first takes advantage of image caching
WORKDIR /tmp
ADD Gemfile /tmp/Gemfile
ADD Gemfile.lock /tmp/Gemfile.lock
RUN bundle install 

WORKDIR /usr/src/app

# Copy files so that this image contains a full copy of the
# application code. In development, docker-compose should define a
# volume mounting a local directory to /usr/src/app, "overlaying" the
# files, so that you can edit local files and changes get picked up
# immediately

COPY . /usr/src/app
RUN mkdir -p tmp/pids

RUN bundle exec rake \
  RAILS_ENV=production \
  SDBMSS_DB_NAME=dummy \
  SDBMSS_DB_USER=dummy \
  SDBMSS_APP_HOST=dummy \
  SDBMSS_SMTP_HOST=dummy \
  SDBMSS_EMAIL_FROM=dummy \
  SDBMSS_NOTIFY_EMAIL=dummy \
  SDBMSS_NOTIFY_EMAIL_PASSWORD=dummy \
  SDBMSS_BLACKLIGHT_SECRET_KEY=dummy \
  SDBMSS_DEVISE_SECRET_KEY=dummy \
  SDBMSS_SECRET_KEY_BASE=dummy \
  SDBMSS_SECRET_TOKEN=dummy \
  assets:precompile --trace

RUN bundle exec rake \
  RAILS_ENV=staging \
  SDBMSS_DB_NAME=dummy \
  SDBMSS_DB_USER=dummy \
  SDBMSS_APP_HOST=dummy \
  SDBMSS_SMTP_HOST=dummy \
  SDBMSS_EMAIL_FROM=dummy \
  SDBMSS_NOTIFY_EMAIL=dummy \
  SDBMSS_NOTIFY_EMAIL_PASSWORD=dummy \
  SDBMSS_BLACKLIGHT_SECRET_KEY=dummy \
  SDBMSS_DEVISE_SECRET_KEY=dummy \
  SDBMSS_SECRET_KEY_BASE=dummy \
  SDBMSS_SECRET_TOKEN=dummy \
  assets:precompile --trace

VOLUME ["/usr/src/app/public"]

#RUN bundle exec bin/rake assets:precompile

# we make sure to rm stale pid file
CMD rm -f /usr/src/app/tmp/pids/server.pid && bundle exec rails s -b 0.0.0.0

EXPOSE 8080

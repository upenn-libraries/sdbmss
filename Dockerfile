
# Very basic container that contains only Ruby/Rails gem dependencies;
# this is used not only by Rails but related processes as well
# (delayed_worker, Solr)

ARG APP_IMAGE_NAME=rails
ARG APP_IMAGE_TAG=4.2.5

FROM ${APP_IMAGE_NAME}:${APP_IMAGE_TAG}

# Jessie has been deprecated so we need to update apt/source
RUN echo "deb [check-valid-until=no] http://archive.debian.org/debian jessie main" > /etc/apt/sources.list

RUN apt-get update && apt-get install -y --force-yes apt-transport-https lsb-release

RUN curl -sL https://deb.nodesource.com/setup_4.x | bash -

RUN apt-get update && apt-get install --force-yes -y \
    nodejs \
    openjdk-7-jdk

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

RUN RAILS_ENV=production \
  SECRET_KEY_BASE=x \
  SDBMSS_APP_HOST=localhost \
  SDBMSS_EMAIL_FROM=x \
  SDBMSS_SMTP_HOST=x \
  SDBMSS_EMAIL_EXCEPTIONS_TO=x \
  SDBMSS_BLACKLIGHT_SECRET_KEY=x \
  SDBMSS_NOTIFY_EMAIL=x \
  SDBMSS_NOTIFY_PASSWORD=x \
  RABBIT_USER=x \
  RABBIT_PASSWORD=x \
  MYSQL_DATABASE=x \
  MYSQL_USER=x \
  MYSQL_PASSWORD=x \
  MYSQL_HOST=x \
  SDBMSS_DEVISE_SECRET_KEY=x \
  bundle exec rake assets:precompile --trace

# we make sure to rm stale pid file
CMD rm -f /usr/src/app/tmp/pids/server.pid && rm -f /usr/src/app/tmp/pids/unicorn.pid && bundle exec rails s unicorn -b 0.0.0.0

EXPOSE 8080

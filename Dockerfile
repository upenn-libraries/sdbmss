
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

# we make sure to rm stale pid file
CMD rm -f /usr/src/app/tmp/pids/server.pid && rm -f /usr/src/app/tmp/pids/unicorn.pid && bundle exec rails s unicorn -b 0.0.0.0

EXPOSE 8080
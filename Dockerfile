
# Very basic container that contains only Ruby/Rails gem dependencies;
# this is used not only by Rails but related processes as well
# (delayed_worker, Solr)

FROM rails:4.2.3

RUN apt-get update && apt-get install -y openjdk-7-jdk

WORKDIR /opt
RUN wget https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-1.9.8-linux-x86_64.tar.bz2 && tar xjf phantomjs-1.9.8-linux-x86_64.tar.bz2 && ln -s phantomjs-1.9.8-linux-x86_64 phantomjs
ENV PATH "$PATH:/opt/phantomjs/bin"

# copying Gemfiles first takes advantage of image caching
WORKDIR /tmp
ADD Gemfile /tmp/Gemfile
ADD Gemfile.lock /tmp/Gemfile.lock
RUN bundle install 

WORKDIR /usr/src/app

# uncomment next section if you want to write the app files to the
# image; as it stands, docker-compose will mount a volume to
# /usr/src/app so changes get picked up immediately

#COPY . /usr/src/app
#RUN mkdir -p tmp/pids
#RUN bundle exec bin/rake assets:precompile
#CMD ["bundle", "exec", "rails", "s", "-b", "0.0.0.0"]

# we make sure to rm stale pid file
CMD rm -f /usr/src/app/tmp/pids/server.pid && bundle exec rails s -b 0.0.0.0

EXPOSE 3000

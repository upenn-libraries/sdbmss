FROM stain/jena-fuseki

# we need ruby for build-in command line HTTP query tools
RUN apk update -q && apk add ruby

#CMD puts ruby --version

# TODO gem install bunny
#RUN gem install rdoc
#RUN gem install bunny -include-dependencies

RUN apk add ruby ruby-bundler

# TODO schedule regular ruby script
#RUN mkdir /usr/app 
#WORKDIR /fuseki
#COPY shiro.ini ./

WORKDIR /jena-fuseki/webapp/js/app
COPY qonsole-config.js ./

WORKDIR /jena-fuseki/webapp
COPY dataset.html ./

WORKDIR /jena-fuseki

COPY shiro.ini ./
COPY yasr.min.js ./webapp/js/lib/yasr.min.js
COPY Gemfile ./ 
#COPY Gemfile.lock ./ 
RUN bundle install

COPY interface.rb ./

#RUN ruby interface.rb
# TODO to check rabbitmq server
# TODO process messages

#CMD ruby interface.rb

CMD rm /fuseki/system/tdb.lock ; rm /fuseki/databases/sdbm/tdb.lock ; ./fuseki-server
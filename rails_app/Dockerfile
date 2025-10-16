
#ARG APP_IMAGE_NAME=gitlab.library.upenn.edu/sdbm/ruby-2.3.8
#ARG APP_IMAGE_TAG=2ad16fb5
ARG APP_IMAGE_NAME=ruby
ARG APP_IMAGE_TAG=2.6.10-bullseye

# Bundle home
ARG BUNDLE_HOME=vendor/bundle

# Bundle version
ARG BUNDLE_VERSION=1.17.3

# The root of our app
ARG PROJECT_ROOT=/home/app

# Rails env
ARG RAILS_ENV=development


# Base Image
FROM ${APP_IMAGE_NAME}:${APP_IMAGE_TAG} as base

ARG BUNDLE_HOME
ENV BUNDLE_HOME=${BUNDLE_HOME}

ARG BUNDLE_VERSION
ENV BUNDLE_VERSION=${BUNDLE_VERSION}

ARG PROJECT_ROOT
ENV PROJECT_ROOT=${PROJECT_ROOT}

ENV BUNDLE_APP_CONFIG="${PROJECT_ROOT}/.bundle"
ENV GEM_HOME="${PROJECT_ROOT}/vendor/bundle/ruby/${RUBY_MAJOR}.0"
ENV GEM_PATH="${GEM_HOME}"

ENV PATH="${GEM_HOME}/bin:${PATH}"

ARG RAILS_ENV=development
ENV RAILS_ENV=${RAILS_ENV}

WORKDIR ${PROJECT_ROOT}

COPY --chown=app:app Gemfile* .

RUN gem install bundler -v ${BUNDLE_VERSION}

RUN ls ${GEM_HOME}
RUN echo ${GEM_HOME}

RUN bundle config path ${GEM_HOME} && \
  set -eux; \
  if [ "${RAILS_ENV}" = "development" ]; then \
  bundle config set with "development:test:assets"; \
  else \
  bundle config set without "development:test:assets"; \
  fi && \
  MAKE="make -j $(nproc)" bundle install && \
  rm -rf ${PROJECT_ROOT}/vendor/bundle/ruby/${RUBY_MAJOR}.0/cache/*.gem && \
  find ${PROJECT_ROOT}/vendor/bundle/ruby/${RUBY_MAJOR}.0/gems/ \( -name "*.c" -o -name "*.o" \) -delete


# Development Image
FROM ${APP_IMAGE_NAME}:${APP_IMAGE_TAG} as development

ARG BUNDLE_HOME
ENV BUNDLE_HOME=${BUNDLE_HOME}

ARG BUNDLE_VERSION
ENV BUNDLE_VERSION=${BUNDLE_VERSION}

ARG PROJECT_ROOT
ENV PROJECT_ROOT=${PROJECT_ROOT}

ARG RAILS_ENV=development
ENV RAILS_ENV=${RAILS_ENV}

ENV BUNDLE_APP_CONFIG="${PROJECT_ROOT}/.bundle"
ENV NLS_LANG=$LANG
ENV RAILS_LOG_TO_STDOUT=true

ENV GEM_PATH="${PROJECT_ROOT}/vendor/bundle/ruby/${RUBY_MAJOR}.0"
ENV GEM_HOME="${GEM_PATH}"
ENV PATH="${GEM_PATH}/bin:${PATH}"

COPY --chown=app:app --chmod=644 --from=base ${PROJECT_ROOT} ${PROJECT_ROOT}

#RUN curl -sL https://deb.nodesource.com/setup_4.x | bash -
#
#RUN apt-get update && apt-get install -y --force-yes \
#      default-libmysqlclient-dev \
#      nodejs \
#      openjdk-8-jre \
#      openjdk-8-jre-headless \
#      openjdk-8-jdk \
#      tzdata && \
#  addgroup app && useradd -m -d ${PROJECT_ROOT} -s /bin/bash -g app app && \
#  mkdir -p ${PROJECT_ROOT}/tmp/pids

# Debian 11 base
#FROM ruby:2.6.10-bullseye

# --- system deps + Node 12 from Debian + Java 8 (Temurin) ---
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl gnupg wget apt-transport-https \
      default-libmysqlclient-dev \
      nodejs npm \
      tzdata \
      chromium \
  && wget -qO - https://packages.adoptium.net/artifactory/api/gpg/key/public \
       | gpg --dearmor -o /etc/apt/trusted.gpg.d/adoptium.gpg \
  && echo "deb https://packages.adoptium.net/artifactory/deb $(. /etc/os-release; echo $VERSION_CODENAME) main" \
       > /etc/apt/sources.list.d/adoptium.list \
  && apt-get update \
  && apt-get install -y --no-install-recommends temurin-8-jdk \
  && rm -rf /var/lib/apt/lists/* \
  && addgroup app && useradd -m -d ${PROJECT_ROOT} -s /bin/bash -g app app \
  && mkdir -p ${PROJECT_ROOT}/tmp/pids
# your existing user/app setup
#ARG PROJECT_ROOT=/home/app
#RUN addgroup app && useradd -m -d ${PROJECT_ROOT} -s /bin/bash -g app app \
# && mkdir -p ${PROJECT_ROOT}/tmp/pids


COPY --chmod=755 docker-entrypoint.sh /usr/local/bin/
COPY --chown=app:app . ${PROJECT_ROOT}

# WORKDIR /opt
#RUN curl -L -O https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-1.9.8-linux-x86_64.tar.bz2 && tar xjf phantomjs-1.9.8-linux-x86_64.tar.bz2 && ln -s phantomjs-1.9.8-linux-x86_64 phantomjs
#ENV PATH "$PATH:/opt/phantomjs/bin"

RUN gem install bundler -v ${BUNDLE_VERSION} && \
    chmod +x -R "${GEM_HOME}/bin/"

WORKDIR ${PROJECT_ROOT}

RUN RAILS_ENV=${RAILS_ENV} \
  SECRET_KEY_BASE=x \
  SDBMSS_APP_HOST=localhost \
  SDBMSS_EMAIL_FROM=x \
  SDBMSS_SMTP_HOST=x \
  SDBMSS_EMAIL_EXCEPTIONS_TO=x \
  SDBMSS_BLACKLIGHT_SECRET_KEY=x \
  SDBMSS_NOTIFY_EMAIL=x \
  SDBMSS_NOTIFY_EMAIL_PASSWORD=x \
  RABBIT_USER=x \
  RABBIT_PASSWORD=x \
  MYSQL_DATABASE=x \
  MYSQL_USER=x \
  MYSQL_PASSWORD=x \
  MYSQL_HOST=x \
  SDBMSS_DEVISE_SECRET_KEY=x \
  bundle exec rake assets:precompile

ENTRYPOINT ["docker-entrypoint.sh"]

CMD ["bundle", "exec", "rails", "s", "unicorn", "-b", "0.0.0.0"]


# Production Image
FROM ${APP_IMAGE_NAME}:${APP_IMAGE_TAG} as production

ARG BUNDLE_VERSION
ENV BUNDLE_VERSION=${BUNDLE_VERSION}

ARG PROJECT_ROOT
ENV PROJECT_ROOT=${PROJECT_ROOT}

ARG RAILS_ENV=production
ENV RAILS_ENV=${RAILS_ENV}

ENV BUNDLE_APP_CONFIG="${PROJECT_ROOT}/.bundle"
ENV NLS_LANG=$LANG
ENV RAILS_LOG_TO_STDOUT=true
ENV RAILS_SERVE_STATIC_FILES=true

ENV GEM_PATH="${PROJECT_ROOT}/vendor/bundle/ruby/${RUBY_MAJOR}.0"
ENV GEM_HOME="${GEM_PATH}"

ENV PATH="${GEM_PATH}/bin:${PATH}"

COPY --chown=app:app --chmod=644 --from=base ${PROJECT_ROOT} ${PROJECT_ROOT}

#RUN curl -sL https://deb.nodesource.com/setup_4.x | bash -
#
#RUN apt-get update && apt-get install -y --force-yes \
#      default-libmysqlclient-dev \
#      nodejs \
#      openjdk-8-jre \
#      openjdk-8-jre-headless \
#      openjdk-8-jdk \
#      tzdata && \
#  addgroup app && useradd -m -d ${PROJECT_ROOT} -s /bin/bash -g app app && \
#  mkdir -p ${PROJECT_ROOT}/tmp/pids
# Debian 11 base
#FROM ruby:2.6.10-bullseye

# --- system deps + Node 12 from Debian + Java 8 (Temurin) ---
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl gnupg wget apt-transport-https \
      default-libmysqlclient-dev \
      nodejs npm \
      tzdata \
      chromium \
  && wget -qO - https://packages.adoptium.net/artifactory/api/gpg/key/public \
       | gpg --dearmor -o /etc/apt/trusted.gpg.d/adoptium.gpg \
  && echo "deb https://packages.adoptium.net/artifactory/deb $(. /etc/os-release; echo $VERSION_CODENAME) main" \
       > /etc/apt/sources.list.d/adoptium.list \
  && apt-get update \
  && apt-get install -y --no-install-recommends temurin-8-jdk \
  && addgroup app && useradd -m -d ${PROJECT_ROOT} -s /bin/bash -g app app \
      && mkdir -p ${PROJECT_ROOT}/tmp/pids \
  && rm -rf /var/lib/apt/lists/*

# your existing user/app setup
#ARG PROJECT_ROOT=/home/app
#RUN addgroup app && useradd -m -d ${PROJECT_ROOT} -s /bin/bash -g app app \
# && mkdir -p ${PROJECT_ROOT}/tmp/pids


COPY --chmod=755 docker-entrypoint.sh /usr/local/bin/
COPY --chown=app:app . ${PROJECT_ROOT}

# WORKDIR /opt
#RUN curl -L -O https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-1.9.8-linux-x86_64.tar.bz2 && tar xjf phantomjs-1.9.8-linux-x86_64.tar.bz2 && ln -s phantomjs-1.9.8-linux-x86_64 phantomjs
#ENV PATH "$PATH:/opt/phantomjs/bin"

RUN gem install bundler -v ${BUNDLE_VERSION} && \
    chmod +x -R "${GEM_HOME}/bin/"

RUN ls ${GEM_HOME}/gems

WORKDIR ${PROJECT_ROOT}

#RUN #ls /home/app/vendor/bundle/ruby/2.3.0/ruby/2.3.0/gems/rake-10.5.0
# RUN ls ${GEM_HOME}
# RUN ls ${GEM_HOME}/ruby/2.6.0/gems/rake-10.5.0

RUN RAILS_ENV=${RAILS_ENV} \
  SECRET_KEY_BASE=x \
  SDBMSS_APP_HOST=localhost \
  SDBMSS_EMAIL_FROM=x \
  SDBMSS_SMTP_HOST=x \
  SDBMSS_EMAIL_EXCEPTIONS_TO=x \
  SDBMSS_BLACKLIGHT_SECRET_KEY=x \
  SDBMSS_NOTIFY_EMAIL=x \
  SDBMSS_NOTIFY_EMAIL_PASSWORD=x \
  RABBIT_USER=x \
  RABBIT_PASSWORD=x \
  MYSQL_DATABASE=x \
  MYSQL_USER=x \
  MYSQL_PASSWORD=x \
  MYSQL_HOST=x \
  SDBMSS_DEVISE_SECRET_KEY=x \
  bundle exec rake assets:precompile

ENTRYPOINT ["docker-entrypoint.sh"]

CMD ["bundle", "exec", "rails", "s", "unicorn", "-b", "0.0.0.0"]

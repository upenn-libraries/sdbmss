
ARG APP_IMAGE_NAME=ruby
ARG APP_IMAGE_TAG=2.3-jessie

# Bundle home
ARG BUNDLE_HOME=vendor/bundle

# The root of our app
ARG PROJECT_ROOT=/home/app

# Rails env
ARG RAILS_ENV=development

ARG BUNDLE_PATH=${PROJECT_ROOT}/${BUNDLE_HOME}

# Base Image
FROM ${APP_IMAGE_NAME}:${APP_IMAGE_TAG} as base

ARG BUNDLE_HOME
ENV BUNDLE_HOME=${BUNDLE_HOME}

ARG BUNDLE_PATH
ENV BUNDLE_PATH=${BUNDLE_PATH}

ARG PROJECT_ROOT
ENV PROJECT_ROOT=${PROJECT_ROOT}

ARG RAILS_ENV=development
ENV RAILS_ENV=${RAILS_ENV}

ENV BUNDLE_APP_CONFIG="${PROJECT_ROOT}/.bundle"

WORKDIR ${PROJECT_ROOT}

COPY --chown=app:app Gemfile* ${PROJECT_ROOT}

RUN bundle config path ${BUNDLE_PATH} && \
  set -eux; \
  if [ "${RAILS_ENV}" = "development" ]; then \
  bundle config set with "development:test:assets"; \
  else \
  bundle config set without "development:test:assets"; \
  fi && \
  MAKE="make -j $(nproc)" bundle install


# Development Image
FROM ${APP_IMAGE_NAME}:${APP_IMAGE_TAG} as development

ARG BUNDLE_HOME
ENV BUNDLE_HOME=${BUNDLE_HOME}

ARG BUNDLE_PATH
ENV BUNDLE_PATH=${BUNDLE_PATH}

ARG PROJECT_ROOT
ENV PROJECT_ROOT=${PROJECT_ROOT}

ARG RAILS_ENV=development
ENV RAILS_ENV=${RAILS_ENV}

ENV BUNDLE_APP_CONFIG="${PROJECT_ROOT}/.bundle"
ENV GEM_HOME="${BUNDLE_PATH}/ruby/${RUBY_MAJOR}.0/"
ENV GEM_PATH="${BUNDLE_PATH}/ruby/${RUBY_MAJOR}.0/"
ENV NLS_LANG=$LANG
ENV PATH="${BUNDLE_PATH}/ruby/${RUBY_MAJOR}.0/bin:${PATH}"
ENV RAILS_LOG_TO_STDOUT=true

RUN echo "deb [check-valid-until=no] http://archive.debian.org/debian jessie main" > /etc/apt/sources.list && \
  apt-get update && apt-get install -y --force-yes \
  apt-transport-https \
  lsb-release

RUN curl -sL https://deb.nodesource.com/setup_4.x | bash - && \
  apt-get update && apt-get install -y --force-yes \
  mysql-client \
  nodejs \
  openjdk-7-jre \
  openjdk-7-jre-headless \
  openjdk-7-jdk \
  tzdata=2018e-0+deb8u1 \
  tzdata-java && \
  addgroup app && useradd -m -d ${PROJECT_ROOT} -s /bin/bash -g app app && \
  mkdir -p ${PROJECT_ROOT}/tmp/pids

COPY --chown=app:app --chmod=755 docker-entrypoint.sh /usr/local/bin/
COPY --chown=app:app --chmod=644 --from=base ${PROJECT_ROOT} ${PROJECT_ROOT}
COPY --chown=app:app . ${PROJECT_ROOT}

# WORKDIR /opt
#RUN curl -L -O https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-1.9.8-linux-x86_64.tar.bz2 && tar xjf phantomjs-1.9.8-linux-x86_64.tar.bz2 && ln -s phantomjs-1.9.8-linux-x86_64 phantomjs
#ENV PATH "$PATH:/opt/phantomjs/bin"

WORKDIR ${PROJECT_ROOT}

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
  bundle exec rake assets:precompile

ENTRYPOINT ["docker-entrypoint.sh"]

CMD ["bundle", "exec", "rails", "s", "unicorn", "-b", "0.0.0.0"]


# Production Image
FROM ${APP_IMAGE_NAME}:${APP_IMAGE_TAG} as production

ARG BUNDLE_HOME
ENV BUNDLE_HOME=${BUNDLE_HOME}

ARG BUNDLE_PATH
ENV BUNDLE_PATH=${BUNDLE_PATH}

ARG PROJECT_ROOT
ENV PROJECT_ROOT=${PROJECT_ROOT}

ARG RAILS_ENV=development
ENV RAILS_ENV=${RAILS_ENV}

ENV BUNDLE_APP_CONFIG="${PROJECT_ROOT}/.bundle"
ENV GEM_HOME="${BUNDLE_PATH}/ruby/${RUBY_MAJOR}.0/"
ENV GEM_PATH="${BUNDLE_PATH}/ruby/${RUBY_MAJOR}.0/"
ENV NLS_LANG=$LANG
ENV PATH="${BUNDLE_PATH}/ruby/${RUBY_MAJOR}.0/bin:${PATH}"
ENV RAILS_LOG_TO_STDOUT=true
ENV RAILS_SERVE_STATIC_FILES=true

RUN echo "deb [check-valid-until=no] http://archive.debian.org/debian jessie main" > /etc/apt/sources.list && \
  apt-get update && apt-get install -y --force-yes \
  apt-transport-https \
  lsb-release

RUN curl -sL https://deb.nodesource.com/setup_4.x | bash - && \
  apt-get update && apt-get install -y --force-yes \
  mysql-client \
  nodejs \
  openjdk-7-jre \
  openjdk-7-jre-headless \
  openjdk-7-jdk \
  tzdata=2018e-0+deb8u1 \
  tzdata-java && \
  addgroup app && useradd -m -d ${PROJECT_ROOT} -s /bin/bash -g app app && \
  mkdir -p ${PROJECT_ROOT}/tmp/pids

COPY --chown=app:app --chmod=755 docker-entrypoint.sh /usr/local/bin/
COPY --chown=app:app --chmod=644 --from=base ${PROJECT_ROOT} ${PROJECT_ROOT}
COPY --chown=app:app . ${PROJECT_ROOT}

# WORKDIR /opt
#RUN curl -L -O https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-1.9.8-linux-x86_64.tar.bz2 && tar xjf phantomjs-1.9.8-linux-x86_64.tar.bz2 && ln -s phantomjs-1.9.8-linux-x86_64 phantomjs
#ENV PATH "$PATH:/opt/phantomjs/bin"

WORKDIR ${PROJECT_ROOT}

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
  bundle exec rake assets:precompile

ENTRYPOINT ["docker-entrypoint.sh"]

CMD ["bundle", "exec", "rails", "s", "unicorn", "-b", "0.0.0.0"]

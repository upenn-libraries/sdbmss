#!/bin/sh
set -e

if [ "$1" = "bundle" -a "$2" = "exec" -a "$3" = "rails" ]; then
    if [ ! -z "${APP_UID}" ] && [ ! -z "${APP_GID}" ]; then
        usermod -u ${APP_UID} app
        groupmod -g ${APP_GID} app
    fi

    if [ "${RAILS_ENV}" = "development" ]; then
        gem install bundler -v ${BUNDLE_VERSION}
        chmod +x -R "${GEM_HOME}/bin/"
        bundle config --local path ${GEM_HOME}
        bundle config set --local with 'development:test:assets'
        bundle install -j$(nproc) --retry 3
    fi

    # remove unicorn.pid
    if [ -f ${PROJECT_ROOT}/tmp/pids/unicorn.pid ]; then
        rm -f ${PROJECT_ROOT}/tmp/pids/unicorn.pid
    fi

    # remove server.pid
    if [ -f ${PROJECT_ROOT}/tmp/pids/server.pid ]; then
        rm -f ${PROJECT_ROOT}/tmp/pids/server.pid
    fi

    # run db migrations
    if [ "$1" = "bundle" -a "$2" = "exec" -a "$3" = "rails" -a "$4" = "s" -a "$5" = "unicorn" ]; then
        if [ "${RAILS_ENV}" = "development" ] || [ "${RAILS_ENV}" = "test" ]; then
            bundle exec rake db:migrate RAILS_ENV=test
        else
          bundle exec rake db:migrate
        fi
    fi

    # chown all dirs
    find . -type d -exec chown app:app {} \;

    # chown all files except keys
    find . -type f \( ! -name "*.key" \) -exec chown app:app {} \;

    # run the application as the app user
    # exec gosu app "$@"
    exec "$@"
fi

exec "$@"

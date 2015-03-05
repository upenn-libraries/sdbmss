#!/bin/sh
#
# Wrapper script around rspec that does some prep so tests run fresh

export RAILS_ENV=test
export SOLR_URL="http://127.0.0.1:8983/solr/test"

bundle exec rake tmp:clear db:drop db:create db:schema:load

bundle exec rspec $@

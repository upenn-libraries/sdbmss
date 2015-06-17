#!/bin/sh
#
# Wrapper script around rspec that does some prep so tests run fresh

export RAILS_ENV=test
export SOLR_URL="http://127.0.0.1:8983/solr/test"

bundle exec god -c sdbmss_test.god -l log/god_test.log

bundle exec rspec $@

bundle exec god stop
bundle exec god terminate

#!/bin/sh
#
# Wrapper script around rspec to ensure we get a Solr instance
#
# Do NOT use this when running in a Docker container!

export RAILS_ENV=test
export SOLR_URL="http://127.0.0.1:8983/solr/test"

bundle exec god -c sdbmss_test.god -l log/god_test.log

bundle exec rspec $@ --profile

bundle exec god stop
bundle exec god terminate

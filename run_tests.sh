#!/bin/sh
#
# Wrapper script around rspec that does some prep so tests run fresh

export RAILS_ENV=test

bundle exec rake tmp:clear db:drop db:create db:schema:load

bundle exec rspec $@

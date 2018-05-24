#!/bin/bash

# ./deploy.sh <HOST> <COMMAND:START/STOP/DEPLOY> **<BRANCH>** <version?>

path='development/sdbmss'

host=$1
command=$2
branch=$3

if [ "$host" = '' ]
then
  echo "MISSING HOST"
  echo "Required syntax is: ./deploy.sh <HOST> <COMMAND> <BRANCH(optional)>"
  echo "Available commands are: start, stop and deploy"
  exit
fi

if [ "$command" = '' ]
then
  echo "MISSING COMMAND"
  echo "Required syntax is: ./deploy.sh <HOST> <COMMAND> <BRANCH(optional)>"
  echo "Available commands are: start, stop and deploy"
  exit
fi

if [ "$command" = 'stop' ] 
then
  ssh $host 'cd development/sdbmss && docker-compose stop'
elif [ "$command" = 'start' ] 
then
  ssh $host 'cd development/sdbmss && docker-compose start'
elif [ "$command" = 'deploy' ] 
then
  ssh $host 'cd development/sdbmss && docker-compose down && git pull && docker build . -t sdbm && docker-compose up --build --detach && docker-compose start'
else
  echo "INVALID COMMAND"
  echo "Required syntax is: ./deploy.sh <HOST> <COMMAND> <BRANCH(optional)>"
  echo "Available commands are: start, stop and deploy"
  exit
fi
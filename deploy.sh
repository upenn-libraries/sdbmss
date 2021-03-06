#!/bin/bash

# Very simple deployment script, that just runs the docker stop/start/build and git pull commands over ssh.  The syntax is as follows:
# ./deploy.sh <HOST> <COMMAND:START/STOP/DEPLOY> **<BRANCH>** <version?>

path='sdbmss/current'

host=$1
command=$2
version=$3

if [ "$host" = '' ]
then
  echo "MISSING HOST"
  echo "Required syntax is: ./deploy.sh <HOST> <COMMAND> <VERSION(optional>"
  echo "Available commands are: start, stop, deploy and version"
  exit
fi

if [ "$command" = '' ]
then
  echo "MISSING COMMAND"
  echo "Required syntax is: ./deploy.sh <HOST> <COMMAND> <VERSION(optional)>"
  echo "Available commands are: start, stop and deploy"
  exit
fi

if [ "$command" = 'stop' ] 
then
  ssh $host "cd $path && docker-compose stop"
elif [ "$command" = 'version' ] 
then
  ssh $host "cd $path && cat VERSION"
elif [ "$command" = 'start' ]
then
  ssh $host "cd $path && docker-compose start"
elif [ "$command" = 'deploy' ] 
then
  if [ "$version" = '']
  then
    echo "Deploying Patch"
    ssh $host "cd $path && docker-compose down && git pull && /bin/bash build.sh && docker-compose up --build --detach && docker-compose start"
  else
    echo "Deploying Version $version"
    ssh $host "cd $path && docker-compose down && git pull && echo $version > VERSION && /bin/bash build.sh && docker-compose up --build --detach && docker-compose start"
  fi
else
  echo "INVALID COMMAND"
  echo "Required syntax is: ./deploy.sh <HOST> <COMMAND> <VERSION(optional)>"
  echo "Available commands are: start, stop and deploy"
  exit
fi


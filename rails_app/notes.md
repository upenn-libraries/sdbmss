notes:

- use MYSQL_DATABASE type env variables to auto-create database
  + https://docs.docker.com/samples/library/mysql/#mysql_allow_empty_password
  + https://docs.docker.com/compose/rails/#build-the-project
- migrations
  + docker-compose run rails bundle exec rake db:migrate
  + IS THERE A BETTER WAY (part of Dockerfile?)
  + had to modify some migration files since they seemed... broken
- make sure ports are correctly setup, modify database.yml HOST to point to docker container instead of IP
- import sql using mysqldump, docker cp, mysql < ...
- reindex
  + docker-compose run rails bundle exec rake sunspot:reindex


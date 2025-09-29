# SDBM -- Schoenberg Database of Manuscripts

This is the Rails / Blacklight application for the Schoenberg Database of Manuscripts.

## Developing

### Working with the Vagrant environment

In order to use the integrated development environment you will need to install [Vagrant](https://www.vagrantup.com/docs/installation) [do *not* use the Vagrant version that may be available for your distro repository - explicitly follow instructions at the Vagrant homepage] and the appropriate virtualization software. If you are running Linux or Mac x86 then install [VirtualBox](https://www.virtualbox.org/wiki/Linux_Downloads), if you are using a Mac with ARM processors then install [Parallels](https://www.parallels.com/).

You may need to update the VirtualBox configuration for the creation of a host-only network. This can be done by creating a file `/etc/vbox/networks.conf` containing:

```
* 10.0.0.0/8
```

#### Vagrant Services

1. [The SDBM Rails app](https://sdbmss-staging.library.upenn.edu/)
2. Solr
3. MySQL
4. RabbitMQ -- queue for Jena updates
5. Jena Fuseki -- RDF/SPARQL server
6. Delayed Job -- background job processing (Rails image)
7. Interface -- service for updating Jena (listens to RabbitMQ queue)
8. Nginx -- reverse proxy

#### Starting

From the [vagrant](vagrant) directory run:

if running with Virtualbox:
```
vagrant up --provision
```

if running with Parallels:
```
vagrant up --provider=parallels --provision
```

This will run the [vagrant/Vagrantfile](vagrant/Vagrantfile) which will bring
up an Ubuntu VM and run the Ansible script which will provision a single node
Docker Swarm behind nginx with a self-signed certificate to mimic a load
balancer. Your hosts file will be modified; the domain
`sdbm-dev.library.upenn.edu` will be added and mapped to the Ubuntu VM. Once the
Ansible script has completed and the Docker Swarm is deployed you can access the
application by navigating to [https://sdbm-dev.library.upenn.edu/][sdbm-dev].

[sdbm-dev]: https://sdbm-dev.library.upenn.edu/ "SDBM Vagrant Instance"

#### Stopping

To stop the development environment, from the `vagrant` directory run:

```
vagrant halt
```

#### Destroying

To destroy the development environment, from the `vagrant` directory run:

```
vagrant destroy -f
```

#### SSH

You may ssh into the Vagrant VM by running:

```
vagrant ssh
```

#### Interacting with the Rails Application

Once your vagrant environment is set up you can ssh into the vagrant box to interact with the application:

1. Enter the Vagrant VM by running `vagrant ssh` in the `/vagrant` directory
2. Start a shell in the `sdbm` container:
```
  docker exec -it $(docker ps -q -f name="sdbmss_app") sh
```

### First-time setup

There are number of initial setup steps required to run this SDBM.

1. Copy static assets into the Rails app
2. Load the database
3. Set up Solr
4. Index the database in Solr
5. Set up Jena

First get the SDBM data files from OneDrive (by permission only):

- [SDBM DB SQL](https://penno365.sharepoint.com/:u:/r/teams/LIBSDBMDev2025/Shared%20Documents/sdbm.sql.gz?csf=1&web=1&e=ME2yFB) (180MB)
- [SDBM static data](https://penno365.sharepoint.com/:u:/r/teams/LIBSDBMDev2025/Shared%20Documents/sdbm_data.tgz?csf=1&web=1&e=NYaJ5m) (120MB)


#### Static assets setup

The SDBM relies on a number of user-managed static HTML files: docs, tooltips, and uploads. These are stored in the `sdbm_data.tgz` file. These files should be extracted and copied into the Rails app container.

```shell
tar xf sdbm_data.tgz  # if needed
cd sdbm_data          # if needed
docker cp docs $(docker ps -q -f name=app):/home/app/public/static/
docker cp tooltips $(docker ps -q -f name=app):/home/app/public/static/
docker cp uploads $(docker ps -q -f name=app):/home/app/public/static/
```

#### Database setup

Copy the database SQL gzip file to the MySQL container, gunzip it and load import it.

```bash
docker cp sdbm.sql.gz  $(docker ps -q -f name=mysql):/tmp/sdbm.sql.gz
docker exec -it  $(docker ps -q -f name=msysql) bash
cd /tmp
gunzip sdbm.sql.gz
mysql -u sdbm -p sdbm < sdbm.sql
# the vagrant env database password is "password"
rm sdbm.sql # remove the sql file (it's very big)
exit # exit the MySQL container
docker exec $(docker ps -q -f name=app) bundle exec rake db:migrate
```

#### Solr setup

Solr should be running in the Solr container. The Solr configuration is in the `solr` directory.

```bash
docker exec $(docker ps -q -f name=app) bundle exec rake sunspot:reindex
```

This process takes a couple of hours.


#### Jena setup

For this step the TTL file is generated from the database and then loaded into Jena.


### Build TTL from the database

```
docker exec -t $(docker ps -q -f name=app) bundle exec rake sparql:test
```
File should be in `.`; gzip it.

```
gzip test.ttl
```

### Import the data into Jena

Copy file to Jena container and gunzip it

```
docker cp test.ttl.gz $(docker ps -q -f name=sdbmss_jena):/tmp/
docker exec -t $(docker ps -q -f name=sdbmss_jena) gunzip /tmp/test.ttl.gz
```

Load the data into Jena

```
docker exec -t $(docker ps -q -f name=sdbmss_jena) sh -c 'cd /jena-fuseki && ./tdbloader --loc=/fuseki/databases/sdbm /tmp/test.ttl'
```

Clean up the files.

```
$ docker exec -t $(docker ps -q -f name=sdbmss_jena) rm /tmp/test.ttl
rm ~/deployments/sdbmss/test.ttl.gz
```

### Create the datset in Jena Fuseki.

Go here and create the sdbm dataset: <https://localhost/sparql/manage.html>

- Click 'add new data set'
- Enter 'sdbm'
- Select 'Persistent – dataset will persist across Fuseki restarts'
- Click 'create dataset'

Scale the services:

```
docker-compose -f docker-compose-dev.yml restart jena
docker-compose -f docker-compose-dev.yml restart rabbitmq
docker-compose -f docker-compose-dev.yml restart rails
```

Run the Jena verify task to confirm that it works. Be sure to hide the debugging output.

```
docker-compose -f docker-compose-dev.yml exec rails bundle exec rake jena:verify | grep -v DEBUG
```

NB: You may need to run the command more than once.

```
sdbm01[~]$ docker-compose -f docker-compose-dev.yml exec rails bundle exec rake jena:verify | grep -v DEBUG
Starting Queue Listening
No more messages in queue.
Remaining responses: 764
$ docker-compose -f docker-compose-dev.yml exec rails bundle exec rake jena:verify | grep -v DEBUG
Starting Queue Listening
Parsed contents: {"id"=>300122, "code"=>"200", "message"=>"OK"}
Jena Update was Successful!
Parsed contents: {"id"=>300211, "code"=>"200", "message"=>"OK"}
Jena Update was Successful!
Parsed contents: {"id"=>300212, "code"=>"200", "message"=>"OK"}
Jena Update was Successful!
Parsed contents: {"id"=>300213, "code"=>"200", "message"=>"OK"}
Jena Update was Successful!
# ... etc.
```







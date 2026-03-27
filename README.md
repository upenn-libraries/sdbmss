# SDBM -- Schoenberg Database of Manuscripts

This is the Rails / Blacklight application for the Schoenberg Database of Manuscripts.

Note that 'sdbmss' is used everywhere in the code because for Ruby versions `< 3.0` 'sdbm' was the
name of a package in Ruby's standard library. With Ruby 3.0 'sdbm' was moved from Ruby's stdlib to a separate gem.

## Documents

Detailed information about the SDBM application and project has been published to the [SDBM](https://sdbm.library.upenn.edu/). Among other information under the About and Help menus you will find:

- [About the SDBM](https://sdbm.library.upenn.edu/pages/About)
- [Technical Overview](https://sdbm.library.upenn.edu/pages/Technical%20Overview)
- [High-level description of the data model](https://sdbm.library.upenn.edu/static/docs/SDBM_data_explanation2019.pdf)
- [Entry Relationship Diagram](https://sdbm.library.upenn.edu/static/docs/erd.pdf)
- [FAQ](https://sdbm.library.upenn.edu/pages/FAQ)

## Developing

### Working with docker compose locally

See [`rails_app/README-docker-dev.md`](./rails_app/README-docker-dev.md) for instructions to run the SDBM in docker for local development.

### Working with the Vagrant environment (Penn Libraries staff only)

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
8. Traefik -- reverse proxy

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
To exit the shell:
```
exit
```
To further exit the vagrant environment:

```
exit
```

#### First-time setup (Vagrant environment)

There are number of initial setup steps required to run this SDBM that are handled by a bash
script setup.sh stored in the rails_app/dev folder and run from the vagrant environment. The setup script
does the following:

1. Copie static assets into the Rails app
2. Loads the database
3. Sets up Solr
4. Indexes the database in Solr
5. Sets up Jena

First get the SDBM data files from [the SDBM Data folder on SharePoint](https://penno365.sharepoint.com/:f:/r/teams/LIBSDBMDev2025/Shared%20Documents/SDBMData?csf=1&web=1&e=y2Vxme) (by permission only):

- `sdbm_data.tgz` (120MB)
- `sdbm.sql.gz` (6.3MB)

### Copy the files to the development environment

Download the files and copy them to the `sdbmss/rails_app/dev` directory. Then run the vagrant environment:

```
vagrant ssh
```

The files that you put in the dev directory will be automatically copied over to a directory in the
docker shell. Make sure you see the files there:

```
ls /sdbmss/rails_app/dev/
```

To perform these setup actions, first navigate to the dev folder within the vagrant environment,
and then run the bash script. This should take about 5 minutes.

```shell
vagrant ssh # if needed
cd /sdbmss/rails_app/dev
bash setup.sh -e VAGRANT
```

#### Check Jena log

When the setup script is finished running, check the Jena log to see if the service starts correctly:
```
docker service logs sdbmss_jena --since 5m -f
```

The log should look something like the output below:
```
sdbmss_jena.1.c08kinpat2hp@sdbm-manager    | Waiting for Fuseki to finish starting up...
sdbmss_jena.1.c08kinpat2hp@sdbm-manager    | [2025-10-06 18:04:55] Server     INFO  Apache Jena Fuseki 3.14.0
sdbmss_jena.1.c08kinpat2hp@sdbm-manager    | [2025-10-06 18:04:55] Config     INFO  FUSEKI_HOME=/jena-fuseki
sdbmss_jena.1.c08kinpat2hp@sdbm-manager    | [2025-10-06 18:04:55] Config     INFO  FUSEKI_BASE=/fuseki
sdbmss_jena.1.c08kinpat2hp@sdbm-manager    | [2025-10-06 18:04:55] Config     INFO  Shiro file: file:///fuseki/shiro.ini
sdbmss_jena.1.c08kinpat2hp@sdbm-manager    | [2025-10-06 18:04:55] Config     INFO  Configuration file: /fuseki/config.ttl
sdbmss_jena.1.c08kinpat2hp@sdbm-manager    | [2025-10-06 18:04:55] Config     INFO  Load configuration: file:///fuseki/configuration/sdbm.ttl
sdbmss_jena.1.c08kinpat2hp@sdbm-manager    | [2025-10-06 18:04:55] Config     INFO  Register: /sdbm
sdbmss_jena.1.c08kinpat2hp@sdbm-manager    | [2025-10-06 18:04:55] Server     INFO  Started 2025/10/06 18:04:55 UTC on port 3030
sdbmss_jena.1.c08kinpat2hp@sdbm-manager    | Fuseki is available :-)
```

## Production and staging deployments

The SDBM is currently structured to be deployed to production and staging docker swarm by Ansible. These deployments are managed by a GitLab CI/CD pipeline.





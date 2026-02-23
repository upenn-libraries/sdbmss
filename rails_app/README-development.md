# SDBM -- Schoenberg Database of Manuscripts

This is the Rails / Blacklight application for the Schoenberg Database of Manuscripts.

## Developing

### Working with docker compose locally

In order to use the docker compose development environment, you will need to have:

- Docker (Linux) or Docker Desktop (macOS)
- A `.docker-environment` file

And, if you're working outside the UPenn network:

- A local image of the SDBM interface service 
- A local image of the SDBM Jena Fuseki service

TODO: Make SDBM interface and Jena Fuseki images publicly available.

You may need to update the VirtualBox configuration for the creation of a host-only network. This can be done by creating a file `/etc/vbox/networks.conf` containing:

```
* 10.0.0.0/8
```

#### Docker Services

1. [The SDBM Rails app](https://sdbmss.localhost/)
2. Solr
3. MySQL
4. RabbitMQ -- queue for Jena updates
5. Jena Fuseki -- RDF/SPARQL server
6. Delayed Job -- background job processing (Rails image)
7. Interface -- service for updating Jena (listens to RabbitMQ queue)
8. Traefik -- reverse proxy

#### Starting

From the [rails_app](.) directory run:

if you've already set up the SDBM:
```
docker compose --env-file=.docker-environment -f docker-compose.dev.yml up

# or, if you don't want log output
docker compose --env-file=.docker-environment -f docker-compose.dev.yml up -d
```

NOTE: See below if this is your first time running the SDBM.

Once the docker compose start process is finished, you should be able to access the SDBM at [http://sdbmss.localhost](http://sdbmss.localhost).

#### Stopping

To stop the development environment, from the [rails_app](.) directory, run:

```
docker compose --env-file=.docker-environment -f docker-compose.dev.yml down
```

This will remove the containers and networks, but leave the volumes in place, so that you can run the docker compose up command above and return the application's previous state. 



#### Destroying

To remove the containers, networks, and the volumes in order to completely rebuild the SDBM docker environment, run:

```
docker compose --env-file=.docker-environment -f docker-compose.dev.yml down
```

#### Restarting

To restart the SDBM, in order to pick up runtime changes from `.docker-environment`, run:

```
docker compose --env-file=.docker-environment -f docker-compose.dev.yml restart
```

For an individual service:

```
docker compose --env-file=.docker-environment -f docker-compose.dev.yml restart SERVICE_NAME # e.g, 'app'
```

#### Interacting with the Rails Application

Once the SDBM is running can use docker exec to interact with the running application:

1. Run `docker ps` to get a list of the running container names:

```
CONTAINER ID   IMAGE                                              COMMAND                   CREATED       STATUS                   PORTS                                                                  NAMES
3b7b1711b099   localhost:8000/sdbmss:development                  "docker-entrypoint.s…"    2 hours ago   Up 2 hours                                                                                      sdbmss-solr-1
390172074c32   localhost:8000/sdbmss:development                  "docker-entrypoint.s…"    2 hours ago   Up 2 hours (healthy)                                                                            sdbmss-app-1
85ca236ca1fe   gitlab.library.upenn.edu/sdbm/jena-fuseki:latest   "/bin/tini -- sh /do…"    2 hours ago   Up 2 hours (unhealthy)   0.0.0.0:3030->3030/tcp, [::]:3030->3030/tcp                            sdbmss-jena-1
09e809feae15   localhost:8000/sdbmss:development                  "docker-entrypoint.s…"    2 hours ago   Up 2 hours                                                                                      sdbmss-delayed_job-1
87f7bc9cd72b   gitlab.library.upenn.edu/sdbm/interface:29ddfa21   "ruby interface.rb"       2 hours ago   Up 2 hours (healthy)                                                                            sdbmss-interface-1
870ef2b77b91   traefik:2.9                                        "/entrypoint.sh --ac…"    2 hours ago   Up 2 hours               0.0.0.0:80->80/tcp, [::]:80->80/tcp, 0.0.0.0:443->443/tcp, [snip...]   sdbmss-traefik-1
a6307da18b07   browserless/chrome:latest                          "./start.sh"              2 hours ago   Up 2 hours               0.0.0.0:3333->3333/tcp, [::]:3333->3333/tcp                            sdbmss-chrome-1
8e55260d7cce   biarms/mysql:5.7                                   "/usr/local/bin/dock…"    2 hours ago   Up 2 hours               3306/tcp                                                               sdbmss-mysql-1
0320eafb450f   rabbitmq:3.7                                       "docker-entrypoint.s…"    2 hours ago   Up 2 hours               4369/tcp, 5671-5672/tcp, 25672/tcp                                     sdbmss-rabbitmq-1
```

2. Start a shell in the `sdbm` container:

```
docker exec -it sdbmss-app-1 bash
```

To exit the shell:
```
exit
```

### Running tests

The SDBM uses rspec for testing. The tests must be run in the running `app` container. To run the tests, docker exec into the container and run rspec as shown below:

```
$ docker exec -it sdbmss-app-1 bash
root@1234abcdef:/home/app# RAILS_ENV=test bundle exec rspec 
```

> IMPORTANT: Be sure to specify `RAILS_ENV=test`

The tests take about 14 minutes to run. 

To skip the Javascript tests for quicker run, use the `--tag ~js` flag.

```
root@1234abcdef:/home/app# RAILS_ENV=test bundle exec rspec --tag ~js
```

Or to run only the Javascript tests:

```
root@1234abcdef:/home/app# RAILS_ENV=test bundle exec rspec --tag js
```

### First-time setup

Before you run `docker compose` for the first time, you must provide a `.docker-environment` file and add the `SDBMSS_APP_HOST` to `/etc/hosts`. 

#### `.docker-environment` changes

Copy [`rails_app/docker-environment-sample`](./docker-environment-sample) to [`rails_app/.docker-environment`](./.docker-environment):

```
cd rails_app
cp docker-environment-sample .docker-environment
```

Edit [`rails_app/.docker-environment`](./.docker-environment) for your environment.

> Note especially that `INTERFACE_IMAGE_NAME` and `JENA_IMAGE_NAME` are specific to the U. Penn's network and require UPenn's VPN for offsite access. If you're working outside the network and lack a PennKey and VPN, you'll need to adjust these for your setup.

#### `/etc/hosts` setup

Before you run `docker compose` for the first time, you must add the `SDBMSS_APP_HOST` to `/etc/hosts`.

For example, if you use the default value for `SDBMSS_APP_HOST` in the sample environment file `sdbmss.localhost`, you should add the following to `/etc/hosts`:

```
127.0.0.1 sdbmss.localhost
```

#### Bring up the application with docker compose

Run docker compose up with the `--build` option to build and set up the SDBM:

```
docker compose --env-file=.docker-environment -f docker-compose.dev.yml up --build
```

This will pull all required images and build the SDBM `app` image.

Wait for the docker compose process to complete before moving on to the next step, _SDBM develop app data setup_. 

#### SDBM develop app data setup

There are number of initial setup steps required to run this SDBM that are handled by a bash script setup.sh stored in the rails_app/dev folder. The setup script does the following:

1. Copies static assets into the Rails app
2. Loads the development database
3. Sets up Solr
4. Indexes the database in Solr
5. Sets up the Jena triple store

First get the SDBM data files from [the SDBM Data folder on SharePoint](https://penno365.sharepoint.com/:f:/r/teams/LIBSDBMDev2025/Shared%20Documents/SDBMData?csf=1&web=1&e=y2Vxme) (by permission only):

- `sdbm_data.tgz` (120MB)
- `sdbm.sql.gz` (33MB)

### Copy the files to the development environment

Download the files and copy them to the `sdbmss/rails_app/dev` directory. 

Confirm that the data files are present:

```
ls rails_app/dev
```

You should see:

```
sdbm_data.tgz sdbm.sql.gz sdbm.ttl setup.sh
```

To perform these setup actions, first navigate to the dev folder, and then run the bash script. This should take about 5 minutes.

```shell
cd rails_app/dev  # if needed
bash setup.sh -e LOCAL  # set up for LOCAL docker, as opposed to docker in VAGRANT 
```

#### Check Jena log

When the setup script is finished running, check the Jena log to see if the service starts correctly:
```
docker compose logs sdbmss_jena --since 5m -f
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



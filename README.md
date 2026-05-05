# SDBM -- Schoenberg Database of Manuscripts

This is the Rails / Blacklight application for the Schoenberg Database of Manuscripts.

Note that 'sdbmss' is used everywhere in the code because for Ruby versions `< 3.0` 'sdbm' was a package in Ruby's standard library. With Ruby 3.0 'sdbm' was removed from Ruby's stdlib and made a separate gem.

## Documents

Detailed information about the SDBM application and project has been published to the [SDBM](https://sdbm.library.upenn.edu/). Among other information under the About and Help menus you will find:

- [About the SDBM](https://sdbm.library.upenn.edu/pages/About)
- [Technical Overview](https://sdbm.library.upenn.edu/pages/Technical%20Overview)
- [High-level description of the data model](https://sdbm.library.upenn.edu/static/docs/SDBM_data_explanation2019.pdf)
- [Entry Relationship Diagram](https://sdbm.library.upenn.edu/static/docs/erd.pdf)
- [FAQ](https://sdbm.library.upenn.edu/pages/FAQ)

## Developing

There are two options for running the SDBM locally:

1. **Docker Compose** — for anyone; see [`rails_app/README-docker-dev.md`](./rails_app/README-docker-dev.md)
2. **Vagrant** — Penn Libraries staff only; see below

### Working with docker compose locally

See [`rails_app/README-docker-dev.md`](./rails_app/README-docker-dev.md) for instructions for running the SDBM in docker for local development.

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
9. Chrome -- development-only headless browser for specs

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

This will run the [vagrant/Vagrantfile](vagrant/Vagrantfile) which will bring up an Ubuntu VM and run the Ansible script which will provision a single node Docker Swarm behind nginx with a self-signed certificate to mimic a load balancer. Your hosts file will be modified; the domain `sdbm-dev.library.upenn.edu` will be added and mapped to the Ubuntu VM. Once the Ansible script has completed and the Docker Swarm is deployed you can access the application by navigating to [https://sdbm-dev.library.upenn.edu/][sdbm-dev].

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

There are number of initial setup steps required to run this SDBM that are handled by a bash script setup.sh stored in the rails_app/dev folder and run from the vagrant environment. The setup script does the following:

1. Copies static assets into the Rails app
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

The files that you put in the dev directory will be automatically copied over to a directory in the docker shell. Make sure you see the files there:

```
ls /sdbmss/rails_app/dev/
```

To perform these setup actions, first navigate to the dev folder within the vagrant environment, and then run the bash script. This should take about 5 minutes.

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

### Staging deployment (MR into `main`)

Merging an MR into `main` triggers the CI/CD pipeline to build and deploy to staging automatically.

**1. Merge the MR** in GitLab.

**2. Watch the pipeline** in GitLab CI until the deploy job completes.

**3. Confirm startup** on the staging server.

`docker service ls` shows replica counts but does not indicate when existing replicas have been *replaced* with the new image — use `docker ps` to see actual container start times:
```bash
watch 'docker ps --format "table {{.Names}}\t{{.Status}}\t{{.RunningFor}}" | grep sdbmss'
```
Wait until all `sdbmss_app` containers show a recent start time before continuing.

**4. Reindex Solr** (required if the Solr volume is fresh or the schema changed):
```bash
docker exec -it $(docker ps -q -f name=sdbmss_app.1) bundle exec rake sunspot:reindex
```

**5. Regenerate Jena** if the triple-store data needs refreshing — see [Regenerating Jena](#regenerating-jenasfuseki-triple-store) below.

---

### Production deployment (version tag)

**Pre-flight** — before creating the tag, SSH to the production server and remove any stale volumes. Confirm volume names first (Docker Swarm prefixes with the stack name `sdbmss_`):
```bash
docker volume ls | grep -E 'sdbm|downloads'
docker service ls
```

If `sdbm_solr`/`sdbmss_sdbm_solr` needs to be replaced, scale Solr down first:
```bash
docker service scale sdbmss_solr=0
watch docker service ls   # wait for replicas to reach 0
docker volume rm sdbmss_sdbm_solr
```

If `sdbm_assets`/`sdbmss_sdbm_assets` needs to be removed:
```bash
docker volume rm sdbmss_sdbm_assets
# If "volume is in use": docker service scale sdbmss_app=0 first
```

**Trigger deployment** by creating a version tag:
```bash
git tag v<X.Y.Z>
git push origin v<X.Y.Z>
```

The pipeline will build and push the production Docker image, then run Ansible to redeploy all services.

**Confirm startup** on the production server. `docker service ls` shows replica counts but does not indicate when replicas have been replaced — use `docker ps`:
```bash
watch 'docker ps --format "table {{.Names}}\t{{.Status}}\t{{.RunningFor}}" | grep sdbmss'
```
Production runs **3 `sdbmss_app` replicas**; allow approximately **10 minutes** for all three to come up. Proceed only once all containers show a recent start time.

**Reindex Solr** once the Solr service is healthy:
```bash
docker exec -it $(docker ps -q -f name=sdbmss_app.1) bundle exec rake sunspot:reindex
```

---

### Regenerating Jena/Fuseki triple store

Use this procedure when the triple-store data needs to be rebuilt from the production database. The existing TDB database must be explicitly cleared before loading.

**1. Create a scratch volume** for the TTL data:
```bash
docker volume create sdbm_ttl_tmp
```

**2. Generate fresh TTL data** from the app container and copy it into the scratch volume:
```bash
docker exec $(docker ps -q -f name=sdbmss_app.1) bundle exec rake sparql:test

docker exec $(docker ps -q -f name=sdbmss_app.1) cat /home/app/test.ttl | \
  docker run --rm -i \
    --mount source=sdbm_ttl_tmp,target=/data \
    alpine sh -c 'cat > /data/test.ttl'
```

**3. Get the Jena image reference**:
```bash
JENA_IMAGE=$(docker service inspect sdbmss_jena --format '{{.Spec.TaskTemplate.ContainerSpec.Image}}')
```

**4. Scale down Jena**:
```bash
docker service scale sdbmss_jena=0
watch docker service ls   # wait for replicas to reach 0
```

**5. Clear the existing TDB database**:
```bash
docker run --rm \
  --mount source=sdbmss_rdf_data,target=/fuseki \
  alpine \
  sh -c 'rm -rf /fuseki/databases/sdbm'
```

**6. Load the new TTL** via tdbloader:
```bash
docker run --rm \
  --entrypoint /jena-fuseki/tdbloader \
  --mount source=sdbmss_rdf_data,target=/fuseki \
  --mount source=sdbm_ttl_tmp,target=/data,readonly \
  "$JENA_IMAGE" \
  --loc=/fuseki/databases/sdbm /data/test.ttl
```

**7. Install the Fuseki dataset config** from the Jena image:
```bash
docker run --rm \
  --entrypoint sh \
  --mount source=sdbmss_rdf_data,target=/fuseki \
  "$JENA_IMAGE" \
  -c 'mkdir -p /fuseki/configuration && cp /jena-fuseki/sdbm.ttl /fuseki/configuration/sdbm.ttl && chmod 0644 /fuseki/configuration/sdbm.ttl'
```

**8. Scale Jena back up and clean up**:
```bash
docker service scale sdbmss_jena=1
docker volume rm sdbm_ttl_tmp
```

**9. Verify** Jena is healthy:
```bash
docker service logs sdbmss_jena --since 5m -f
```

The log should show `Fuseki is available :-)` once the service is ready.

> **Note**: Confirm the `rdf_data` volume name on the target server with `docker volume ls | grep rdf_data` — it may carry the stack prefix `sdbmss_`. Also confirm `sdbm.ttl` is present in the Jena image: `docker run --rm --entrypoint sh "$JENA_IMAGE" -c 'ls /jena-fuseki/sdbm.ttl'`.


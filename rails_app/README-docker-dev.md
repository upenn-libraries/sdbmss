# SDBM — Local Docker Development

## Prerequisites

- Docker Desktop (macOS) or Docker Engine (Linux)
- Ruby (to run `bin/tools`)
- A `.env` file (see below)
- `sdbmss.localhost` in `/etc/hosts` (see below)

## First-time setup

### 1. Create `.env`

From the `rails_app/` directory:

```
cp docker-environment-sample .env
```

Edit `.env` for your environment.

### 2. Add `/etc/hosts` entry

```
127.0.0.1 sdbmss.localhost
```

> On macOS this is required. Linux may not need it.

### 3. Get data files

Download from [SDBM Data on SharePoint](https://penno365.sharepoint.com/:f:/r/teams/LIBSDBMDev2025/Shared%20Documents/SDBMData?csf=1&web=1&e=y2Vxme) (by permission only):

- `sdbm_data.tgz` (120 MB)
- `sdbm.sql.gz` (33 MB)

Place them in `rails_app/dev/data/`.

### 4. Start the stack

From `rails_app/`:

```
bin/tools start
```

This builds the interface and Jena images from GitHub, then starts all services.

### 5. Run setup

```
bin/tools setup
```

This loads the database, copies static assets, adds test users, reindexes Solr, and loads Jena. Takes about 5 minutes.

### 6. Confirm

Go to [http://sdbmss.localhost](http://sdbmss.localhost). Log in as `admin` / `testpassword`.

---

## Daily use

| Command                   | What it does                          |
|---------------------------|---------------------------------------|
| `bin/tools start`         | Start all services                    |
| `bin/tools stop`          | Stop all services (volumes preserved) |
| `bin/tools clean`         | Remove all services and volumes       |
| `bin/tools start --force` | Rebuild custom images before starting |

All commands run from `rails_app/`.

## Running tests

Tests run inside the app container:

```
docker exec -it sdbmss-app-1 bash
RAILS_ENV=test bundle exec rspec
```

Skip JS tests for a faster run: `bundle exec rspec --tag ~js`

The full suite takes about 14 minutes.

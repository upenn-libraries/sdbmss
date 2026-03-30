
Running the SDBM
======

The Schoenberg Database of Manuscripts. This is the Ruby on Rails /
Blacklight project reboot, started in late Nov 2014.

Note that we use 'sdbmss' everywhere in the code because 'sdbm' is the
name of a package in Ruby's standard library.

Deployment
=====

The application is currently structured to be deployed to production and staging docker swarm by Ansible. These Ansible deployments are managed by a GitLab CI/CD pipeline. There are two options for development deployments: 

1. An Ansible/Vagrant/docker swarm deployment. This deployment requires to Penn Libraries-only services.
2. A development docker compose environment. See [README-docker-dev.yml](README-docker-dev.md).


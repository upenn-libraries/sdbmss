# 2. Build CRUD and search application

Date: 2019-07-15

## Status

Accepted

## Context

The Schoenberg Institute won three-year NEH grant to rebuild the existing Schoenberg Database of Manuscripts to 
replace the then current SDBM which was written in ColdFusion, lacked critical data model features and user-based editing.
The new application needed a more flexible, user contribution, complex search and an up-to-date technology stack.

## Decision

The following technologies were select for the following reasons.

- Blacklight, which uses Solr, was chosen to provide complex, configurable search, and uses technology common in the library, and for which long term product support could be expected. Blacklight was also used for bookmarking.
- Rails is required by Blacklight
- MySQL was selected as it was the database of choice within library technology services, and supported by sysadmin staff
- Solr is required by Blacklight
- Delayed Job (URL) was chosen as for orchestrating background jobs, namely sending updates from the database to the Solr index
- Sunspot was chosen for the Rails-Solr interaction
- AngularJS was chosen to support complex, dynamic page interactions 
- cancancan was selected to provide tiered, role-based access for users with different permission levels

## Consequences

These choices made possible the goals of the project: well-supported and flexible technology stack, user editing of records, complex and dynamic data search.

We are now in a position where Sunspot is not maintained and a new technology is needed.

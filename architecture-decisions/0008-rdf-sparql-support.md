# 8. RDF SPARQL support

Date: 2019-07-15

## Status

Accepted

## Context

As part of participation in the [Mapping Manuscript Migrations (MMM)][mmm] Linked Data project, the SDBM needed to export its data in RDF format for aggregation in a unified set of data from the project's three contributing organizations. 

[mmm]: http://mappingmanuscriptmigrations.org "Mapping Manuscript Migrations project site"

At the time the export was built a single unified data model had not been agreed upon.

## Decision

The project decided to build a SPARQL endpoint built on Apache Jena. Since there was no target data model, the SDBM was exported to a custom namespace using a simple, direct mapping from SDBM model attributes to RDF. RabbitMQ messenger queue and a listener interface (`interface.rb`) to push updates from the SDBM to Jena. Also a simple SPARQL query interface was added for SDBM users.

## Consequences

The SDBM data is available from the SDBM site via SPARQL and was available for integration into the MMM project. It is not expressed in standard ontologies and, thus, limits interoperability in its current state.

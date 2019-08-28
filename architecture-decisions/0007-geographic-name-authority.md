# 7. Geographic name authority

Date: 2019-07-15

## Status

Accepted

## Context

To improve SDBM data interoperability, in particular for the [Mapping Manuscript Migrations][mmm] Linked Data project, the project wanted to add authority URIs to SDBM Place records.

[mmm]: http://mappingmanuscriptmigrations.org "Mapping Manuscript Migrations project site"

## Decision

The project chose to add name records from the [Getty Thesaurus of Geographic Names (TGN)][TGN] and [GeoNames][GEO] databases. Search functionality was enabled for GeoNames, which supports HTTPS, but not TGN which does not. TGN is used because it includes historic place and region names. Form integration is managed through an Angular controller.

[TGN]: http://www.getty.edu/research/tools/vocabularies/tgn/ "Getty Thesaurus of Geographic Names Online"
[GEO]: https://www.geonames.org "GeoNames"

## Consequences

Users add place authority URIs from TGN and GeoNames and export SDBM places are more inter-operable with other data sets and applications. Entering information is easier for GeoNames, as it is integrated with the pages.

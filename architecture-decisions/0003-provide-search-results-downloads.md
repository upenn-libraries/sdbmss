# 3. Provide search results downloads

Date: 2019-07-15

## Status

Accepted

## Context

Users wanted to be able to download sets of search results for use apart from the application.

## Decision

The CSV format was chosen for downloaded search results. Because these sets can be quite large, the creation of search
results is backgrounded using delayed and users or informed of this through a dashboard and in-browser notification. Delayed job is used for background orchestration.

## Consequences

The application now has a user-accessible mode of data delivery. Because of the flat nature of CSV tabular files, not 
all of the hierarchical SDBM data is available via these files.

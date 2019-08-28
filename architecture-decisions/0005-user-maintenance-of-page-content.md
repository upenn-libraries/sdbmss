# 5. User maintenance of page content

Date: 2019-07-15

## Status

Accepted

## Context

The project team wanted to able to edit frequently different varieties of textual page content--welcome messages, instructional text, read-me text, tool tips, and so forth.

## Decision

A system of HTML pages was created to be loaded via an AngularJS plugin so that admin users can edit the static files directly. The edited files are saved to disk and included in the pages at load time.

## Consequences

The pages thus managed are not in version control with the application code. This creates a need to backup up those pages using some other means.

Not all text content on the site is amenable to this method, requiring that some text still must be edited in the source repository. Users have little insight into why some text is editable and others not.

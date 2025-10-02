#  Maintenance Scripts

This directory contains scripts that are used to maintain this package.

Beware! The contents of this directory are not source stable. They are provided as is, with no compatibility promises across package releases. Future versions of this package can arbitrarily change these files or remove them, without any advance notice. (This can include patch releases.)

- `generate-docs.sh`: A shell scripts that automates the generation of API documentation.

- `run-full-tests.sh`: A shell script that exercises many common configurations of this package in a semi-automated way. This is used before tagging a release to avoid accidentally shipping a package version that breaks some setups.

- `shuffle-sources.sh`: A legacy utility that randomly reorders Swift source files in a given directory. This is used to avoid reoccurrances of issue #7. (This is hopefully only relevant with compilers that the package no longer supports.)

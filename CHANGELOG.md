# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [3.1.0] - 2019-02-15

### Added
- `oscp_stapling`, `resolvers`, `resolver_valid` and `resolver_timeout` resource properties.

### Changed
- `tls` cookbook dependency pinned to `~> 3.1.0`.

### Removed
- HPKP support.
- `ec_certificates` and `hpkp_max_age` resource properties.

## [3.0.0] - 2018-11-19

Rewrite the cookbook.

### Added
- `gogs_app` resource is added.

### Removed
- the default recipe is removed.

## [2.1.3] - 2018-07-30

Create the CHANGELOG.

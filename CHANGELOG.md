# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [4.4.1] - 2021-08-25

### Added
- Add LFS data backup.
- Add `nginx_client_max_body_size` resource property

## [4.4.0] - 2021-08-25

### Added
- Add Git LFS support.

## [4.3.1] - 2021-04-28

### Added
- `additional_access_log` resource property to write Nginx logs to another log file.

## [4.3.0] - 2021-03-29

### Added
- `brand_name` resource property.

### Changed
- generated configuration (app.ini) now adheres to gogs version 0.12 or later.

## [4.0.0] - 2020-03-05

### Added
- `access_log_options` and `error_log_options` resource properties.

### Changed
- changed `nginx` cookbook dependency to `ngx`.
- renamed `https` resource property to `secure`.
- changed `config` resource property required format (use strings instead of symbols).

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

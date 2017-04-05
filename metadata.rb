name 'gogs'
maintainer 'Alexander Pyatkin'
maintainer_email 'aspyatkin@gmail.com'
license 'MIT'
version '1.5.1'
description 'Installs and configures Gogs'
long_description ::IO.read(::File.join(::File.dirname(__FILE__), 'README.md'))

recipe 'gogs', 'Installs and configures Gogs'

depends 'golang', '~> 1.7.0'
depends 'latest-redis', '~> 1.1.4'
depends 'postgresql', '~> 4.0.6'
depends 'database', '~> 6.1.1'
depends 'supervisor', '~> 0.4.12'
depends 'chef_nginx', '~> 6.0.0'
depends 'tls', '~> 3.0.0'
depends 'apt'
depends 'poise-python', '~> 1.5.1'

supports 'ubuntu'

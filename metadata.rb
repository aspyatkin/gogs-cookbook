name 'gogs'
maintainer 'Alexander Pyatkin'
maintainer_email 'aspyatkin@gmail.com'
license 'MIT'
version '1.1.1'
description 'Installs and configures Gogs'
long_description ::IO.read(::File.join(::File.dirname(__FILE__), 'README.md'))

recipe 'gogs', 'Installs and configures Gogs'

depends 'latest-git', '~> 1.1.9'
depends 'golang', '~> 1.7.0'
depends 'latest-redis', '~> 1.1.3'
depends 'postgresql', '~> 4.0.6'
depends 'database', '~> 5.1.2'
depends 'supervisor', '~> 0.4.12'
depends 'modern_nginx', '~> 1.3.0'
depends 'tls', '~> 2.0.0'

supports 'ubuntu'

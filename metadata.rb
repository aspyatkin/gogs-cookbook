name 'gogs'
maintainer 'Alexander Pyatkin'
maintainer_email 'aspyatkin@gmail.com'
license 'MIT'
version '3.1.0'
description 'Installs and configures Gogs'
long_description ::IO.read(::File.join(::File.dirname(__FILE__), 'README.md'))

recipe 'gogs', 'Installs and configures Gogs'

depends 'instance', '~> 2.0.1'
depends 'ark', '~> 4.0.0'
depends 'nginx'
depends 'tls', '~> 3.1.0'

supports 'ubuntu'

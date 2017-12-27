name 'gogs'
maintainer 'Alexander Pyatkin'
maintainer_email 'aspyatkin@gmail.com'
license 'MIT'
version '2.0.0'
description 'Installs and configures Gogs'
long_description ::IO.read(::File.join(::File.dirname(__FILE__), 'README.md'))

recipe 'gogs', 'Installs and configures Gogs'

depends 'instance', '~> 2.0.0'
depends 'secret', '~> 1.0.0'
depends 'ark', '~> 3.1.0'
depends 'supervisor', '~> 0.4.12'
depends 'postgresql', '~> 6.1.1'
depends 'database', '~> 6.1.1'
depends 'nginx', '~> 7.0.0'
depends 'tls', '~> 3.0.0'

supports 'ubuntu'

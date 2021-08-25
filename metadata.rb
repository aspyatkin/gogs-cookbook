name 'gogs'
maintainer 'Alexander Pyatkin'
maintainer_email 'aspyatkin@gmail.com'
license 'MIT'
version '4.4.1'
description 'Installs and configures Gogs'
long_description ::IO.read(::File.join(::File.dirname(__FILE__), 'README.md'))

recipe 'gogs', 'Installs and configures Gogs'

depends 'ark', '>= 5.0.0'
depends 'ngx', '~> 2.2'
depends 'tls', '~> 4.1'

supports 'ubuntu'

name 'gogs'
maintainer 'Alexander Pyatkin'
maintainer_email 'aspyatkin@gmail.com'
license 'MIT'
version '4.0.0'
description 'Installs and configures Gogs'
long_description ::IO.read(::File.join(::File.dirname(__FILE__), 'README.md'))

recipe 'gogs', 'Installs and configures Gogs'

depends 'instance', '~> 2.0.1'
depends 'ark', '>= 5.0.0'
depends 'ngx'
depends 'tls', '>= 3.2.0'

supports 'ubuntu'

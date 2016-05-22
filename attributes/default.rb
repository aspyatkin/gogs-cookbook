id = 'gogs'

default[id][:go][:version] = '1.6.2'
default[id][:go][:platform] = 'amd64'

default[id][:redis][:listen][:address] = '127.0.0.1'
default[id][:redis][:listen][:port] = 6379

default[id][:postgres][:version] = '9.5'
default[id][:postgres][:listen][:address] = '127.0.0.1'
default[id][:postgres][:listen][:port] = 5432
default[id][:postgres][:dbname] = 'gogs_db'
default[id][:postgres][:username] = 'gogs_user'

default[id][:gogs][:package] = 'github.com/gogits/gogs'
default[id][:gogs][:user] = 'git'
default[id][:gogs][:group] = 'git'
default[id][:gogs][:log_dir] = '/var/log/gogs'
default[id][:gogs][:conf][:app_name] = 'Git service'

default[id][:gogs][:conf][:repository][:force_private] = true

default[id][:gogs][:conf][:server][:protocol] = 'http'
default[id][:gogs][:conf][:server][:domain] = 'localhost'
default[id][:gogs][:conf][:server][:root_url] = '%(PROTOCOL)ss://%(DOMAIN)s/'
default[id][:gogs][:conf][:server][:http_addr] = '127.0.0.1'
default[id][:gogs][:conf][:server][:http_port] = 3000
default[id][:gogs][:conf][:server][:minimum_key_size_check] = true

default[id][:gogs][:conf][:service][:register_email_confirm] = true
default[id][:gogs][:conf][:service][:disable_registration] = true
default[id][:gogs][:conf][:service][:require_signin_view] = true
default[id][:gogs][:conf][:service][:enable_notify_mail] = true

default[id][:gogs][:conf][:mailer][:enabled] = true
default[id][:gogs][:conf][:mailer][:subject] = 'Service notification'
default[id][:gogs][:conf][:mailer][:from] = 'git@localhost'

default[id][:gogs][:conf][:cache][:redis_db] = 1

default[id][:gogs][:conf][:session][:redis_db] = 2

default[id][:gogs][:frontend][:hsts_max_age] = 15_724_800
default[id][:gogs][:frontend][:hpkp_max_age] = 604_800
default[id][:gogs][:frontend][:with_ipv6] = false

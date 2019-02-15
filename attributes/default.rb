id = 'gogs'

default[id]['version'] = '0.11.86'
default[id]['url'] = 'https://dl.gogs.io/%{version}/gogs_%{version}_linux_amd64.tar.gz'
default[id]['script_dir'] = '/etc/chef-gogs'

default[id]['user'] = 'git'
default[id]['group'] = 'git'

default[id]['log_dir'] = '/var/log/gogs'

default[id]['mailer']['enabled'] = false
default[id]['mailer']['from'] = nil

default[id]['cache']['redis_db'] = 1
default[id]['session']['redis_db'] = 2

default[id]['web']['fqdn'] = nil
default[id]['web']['ssl'] = false
default[id]['web']['use_ec_certificate'] = false
default[id]['web']['hsts_max_age'] = 15_724_800
default[id]['web']['hpkp_max_age'] = 604_800

default[id]['postgres']['host'] = '127.0.0.1'
default[id]['postgres']['port'] = 5432
default[id]['postgres']['database'] = 'gogs_db'
default[id]['postgres']['user'] = 'gogs_user'

default[id]['redis']['host'] = '127.0.0.1'
default[id]['redis']['port'] = 6379

default[id]['conf']['repository']['force_private'] = true

default[id]['conf']['service']['register_email_confirm'] = true
default[id]['conf']['service']['disable_registration'] = true
default[id]['conf']['service']['require_signin_view'] = true
default[id]['conf']['service']['enable_notify_mail'] = true

default[id]['conf']['admin']['disable_regular_org_creation'] = true

default[id]['conf']['git']['max_diff_lines'] = 1000
default[id]['conf']['git']['max_diff_line_characters'] = 500
default[id]['conf']['git']['max_diff_files'] = 100

default[id]['backup']['enabled'] = false
default[id]['backup']['aws']['iam']['account_alias'] = 'backup_user'
default[id]['backup']['aws']['s3']['bucket_region'] = nil
default[id]['backup']['aws']['s3']['bucket_name'] = nil
default[id]['backup']['cron']['mailto'] = nil
default[id]['backup']['cron']['mailfrom'] = nil
default[id]['backup']['cron']['minute'] = '0'
default[id]['backup']['cron']['hour'] = '2'
default[id]['backup']['cron']['day'] = '*'
default[id]['backup']['cron']['month'] = '*'
default[id]['backup']['cron']['weekday'] = '*'

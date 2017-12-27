id = 'gogs'

secret = ::ChefCookbook::Secret::Helper.new(node)

include_recipe 'database::postgresql'

postgres_root_username = 'postgres'

postgresql_connection_info = {
  host: node[id]['postgres']['host'],
  port: node[id]['postgres']['port'],
  username: postgres_root_username,
  password: secret.get("postgres:password:#{postgres_root_username}")
}

postgresql_database node[id]['postgres']['database'] do
  connection postgresql_connection_info
  action :create
end

postgresql_database_user node[id]['postgres']['user'] do
  connection postgresql_connection_info
  database_name node[id]['postgres']['database']
  password secret.get("postgres:password:#{node[id]['postgres']['user']}")
  privileges [:all]
  action [:create, :grant]
end

group node[id]['group'] do
  system true
  action :create
end

user_home = ::File.join('/home', node[id]['user'])

user node[id]['user'] do
  group node[id]['group']
  shell '/bin/bash'
  system true
  manage_home true
  home user_home
  comment 'Gogs'
  action :create
end

ark 'gogs' do
  url "https://cdn.gogs.io/#{node[id]['version']}/linux_amd64.tar.gz"
  version node[id]['version']
  action :install
end

log_dir = node[id]['log_dir']

directory log_dir do
  owner node[id]['user']
  group node[id]['group']
  mode 0755
  recursive true
  action :create
end

gogs_work_dir = ::File.join(node['ark']['prefix_home'], 'gogs')

custom_conf_path = ::File.join(gogs_work_dir, 'custom', 'conf')

directory custom_conf_path do
  owner node[id]['user']
  group node[id]['group']
  mode 0755
  recursive true
  action :create
end

repository_root = ::File.join(user_home, 'repositories')

directory repository_root do
  owner node[id]['user']
  group node[id]['group']
  mode 0755
  recursive true
  action :create
end

ssh_root = ::File.join(user_home, '.ssh')

directory ssh_root do
  owner node[id]['user']
  group node[id]['group']
  mode 0700
  recursive true
  action :create
end

data_dir = ::File.join(user_home, 'data')

directory data_dir do
  owner node[id]['user']
  group node[id]['group']
  mode 0755
  recursive true
  action :create
end

avatar_dir = ::File.join(data_dir, 'avatars')

directory avatar_dir do
  owner node[id]['user']
  group node[id]['group']
  mode 0755
  recursive true
  action :create
end

attachment_dir = ::File.join(data_dir, 'attachments')

directory attachment_dir do
  path attachment_dir
  owner node[id]['user']
  group node[id]['group']
  mode 0755
  recursive true
  action :create
end

app_ini_path = ::File.join(custom_conf_path, 'app.ini')
run_mode = node.chef_environment.start_with?('development') ? 'dev' : 'prod'

fqdn = node[id]['web']['fqdn'] || instance.fqdn
mailer_enabled = node[id]['mailer']['enabled']

template app_ini_path do
  path app_ini_path
  source 'app.ini.erb'
  owner node[id]['user']
  group node[id]['group']
  variables(
    run_user: node[id]['user'],
    run_mode: run_mode,
    repository: {
      root: repository_root,
      force_private: node[id]['conf']['repository']['force_private']
    },
    web: {
      ssl: node[id]['web']['ssl'],
      fqdn: fqdn
    },
    server: {
      ssh_root_path: ssh_root,
      minimum_key_size_check: true,
      app_data_path: data_dir
    },
    database: {
      db_type: 'postgres',
      host: node[id]['postgres']['host'],
      port: node[id]['postgres']['port'],
      name: node[id]['postgres']['database'],
      user: node[id]['postgres']['user'],
      password: secret.get("postgres:password:#{node[id]['postgres']['user']}")
    },
    admin: {
      disable_regular_org_creation: node[id]['conf']['admin']['disable_regular_org_creation']
    },
    security: {
      install_lock: true,
      secret_key: secret.get('gogs:security:secret_key')
    },
    service: {
      register_email_confirm: node[id]['conf']['service']['register_email_confirm'],
      disable_registration: node[id]['conf']['service']['disable_registration'],
      require_signin_view: node[id]['conf']['service']['require_signin_view'],
      enable_notify_mail: node[id]['conf']['service']['enable_notify_mail']
    },
    mailer: {
      enabled: mailer_enabled,
      host: secret.get('gogs:mailer:host', required: mailer_enabled),
      port: secret.get('gogs:mailer:port', required: mailer_enabled),
      user: secret.get('gogs:mailer:user', required: mailer_enabled),
      password: secret.get('gogs:mailer:password', required: mailer_enabled),
      from: node[id]['mailer']['from']
    },
    cache: {
      adapter: 'redis',
      host: "network=tcp,addr=#{node[id]['redis']['host']}:"\
            "#{node[id]['redis']['port']},db="\
            "#{node[id]['cache']['redis_db']},"\
            'pool_size=100,idle_timeout=180'
    },
    session: {
      provider: 'redis',
      provider_config: 'network=tcp,addr='\
                       "#{node[id]['redis']['host']}:"\
                       "#{node[id]['redis']['port']},db="\
                       "#{node[id]['session']['redis_db']},"\
                       'pool_size=100,idle_timeout=180'
    },
    picture: {
      avatar_upload_path: avatar_dir
    },
    attachment: {
      path: attachment_dir
    },
    log: {
      root_path: log_dir
    },
    git: {
      max_diff_lines: node[id]['conf']['git']['max_diff_lines'],
      max_diff_line_characters: node[id]['conf']['git']['max_diff_line_characters'],
      max_diff_files: node[id]['conf']['git']['max_diff_files']
    }
  )
  mode 0644
  notifies :restart, 'supervisor_service[gogs]', :delayed
  action :create
end

supervisor_service 'gogs' do
  command "#{::File.join(gogs_work_dir, 'gogs')} web"
  process_name '%(program_name)s'
  numprocs 1
  numprocs_start 0
  priority 300
  autostart true
  autorestart true
  startsecs 10
  startretries 3
  exitcodes [0, 2]
  stopsignal :TERM
  stopwaitsecs 10
  stopasgroup nil
  killasgroup nil
  user node[id]['user']
  redirect_stderr false
  stdout_logfile ::File.join(log_dir, 'app-stdout.log')
  stdout_logfile_maxbytes '10MB'
  stdout_logfile_backups 10
  stdout_capture_maxbytes '0'
  stdout_events_enabled false
  stderr_logfile ::File.join(log_dir, 'app-stderr.log')
  stderr_logfile_maxbytes '10MB'
  stderr_logfile_backups 10
  stderr_capture_maxbytes '0'
  stderr_events_enabled false
  environment(
    'HOME' => user_home,
    'USER' => node[id]['user']
  )
  directory gogs_work_dir
  serverurl 'AUTO'
  action :enable
end

ngx_vhost_variables = {
  fqdn: fqdn,
  access_log: ::File.join(node['nginx']['log_dir'], 'gogs_access.log'),
  error_log: ::File.join(node['nginx']['log_dir'], 'gogs_error.log'),
  gogs_host: '127.0.0.1',
  gogs_port: 3000,
  ssl: node[id]['web']['ssl'],
}

if node[id]['web']['ssl']
  tls_rsa_certificate fqdn do
    action :deploy
  end

  tls_rsa_item = ::ChefCookbook::TLS.new(node).rsa_certificate_entry(fqdn)

  ngx_vhost_variables.merge!({
    ssl_rsa_certificate: tls_rsa_item.certificate_path,
    ssl_rsa_certificate_key: tls_rsa_item.certificate_private_key_path,
    hsts_max_age: node[id]['web']['hsts_max_age'],
    oscp_stapling: node.chef_environment.start_with?('production'),
    scts: node.chef_environment.start_with?('production'),
    scts_rsa_dir: tls_rsa_item.scts_dir,
    hpkp: node.chef_environment.start_with?('production'),
    hpkp_pins: tls_rsa_item.hpkp_pins,
    hpkp_max_age: node[id]['web']['hpkp_max_age'],
    use_ec_certificate: node[id]['web']['use_ec_certificate']
  })

  if node[id]['web']['use_ec_certificate']
    tls_ec_certificate fqdn do
      action :deploy
    end

    tls_ec_item = ::ChefCookbook::TLS.new(node).ec_certificate_entry(fqdn)

    ngx_vhost_variables.merge!({
      ssl_ec_certificate: tls_ec_item.certificate_path,
      ssl_ec_certificate_key: tls_ec_item.certificate_private_key_path,
      scts_ec_dir: tls_ec_item.scts_dir,
      hpkp_pins: (ngx_vhost_variables[:hpkp_pins] + tls_ec_item.hpkp_pins).uniq,
    })
  end
end

nginx_site 'gogs' do
  template 'nginx.conf.erb'
  variables ngx_vhost_variables
  action :enable
end

backup_script = ::File.join(node[id]['script_dir'], 'gogs-backup')

template backup_script do
  source 'backup.sh.erb'
  owner 'root'
  group node['root_group']
  mode 0755
  variables(
    user: node[id]['user'],
    user_home: user_home,
    gogs_work_dir: gogs_work_dir
  )
end

create_admin_script = ::File.join(node[id]['script_dir'], 'gogs-create-admin')

template create_admin_script do
  source 'create-admin.sh.erb'
  owner 'root'
  group node['root_group']
  mode 0755
  variables(
    user: node[id]['user'],
    gogs_work_dir: gogs_work_dir
  )
end

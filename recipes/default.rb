id = 'gogs'

include_recipe "#{id}::prerequisite_go"
include_recipe "#{id}::prerequisite_redis"
include_recipe "#{id}::prerequisite_postgres"
include_recipe "#{id}::prerequisite_supervisor"
include_recipe "#{id}::prerequisite_nginx"

golang_package node[id][:gogs][:package] do
  action :install
end

postgresql_database node[id][:postgres][:dbname] do
  Chef::Resource::PostgresqlDatabase.send :include, Gogs::Helper
  connection postgres_connection_info
  action :create
end

postgresql_database_user node[id][:postgres][:username] do
  Chef::Resource::PostgresqlDatabaseUser.send :include, Gogs::Helper
  connection postgres_connection_info
  database_name node[id][:postgres][:dbname]
  password data_bag_item('postgres', node.chef_environment)['credentials'][node[id][:postgres][:username]]
  privileges [:all]
  action [:create, :grant]
end

group 'Create group for Gogs service' do
  group_name node[id][:gogs][:group]
  system true
  action :create
end

user_home = ::File.join '/home', node[id][:gogs][:user]

user 'Create user for Gogs service' do
  username node[id][:gogs][:user]
  group node[id][:gogs][:group]
  shell '/bin/bash'
  system true
  manage_home true
  home user_home
  comment 'Gogs'
  action :create
end

log_dir = node[id][:gogs][:log_dir]

directory 'Create log directory for Gogs service' do
  path log_dir
  owner node[id][:gogs][:user]
  group node[id][:gogs][:group]
  mode 0755
  recursive true
  action :create
end

gogs_work_dir = ::File.join node['go']['gopath'], 'src', node[id][:gogs][:package]
custom_conf_path = ::File.join gogs_work_dir, 'custom', 'conf'

directory 'Create configuration directory for Gogs service' do
  path custom_conf_path
  owner node[id][:gogs][:user]
  group node[id][:gogs][:group]
  mode 0755
  recursive true
  action :create
end

repository_root = ::File.join user_home, 'repositories'

directory 'Create repository directory for Gogs service' do
  path repository_root
  owner node[id][:gogs][:user]
  group node[id][:gogs][:group]
  mode 0755
  recursive true
  action :create
end

ssh_root = ::File.join user_home, '.ssh'

directory 'Create SSH directory for Gogs service' do
  path ssh_root
  owner node[id][:gogs][:user]
  group node[id][:gogs][:group]
  mode 0700
  recursive true
  action :create
end

data_dir = ::File.join user_home, 'data'

directory 'Create data directory for Gogs service' do
  path data_dir
  owner node[id][:gogs][:user]
  group node[id][:gogs][:group]
  mode 0755
  recursive true
  action :create
end

avatar_dir = ::File.join data_dir, 'avatars'

directory 'Create avatar directory for Gogs service' do
  path avatar_dir
  owner node[id][:gogs][:user]
  group node[id][:gogs][:group]
  mode 0755
  recursive true
  action :create
end

attachment_dir = ::File.join data_dir, 'attachments'

directory 'Create attachment directory for Gogs service' do
  path attachment_dir
  owner node[id][:gogs][:user]
  group node[id][:gogs][:group]
  mode 0755
  recursive true
  action :create
end

app_ini_path = ::File.join custom_conf_path, 'app.ini'
run_mode = node.chef_environment.start_with?('development') ? 'dev' : 'prod'

fqdn = node[id][:gogs][:conf][:server][:domain]

template 'Create custom configuration file for Gogs service' do
  path app_ini_path
  source 'app.ini.erb'
  owner node[id][:gogs][:user]
  group node[id][:gogs][:group]
  variables(
    app_name: node[id][:gogs][:conf][:app_name],
    run_user: node[id][:gogs][:user],
    run_mode: run_mode,
    repository: {
      root: repository_root,
      force_private: node[id][:gogs][:conf][:repository][:force_private]
    },
    server: {
      protocol: node[id][:gogs][:conf][:server][:protocol],
      domain: fqdn,
      root_url: node[id][:gogs][:conf][:server][:root_url],
      http_addr: node[id][:gogs][:conf][:server][:http_addr],
      http_port: node[id][:gogs][:conf][:server][:http_port],
      ssh_root_path: ssh_root,
      minimum_key_size_check: node[id][:gogs][:conf][:server][:minimum_key_size_check],
      app_data_path: data_dir
    },
    database: {
      db_type: 'postgres',
      host: node[id][:postgres][:listen][:address],
      port: node[id][:postgres][:listen][:port],
      dbname: node[id][:postgres][:dbname],
      username: node[id][:postgres][:username],
      password: data_bag_item('postgres', node.chef_environment)['credentials'][node[id][:postgres][:username]]
    },
    security: {
      secret_key: data_bag_item('gogs', node.chef_environment)['security']['secret_key']
    },
    service: {
      register_email_confirm: node[id][:gogs][:conf][:service][:register_email_confirm],
      disable_registration: node[id][:gogs][:conf][:service][:disable_registration],
      require_signin_view: node[id][:gogs][:conf][:service][:require_signin_view],
      enable_notify_mail: node[id][:gogs][:conf][:service][:enable_notify_mail],
    },
    mailer: {
      enabled: node[id][:gogs][:conf][:mailer][:enabled],
      host: data_bag_item('gogs', node.chef_environment)['mailer']['host'],
      port: data_bag_item('gogs', node.chef_environment)['mailer']['port'],
      username: data_bag_item('gogs', node.chef_environment)['mailer']['username'],
      password: data_bag_item('gogs', node.chef_environment)['mailer']['password'],
      subject: node[id][:gogs][:conf][:mailer][:subject],
      from: node[id][:gogs][:conf][:mailer][:from]
    },
    cache: {
      adapter: 'redis',
      host: "network=tcp,addr=#{node[id][:redis][:listen][:address]}:#{node[id][:redis][:listen][:port]},db=#{node[id][:gogs][:conf][:cache][:redis_db]},pool_size=100,idle_timeout=180"
    },
    session: {
      provider: 'redis',
      provider_config: "network=tcp,addr=#{node[id][:redis][:listen][:address]}:#{node[id][:redis][:listen][:port]},db=#{node[id][:gogs][:conf][:cache][:redis_db]},pool_size=100,idle_timeout=180"
    },
    picture: {
      avatar_upload_path: avatar_dir
    },
    attachment: {
      path: attachment_dir
    },
    log: {
      root_path: log_dir
    }
  )
  mode 0644
  notifies :restart, 'supervisor_service[gogs]', :delayed
  action :create
end

gogs_exec = ::File.join node['go']['gobin'], 'gogs'

supervisor_service 'gogs' do
  command "#{gogs_exec} web"
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
  user node[id][:gogs][:user]
  redirect_stderr false
  stdout_logfile ::File.join log_dir, 'app-stdout.log'
  stdout_logfile_maxbytes '10MB'
  stdout_logfile_backups 10
  stdout_capture_maxbytes '0'
  stdout_events_enabled false
  stderr_logfile ::File.join log_dir, 'app-stderr.log'
  stderr_logfile_maxbytes '10MB'
  stderr_logfile_backups 10
  stderr_capture_maxbytes '0'
  stderr_events_enabled false
  environment(
    'HOME' => user_home,
    'USER' => node[id][:gogs][:user],
    'GOGS_WORK_DIR' => gogs_work_dir
  )
  directory user_home
  serverurl 'AUTO'
  action :enable
end

nginx_log_dir = ::File.join log_dir, 'nginx'

directory 'Create log directory for Nginx service' do
  path nginx_log_dir
  owner node['nginx']['user']
  group node['nginx']['group']
  mode 0755
  recursive true
  action :create
end

template 'Nginx configuration for Gogs service' do
  ::Chef::Resource::Template.send :include, ::ModernNginx::Helper
  path ::File.join node[:nginx][:dir], 'sites-available', 'gogs.conf'
  source 'nginx.conf.erb'
  mode 0644
  variables(
    server_name: fqdn,
    backend_host: node[id][:gogs][:conf][:server][:http_addr],
    backend_port: node[id][:gogs][:conf][:server][:http_port],
    access_log: ::File.join(nginx_log_dir, 'access.log'),
    error_log: ::File.join(nginx_log_dir, 'error.log'),
    ssl_certificate: get_ssl_certificate_path(fqdn),
    ssl_certificate_key: get_ssl_certificate_private_key_path(fqdn),
    oscp_stapling: node.chef_environment.start_with?('production'),
    hsts_max_age: node[id][:gogs][:frontend][:hsts_max_age],
    scts: node.chef_environment.start_with?('production'),
    scts_directory: get_scts_directory(fqdn),
    hpkp: node.chef_environment.start_with?('production'),
    hpkp_pins: get_hpkp_pins(fqdn),
    hpkp_max_age: node[id][:gogs][:frontend][:hpkp_max_age],
    acme_challenge: node.chef_environment.start_with?('production'),
    acme_challenge_directory: get_acme_challenge_directory(fqdn)
  )
  notifies :reload, 'service[nginx]', :immediately
end

nginx_site 'gogs.conf' do
  enabled true
end

create_admin_script_path = ::File.join ::Chef::Config[:file_cache_path], 'gogs_create_admin.go'

cookbook_file create_admin_script_path do
  source 'create_admin.go'
  owner node[id][:gogs][:user]
  group node[id][:gogs][:group]
  mode 0644
  action :create
end

execute 'Create admin for Gogs service' do
  command "#{node['go']['install_dir']}/go/bin/go run #{create_admin_script_path}"
  cwd user_home
  user node[id][:gogs][:user]
  group node[id][:gogs][:group]
  environment(
    'GOPATH' => node['go']['gopath'],
    'GOBIN' => node['go']['gobin'],
    'HOME' => user_home,
    'USER' => node[id][:gogs][:user],
    'GOGS_WORK_DIR' => gogs_work_dir,
    'GOGS_CONFIG' => app_ini_path,
    'ADMIN_USER_CREATE' => 'true',
    'ADMIN_USER_NAME' => data_bag_item('gogs', node.chef_environment)['admin']['username'],
    'ADMIN_USER_EMAIL' => data_bag_item('gogs', node.chef_environment)['admin']['email'],
    'ADMIN_USER_PASSWORD' => data_bag_item('gogs', node.chef_environment)['admin']['password']
  )
end

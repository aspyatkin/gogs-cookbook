resource_name :gogs_app

property :name, String, name_property: true

property :version, String, default: '0.12.3'
property :checksum, String, default: '13eefa0a0d6fd7ed0c65b52182b6b6c318d4df71c962c744726a6d56367490ec'
property :url, String, default: 'https://dl.gogs.io/%{version}/gogs_%{version}_linux_amd64.tar.gz'

property :service_user, String, default: 'git'
property :service_group, String, default: 'git'
property :service_log_dir, String, default: '/var/log/gogs'
property :service_script_dir, String, default: '/usr/local/bin'

property :service_host, String, default: '127.0.0.1'
property :service_port, Integer, default: 3000

property :secure, [TrueClass, FalseClass], default: false
property :hsts_max_age, Integer, default: 15_724_800
property :oscp_stapling, [TrueClass, FalseClass], default: true
property :resolvers, Array, default: %w(8.8.8.8 1.1.1.1 8.8.4.4 1.0.0.1)
property :resolver_valid, Integer, default: 600
property :resolver_timeout, Integer, default: 10
property :access_log_options, String, default: 'combined'
property :error_log_options, String, default: 'error'
property :additional_access_log, [String, NilClass], default: nil

property :conf, Hash, default: {}

property :postgres_host, String, required: true
property :postgres_port, Integer, required: true
property :postgres_database, String, required: true
property :postgres_user, String, required: true
property :postgres_password, String, required: true

property :redis_host, String, required: true
property :redis_port, Integer, required: true
property :redis_db, Integer, default: 1

property :brand_name, String, default: 'Git'

property :vlt_provider, Proc, default: lambda { nil }
property :vlt_format, Integer, default: 1

property :nginx_client_max_body_size, String, default: '250m'

default_action :install

action :install do
  group new_resource.service_group do
    system true
    action :create
  end

  service_user_home = ::File.join('/home', new_resource.service_user)

  user new_resource.service_user do
    group new_resource.service_group
    shell '/bin/bash'
    system true
    manage_home true
    home service_user_home
    comment 'Gogs'
    action :create
  end

  ark 'gogs' do
    url new_resource.url % {version: new_resource.version}
    version new_resource.version
    checksum new_resource.checksum
    action :install
  end

  directory new_resource.service_log_dir do
    owner new_resource.service_user
    group new_resource.service_group
    mode 0755
    recursive true
    action :create
  end

  gogs_work_dir = ::File.join(node['ark']['prefix_home'], 'gogs')

  custom_conf_path = ::File.join(gogs_work_dir, 'custom', 'conf')

  directory custom_conf_path do
    owner new_resource.service_user
    group new_resource.service_group
    mode 0755
    recursive true
    action :create
  end

  repository_root = ::File.join(service_user_home, 'repositories')

  directory repository_root do
    owner new_resource.service_user
    group new_resource.service_group
    mode 0755
    recursive true
    action :create
  end

  ssh_root = ::File.join(service_user_home, '.ssh')

  directory ssh_root do
    owner new_resource.service_user
    group new_resource.service_group
    mode 0700
    recursive true
    action :create
  end

  data_dir = ::File.join(service_user_home, 'data')

  directory data_dir do
    owner new_resource.service_user
    group new_resource.service_group
    mode 0755
    recursive true
    action :create
  end

  avatar_dir = ::File.join(data_dir, 'avatars')

  directory avatar_dir do
    owner new_resource.service_user
    group new_resource.service_group
    mode 0755
    recursive true
    action :create
  end

  lfs_objects_dir = ::File.join(data_dir, 'lfs-objects')

  directory lfs_objects_dir do
    owner new_resource.service_user
    group new_resource.service_group
    mode 0755
    recursive true
    action :create
  end

  attachment_dir = ::File.join(data_dir, 'attachments')

  directory attachment_dir do
    owner new_resource.service_user
    group new_resource.service_group
    mode 0755
    recursive true
    action :create
  end

  gogs_secret_file = ::File.join(service_user_home, '.gogs_secret')

  require 'securerandom'

  file gogs_secret_file do
    content ::SecureRandom.hex(32)
    sensitive true
    owner new_resource.service_user
    group new_resource.service_group
    mode 0400
    action :create_if_missing
  end

  app_ini_path = ::File.join(custom_conf_path, 'app.ini')

  server_conf = new_resource.conf.fetch('server', {})
  gogs_fqdn = server_conf['domain']

  repository_conf = new_resource.conf.fetch('repository', {})
  admin_conf = new_resource.conf.fetch('admin', {})
  auth_conf = new_resource.conf.fetch('auth', {})
  email_conf = new_resource.conf.fetch('email', {})
  cron_conf = new_resource.conf.fetch('cron', {})
  git_conf = new_resource.conf.fetch('git', {})

  template app_ini_path do
    cookbook 'gogs'
    source 'app.ini.erb'
    owner new_resource.service_user
    group new_resource.service_group
    variables(lazy {
      {
        'run_user' => new_resource.service_user,
        'run_mode' => node.chef_environment.start_with?('development') ? 'dev' : 'prod',
        'brand_name' => new_resource.brand_name,
        'https' => new_resource.secure,
        'server' => {
          'http_addr' => new_resource.service_host,
          'http_port' => new_resource.service_port,
          'domain' => gogs_fqdn,
          'ssh_root_path' => ssh_root,
          'minimum_key_size_check' => server_conf.fetch('minimum_key_size_check', true),
          'app_data_path' => data_dir
        },
        'repository' => {
          'root' => repository_root,
          'force_private' => repository_conf.fetch('force_private', true)
        },
        'database' => {
          'type' => 'postgres',
          'host' => new_resource.postgres_host,
          'port' => new_resource.postgres_port,
          'name' => new_resource.postgres_database,
          'user' => new_resource.postgres_user,
          'password' => new_resource.postgres_password
        },
        'admin' => {
          'disable_regular_org_creation' => admin_conf.fetch('disable_regular_org_creation', true)
        },
        'security' => {
          'install_lock' => true,
          'secret_key' => ::File.read(gogs_secret_file)
        },
        'auth' => {
          'require_email_confirmation' => auth_conf.fetch('require_email_confirmation', true),
          'disable_registration' => auth_conf.fetch('disable_registration', true),
          'require_signin_view' => auth_conf.fetch('require_signin_view', true),
          'enable_email_notification' => auth_conf.fetch('enable_email_notification', true)
        },
        'email' => {
          'enabled' => email_conf.fetch('enabled', false),
          'host' => email_conf.fetch('host', nil),
          'port' => email_conf.fetch('port', nil),
          'user' => email_conf.fetch('user', nil),
          'password' => email_conf.fetch('password', nil),
          'from' => email_conf.fetch('from', nil)
        },
        'cache' => {
          'adapter' => 'redis',
          'host' => "network=tcp,addr=#{new_resource.redis_host}:"\
                    "#{new_resource.redis_port},db="\
                    "#{new_resource.redis_db},"\
                    'pool_size=100,idle_timeout=180'
        },
        'session' => {
          'provider' => 'redis',
          'provider_config' => 'network=tcp,addr='\
                               "#{new_resource.redis_host}:"\
                               "#{new_resource.redis_port},db="\
                               "#{new_resource.redis_db},"\
                               'pool_size=100,idle_timeout=180'
        },
        'picture' => {
          'avatar_upload_path' => avatar_dir
        },
        'lfs' => {
          'objects_path' => lfs_objects_dir
        },
        'attachment' => {
          'path' => attachment_dir
        },
        'log' => {
          'root_path' => new_resource.service_log_dir
        },
        'cron' => {
          'repo_health_check' => {
            'timeout' => cron_conf.fetch('repo_health_check', {}).fetch('timeout', '60s')
          }
        },
        'git' => {
          'max_diff_lines' => git_conf.fetch('max_diff_lines', 1000),
          'max_diff_line_characters' => git_conf.fetch('max_diff_line_characters', 500),
          'max_diff_files' => git_conf.fetch('max_diff_files', 100)
        }
      }
    })
    mode 0644
    sensitive true
    notifies :restart, 'service[gogs]', :delayed
    action :create
  end

  systemd_unit 'gogs.service' do
    content({
      Unit: {
        Description: 'Gogs',
        After: [
          'syslog.target',
          'network.target',
          'postgresql.service',
          "redis@#{new_resource.redis_port}.service"
        ],
      },
      Service: {
        Type: 'simple',
        User: new_resource.service_user,
        Group: new_resource.service_group,
        WorkingDirectory: gogs_work_dir,
        ExecStart: "#{::File.join(gogs_work_dir, 'gogs')} web",
        Restart: 'always',
        Environment: "USER=#{new_resource.service_user} HOME=#{service_user_home}",
        ProtectSystem: 'full',
        PrivateDevices: 'yes',
        PrivateTmp: 'yes',
        NoNewPrivileges: 'true'
      },
      Install: {
        WantedBy: 'multi-user.target'
      }
    })
    verify true
    action [:create]
  end

  service 'gogs' do
    action [:enable, :start]
  end

  ngx_vhost_variables = {
    fqdn: gogs_fqdn,
    additional_access_log: new_resource.additional_access_log,
    access_log_options: new_resource.access_log_options,
    error_log_options: new_resource.error_log_options,
    upstream_host: new_resource.service_host,
    upstream_port: new_resource.service_port,
    secure: new_resource.secure,
    client_max_body_size: new_resource.nginx_client_max_body_size
  }

  if new_resource.secure
    tls_rsa_certificate gogs_fqdn do
      vlt_provider new_resource.vlt_provider
      vlt_format new_resource.vlt_format
      action :deploy
    end

    tls = ::ChefCookbook::TLS.new(node, vlt_provider: new_resource.vlt_provider, vlt_format: new_resource.vlt_format)

    if tls.has_ec_certificate?(gogs_fqdn)
      tls_ec_certificate gogs_fqdn do
        vlt_provider new_resource.vlt_provider
        vlt_format new_resource.vlt_format
        action :deploy
      end
    end

    ngx_vhost_variables.merge!({
      certificate_entries: [
        tls.rsa_certificate_entry(gogs_fqdn)
      ],
      hsts_max_age: new_resource.hsts_max_age,
      oscp_stapling: new_resource.oscp_stapling,
      resolvers: new_resource.resolvers,
      resolver_valid: new_resource.resolver_valid,
      resolver_timeout: new_resource.resolver_timeout
    })

    if tls.has_ec_certificate?(gogs_fqdn)
      ngx_vhost_variables[:certificate_entries] << tls.ec_certificate_entry(gogs_fqdn)
    end
  end

  nginx_vhost 'gogs' do
    cookbook 'gogs'
    template 'nginx.conf.erb'
    variables(lazy {
      ngx_vhost_variables.merge(
        access_log: ::File.join(
          node.run_state['nginx']['log_dir'],
          'gogs_access.log'
        ),
        error_log: ::File.join(
          node.run_state['nginx']['log_dir'],
          'gogs_error.log'
        )
      )
    })
    action :enable
  end

  node.run_state['gogs'] = {}

  node.run_state['gogs']['create_admin_script'] = ::File.join(new_resource.service_script_dir, 'gogs-create-admin')
  template node.run_state['gogs']['create_admin_script'] do
    cookbook 'gogs'
    source 'create-admin.sh.erb'
    owner 'root'
    group node['root_group']
    mode 0755
    variables(
      user: new_resource.service_user,
      gogs_work_dir: gogs_work_dir
    )
  end

  node.run_state['gogs']['backup_script'] = ::File.join(new_resource.service_script_dir, 'gogs-backup')
  template node.run_state['gogs']['backup_script'] do
    cookbook 'gogs'
    source 'backup.sh.erb'
    owner 'root'
    group node['root_group']
    mode 0755
    variables(
      user: new_resource.service_user,
      user_home: service_user_home,
      gogs_work_dir: gogs_work_dir,
      lfs_dir_base: ::File.dirname(lfs_objects_dir),
      lfs_dir_name: ::File.basename(lfs_objects_dir)
    )
  end
end

resource_name :gogs_app

property :name, String, name_property: true

property :version, String, default: '0.11.66'
property :checksum, String, default: 'af01103fa4da64811f9139cce221c2d88063cb5d41283df79278a829737dece2'
property :url, [String, nil], default: nil

property :service_user, String, default: 'git'
property :service_group, String, default: 'git'
property :service_log_dir, String, default: '/var/log/gogs'
property :service_script_dir, String, default: '/usr/local/bin'

property :https, [TrueClass, FalseClass], default: false
property :ec_certificates, [TrueClass, FalseClass], default: false
property :hsts_max_age, Integer, default: 15_724_800
property :hpkp_max_age, Integer, default: 604_800

property :conf, Hash, default: {}

property :postgres_host, String, required: true
property :postgres_port, Integer, required: true
property :postgres_database, String, required: true
property :postgres_user, String, required: true
property :postgres_password, String, required: true

property :redis_host, String, required: true
property :redis_port, Integer, required: true
property :redis_db, Integer, default: 0

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

  download_url = new_resource.url
  if download_url.nil?
    download_url = "https://dl.gogs.io/#{new_resource.version}/gogs_#{new_resource.version}_linux_amd64.tar.gz"
  end

  ark 'gogs' do
    url download_url
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

  instance = ::ChefCookbook::Instance::Helper.new(node)

  app_ini_path = ::File.join(custom_conf_path, 'app.ini')

  server_conf = new_resource.conf.fetch(:server, {})
  gogs_fqdn = server_conf.fetch(:domain, instance.fqdn)

  repository_conf = new_resource.conf.fetch(:repository, {})
  admin_conf = new_resource.conf.fetch(:admin, {})
  service_conf = new_resource.conf.fetch(:service, {})
  mailer_conf = new_resource.conf.fetch(:mailer, {})
  git_conf = new_resource.conf.fetch(:git, {})

  gogs_host = '127.0.0.1'
  gogs_port = 3001

  template app_ini_path do
    cookbook 'gogs'
    source 'app.ini.erb'
    owner new_resource.service_user
    group new_resource.service_group
    variables(lazy {
      {
        run_user: new_resource.service_user,
        run_mode: node.chef_environment.start_with?('development') ? 'dev' : 'prod',
        https: new_resource.https,
        server: {
          http_addr: gogs_host,
          http_port: gogs_port,
          domain: gogs_fqdn,
          ssh_root_path: ssh_root,
          minimum_key_size_check: server_conf.fetch(:minimum_key_size_check, true),
          app_data_path: data_dir
        },
        repository: {
          root: repository_root,
          force_private: repository_conf.fetch(:force_private, true)
        },
        database: {
          db_type: 'postgres',
          host: new_resource.postgres_host,
          port: new_resource.postgres_port,
          name: new_resource.postgres_database,
          user: new_resource.postgres_user,
          passwd: new_resource.postgres_password
        },
        admin: {
          disable_regular_org_creation: admin_conf.fetch(:disable_regular_org_creation, true)
        },
        security: {
          install_lock: true,
          secret_key: ::File.read(gogs_secret_file)
        },
        service: {
          register_email_confirm: service_conf.fetch(:register_email_confirm, true),
          disable_registration: service_conf.fetch(:disable_registration, true),
          require_signin_view: service_conf.fetch(:require_signin_view, true),
          enable_notify_mail: service_conf.fetch(:enable_notify_mail, true)
        },
        mailer: {
          enabled: mailer_conf.fetch(:enabled, false),
          host: mailer_conf.fetch(:host, nil),
          port: mailer_conf.fetch(:port, nil),
          user: mailer_conf.fetch(:user, nil),
          passwd: mailer_conf.fetch(:passwd, nil),
          from: mailer_conf.fetch(:from, nil)
        },
        cache: {
          adapter: 'redis',
          host: "network=tcp,addr=#{new_resource.redis_host}:"\
                "#{new_resource.redis_port},db="\
                "#{new_resource.redis_db},"\
                'pool_size=100,idle_timeout=180'
        },
        session: {
          provider: 'redis',
          provider_config: 'network=tcp,addr='\
                           "#{new_resource.redis_host}:"\
                           "#{new_resource.redis_port},db="\
                           "#{new_resource.redis_db},"\
                           'pool_size=100,idle_timeout=180'
        },
        picture: {
          avatar_upload_path: avatar_dir
        },
        attachment: {
          path: attachment_dir
        },
        log: {
          root_path: new_resource.service_log_dir
        },
        git: {
          max_diff_lines: git_conf.fetch(:max_diff_lines, 1000),
          max_diff_line_characters: git_conf.fetch(:max_diff_line_characters, 500),
          max_diff_files: git_conf.fetch(:max_diff_files, 100)
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
          'redis@6379.service'
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
    server_name: gogs_fqdn,
    access_log: ::File.join(node['nginx']['log_dir'], 'gogs_access.log'),
    error_log: ::File.join(node['nginx']['log_dir'], 'gogs_error.log'),
    gogs_host: gogs_host,
    gogs_port: gogs_port,
    https: new_resource.https,
  }

  if new_resource.https
    tls_rsa_certificate gogs_fqdn do
      action :deploy
    end

    tls_rsa_item = ::ChefCookbook::TLS.new(node).rsa_certificate_entry(gogs_fqdn)
    tls_ec_item = nil

    if new_resource.ec_certificates
      tls_ec_certificate gogs_fqdn do
        action :deploy
      end

      tls_ec_item = ::ChefCookbook::TLS.new(node).ec_certificate_entry(gogs_fqdn)
    end

    has_scts = tls_rsa_item.has_scts? && (tls_ec_item.nil? ? true : tls_ec_item.has_scts?)

    ngx_vhost_variables.merge!({
      rsa_certificate: tls_rsa_item.certificate_path,
      rsa_certificate_key: tls_rsa_item.certificate_private_key_path,
      hsts_max_age: new_resource.hsts_max_age,
      oscp_stapling: node.chef_environment.start_with?('production'),
      scts: has_scts,
      scts_rsa_dir: tls_rsa_item.scts_dir,
      hpkp: node.chef_environment.start_with?('production'),
      hpkp_pins: tls_rsa_item.hpkp_pins,
      hpkp_max_age: new_resource.hpkp_max_age
    })

    if new_resource.ec_certificates
      ngx_vhost_variables.merge!({
        ec_certificate: tls_ec_item.certificate_path,
        ec_certificate_key: tls_ec_item.certificate_private_key_path,
        scts_ec_dir: tls_ec_item.scts_dir,
        hpkp_pins: (ngx_vhost_variables[:hpkp_pins] + tls_ec_item.hpkp_pins).uniq,
      })
    end
  end

  nginx_site 'gogs' do
    cookbook 'gogs'
    template 'nginx.conf.erb'
    variables ngx_vhost_variables
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
      gogs_work_dir: gogs_work_dir
    )
  end
end

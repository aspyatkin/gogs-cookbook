# gogs-cookbook
Chef cookbook to install [Gogs](https://gogs.io) Git service.

## Usage

`gogs_app` resource should be used to install [Gogs](https://gogs.io) Git service.

```ruby
gogs_app 'default' do
  postgres_host '127.0.0.1'
  postgres_port 5432
  postgres_database 'gogs'
  postgres_user 'gogs'
  postgres_password 'TOPSECRET'
  redis_host '127.0.0.1'
  redis_port 6379
  https true
  conf(
    server: {
      domain: 'git.example'
    },
    mailer: {
      enabled: true,
      host: mx.example,
      port: 587,
      user: 'admin@git.example',
      passwd: 'TOPSECRET',
      from: 'Gogs <admin@git.example>'
    }
  )
  action :install
end
```

It is expected that PostgreSQL and Redis are already set up on the node before utilizing this resource. One may use the corresponding Supermarket cookbooks (e.g. [postgresql](https://supermarket.chef.io/cookbooks/postgresql) and [redisio](https://supermarket.chef.io/cookbooks/redisio)) so as to install and configure them.

## Tips

Scripts are created in a directory specified by `service_script_dir` property (`/usr/local/bin` by default). Scripts are meant to be run by a user that can `su` as a Gogs service user (`git` by default). Paths to scripts are exposed in `node.run_state['gogs']['create_admin_script']` and `node.run_state['gogs']['backup_script']`.

### Creating an admin user

Run a simple interactive program to create a Gogs admin user.

```sh
$ gogs-create-admin
Username: git-admin
Password:
Repeat password:
Email: git-admin@example.com

New user 'git-admin' has been successfully created!
```

### Backing up

Creates a zip archive containing Gogs backup data in a current directory.

```sh
$ gogs-backup
```

## License
MIT © [Alexander Pyatkin](https://github.com/aspyatkin)

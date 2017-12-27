# gogs-cookbook
Chef cookbook to install [Gogs](https://gogs.io) Git service.

## Tips

Scripts are created in a directory specified by `default['gogs']['script_dir']` attribute (`/usr/local/bin` by default). Scripts are meant to be run by a user that can `su` as a Gogs service user (`git` by default).

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

## Self-hosted git server with static stagit frontend

0. Set up a server, open ports {22,80,443,9418}, and configure {A,AAAA} DNS records.

1. Make sure the necessary software dependencies are in place.

```
gcc
make
libgit2
nginx
ufw (optional)
```

2. Install `stagit`.

```
    test $UID = 0 || exit # assert(`whoami` == non-root admin user)
    cd
    git clone git://git.codemadness.org/stagit && cd stagit
    make
    sudo make install
```

3. Set up a `git` user.

```
    sudo adduser git
    sudo chsh git -s $(which git-shell)
    sudo su git -s /bin/bash <<EOF
    cd
    mkdir .ssh && chmod 700 .ssh
    touch .ssh/authorized_keys && chmod 600 .ssh/authorized_keys
    EOF
```

4. Authenticate (write-authorized) client-side public keys with restricted access.

```
    sudo su -
    >> ~git/.ssh/authorized_keys <<EOF
    no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty ssh-rsa AAAAB3Nz...== first client
    no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty ssh-rsa AAAAB3Nz...== second client
    no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty ssh-rsa AAAAB3Nz...== third client
    EOF
```

5. Set up the git daemon (e.g. through `systemd`).

```
    >| /etc/systemd/system/git-daemon.service <<EOF
    [Unit]
    Description=Start Git Daemon

    [Service]
    ExecStart=/usr/bin/git daemon --reuseaddr --base-path=/srv/git/ /srv/git/

    Restart=always
    RestartSec=500ms

    StandardOutput=syslog
    StandardError=syslog
    SyslogIdentifier=git-daemon

    User=git
    Group=git

    [Install]
    WantedBy=multi-user.target
    EOF
    systemctl enable --now git-daemon
```

6. Create a data store for git repositories.

```
    mkdir -p /srv/git
    chown -R git:git /srv/git
```

7. Add our global post-receive hook for automated static page {,re}generation.

```
    su git -s /bin/bash <<EOF
    cd /srv/git
    >| post-receive <<EOF2
    # contents of this repo's post-receive
    EOF2
    chmod +x ./post-receive
    EOF
```

8. Allow the `git` user write access to public directory.

```
    mkdir -p /var/www/html
    usermod -a -G www-data git
    chown -R root:www-data /var/www/html
```

9. Generate LetsEncrypt SSL certificates.

```
    which ufw && ufw allow 80 && ufw allow 443 && ufw allow 9418 # if using ufw
    certbot --nginx # dependency: python3-certbot-nginx
    crontab -l | { cat; echo "0 0 1 * * certbot --nginx renew"; } | crontab -
```

10. Prepare the public directory for static page generation.

```
    su git -s /bin/bash <<EOF
    cd /var/www/html
    >| ./style.css <<EOF2
    # contents of this repo's style.css
    EOF2
    >| ./generate.sh <<EOF2
    # contents of this repo's generate.sh
    EOF2
    chmod +x ./generate.sh
    # add a custom ./logo.png
    # add a custom ./favicon.png
    EOF
```

11. Add convenience script for adding new {public,private} git repositories.

```
    exit # back to non-root admin user
    mkdir ~/bin
    echo 'export PATH="$HOME/bin:$PATH"' >> ~/.profile
    >| ~/bin/new-repo <<EOF
    # contents of this repo's new-repo
    EOF
    chmod +x ~/bin/new-repo
    sudo install ~/bin/new-repo /usr/local/bin/
```

12. Add new repositories remotely.

```
    # client-side
    ssh admin@git.mydomain.net new-repo <public|private> <name> <description>
```

13. Push changes to self-hosted server; static pages are henceforth regenerated automatically by virtue of our custom `post-receive` git hook.

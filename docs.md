## Requirements
- Debian/Ubuntu Host System (may work with other OSes but not guaranteed)
- Cron (present by default on Debian/Ubuntu)
- Portainer API Key of an Administrator user
- Portainer Hostname
- AWS S3 Bucket and Credentials with read/write access
- [jq](https://jqlang.github.io/jq/download/)

## Installation
Set the following entries in either root user or system cron table

### Root user Cron
As root on host system edit the crontab with the following command:

```bash
crontab -e
```

This will prompt you to choose an editor, you'll probably want to choose nano.

Add the following entries at the bottom:

```bash
PORTAINER_HOST=<YOUR PORTAINER HOST>
PORTAINER_BACKUP_PASSWORD=<ENCRYPTION PASSWORD HERE>
PORTAINER_API_TOKEN=<PORTAINER API TOKEN>

@daily /root/portainer/backup-portainer.sh
@daily /root/portainer/backup-traefik.sh
@daily /root/portainer/backup-wordpress.sh <stack name>
@daily /root/portainer/backup-wordpress.sh <other stack name>
```

### System Cron
@todo

## Recovering from Backups

This Backup/Recovery scheme is specifically designed around using Portainer CE and Traefik together
and assumes the deployment is from a Docker Compose file.

The backup files are stored in cloud storage like AWS S3.

The files are organized with a path scheme as follows:

`/backups/<yyyy-mm-dd>/<service>/`

### Portainer + Traefik

Download the portainer backup and the traefik backup from the cloud storage (ex: AWS S3).

You should end up with a `portainer.tar.gz.encrypted` and for Traefik an `acme.json`.

Deploy Portainer/Traefik using the Docker Compose file ensuring that the `acme.json` from the backup file is available on the file system and the relative path matches what is specified in the Docker Compose file. 

Follow Portainer docs on [Restoring from a local file](https://docs.portainer.io/admin/settings/general#restoring-from-a-local-file).

### WordPress

### Nextcloud

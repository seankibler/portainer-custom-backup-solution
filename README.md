## Requirements
- Debian/Ubuntu Host System (may work with other OSes but not guaranteed)
- Cron (present by default on Debian/Ubuntu)
- Portainer API Key of an Administrator user
- Portainer Hostname
- AWS S3-compatible cloud storage bucket (ex: Digital Ocean Spaces) and Credentials with read/write access
- [jq](https://jqlang.github.io/jq/download/) 
- curl

## Installation
Simply run `./install.sh` or manually place all shell script files ending in `.sh` into path `/usr/local/bin/` on the host system (VPS) and ensure they are executable.

Install package dependencies

```bash
sudo apt-get update -y && sudo apt-get install -y jq curl
```

Set the following entries in either root user OR system cron table; DO NOT USE BOTH!

```bash
PORTAINER_API_TOKEN=api_token                           # Replace with your own value
PORTAINER_URL=https://portainer.mydomain.local          # Replace with your own value
PORTAINER_BACKUP_PASSWORD=somepassword                  # Replace with your own value
AWS_ACCESS_KEY_ID=access_key                            # Replace with your own value
AWS_SECRET_ACCESS_KEY=secret_access_key                 # Replace with your own value
S3_HOST=sfo2.digitaloceanspaces.com                     # Adjust according to your needs
S3_HOST_BUCKET="%(bucket)s.sfo2.digitaloceanspaces.com" # Adjust according to your needs

30 23 * * * /usr/local/bin/backup.sh s3://sos-backups
```

### Root User Cron ###
As root on host system edit the crontab with the following command:

```bash
crontab -e
```

This will prompt you to choose an editor, you'll probably want to choose nano.

### System Cron ###

Using the editor of your choice (nano recommended) install the above lines to `/etc/cron.d/backup`

Whichever method you choose, add the following entries at the bottom:

## Adding a New Site

If you deploy more WordPress/Nextcloud sites that you want to be included in the backup you will need to add them to the `/usr/local/bin/backup.sh` script.

Most importantly, the new entries MUST be added before the `backup-upload.sh` entry.

The names should match the Stack name in Portainer.

Here's an example below.

```bash
# System services
/usr/local/bin/backup-portainer.sh
/usr/local/bin/backup-traefik.sh

# WordPress Sites
/usr/local/bin/backup-wordpress.sh seahunny-wordpress-www
/usr/local/bin/backup-wordpress.sh averybros-wordpress-www
/usr/local/bin/backup-wordpress.sh sos-wordpress-www
/usr/local/bin/backup-wordpress.sh newsite-wordpress-www # ADDED NEW SITE HERE

# Nextcloud
/usr/local/bin/backup-nextcloud.sh nextcloud
/usr/local/bin/backup-nextcloud.sh averybros-nextcloud # ADDED NEW NEXTCLOUD SITE HERE

# Upload to cloud
/usr/local/bin/backup-upload.sh $BUCKET_PATH
```

## Recovering from Backups

This Backup/Recovery scheme is specifically designed around using Portainer CE and Traefik together
and assumes the deployment is from a Docker Compose file.

This scheme does NOT backup your Docker Compose file that deploys Portainer and Traefik but it does back up the Portainer and Traefik configuration. Therefore it is recommended that you should arrange to store your Docker Compose somewhere like GitHub.

The backup files are stored in AWS S3-compatible cloud storage like AWS S3 or Digital Ocean Spaces.

The files are organized with a path scheme as follows:

`/backups/<yyyy-mm-dd>/<service>/`

With this path scheme backups will be retained for one year before being overwritten.

If you rebuild your VPS as part of recovery be sure to re-install the backup scripts to continue backing up on the new host!

If you are attempting a total recovery in the event that the entire VPS was lost you will start by doing a fresh install of Portainer on your new VPS then restore Portainer using the Portainer backup file. See further instructions below. Then you will have your Portainer environment with all of your custom templates available. You'll need to deploy each site fresh from the custom template, then follow the instructions in [WordPress](/#WordPress) or [NextCloud](/#Nextcloud) section to restore each site from backup data.

### Portainer + Traefik

Download the portainer backup and the traefik backup from the cloud storage (ex: AWS S3).

You should end up with a `portainer.tar.gz.encrypted` and for Traefik an `acme.json` and a `traefik.toml`.

You'll need to upload the docker-compose.yml that you use to deploy Portainer + Traefik as well as the acme.json to the host (VPS).

You will keep the Portainer backup file on your computer that you'll use to access the Portainer web UI.

Deploy Portainer/Traefik using the Docker Compose file ensuring that the `acme.json` and `traefik.toml` from the backup file is copied to wherever you are running the docker compose file from. 

Follow Portainer docs on [Restoring from a local file](https://docs.portainer.io/admin/settings/general#restoring-from-a-local-file).

### WordPress
There are helper scripts to assist in recovery, manual steps are still documented below.

Use the retrieve.sh script to to download and store the backups for the stack to the local server. The example below is for the stack `mysite-wordpress-www` on the date 2024-10-02 to the server backup path `/data/backups/2024-10-02/mysite-wordpress-www`.

```bash
/usr/local/bin/retrieve.sh s3://sos-backups mysite-wordpress-www 2024-10-02 
```

Next use the restore-wordpress.sh script to apply the backup files and database to the live running containers for the named stack. The same values are used from above in the below example.

```bash
/usr/local/bin/restore-wordpress.sh mysite-wordpress-www 2024-10-02
```

#### Alternative Manual Restore Steps
**Files (plugins, templates, etc)**

Download the relevant WordPress data tar from backup storage and place it onto the cloud host running Portainer.

Lets assume the backup filename and path is `/data/backups/2024-09-25/mysite-wordpress-www/wordpress.tar.gz`

```bash
docker run --rm --volumes-from mysite-wordpress-www-blog-1 -v /data/backups/2024-09-25/mysite-wordpress-www:/backup debian:latest sh -c 'tar -xvzf /backup/wordpress.tar.gz'
```

**Database**

Download the relevant WordPress database dump from backup storage and place it onto the cloud host running Portainer.

Execute the following on the Portainer cloud host, lets assume the backup filename is `/data/backups/2024-10-02/wordpress.sql` and the database container is named `mysite-wordpress-www-mysql-1`

```bash
docker cp /data/backups/2024-10-02/wordpress.sql mysite-wordpress-www-mysql-1:/tmp/wordpress.sql
```

Then run

```bash
docker exec -it mysite-wordpress-www-mysql-1 sh -c 'mysql -u root --password < /tmp/wordpress.sql'
```

You'll be prompted for the root user mysql password, this can be found in the environment settings of the database container in Portainer as `MYSQL_ROOT_PASSWORD`.

Once entered correctly the command prompt should return with no output and the database should be restored.

At this point the relevant WordPress site should be working again.


### Nextcloud
The recovery process is very similar to the process for WordPress. The difference is that the database command line tool is mariadb not mysql.

**Files**
Lets assume the backup filename and path is `/data/backups/2024-09-25/nextcloud/nextcloud.tar.gz`

```bash
docker run --rm --volumes-from nextcloud-nextcloud-1 -v /data/backups/2024-09-25/nextcloud:/backup debian:latest sh -c 'tar -xvzf /backup/nextcloud.tar.gz'
```

**Database**

Download the relevant Nextcloud database dump from backup storage and place it onto the cloud host running Portainer.

Execute the following on the Portainer cloud host, lets assume the backup path and filename is `/data/backup/2024-09-25/nextcloud/nextcloud.sql` and the database container is named `nextcloud-nextcloud-mysql-1`

```bash
docker cp /data/backup/2024-09-25/nextcloud/nextcloud.sql nextcloud-nextcloud-mysql-1:/tmp/nextcloud.sql
docker exec -it nextcloud-nextcloud-mysql-1 sh -c 'mariadb -u root --password < /tmp/nextcloud.sql'
```

You'll be prompted for the root user mariadb password, this can be found in the environment settings of the database container in Portainer as `MYSQL_ROOT_PASSWORD`.

Once entered correctly the command prompt should return with no output and the database should be restored.

At this point the Nextcloud site should be working again.

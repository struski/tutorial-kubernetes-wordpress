#!/usr/bin/env bash

set -e # if errors then exit

>&2 echo "Initializing container ... "

if [ -z ${VOLUME_MOUNT_PATH+x} ]; then
    >&2 echo "wp-content/ parent path is unset";
else
    >&2 echo "wp-content/ parent path is set to '$VOLUME_MOUNT_PATH'"
fi
WP_CONTENT_PARENT=${VOLUME_MOUNT_PATH:-"/var/www/example.com"}

if [ ! -d "$WP_CONTENT_PARENT" ]; then
  >&2 echo "wp-content/ parent $WP_CONTENT_PARENT does not exist"
  exit 1;
fi

# Fix permissions and ownership if required
if [ -d "$WP_CONTENT_PARENT" ]; then
    # Change file permissions only if they require changing
    OWNER_NAME="$(stat -c '%U' $WP_CONTENT_PARENT)"
    GROUP_NAME="$(stat -c '%G' $WP_CONTENT_PARENT)"
    if [ "$OWNER_NAME" != "deployer" ] || [ "$GROUP_NAME" != "www-data" ]; then
        >&2 echo "Making deployer owner of $WP_CONTENT_PARENT. Giving full access to this directory to user and group"
        chown -R deployer:www-data $WP_CONTENT_PARENT/*
        chmod 770 $WP_CONTENT_PARENT
    fi
fi

# Create directory that will hold config files generated by Wordpress plugins
# eg. W3 Total Cache generates nginx configuration into a file. It would be
# preferable to hold this file on the volume that is persistent.
mkdir -p $WP_CONTENT_PARENT/conf

if [ -d "$WP_CONTENT_PARENT/wp-content" ]; then
    OWNER_NAME="$(stat -c '%U' $WP_CONTENT_PARENT/wp-content/)"
    GROUP_NAME="$(stat -c '%G' $WP_CONTENT_PARENT/wp-content/)"
    if [ "$OWNER_NAME" != "deployer" ] || [ "$GROUP_NAME" != "www-data" ]; then
        >&2 echo "Making deployer owner of wp-content/ and conf/. Giving write permissions on wp-content/ and conf/ to group www-data"
        chown -R deployer:www-data /var/www/html
        chown -R deployer:www-data $WP_CONTENT_PARENT/{conf,wp-content}
        chmod -R g+w $WP_CONTENT_PARENT/{conf,wp-content}
    fi
fi

#  UNCOMMENT WHEN TUTORIAL POINTS YOU TO THIS PLACE - Git authorization automation
#>&2 echo "Configuring SSH keys for git repository access"
#mkdir -p /home/deployer/.ssh/secret
#touch /home/deployer/.ssh/known_hosts
#ln -s /home/deployer/.ssh/secret/config /home/deployer/.ssh/config
#chown deployer:www-data /home/deployer/.ssh /home/deployer/.ssh/known_hosts
#chmod 700 /home/deployer/.ssh
#if [ -d "$WP_CONTENT_PARENT/.git" ]; then
#    # Change file permissions only if they require changing
#    OWNER_NAME="$(stat -c '%U' $WP_CONTENT_PARENT/.git/)"
#    GROUP_NAME="$(stat -c '%G' $WP_CONTENT_PARENT/.git/)"
#    if [ "$OWNER_NAME" != "deployer" ] || [ "$GROUP_NAME" != "www-data" ]; then
#        >&2 echo "Making deployer owner of .git/ and .gitignore. Giving exclusive access to git files to deployer"
#        chown -R deployer:www-data $WP_CONTENT_PARENT/.git*
#        chmod 700 $WP_CONTENT_PARENT/.git
#        chmod 600 $WP_CONTENT_PARENT/.gitignore
#    fi
#fi
#

# Nginx
ln -sf /dev/stdout /var/log/nginx/access.log
ln -sf /dev/stderr /var/log/nginx/error.log
ln -s /tmp /var/lib/nginx/body
mkdir -p /tmp/nginx-client-body /tmp/nginx-proxy /tmp/nginx-fastcgi /tmp/nginx-uwsgi /tmp/nginx-scgi
chown -R www-data:www-data /tmp/nginx*
chmod 777 /tmp/nginx*

#  UNCOMMENT IF W3 Total Cache plugin is installed and activated
#  W3 Total Cache plugin's generated config file is always included. Empty one is created here
#  IMPORTANT - When W3 Total Cache plugin is installed it should point nginx config file path to that touched file
#touch $WP_CONTENT_PARENT/conf/w3-total-cache.conf
#chown -R www-data:www-data $WP_CONTENT_PARENT/conf/w3-total-cache.conf

# Supervisor
mkdir -p /var/log/supervisor
#Execute Supervisor ($@ means all other arguments ie. command that has been passed in Dockerfile in CMD)
exec "$@"
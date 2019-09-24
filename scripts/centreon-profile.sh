#!/bin/sh

if [[ $EUID -eq 0 ]]; then
    CENTREON_RELEASE=$(rpm -qa | grep centreon-release | cut -d '-' -f3)
    CENTOS_RELEASE=$(cat /etc/centos-release)

    banner "Centreon ${CENTREON_RELEASE}"

echo -e "Based on $CENTOS_RELEASE

+-------------------------------------------------------------------+

Please execute following instruction:

1. Define timezone of your server:
# timedatectl set-timezone Europe/London

2. Define PHP timezone:
# echo "date.timezone = Europe/London" > /etc/opt/rh/rh-php72/php.d/php-timezone.ini
# systemctl restart rh-php72-php-fpm
# systemctl restart httpd24-httpd

3. Change hostname of your server:
# hostnamectl set-hostname centreon-central

4. Update Centreon partition database (mandatory):
# su - centreon
\$ /opt/rh/rh-php72/root/bin/php /usr/share/centreon/cron/centreon-partitioning.php

5. Restart Centreon Broker process (mandatory):
# systemctl restart cbd

You can disable the CEIP program using Centreon official documentation.

To delete this message, delete the /etc/profile.d/centreon.sh file".

    if [[ -d /srv/centreon ]]; then
        /opt/rh/rh-php72/root/bin/php /srv/centreon/generateUUID.php > /var/log/centreon/generateUUID.log 2>&1
        /opt/rh/rh-php72/root/bin/php /srv/centreon/generateAppKey.php > /var/log/centreon/generateAppKey.php 2>&1
        MINUTES=$(($RANDOM % 59 + 1 | bc))
        HOURS=$(($RANDOM % 23 + 1 | bc))
        sed -r -i "s|[0-9]+ [0-9]+ (.* /usr/share/centreon/cron/centreon-send-stats.php .*)|$MINUTES $HOURS \1|g" /etc/cron.d/centreon
        /usr/bin/rm /srv/centreon -Rf
        /usr/bin/systemctl restart centcore
        /usr/bin/systemctl restart centreontrapd
        /usr/bin/systemctl restart cbd
    fi
fi

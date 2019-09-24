#!/bin/sh

MYSQL_HOST="localhost"
MYSQL_PORT="3306"
MYSQL_USER="centreon"
MYSQL_PASSWD="c3ntr30n"
MYSQL_ROOT_PASSWORD="change123"
CENTREON_ADMIN_NAME="Administrator"
CENTREON_ADMIN_EMAIL="admin@admin.co"
CENTREON_ADMIN_PASSWD="change123"

InstallDbCentreon() {

    CENTREON_HOST="http://localhost"
    COOKIE_FILE="/tmp/install.cookie"
    CURL_CMD="curl -q -b ${COOKIE_FILE}"

    curl -q -c ${COOKIE_FILE} ${CENTREON_HOST}/centreon/install/install.php
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/step.php?action=stepContent"
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/step.php?action=nextStep"
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/step.php?action=nextStep"
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/process/process_step3.php" \
        --data "install_dir_engine=%2Fusr%2Fshare%2Fcentreon-engine&centreon_engine_stats_binary=%2Fusr%2Fsbin%2Fcentenginestats&monitoring_var_lib=%2Fvar%2Flib%2Fcentreon-engine&centreon_engine_connectors=%2Fusr%2Flib64%2Fcentreon-connector&centreon_engine_lib=%2Fusr%2Flib%2Fcentreon-engine&centreonplugins=%2Fusr%2Flib%2Fcentreon%2Fplugins%2F"
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/step.php?action=nextStep"
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/process/process_step4.php" \
        --data "centreonbroker_etc=%2Fetc%2Fcentreon-broker&centreonbroker_cbmod=%2Fusr%2Flib64%2Fnagios%2Fcbmod.so&centreonbroker_log=%2Fvar%2Flog%2Fcentreon-broker&centreonbroker_varlib=%2Fvar%2Flib%2Fcentreon-broker&centreonbroker_lib=%2Fusr%2Fshare%2Fcentreon%2Flib%2Fcentreon-broker"
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/step.php?action=nextStep"
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/process/process_step5.php" \
        --data "admin_password=${CENTREON_ADMIN_PASSWD}&confirm_password=${CENTREON_ADMIN_PASSWD}&firstname=${CENTREON_ADMIN_NAME}&lastname=${CENTREON_ADMIN_NAME}&email=${CENTREON_ADMIN_EMAIL}"
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/step.php?action=nextStep"
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/process/process_step6.php" \
        --data "address=${MYSQL_HOST}&port=${MYSQL_PORT}&root_password=${MYSQL_ROOT_PASSWORD}&db_configuration=centreon&db_storage=centreon_storage&db_user=${MYSQL_USER}&db_password=${MYSQL_PASSWD}&db_password_confirm=${MYSQL_PASSWD}"
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/step.php?action=nextStep"
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/process/configFileSetup.php" -X POST
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/process/installConfigurationDb.php" -X POST
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/process/installStorageDb.php" -X POST
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/process/createDbUser.php" -X POST
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/process/insertBaseConf.php" -X POST
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/process/partitionTables.php" -X POST
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/step.php?action=nextStep"
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/process/process_step8.php" \
        --data "modules%5B%5D=centreon-license-manager&modules%5B%5D=centreon-pp-manager&modules%5B%5D=centreon-autodiscovery-server"
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/step.php?action=nextStep"
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/process/process_step9.php" \
        --data "send_statistics=1"
}

installPlugins() {
    PLUGINS=(
        '{"slug": "base-generic", "version": "3.2.1", "action": "install"}'
        '{"slug": "applications-databases-mysql", "version": "3.1.3", "action": "install"}'
        '{"slug": "operatingsystems-linux-snmp", "version": "3.2.1", "action": "install"}'
        '{"slug": "applications-monitoring-centreon-database", "version":"3.3.0", "action": "install"}'
        '{"slug": "applications-monitoring-centreon-central", "version": "3.3.3", "action": "install"}'
    )

    CENTREON_HOST="http://localhost"
    CURL_CMD="curl -q -o /dev/null"
    API_TOKEN=$(curl -q -d "username=admin&password=${CENTREON_ADMIN_PASSWD}" \
        "${CENTREON_HOST}/centreon/api/index.php?action=authenticate" \
        | cut -f2 -d":" | sed -e "s/\"//g" -e "s/}//"
    )

    for PLUGIN in "${PLUGINS[@]}"; do
        ${CURL_CMD} -X POST \
            -H "Content-Type: application/json" \
            -H "centreon-auth-token: ${API_TOKEN}"\
            -d "{\"pluginpack\":[${PLUGIN}]}" \
            "${CENTREON_HOST}/centreon/api/index.php?object=centreon_pp_manager_pluginpack&action=installupdate"
        sleep 2
    done
}

installWidgets() {
    WIDGETS=(
        engine-status
        global-health
        graph-monitoring
        grid-map
        host-monitoring
        hostgroup-monitoring
        httploader
        live-top10-cpu-usage
        live-top10-memory-usage
        service-monitoring
        servicegroup-monitoring
        tactical-overview
    )

    CENTREON_HOST="http://localhost"
    CURL_CMD="curl -q -o /dev/null"
    API_TOKEN=$(curl -q -d "username=admin&password=${CENTREON_ADMIN_PASSWD}" \
        "${CENTREON_HOST}/centreon/api/index.php?action=authenticate" \
        | cut -f2 -d":" | sed -e "s/\"//g" -e "s/}//"
    )

    for WIDGET in "${WIDGETS[@]}"; do
        # Install package
        yum install -y centreon-widget-${WIDGET}
        # Configure widget in Centreon
        ${CURL_CMD} -X POST \
            -H "Content-Type: application/json" \
            -H "centreon-auth-token: ${API_TOKEN}"\
            "${CENTREON_HOST}/centreon/api/index.php?object=centreon_module&action=install&id=${WIDGET}&type=widget"
    done
}


yum install -y centos-release-scl wget curl yum-utils
yum install -y http://yum.centreon.com/standard/19.04/el7/stable/noarch/RPMS/centreon-release-19.04-1.el7.centos.noarch.rpm
yum install -y centreon

echo "date.timezone = Europe/Paris" > /etc/opt/rh/rh-php71/php.d/php-timezone.ini
systemctl daemon-reload
systemctl restart mysql
mysqladmin -u root password $MYSQL_ROOT_PASSWORD # Set password to root mysql
systemctl restart rh-php71-php-fpm
systemctl restart httpd24-httpd
sleep 5 # waiting start httpd process
InstallDbCentreon # Configure database
su - centreon -c "/opt/rh/rh-php71/root/bin/php /usr/share/centreon/cron/centreon-partitioning.php"
systemctl restart cbd

# Install Plugins
installPlugins

# Install widgets and configure
installWidgets

# Set firstboot script
mkdir -p /srv/centreon/scripts
mv /tmp/scripts/firstboot.sh /srv/centreon/scripts/
mv /tmp/scripts/generateAppKey.php /srv/centreon/scripts/
mv /tmp/scripts/generateUUID.php /srv/centreon/scripts/

chmod +x /srv/centreon/scripts/firstboot.sh
cat <<EOF > /etc/systemd/system/firstboot.service 
[Unit]
Description=Auto-execute post install scripts
After=network.target
 
[Service]
ExecStart=/srv/centreon/scripts/firstboot.sh
 
[Install]
WantedBy=multi-user.target
EOF

systemctl enable firstboot

# Enable all others services
systemctl enable httpd24-httpd
systemctl enable snmpd
systemctl enable snmptrapd
systemctl enable rh-php71-php-fpm
systemctl enable centcore
systemctl enable centreontrapd
systemctl enable cbd
systemctl enable centengine
systemctl enable centreon

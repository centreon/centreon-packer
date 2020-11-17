#!/bin/sh

DEBUG=1

MYSQL_HOST="localhost"
MYSQL_PORT="3306"
MYSQL_USER="centreon"
MYSQL_PASSWD="c3ntr30n"
MYSQL_ROOT_PASSWORD="change123"
CENTREON_ADMIN_NAME="Administrator"
CENTREON_ADMIN_EMAIL="admin@admin.co"
CENTREON_ADMIN_PASSWD="change123"

function InstallDbCentreon() {

    CENTREON_HOST="http://localhost"
    COOKIE_FILE="/tmp/install.cookie"
    CURL_CMD="curl -q -o /dev/null -b ${COOKIE_FILE}"

    curl -q -c ${COOKIE_FILE} ${CENTREON_HOST}/centreon/install/install.php
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/step.php?action=stepContent"
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/step.php?action=nextStep"
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/step.php?action=nextStep"
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/process/process_step3.php" \
        --data "install_dir_engine=%2Fusr%2Fshare%2Fcentreon-engine&centreon_engine_stats_binary=%2Fusr%2Fsbin%2Fcentenginestats&monitoring_var_lib=%2Fvar%2Flib%2Fcentreon-engine&centreon_engine_connectors=%2Fusr%2Flib64%2Fcentreon-connector&centreon_engine_lib=%2Fusr%2Flib64%2Fcentreon-engine&centreonplugins=%2Fusr%2Flib%2Fcentreon%2Fplugins%2F"
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/step.php?action=nextStep"
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/process/process_step4.php" \
        --data "centreonbroker_etc=%2Fetc%2Fcentreon-broker&centreonbroker_cbmod=%2Fusr%2Flib64%2Fnagios%2Fcbmod.so&centreonbroker_log=%2Fvar%2Flog%2Fcentreon-broker&centreonbroker_varlib=%2Fvar%2Flib%2Fcentreon-broker&centreonbroker_lib=%2Fusr%2Fshare%2Fcentreon%2Flib%2Fcentreon-broker"
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/step.php?action=nextStep"
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/process/process_step5.php" \
        --data "admin_password=${CENTREON_ADMIN_PASSWD}&confirm_password=${CENTREON_ADMIN_PASSWD}&firstname=${CENTREON_ADMIN_NAME}&lastname=${CENTREON_ADMIN_NAME}&email=${CENTREON_ADMIN_EMAIL}"
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/step.php?action=nextStep"
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/process/process_step6.php" \
        --data "address=${MYSQL_HOST}&port=${MYSQL_PORT}&root_user=root&root_password=${MYSQL_ROOT_PASSWORD}&db_configuration=centreon&db_storage=centreon_storage&db_user=${MYSQL_USER}&db_password=${MYSQL_PASSWD}&db_password_confirm=${MYSQL_PASSWD}"
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

function installPlugins() {

    # Install JQ tool (https://stedolan.github.io/jq/)
    # to help manage json output in shell
    curl -q -o /usr/sbin/jq -L https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
    chmod +x /usr/sbin/jq

    SLUGS=$(curl -q -L -g 'https://api.imp.centreon.com/api/pluginpack/pluginpack?sort=catalog_level&by=asc&page[number]=1&page[size]=20')

    PLUGINS=(
      base-generic
      applications-databases-mysql
      operatingsystems-linux-snmp
      applications-monitoring-centreon-database
      applications-monitoring-centreon-central
    )

    CENTREON_HOST="http://localhost"
    CURL_CMD="curl "

    for PLUGIN in "${PLUGINS[@]}"; do
        JSON_PLUGIN="{\"slug\": \"${PLUGIN}\", \"version\": $(echo $SLUGS | tr '\r\n' ' ' | jq ".data[].attributes | select(.slug | contains(\"${PLUGIN}\")).version"), \"action\": \"install\"}"
        STATUS=0
        while [ $STATUS -eq 0 ]; do
            API_TOKEN=$(curl -q -d "username=admin&password=${CENTREON_ADMIN_PASSWD}" \
                "${CENTREON_HOST}/centreon/api/index.php?action=authenticate" \
                | cut -f2 -d":" | sed -e "s/\"//g" -e "s/}//"
            )
            CURL_OUTPUT=$(${CURL_CMD} -X POST \
                -H "Content-Type: application/json" \
                -H "centreon-auth-token: $(read <<<"$API_TOKEN";echo "$REPLY")" \
                -d "{\"pluginpack\":[${JSON_PLUGIN}]}" \
                "${CENTREON_HOST}/centreon/api/index.php?object=centreon_pp_manager_pluginpack&action=installupdate"
            )
            if [ $DEBUG -eq 1 ]; then
                echo "Curl ouput: ${CURL_OUTPUT}"
            fi
            if ! [ $(echo $CURL_OUTPUT | grep "Forbidden") ]; then
                STATUS=1
            fi
        done
    done
}

function installWidgets() {
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

    for WIDGET in "${WIDGETS[@]}"; do
        # Install package
        yum install -y centreon-widget-${WIDGET}
        API_TOKEN=$(curl -q -d "username=admin&password=${CENTREON_ADMIN_PASSWD}" \
            "${CENTREON_HOST}/centreon/api/index.php?action=authenticate" \
            | cut -f2 -d":" | sed -e "s/\"//g" -e "s/}//"
        )
        # Configure widget in Centreon
        ${CURL_CMD} -X POST \
            -H "Content-Type: application/json" \
            -H "centreon-auth-token: $(read <<<"$API_TOKEN";echo "$REPLY")" \
            "${CENTREON_HOST}/centreon/api/index.php?object=centreon_module&action=install&id=${WIDGET}&type=widget"
    done
}

function initialConfiguration() {

    # Add server and set snmp configuration
    centreon -u admin -p ${CENTREON_ADMIN_PASSWD} -o HG -a add -v "Linux;Linux servers"
    centreon -u admin -p ${CENTREON_ADMIN_PASSWD} -o HOST -a ADD -v "centreon-central;Centreon Central;127.0.0.1;App-Monitoring-Centreon-Central-custom|App-Monitoring-Centreon-Database-custom;central;Linux"
    centreon -u admin -p ${CENTREON_ADMIN_PASSWD} -o HOST -a setmacro -v "centreon-central;MYSQLPASSWORD;${MYSQL_PASSWD}"
    centreon -u admin -p ${CENTREON_ADMIN_PASSWD} -o HOST -a setparam -v "centreon-central;snmp_community;public"
    centreon -u admin -p ${CENTREON_ADMIN_PASSWD} -o HOST -a setparam -v "centreon-central;snmp_version;2c"
    centreon -u admin -p ${CENTREON_ADMIN_PASSWD} -o HOST -a applytpl -v "centreon-central"

    # add a plugin to monitor each ethernet interface
    ip -o link show | awk -F': ' '{print $2}' | grep -v 'lo' | while read IFNAME; do
        centreon -u admin -p ${CENTREON_ADMIN_PASSWD} -o SERVICE -a add -v "centreon-central;Interface-${IFNAME};OS-Linux-Traffic-Generic-Name-SNMP"
        centreon -u admin -p ${CENTREON_ADMIN_PASSWD} -o SERVICE -a setmacro -v "centreon-central;Interface-${IFNAME};INTERFACENAME;${IFNAME}"
    done

    # add mount point from partition of system to monitor
    lsblk -o MOUNTPOINT | sed -e 1d -e '/^$/d' | while read MP; do
        centreon -u admin -p ${CENTREON_ADMIN_PASSWD} -o SERVICE -a add -v "centreon-central;Mountpoint-${MP};OS-Linux-Disk-Generic-Name-SNMP"
        centreon -u admin -p ${CENTREON_ADMIN_PASSWD} -o SERVICE -a setmacro -v "centreon-central;Mountpoint-${MP};DISKNAME;${MP}"
    done

    # Apply configuration
    centreon -u admin -p ${CENTREON_ADMIN_PASSWD} -a CFGMOVE -v 1
}

dnf install -y wget curl openssh-server
dnf install -y 'dnf-command(config-manager)'
dnf config-manager --set-enabled PowerTools
dnf install -y http://yum.centreon.com/standard/20.10/el8/stable/noarch/RPMS/centreon-release-20.10-2.el8.noarch.rpm
#curl -L https://raw.githubusercontent.com/centreon/centreon/master/unattended.sh | sh

dnf install -y centreon centreon-database

systemctl daemon-reload
systemctl restart mariadb
mysqladmin -u root password $MYSQL_ROOT_PASSWORD # Set password to root mysql
systemctl restart php-fpm
systemctl restart httpd
sleep 5 # waiting start httpd process
InstallDbCentreon # Configure database
su - centreon -c "/bin/php /usr/share/centreon/cron/centreon-partitioning.php"
systemctl restart cbd

# Install Plugins
installPlugins

# Install widgets and configure
#installWidgets

# Apply initial configuration from owner server
initialConfiguration

# Enable all others services
systemctl enable mariadb
systemctl enable httpd
systemctl enable snmpd
systemctl enable snmptrapd
#systemctl enable ntpd
systemctl enable php-fpm
systemctl enable gorgoned
systemctl enable centreontrapd
systemctl enable cbd
systemctl enable centengine
systemctl enable centreon

# Set profile script
mkdir -p /srv/centreon
mv -v /tmp/scripts/generateUUID.php /srv/centreon/generateUUID.php
mv -v /tmp/scripts/generateAppKey.php /srv/centreon/generateAppKey.php
# install banner binary from Epel, used by centreon profile.d
yum install -y epel-release \
  && yum install -y banner \
  && yum remove -y epel-release
mv -v /tmp/scripts/centreon-profile.sh /etc/profile.d/centreon.sh

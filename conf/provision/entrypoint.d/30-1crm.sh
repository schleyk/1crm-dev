#############################
## check if 1CRM is installed
#############################

if [[ ! -e "/app/sugar_version.php" ]]; then
	wget https://1crm-system.de/downloads/1CRM_DE_8.6.9-803.zip -O download.zip
	unzip download.zip -d /app
	rm download.zip
	chown application:application /app -R
	## change 1CRM Log setting
	sed -i 's/logs_dir: logs\//logs_dir: ""/' /app/include/config/standard/site.php 
	sed -i 's/file: site.log/file: "php:\/\/stderr"\n    dir: ""/' /app/include/config/standard/site.php
fi
if [[ -n "${CRM_DB_PASSWORD+x}" && ! -e "/app/include/config/local_config.php" ]]; then
	db_name="onecrm"
	if [[ -n "${CRM_DB_NAME+x}" ]]; then
		db_name=$CRM_DB_NAME
	fi
	db_host="mysql"
	if [[ -n "${CRM_DB_HOST+x}" ]]; then
		db_host=$CRM_DB_HOST
	fi
	crm_url="1crm.dev"
	if [[ -n "${CRM_URL+x}" ]]; then
		crm_url=$CRM_URL
	fi
	cd /app && /usr/bin/php install.php -d $db_name -h $db_host -u $db_user -p "$CRM_DB_PASSWORD" -a $db_user -w  "$CRM_DB_PASSWORD" --url $crm_url --ap visual4 --wc
fi
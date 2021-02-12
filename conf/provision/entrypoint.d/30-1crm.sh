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

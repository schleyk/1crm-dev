# 1CRM Docker Image
the image is based on [webdevops/php-nginx](https://dockerfile.readthedocs.io/en/latest/content/DockerImages/dockerfiles/php-nginx.html). The base is php-fpm 8.1 with 1CRM specific configurations:
- 1crmredirects are included
- the 1CRM logfile is forwarded to stdout for output with docker logs
- on initialization 1CRM is downloaded and unpacked to /app (if no sugar_version.php is available)
- the 1CRM cronjob is activated and calls scheduler.php every 5 minutes
- postfix/sendmail is deactivated, SMTP must be used to send mails

the image listens on ports 80 and 443, a self-signed certificate is included.  As volume /app is exported.
All environment variables to configure NGINX and PHP of the webdevops/php-nginx image work.
### Docker installation

You'll find information on how to install docker on https://docs.docker.com/get-docker/

> Important for production environments: Docker deletes data when a container is deleted! Backup and configuration of the volumes are crucial to avoid data loss

### 1CRM **Sandbox** system with Docker:

create the following docker-compose.yml:
```yaml
version: "3"
services:
    1crm:
        image: gitlab.visual4.de:5050/docker/nginx-php-1crm:8.7.4
        volumes:
            - "crm_storage:/app"            
        ports:
            - "80:80"
            - "443:443"           
        links:
            - mysql
        depends_on:
            - mysql
        environment:
            WEB_ALIAS_DOMAIN: 1crm.dev
            # CRM_DB_PASSWORD is required to start installation if local_config.php is missing
            CRM_DB_PASSWORD: visual4
            # CRM_DB_NAME default onecrm
            # CRM_DB_HOST default mysql
            # CRM_DB_USER default onecrm
            # CRM_URL default https://1crm.dev
            # CRM_ADMIN_PASSWORD default visual4
    mysql:
        image: mariadb:latest
        environment: 
            MYSQL_ROOT_PASSWORD: visual4
            MYSQL_DATABASE: onecrm
            MYSQL_USER: onecrm
            MYSQL_PASSWORD: visual4
        volumes:
            - "mysql_storage:/var/lib/mysql"
        
volumes:
    mysql_storage:
    crm_storage:

```


Start 1CRM with ``#> docker-compose up -d``, 1CRM is then reachable via port 80 and with SSL via 443.
#### automatic download of 1CRM
if there is no file "sugar_version.php" in /app, i.e. also for a first time installation, the automatic download of 1CRM will start. The files are unpacked into the /app directory, respectively crm_storage or the corresponding mounted volume.
In crm_storage and mysql_storage all data of 1CRM is stored, so a suitable backup strategy should be provided, especially for production systems.

#### automatic installation
Because the environment variable CRM_DB_PASSWORD is included in the compose file, the 1CRM installation starts directly after the download. 

#### manual installation
if the variable CRM_DB_PASSWORD is commented out, there is no automatic installation, when accessing it, the installer of 1CRM is displayed.
During the installation ``mysql`` must be entered as database server, the credentials can be customized in the ddocker-compose.yml.

> **this configuration is meant for testing only!** Within the German README, you will find additional things to do for production setups.

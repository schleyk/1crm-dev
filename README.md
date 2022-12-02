# 1CRM Docker Image
das Image basiert auf [webdevops/php-nginx](https://dockerfile.readthedocs.io/en/latest/content/DockerImages/dockerfiles/php-nginx.html). Die Basis ist dabei php-fpm 7.4 mit 1CRM spezifisschen Konfigurationen:
- 1crmredirects sind enthalten
- das 1CRM Logfile wird an stdout weitergeleitet um es mit docker logs ausgeben zu können
- bei der Initialisierung wird 1CRM heruntergeladen und nach /app entpackt (falls keine sugar_version.php vorhanden ist)
- der 1CRM Cronjob ist aktiviert und ruft ale 5 Minuten scheduler.php auf
- Postfix/sendmail ist deaktiviert, zum Mailversand muss SMTP verwendet werden

das Image hört auf den Ports 80 und 443, ein selbstsigniertes Zertifikat ist enthalten.  Als volume wird /app exportiert.
Alle Umgebungsvariablen zur Konfiguration von NGINX und PHP des webdevops/php-nginx Images funktionieren.

### Installation von Docker
Voraussetzung für die Installation ist ein installiertes Docker inklusive Docker Compose
- Die Installation unter Windows, Mac und Linux ist unter https://docs.docker.com/get-docker/ beschrieben 
- NAS-Systeme von QNAP und Synology bringen z.B. die  ContainerStation mit, über die Docker-Container ausgeführt werden können

> Wichtig bei Produktivumgebungen: Docker löscht Daten, wenn ein Container gelöscht wird! Backup und Konfiguration der Volumes sind entscheidend  um Datenverlust zu vermeiden

### Nutzung mit Docker:

Legen Sie eine Datei docker-compose.yml mit folgendem Inhalt an:

```yaml
version: "3"
services:
    1crm:
        image: gitlab.visual4.de:5050/docker/nginx-php-1crm:latest
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

1CRM mit ```#> docker-compose up -d``` starten, 1CRM ist dann über Port 80 und mit SSL über 443 erreichbar.
#### automatischer Download von 1CRM
falls in /app keine Datei "sugar_version.php" vorhanden ist, also auch bei einer erstmaligen Installation, startet der automatische Download von 1CRM. Die Dateien werden in das /app-Verzeichnis, bzw. crm_storage oder das entsprechend gemountete Volume entpackt.
In crm_storage und mysql_storage werden alle Daten von 1CRM gespeichert, eine passende Backupstrategie sollte also, insbesondere bei Produktivsystemen vorgesehen werden.

#### automatische Installation
Dadurch, dass in der compose-Datei die Umgebungsvariable CRM_DB_PASSWORD mitgegeben wird, startet die 1CRM Installation direkt nach dem Download. 

#### manuelle Installation
wenn die Variable CRM_DB_PASSWORD auskommentiert wird, erfolgt keine automatische Installation, beim Zugriff wird der Installer von 1CRM angezeigt.
Während der Installation muss als Datenbankserver ```mysql``` eingegeben werden, die Zugangsdaten können in der ddocker-compose.yml angepasst werden.




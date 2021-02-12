# 1CRM Docker Image
das Image basiert auf [webdevops/php-nginx](https://dockerfile.readthedocs.io/en/latest/content/DockerImages/dockerfiles/php-nginx.html). Die Basis ist dabei php-fpm 7.4 mit 1CRM spezifisschen Konfigurationen:
- 1crmredirects sind enthalten
- das 1CRM Logfile wird an stdout weitergeleitet um es mit docker logs ausgeben zu können
- bei der Initialisierung wird 1CRM heruntergeladen und nach /app entpackt (falls keine sugar_version.php vorhanden ist)
- der 1CRM Cronjob ist aktiviert und ruft ale 5 Minuten scheduler.php auf
- Postfix/sendmail ist deaktiviert, zum Mailversand muss SMTP verwendet werden

das Image hört auf den Ports 80 und 443, ein selbstsigniertes Zertifikat ist enthalten.  Als volume wird /app exportiert.
Alle Umgebungsvariablen zur Konfiguration von NGINX und PHP des webdevops/php-nginx Images funktionieren.

### Nutzung mit Docker:
```
#> docker run -d -p 8443:443 -v /path/to/1crm-data:app --name 1crm gitlab.visual4.de:5050/docker/nginx-php-1crm:latest
```
1CRM kann danach über https://localhost:8443 augerufen werden. Die 1CRM-Dateien liegen in /path/to/1crm-data (im Aufruf durch eigenes lokales Verzeichnis ersetzen)

### Nutzung mit docker-compose

folgende docker-compose.yml anlegen und den Pfad ```~/source/web/``` ersetzen
```
version: "3"
services:
    web:
        image: gitlab.visual4.de:5050/docker/nginx-php-1crm:latest
        volumes:
            - "~/source/web/:/app"            
        ports:
            - "80:80"
            - "443:443"           
        links:
            - mysql
        depends_on:
            - mysql
        environment:
            - WEB_ALIAS_DOMAIN=1crm.local.dev
            - PHP_MEMORY_LIMIT=2048M
            - PHP_MAX_EXECUTION_TIME=-1            
    mysql:
        image: mariadb:latest
        environment: 
            MYSQL_ROOT_PASSWORD: visual4
            MYSQL_DATABASE: onecrm
            MYSQL_USER: onecrm
            MYSQL_PASSWORD: visual4
        ports:
            - "3306:3306"
        volumes:
            - "mysql_storage:/var/lib/mysql"
        
volumes:
    mysql_storage:
```

1CRM mit ```#> docker-compose up -d``` starten, 1CRM ist dann über Port 80 und mit SSL über 443 erreichbar. Während der Installation muss als Datenbankserver ```mysql``` eingegeben werden, die Zugangsdaten können in der ddocker-compose.yml angepasst werden.

> Docker muss natürlich inklusive docker-compose installiert sein. Die Installation unter Windows ist unter https://docs.docker.com/docker-for-windows/install/ beschrieben oder für bessere Performance mit WSL2: https://docs.docker.com/docker-for-windows/wsl/.
> unter Linux gibt es umfangreiche Anleitungen für jede Distribution unter Ubuntu muss z.B. erst [Docker](https://docs.docker.com/engine/install/ubuntu/) und dann [Docker-Compose](https://docs.docker.com/compose/install/) installiert werden.

> Wichtig bei Produktivumgebungen: Docker löscht Daten, wenn ein Container gelöscht wird! Backup und Konfiguration der Volumes sind entscheidend  um Datenverlust zu vermeiden


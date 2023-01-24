# 1CRM & Docker
## Was ist Docker
Docker ist ein Tool, mit dem auf einem Computer oder Server vorgefertigte Anwendungs-Images als sogenannte Container gestartet werden können. Dabei sind alle erforderlichen Software-Komponenten in dem jeweiligen Image enthalten, die Anwendungen werden dadurch universell und schnell einsetzbar. Bei dem in dieser Anleitung verwendeten Docker-Compose wird über eine einfache Konfigurationsdatei eine Multi-Container-Umgebung definiert, hier bestehend aus dem Datenbankserver und dem Webserver mit 1CRM. Innerhalb der Konfigurationsdatei können Parameter, wie Passwörter und URLs dieser Umgebung einfach angepasst werden. Weitergehende Informationen dazu gibt es unter https://docs.docker.com/compose/

### Installation von Docker
Voraussetzung für die Verwendung des 1CRM Docker-Images ist ein installiertes Docker inklusive Docker Compose
- Die Installation unter Windows, Mac und Linux ist unter https://docs.docker.com/get-docker/ beschrieben 
- NAS-Systeme von QNAP und Synology bringen z.B. die  ContainerStation mit, über die Docker-Container und Compose-Dateien direkt gestartet werden können

## Das 1CRM Docker Image
Das 1CRM Docker Image beinhaltet einen Webserver mit PHP und lädt beim ersten Start automatisch das 1CRM Installationspaket herunter. Mit der gezeigten Konfiguration wird im Anschluss automatisch die Installation gestartet, so dass 1CRM nach etwa einer Minute über https://localhost aufgerufen werden kann (Benutzer admin, Passwort visual4). Das Image basiert auf [webdevops/php-nginx](https://dockerfile.readthedocs.io/en/latest/content/DockerImages/dockerfiles/php-nginx.html). Die Basis ist dabei NGINX und php-fpm 8.1 mit 1CRM-spezifischen Konfigurationen:
- 1crmredirects sind enthalten
- das 1CRM Logfile wird an stdout weitergeleitet um es mit docker logs ausgeben zu können
- bei der Initialisierung wird 1CRM heruntergeladen und nach /app entpackt (falls keine sugar_version.php vorhanden ist)
- der 1CRM Cronjob ist aktiviert und ruft ale 5 Minuten scheduler.php auf
- Postfix/sendmail ist deaktiviert, zum Mailversand muss SMTP verwendet werden

das Image hört auf den Ports 80 und 443, ein selbstsigniertes Zertifikat ist enthalten.  Vor dem Start müssen ggf. andere Server, die auf demselben Rechner Dienste über Port 80/443 zur Verfügung stellen deaktiviert werden (z.B. WAMP/XAMPP). Als volume wird /app exportiert.
Alle Umgebungsvariablen zur Konfiguration von NGINX und PHP des webdevops/php-nginx Images funktionieren.

> Falls der Webserver über andere Ports als 80 und 443 laufen soll, muss die 1CRM-Installation manuell durchgeführt werden, das heisst CRM_DB_PASSWORD darf nicht gesetzt sein.


> Die gezeigte Konfiguration ist für ein Testsystem gedacht, einfaches Setup und Konfiguration waren bei der Konzeption wichtiger als Datensicherheit und Verfügbarkeit, siehe auch die Hinweise am Ende der Seite.

### Nutzung von Docker Compose als Testsystem für 1CRM:

Legen Sie eine Datei docker-compose.yml mit folgendem Inhalt an:

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
            ## CRM_DB_PASSWORD is required to start installation if local_config.php is missing
            CRM_DB_PASSWORD: visual4
            # CRM_DB_NAME default onecrm
            # CRM_DB_HOST default mysql
            # CRM_DB_USER default onecrm
            # CRM_URL default https://1crm.dev
            # CRM_ADMIN_PASSWORD default visual4
            ## php.ini settings, see https://dockerfile.readthedocs.io/en/latest/content/DockerImages/dockerfiles/php.html#php-ini-variables
            php.error_reporting: "E_ALL & ~E_WARNING & ~E_NOTICE & ~E_STRICT & ~E_DEPRECATED"
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

1CRM mit ```#> docker compose up``` starten, 1CRM ist dann über Port 80 und mit SSL über 443 erreichbar.

#### automatischer Download von 1CRM
falls in /app keine Datei "sugar_version.php" vorhanden ist, also auch bei einer erstmaligen Installation, startet der automatische Download von 1CRM. Die Dateien werden in das /app-Verzeichnis, bzw. crm_storage oder das entsprechend gemountete Volume entpackt.
In crm_storage und mysql_storage werden alle Daten von 1CRM gespeichert, eine passende Backupstrategie sollte also, insbesondere bei Produktivsystemen vorgesehen werden.

#### automatische Installation
Dadurch, dass in der compose-Datei die Umgebungsvariable CRM_DB_PASSWORD mitgegeben wird, startet die 1CRM Installation direkt nach dem Download. 

#### manuelle Installation
wenn die Variable CRM_DB_PASSWORD auskommentiert wird, erfolgt keine automatische Installation, beim Zugriff wird der Installer von 1CRM angezeigt.
Während der Installation muss als Datenbankserver ```mysql``` eingegeben werden, die Zugangsdaten können in der ddocker-compose.yml angepasst werden.

### Update des Images
über gitlab.visual4.de werden regelmässig neue Versionen des Images mit aktualisierten Upstream-Paketen erstellt. Die aktualisierten Images können mithilfe von ```docker pull gitlab.visual4.de:5050/docker/nginx-php-1crm:latest``` heruntergeladen werden (ggf. Version/Tag anpassen). 1CRM aktualisiert sich nicht automatisch, das muss im Rahmen einer gültigen Subscription über die integrierte Update-Funktion erfolgen, aber NGINX und PHP werden durch den Pull aktualisiert. Entsprechend sollte auch mit dem Datenbank-Image verfahren werden.

### Nutzung von Docker Compose als Live-System für 1CRM:
die oben gezeigte Konfigurationsdatei kann als Startpunkt für eigene Konfigurationen verwendet werden. Für ein Live- oder Produktivsystem müssen zumindest die folgenden Punkte individuell gelöst und konfiguriert werden:

- ggf. direkte Verwendung von PHP- und NGINX Docker-Images, hier muss Sicherheit gegen Einfachheit abgewogen werden.
- Verwendung sicherer Passwörter, Auslagerung in eine .env-Datei
- Erstellung persistenter Volumes für 1CRM und MariaDB
- Verwendung eines gültigen SSL-Zertifikates mit eigener Domain, z.B. über einen Letsencrypt-Reverse-Proxy oder einen Loadbalancer
- Daemonisierung und automatischer Start der Container
- Backup der Volumes, Backup der Datenbank über mysqldump
- regelmässige Aktualisierung der Basis-Images um Sicherheitsupdates in PHP, MariaDB und NGINX zeitnah einzuspielen. Der visual4-Buildserver aktualisiert wöchentlich das master/latest-Image auf Basis des webdevops/php-nginx Basisimages.

> Aufgrund der mehrstufigen Software-Supply-Chain übernimmt die visual4 GmbH keine Verantwortung für das rechtzeitige Einspielen von erforderlichen Sicherheitsupdates in die unter gitlab.visual4.de zu testzwecken zur Verfügung gestellten Docker-Images.


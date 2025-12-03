#!/bin/bash
# Script written by AccaEmme on 03rd dic 2025
# GitHub: https://github.com/AccaEmme/FastwebCyberSec2025/2025-12-03/
#
# how to install:
# - copy text into my_checkup_script.sh file
# - run: chmod +x ./my_checkup_script.sh
#
# usage:
# ./my_checkup_script.sh

echo "=== Mini Comandi bash per lo Scenario 3 - a cura di Hermann ==="

echo " :: Modifiche recenti al file /etc/passwd e /etc/shadow"
stat /etc/passwd
ls -lh /etc/passwd /etc/shadow

echo ""
echo " :: List file log più recenti in /var/log"
ls -lth /var/log | head -20

echo ""
echo " :: Evidenzia gli utenti che hanno accesso a qualsiasi shell"
echo "ovvero se la shell è utilizzabile per un utente al quale non sarebbe prevista, capire che succede"
grep -vE "(/usr/sbin/nologin|/bin/false)" /etc/passwd # Mostra utenti con shell diversa da /usr/sbin/nologin o /bin/false

echo ""
echo " :: Evidenzia gli utenti che hanno uid=0 e quindi di root"
awk -F: '($3 == 0) {print $1}' /etc/passwd

echo ""
# mostra il file /etc/passwd per un controllo umano
cat /etc/passwd
echo ""
echo ""

echo ""
echo " :: Accessi con successo mediante SSH in /var/log/auth.log"
cat /var/log/auth.log | grep -i "Accepted" | grep -i ssh

echo ""
echo " :: Tentativi di accesso via SSH in /var/log/auth.log"
cat /var/log/auth.log | tail -n 10

echo ""
echo " :: Gli ultimi utenti loggati. Eseguo: lastlog"
echo "capire se ci sono potenziali anomalie, come utente root loggato o utenti di sistema loggati"
lastlog



echo ""
echo " :: Cercare servizi legati a condizioni temporali particolari o eventi"
cd /etc/systemd/system
ls *.timer # Cerca servizi con timer
grep -i "OnCalendar" *.timer # Cerca servizi legati a eventi

echo ""
echo " :: Elenca i file dei servizi presenti"
ls /etc/systemd/system/*.service
systemctl status | grep running

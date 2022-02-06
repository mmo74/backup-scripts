#!/bin/bash

################################################################################
# this script calls another script per ssh to start a bareos-job.
#
# Copyright (C) 2014  Michael Oehme <m.m.oehme@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.#
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
################################################################################


################################################################################
# Dieses Script wertet keine Kommandozeilenparamter aus, da dies dem Sinn dieses
# Scripts widersprechen würde.
# Statt dessen sollten nachfolgend alle notwendigen Einstellungen vorgenommen
# werden.

################################################################################
# PARAMETER

## INTERFACE: Wenn der Start des Backups ausschließlich erfolgen soll, wenn
##            ein bestimmtes Netzwerkinterface aktiviert wurde.
##            Z.B. kann so verhindert werden, dass ein Backup über das WLAN
##            läuft. Dieser Parameter macht aber nur Sinn, wenn dieses Script
##            aus /etc/networ/if-up.d aufgerufen wird. In diesem Fall wird 
##            im Environment die Variable IFACE gesetzt. Diese wir dann mit
##            INTERFACE verglichen. Sind diese unterschiedlich wird das Script
##            beendet.
##            HINWEIS: Die entsprechende Funktion ist per Default auskommentiert,
##            da sonst Probleme beim Aufruf per cron.daily drohen. HIer wird 
##            IFACE nicht gesetzt. Weshalb das Script immer abbrechen würde.             
#INTERFACE="eth0"

## BAREOSSERVER: Hostname oder IP-Adresse des Bareosservers
BAREOSSERVER="CHANGEME_BAREOSSERVER"

## BAREOSREMOTESCRIPT; Wie heißt das Script auf dem Server?
##            Dieses muss den Parameter start und einen Bareosjob als
##            Parameter akzeptieren.
BAREOSREMOTESCRIPT="/etc/bareos/bareos-remote.sh"

## BAREOSJO: Name des Jobs welcher auf dem Bareosserver gestartet werden soll
BAREOSJOB="JOB_TO_RUN"

## LASTRUNFILE: Datei deren ZEitstempel den letzten Programmaufruf speichert.
LASTRUNFILE="/var/lib/bareos/lastrun"



## Wurde das richtige INTERFACE aktiv? -> Wenn nicht, dann ENDE
## Diese Funktion ist per Defaul auskommentiert. Erklärung siehe Parameter INTERFACE.
#if [ "$IFACE" != "$INTERFACE" -o -z "$IFACE" ]; then 
#   /usr/bin/logger info "BAREOS: Nicht die richtige Netzwerkkarte aktiviert."
#   exit 0
#fi


## IST der Server erreichbar? -> Wenn nicht, dann ENDE
if ! /bin/ping -c 1 $BAREOSSERVER > /dev/null
then
  /usr/bin/logger info "BAREOS: Der Server ist nicht erreichbar."
  exit 0 
fi

## Liegt der letze Skriptaufruf länger als einen Tag zurück? Wenn nicht, dann ENDE
## Diese Abschnitt prüft, ob am Tag des Aufrufs bereits ein Backup gestartet wurde.
## Dazu kommt die Datei in LASTRUN zum Einsatz. Es wird geprüft ob die letzte
## Änderung der Datei mind. einen Tag vor Aufruf dieses Scripts erfolgt ist.
if [ $(find $LASTRUNFILE -mtime -1|wc -l) -gt 0 ]; 
then
   /usr/bin/logger info "BAREOS: Backup heute bereits gelaufen."
   exit 0
fi

################################################################################
# Gut. 
# Da wir bis hierher gekommen sind, sollte das Backup nun auch gestartet werden.
if ssh $BAREOSSERVER -C "$BAREOSREMOTESCRIPT start $BAREOSJOB"
then 
    ## Wenn dabei alles glatt geht wird ein Eintrag ins Log geschrieben, ...
    /usr/bin/logger info "BAREOS: Backup wurde in die Warteschlange aufgenommen."
    ## ... der Zeitstempel des LASTRUNFILE angepasst
    ## (Das Datum wird dabei auf 00:00 des aktuellen Tages gesetzt) ...
    touch -t `date +%m%d0000` $LASTRUNFILE
    ## und das Script mit dem Exitcode 0 (kein Fehler) beendet.
    exit 0
fi

## Sollte das Script bis hier kommen, dann ist irgend etwas in die Hose gegangen.
## Dementsprechen erfolgt ein Eintrag im Log ..
/usr/bin/logger info "BAREOS: Backup konnte nicht in die Warteschlange aufgenommen werden."
## --- und das Script wird mit dem Exitcode 1 (Fehler) beendet.
exit 1

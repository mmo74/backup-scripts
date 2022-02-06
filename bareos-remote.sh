#!/bin/bash

################################################################################
# this script pipes commands to bconsole to start or cancel a bareos/bacula job
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
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.
################################################################################
   
################################################################################
# Am Anfang werten wir die Kommandozeile aus und weißen die einzelnen Parameter
# verschiedenen Variablen zu, welche wir im weiteren Verlauf des Skript noch
# benötigen

# Unter welchem Namen wurde diese Skript aufgerufen?
MYSELF=$0
# Als erster Parameter muss die gewünschte Aktion (start oder stop) angegeben werden.
ACTION=$1
# Als zweiter Parameter wird ein Bareos/Bacula-Job-Name erwartet
JOBTORUN=$2

################################################################################
## Funktion für die Ausgabe der Synopsis (--help)
function usage {
  echo "Usage: $MYSELF start|stop Job"
  echo ""
  echo "start|stop     Should the given Job be started or stoped?"
  echo "Job            Which bareos Job should be processed?"
}

################################################################################
## Funktion zum Start eine Bareos/Bacula-Jobs
function start_job {
echo "Job wird gestartet."
/usr/sbin/bconsole <<EOF
run job=$JOBTORUN yes
quit
EOF
}

################################################################################
## Funktion zum Abbruch eine Bareos/Bacula-Jobs
function stop_job {
echo "Job wird abgebrochen!"
/usr/sbin/bconsole <<EOF
cancel job=$JOBTORUN
EOF
}

################################################################################
## Funktion zum überprüfen ob der angegebene Job ein gültiger Bareos/Bacula-Job ist
function check_jobs {
  # Im ersten Schritt werden alle bekannten Jobs per bconsole ausgelesen und in
  # AVAILJOBS abgelegt. Damit nur die Ausgabe von .jobs in der Variable ankommt,
  # werden vorher alle messages nach /dev/null geschickt.
  AVAILJOBS=`echo -e "@output /dev/null\nmess\n@output\n.jobs"|/usr/sbin/bconsole `
  # Im zweiten Schritt wird von der Ausgabe des ersten Schrittes noch die Zeile 
  # mit dem Kommando (.jobs) entfernt, sodas in AVAILJOBS nur noch die tatsächlich
  # vorhandenen Jobs abgelegt sind.
  AVAILJOBS=`echo $AVAILJOBS|sed 's/.*\.jobs //'`

  # Iteration über alle vorhandenen Bareos/Bacula-Jobs und vergleich die
  # Namen mit dem übergebenen Parameter.
  for Job in $(echo $AVAILJOBS); do
      # Wenn ein zum Parameter passender Job gefunden wurde, kehrt die Funktion zum
      # Aufrufer zurück.
      [ "$Job" = "$JOBTORUN" ] && return
  done
  # Ansonsten  bricht das Skript mit einer Fehlermeldung ...
  echo "Kein gültiger Job angegeben."
  #  ... und Exit-Code 1 ab. 
  exit 1
}


################################################################################
## JETZT GEHTS LOHOS, ...

# wenn der erste Parameter (abgelegt in $ACTION) ...
case $ACTION in
# ... = start ist, dann ...
start)
	# ... prüfen ob ein entsprechender Job vorhanden ist.
	check_jobs
	# wenn Ja, dann starten wir das Backup
	start_job
        # und beenden dieses Skript mit dem Exit-Code 0 (=kein Fehler)
	exit 0
        ;;

# ... = stop ist, dann
stop)
	# ... prüfen ob ein entsprechender Job vorhanden ist.
	check_jobs
	# wenn Ja, dann brechen wir das Backup ab
	stop_job
        # und beenden dieses Skript mit dem Exit-Code 0 (=kein Fehler)
	exit 0
        ;;

# Für alle anderen Werte wird der Hilfetext ausgegeben. 
*)      usage
esac

# Wenn das Skript bis hierher läuft, dann ist irgendwo etwas in die Hose
# gegangen. Vermutlich wurde ein falscher Parameter eingegeben. Daher
# wird das Skript jetzt mit dem Exit-Code 1 (=ein Fehler ist aufgetreten)
# beendet.
exit 1

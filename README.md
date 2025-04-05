# nmap-fast-scanner
Script for fast port-service scanning.
Might be helpful in solving machines in HTB platform.
The core was copied from "xakep"-journal.
It operates in two stages. The first one performs a normal quick scan, the second one performs a more thorough scan using the available scripts (option -A).
Final version contains flags **--ping**, **--list** and **--cve**

**Usage:**

0. Basic usage (fast_scan):

_./nmap-fast-scan.sh example.com
_
1. Usage with pingability check (just adds -Pn to nmap if host is unreachable):

_./nmap-fast-scan.sh --ping example.com_

2. Usage with CVE check:

_./nmap-fast-scan.sh --cve example.com_

3. Usage with list of hosts:

_./nmap-fast-scan.sh --list hosts.txt_

3. Basic fast scan of several hosts without list:

_./nmap-fast-scan.sh 192.168.1.1 192.168.1.2 192.168.1.3_


Every scans saves in /tmp/nmap_scans/ with unique name.


**Requirements:**
1. uuidgen
2. nmap

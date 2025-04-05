#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Root check
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${YELLOW}[!] Warning: Some scan features require root privileges${NC}"
        sleep 2
    fi
}

# Progress bar animation
progress() {
    local width=40
    local percent=$(( $1 * width / 100 ))
    printf -v arrows "%${percent}s"
    printf -v dots "%$((width - percent))s"
    echo -ne "[${arrows// /▶}${dots// /─}] $1%% \r"
}

# Initialize variables
ping_check=false
cve_scan=false
list_file=""
targets=()
output_dir="/tmp/nmap_scans"
nmap_flags=""
script_flags=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --ping)
            ping_check=true
            shift
            ;;
        --cve)
            cve_scan=true
            script_flags+=" --script=vuln"
            shift
            ;;
        --list)
            if [ -n "$2" ]; then
                list_file="$2"
                shift 2
            else
                echo -e "${RED}[-] Error: --list requires a file argument${NC}"
                exit 1
            fi
            ;;
        *)
            targets+=("$1")
            shift
            ;;
    esac
done

# Check root privileges
check_root

# Create output directory
mkdir -p "$output_dir" || exit 1

# Main scan function
scan_host() {
    local host=$1
    local total_steps=3
    local current_step=0
    local fname="${output_dir}/$(uuidgen -r).xml"
    
    echo -e "\n${BLUE}=== Starting scan: ${host} ===${NC}"
    
    # Initial progress
    progress 0
    
    # Ping check logic
    local host_flags=""
    local initial_scan_ping_flag=""
    if $ping_check; then
        current_step=$((current_step + 1))
        progress $((current_step * 100 / total_steps))
        if ! ping -c 1 -W 1 "$host" &> /dev/null; then
            echo -e "\n${YELLOW}[!] Host not responding, using -Pn${NC}"
            host_flags="-Pn"
            initial_scan_ping_flag="-Pn"
        fi
    else
        host_flags="-Pn"
        initial_scan_ping_flag="-Pn"
    fi

    # Port scanning
    current_step=$((current_step + 1))
    progress $((current_step * 100 / total_steps))
    local ports
    ports=$(nmap -p- --min-rate=500 $initial_scan_ping_flag "$host" | grep '^[0-9]' | cut -d '/' -f1 | tr '\n' ',' | sed 's/,$//')
    
    if [ -z "$ports" ]; then
        echo -e "\n${YELLOW}[!] No open ports found${NC}"
        return
    fi

    # Detailed scan
    current_step=$((current_step + 1))
    progress $((current_step * 100 / total_steps))
    echo -e "\n${GREEN}[*] Starting detailed scan...${NC}"
    nmap -p"$ports" -A $host_flags $script_flags --webxml -oX "$fname" "$host"
    
    echo -e "\n${GREEN}[+] Results saved: ${fname}${NC}"
    progress 100
    echo
}

# Execution logic
if [ -n "$list_file" ]; then
    if [ ! -f "$list_file" ]; then
        echo -e "${RED}[-] Error: File not found: ${list_file}${NC}"
        exit 1
    fi
    hosts_count=$(wc -l < "$list_file")
    current_host=0
    while IFS= read -r host || [ -n "$host" ]; do
        current_host=$((current_host + 1))
        echo -e "${BLUE}\n[Progress] Host ${current_host}/${hosts_count}${NC}"
        scan_host "$host"
    done < "$list_file"
elif [ ${#targets[@]} -gt 0 ]; then
    for host in "${targets[@]}"; do
        scan_host "$host"
    done
else
    echo -e "${RED}[-] Usage: $0 [--ping] [--cve] [--list <file>] <target1> [target2...]${NC}"
    exit 1
fi

echo -e "\n${GREEN}[+] All scans completed!${NC}"

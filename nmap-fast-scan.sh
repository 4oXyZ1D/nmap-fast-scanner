#!/bin/bash

# Инициализация переменных
ping_check=false
cve_scan=false
list_file=""
targets=()
output_dir="/tmp/nmap_scans"
nmap_flags=""
script_flags=""

# Обработка аргументов
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
                echo "Error: --list requires a file argument"
                exit 1
            fi
            ;;
        *)
            targets+=("$1")
            shift
            ;;
    esac
done

# Создаем директорию для результатов
mkdir -p "$output_dir" || exit 1

# Функция сканирования
scan_host() {
    local host=$1
    local fname
    fname="${output_dir}/$(uuidgen -r).xml"
    
    echo "------------ Scanning $host ------------"
    
    # Проверка ping если нужно
    local host_flags=""
    if $ping_check; then
        if ! ping -c 1 -W 1 "$host" &> /dev/null; then
            echo "-- Host not responding, using -Pn --"
            host_flags="-Pn"
        fi
    else
        host_flags="-Pn"
    fi

    # Сканирование портов
    local ports
    ports=$(nmap -p- --min-rate=500 $host_flags "$host" | grep '^[0-9]' | cut -d '/' -f1 | tr '\n' ',' | sed 's/,$//')
    
    if [ -z "$ports" ]; then
        echo "-- No open ports found, skipping detailed scan --"
        return
    fi

    # Полное сканирование
    echo "-- Starting detailed scan --"
    nmap -p"$ports" -A $host_flags $script_flags --webxml -oX "$fname" "$host"
    
    echo "-- Result saved to $fname --"
}

# Основная логика
if [ -n "$list_file" ]; then
    if [ ! -f "$list_file" ]; then
        echo "Error: List file $list_file not found!"
        exit 1
    fi
    while IFS= read -r host || [ -n "$host" ]; do
        scan_host "$host"
    done < "$list_file"
elif [ ${#targets[@]} -gt 0 ]; then
    for host in "${targets[@]}"; do
        scan_host "$host"
    done
else
    echo "Usage: $0 [--ping] [--cve] [--list <file>] <target1> [target2...]"
    exit 1
fi

echo "All scans completed!"

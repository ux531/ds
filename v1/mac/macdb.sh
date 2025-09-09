#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATABASE_DIR="$SCRIPT_DIR/../production_db"

GREEN="\033[1;32m"
BLUE="\033[1;34m"
YELLOW="\033[1;33m"
NC="\033[0m"

# Argument check
if [ $# -eq 1 ]; then
    search_mode="global"
    search_id="$1"
elif [ $# -eq 2 ]; then
    search_mode="local"
    location="$1"
    search_id="$2"
else
    echo "Usage:"
    echo "  ./macbd.sh EMPLOYEE_ID"
    echo "  ./macbd.sh LOCATION EMPLOYEE_ID"
    exit 1
fi

echo -e "\n=== Employee Lookup ===\n"

results=()

# Function to search CSVs
search_csv() {
    local file="$1"
    local loc="$2"
    awk -v search="$search_id" -v loc="$loc" '
    BEGIN { FS=","; OFS="," }
    NR>1 {
        for(i=1;i<=NF;i++) gsub(/^"|"$/, "", $i)
        if(tolower($1)==tolower(search) || tolower($2)==tolower(search))
            print loc, $1, $2, $3, $4, $5
    }' "$file"
}

# Local search
if [ "$search_mode" = "local" ]; then
    file="$DATABASE_DIR/$location.csv"
    if [ ! -f "$file" ]; then
        echo "Location $location not found."
        exit 1
    fi
    while IFS= read -r line; do
        results+=("$line")
    done < <(search_csv "$file" "$location")
fi

# Global search
if [ "$search_mode" = "global" ]; then
    for file in "$DATABASE_DIR"/*.csv; do
        [ -f "$file" ] || continue
        loc=$(basename "$file" .csv)
        while IFS= read -r line; do
            results+=("$line")
        done < <(search_csv "$file" "$loc")
    done
fi

# Display results
if [ ${#results[@]} -eq 0 ]; then
    echo -e "${YELLOW}No matching employee found.${NC}\n"
else
    printf "${GREEN}%-15s %-10s %-10s %-15s %-15s %-30s${NC}\n" "Location" "SID" "ID" "JOB_DEF" "FILIAL" "COMMENT"
    printf '%.0s-' {1..95}; echo

    for result in "${results[@]}"; do
        IFS=',' read -r loc sid id job_def filial comment <<< "$result"
        printf "%-15s %-10s %-10s %-15s %-15s %-30s\n" "$loc" "$sid" "$id" "$job_def" "$filial" "$comment"
    done

    echo -e "\nTotal matches found: ${#results[@]}\n"
fi

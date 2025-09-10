#!/bin/bash

# ==============================================================================
# Employee/Job Definition Lookup in CSV file
# This script is a functional equivalent of the provided PowerShell script,
# adapted to work on macOS with a CSV file instead of an MDB database.
# This version uses standard 'awk' for better portability on macOS.
# ==============================================================================

# --- CONFIGURATION ---
MDBFile="employees.csv"  # Renamed to a CSV file for testing
MAX_RESULTS=2

# --- ANSI Color Codes ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# --- Determine Search Mode and Value ---
if [ "$#" -eq 2 ]; then
    SearchMode="Local"
    TableName="$1"
    SearchID="$2"
    echo "🔍 Searching in specific 'Filial' table: $TableName"
elif [ "$#" -eq 1 ]; then
    SearchMode="Global"
    SearchID="$1"
    echo "🔍 Global search in all rows..."
else
    # Read from clipboard on macOS
    ClipboardContent=$(pbpaste | tr -d '\n' | xargs)
    if [ -z "$ClipboardContent" ]; then
        echo -e "${RED}❌ No arguments provided and clipboard is empty. Please provide a search ID.${NC}"
        exit 1
    fi
    SearchMode="Global"
    SearchID="$ClipboardContent"
    echo "Using clipboard content as search ID: '$SearchID'"
fi

# Convert search term to lowercase for case-insensitive matching
SearchID=$(echo "$SearchID" | tr '[:upper:]' '[:lower:]')

# --- Check for CSV file ---
if [ ! -f "$MDBFile" ]; then
    echo -e "${RED}❌ CSV file '$MDBFile' not found.${NC}"
    exit 1
fi

# --- Begin Searching ---
echo ""
echo -e "${CYAN}================== SEARCH RESULTS ==================${NC}"

if [ "$SearchMode" == "Local" ]; then
    # Local search: checks both the search ID and the filial column
    # The tolower() function is used for case-insensitive matching
    awk -F',' -v search="$SearchID" -v table="$TableName" -v cyan="$CYAN" -v nc="$NC" -v red="$RED" '
    BEGIN {
        results=0;
        printf "%s%-15s %-15s %-15s %-15s %-30s %-10s %-15s %-10s%s\n", cyan, "USER_ID", "JOBDEF", "OLD_JOBDEF", "FILIAL", "NAME", "LEVEL", "DATE_REG", "DATE_DEL", nc
    }
    {
        if (NR>1) {
            if ((tolower($1) ~ search || tolower($2) ~ search || tolower($3) ~ search || tolower($4) ~ search) && tolower($4) == tolower(table)) {
                printf "%-15s %-15s %-15s %-15s %-30s %-10s %-15s %-10s\n", $1, $2, $3, $4, $5, $6, $7, $8
                results++
                if (results >= 2) {
                    exit
                }
            }
        }
    }
    END {
        if (results == 0) {
            print red "❌ No matches found for \047" search "\047." nc
        }
    }' "$MDBFile"
else
    # Global search: checks all columns for the search ID
    # The tolower() function is used for case-insensitive matching
    awk -F',' -v search="$SearchID" -v cyan="$CYAN" -v nc="$NC" -v red="$RED" '
    BEGIN {
        results=0;
        printf "%s%-15s %-15s %-15s %-15s %-30s %-10s %-15s %-10s%s\n", cyan, "USER_ID", "JOBDEF", "OLD_JOBDEF", "FILIAL", "NAME", "LEVEL", "DATE_REG", "DATE_DEL", nc
    }
    {
        if (NR>1) {
            if (tolower($1) ~ search || tolower($2) ~ search || tolower($3) ~ search || tolower($4) ~ search) {
                printf "%-15s %-15s %-15s %-15s %-30s %-10s %-15s %-10s\n", $1, $2, $3, $4, $5, $6, $7, $8
                results++
                if (results >= 2) {
                    exit
                }
            }
        }
    }
    END {
        if (results == 0) {
            print red "❌ No matches found for \047" search "\047." nc
        }
    }' "$MDBFile"
fi

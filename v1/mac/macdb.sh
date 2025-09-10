#!/bin/bash

# Set script and database directory paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATABASE_DIR="$SCRIPT_DIR/../production_db"

# Define color codes for output formatting
GREEN="\033[1;32m"
BLUE="\033[1;34m"
YELLOW="\033[1;33m"
NC="\033[0m"

# Check command-line arguments
if [ $# -eq 1 ]; then
    search_mode="global"  # Global search mode: search all fields across all files
    search_id="$1"
elif [ $# -eq 2 ]; then
    search_mode="local"   # Local search mode: search within a specific location
    location="$1"
    search_id="$2"
else
    echo "Usage:"
    echo "  ./macdb.sh SEARCH_TERM"
    echo "  ./macdb.sh LOCATION SEARCH_TERM"
    exit 1
fi

# Print lookup header
echo -e "\n=== Employee Lookup ===\n"

# Initialize array to store results
results=()

# Function to search CSV files
search_csv() {
    local file="$1"  # Input CSV file
    local loc="$2"   # Location for local search (empty for global)
    awk -v search="$search_id" -v loc="$loc" '
    BEGIN { FS=","; OFS=","; header_type="" }  # Set comma as field separator
    NR==1 {
        gsub(/[\r\n]+$/, "", $0)  # Remove trailing newlines from header
        # Identify header type
        if ($0 == "USER_ID,NAME,JOBDEF,OLD_JOBDEF,DATE_REG,DATE_DEL,FILIAL,LEVEL") header_type="new"
        else if ($0 == "SID,ID,JOB_DEF,FILIAL,COMMENT") header_type="old"
        else next  # Skip file if header is unrecognized
    }
    NR>1 && header_type != "" {  # Process data rows for valid headers
        for(i=1;i<=NF;i++) gsub(/^"|"$/, "", $i)  # Remove quotes from fields
        match_found = 0
        filial = ""
        if (header_type == "new") {  # Handle new format (USER_ID,NAME,...)
            # Search in USER_ID, JOBDEF, OLD_JOBDEF, FILIAL
            if (tolower($1)==tolower(search) || tolower($3)==tolower(search) || tolower($4)==tolower(search) || tolower($7)==tolower(search)) match_found = 1
            filial = $7  # FILIAL is in column 7
            if (loc != "" && tolower(filial) != tolower(loc)) next  # Skip if location doesn’t match
            if (match_found) print "new", filial, $1, $3, $4, $5, $6, $8, $2  # Output new format fields
        } else if (header_type == "old") {  # Handle old format (SID,ID,...)
            # Search in SID, ID
            if (tolower($1)==tolower(search) || tolower($2)==tolower(search)) match_found = 1
            filial = $4  # FILIAL is in column 4
            if (loc != "" && tolower(filial) != tolower(loc)) next  # Skip if location doesn’t match
            if (match_found) print "old", filial, $1, $2, $3, "", "", "", $5  # Output old format fields, padding missing ones
        }
    }' "$file"
}

# Search logic for both modes
for file in "$DATABASE_DIR"/*.csv; do
    [ -f "$file" ] || continue  # Skip if no CSV files exist
    # Run search_csv with location for local mode, empty for global
    while IFS= read -r line; do
        results+=("$line")
    done < <(search_csv "$file" $( [ "$search_mode" = "local" ] && echo "$location" || echo "" ))
done

# Display results
if [ ${#results[@]} -eq 0 ]; then
    echo -e "${YELLOW}No matching employee found.${NC}\n"
else
    # Print header for output table
    printf "${GREEN}%-15s %-10s %-15s %-15s %-15s %-15s %-10s %-30s${NC}\n" "FILIAL" "USER_ID" "JOBDEF" "OLD_JOBDEF" "DATE_REG" "DATE_DEL" "LEVEL" "NAME/COMMENT"
    printf '%.0s-' {1..110}; echo
    # Print each result row
    for result in "${results[@]}"; do
        IFS=',' read -r type filial user_id jobdef old_jobdef date_reg date_del level name <<< "$result"
        printf "%-15s %-10s %-15s %-15s %-15s %-15s %-10s %-30s\n" "$filial" "$user_id" "$jobdef" "$old_jobdef" "$date_reg" "$date_del" "$level" "$name"
    done
    echo -e "\nTotal matches found: ${#results[@]}\n"
fi
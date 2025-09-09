#!/bin/bash
# gen_csv.sh - Generate fake employee CSV database for testing (macOS/Linux safe)

OUTDIR="./test_db"
mkdir -p "$OUTDIR"

# Example location codes (tables)
LOCATIONS=("1251" "1252" "1253" "2001" "3001")

# Some job definitions
JOB_DEFS=("Cashier" "Sales_Manager" "Back_Office" "Finance_Supervisor" "IT_Support" "Front_Desk")

# Generate random employee IDs (8 chars: 6 letters + 2 digits)
gen_id() {
  letters=$(LC_CTYPE=C tr -dc 'A-Z' </dev/urandom | head -c 6)
  digits=$(LC_CTYPE=C tr -dc '0-9' </dev/urandom | head -c 2)
  echo "${letters}${digits}"
}

# Main loop
for loc in "${LOCATIONS[@]}"; do
  FILE="$OUTDIR/${loc}.csv"
  echo "SID,ID,JOB_DEF,FILIAL,COMMENT" > "$FILE"

  for i in $(seq 1 200); do
    ID=$(gen_id)
    SID="P${ID}"  # substitute ID
    JOB_DEF=${JOB_DEFS[$((RANDOM % ${#JOB_DEFS[@]}))]}
    FILIAL=${JOB_DEFS[$((RANDOM % ${#JOB_DEFS[@]}))]}
    COMMENT="Employee $i at location $loc"
    echo "$SID,$ID,$JOB_DEF,$FILIAL,$COMMENT" >> "$FILE"
  done

  echo "Created $FILE with 200 employees"
done

echo "✅ Test database generation complete! Folder: $OUTDIR"

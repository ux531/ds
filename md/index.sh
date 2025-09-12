#!/bin/bash

# ==============================================================================
# SCRIPT: index.sh
# DESCRIPTION:
# Searches inside procedures.json for the best matching procedures based on
# keywords, section names, and step text. Supports Unicode input (Cyrillic + English).
# Shows the top 3 candidates and allows the user to view the top candidate's full procedure.
# ============================================================================== 

PROCEDURES_JSON="./procedures.json"

# --- Input Handling ---
# Decide whether to use command line arguments or clipboard content
# Unicode input is preserved without forcing ASCII conversion
if [[ $# -gt 0 ]]; then
  text=$(echo "$@")  # user-provided input
else
  if command -v pbpaste &>/dev/null; then
    CLIPBOARD_CONTENT=$(pbpaste)
  elif command -v powershell.exe &>/dev/null; then
    CLIPBOARD_CONTENT=$(powershell.exe Get-Clipboard | tr -d '\r')
  else
    CLIPBOARD_CONTENT=$(xclip -o -selection clipboard 2>/dev/null || echo "")
  fi
  text=$(echo "$CLIPBOARD_CONTENT")  # keep Unicode as-is
fi

# --- Normalize Input Words ---
# Split input into individual words by space, comma, semicolon, or pipe
# Trim whitespace with xargs
text=$(echo "$text" | sed 's/[|,;]\+/\n/g' | xargs)
read -ra words <<< "$text"

echo "=== Filtered input words ==="
printf '%s\n' "${words[@]}"
echo "===========================\n"

# Build phrase for multi-word phrase match (not strictly required but kept for future use)
phrase="${words[*]}"

# --- Search + Scoring ---
# We use jq to process the JSON file. Reasoning:
# - JSON is structured; jq is very fast for structured data
# - Unicode is handled correctly when using regex test with 'i' (case-insensitive)
# - Keywords are given a dominant weight (100 points) to ensure exact matches rank highest
# - Steps and section names contribute minor points (1 point per match)
# Pitfalls avoided: ASCII-only functions (contains()) which fail for Cyrillic, case sensitivity issues
results=$(jq -r --argjson words "$(printf '%s\n' "${words[@]}" | jq -R . | jq -s .)" \
               --arg phrase "$phrase" '
  .procedures[]
  | {
      name,
      keywords: (.keywords // "") | split(";") | map(tostring),
      sections: [.sections[] | {name, steps}]
    }
  | . as $proc
  | (
      # Collect searchable fields: procedure name, section names, and all steps
      [$proc.name] + ($proc.sections | map(.name)) + ($proc.sections | map(.steps[]) )
      | {fields: ., keywords: $proc.keywords}
    ) as $data
  | (
      # Score keyword matches first (dominant)
      ($data.keywords // []) as $kw
      | reduce $words[] as $w ({score:0, matched:[]};
          reduce $kw[] as $k (. ;
              # Use test(regex;"i") for Unicode-safe, case-insensitive match
              if ($k | test($w;"i")) then .score += 100 | .matched += [$w] else . end
          )
      ) as $keywordscore
      # Score steps and section names with minor weight
      | reduce $words[] as $w ($keywordscore;
          reduce ($data.fields | map(.)[]) as $f (. ;
              if ($f | test($w;"i")) then .score += 1 | .matched += [$w] else . end
          )
      )
  ) as $score
  | {
      name: $proc.name,
      score: $score.score,
      matched: ($score.matched | unique | join(", "))
    }
' "$PROCEDURES_JSON" \
| jq -s 'sort_by(-.score) | .[:3]'
)

# Exit early if no matches found
if [[ -z "$results" || "$results" == "[]" ]]; then
  echo "❌ No matching procedures found."
  exit 0
fi

# --- Display Top Candidates ---
# Show top 3 candidates with scores and matched words
echo "=== Top Candidates ==="
first_match=$(echo "$results" | jq -r '.[0].name')

echo "$results" | jq -r '.[] | "\(.score)\t\(.name)\t\(.matched)"' | while IFS=$'\t' read -r score name matched; do
  if [[ "$name" == "$first_match" ]]; then
    echo -e "\033[36m--- Candidate 1 (Top Match) 🏆 (Score: $score) ---\033[0m"
  else
    echo "--- Candidate (Score: $score) ---"
  fi
  echo "Name   : $name"
  echo "Matched: $matched"
  echo "-------------------------------------"
done

# --- Show Procedure for the Top Candidate ---
# Wait for Enter to display full steps, avoids showing by accident
if [[ -n "$first_match" ]]; then
  read -p "Show procedure for '$first_match' or exit" -r -s
  echo
  if [[ -z "$REPLY" ]]; then
    # Display procedure sections and steps in readable format
    jq -r --arg name "$first_match" '
      .procedures[]
      | select(.name == $name)
      | "### ✅ Procedure Found: " + .name + " ###\n\n"
        + (
            .sections[]
            | "Section: " + .name + "\n\n"
            + ( .steps | map("- " + .) | join("\n") )
            + "\n"
          )
    ' "$PROCEDURES_JSON"
  fi
fi

# ==============================================================================
# Notes on design decisions:
# - Keywords given high weight (100) ensures queries match semantic intent even with few words
# - Fields/steps get minor weight (1) to differentiate similar procedures
# - Unicode-safe matching solves previous issues with Cyrillic
# - Waiting for Enter avoids accidental exposure of procedures
# - jq used for structured and efficient scoring
# - All scoring done in jq; Bash only handles I/O and display
# ==============================================================================

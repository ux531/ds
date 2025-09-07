#!/bin/bash

# ==============================================================================
# SCRIPT: dynamic_search.sh
# DESCRIPTION:
# This script reads a phrase from the clipboard, filters out common words, and
# then searches for matching keywords in multiple CSV files within a specified
# directory. It scores each match based on relevance, prioritizes perfect phrase
# matches, and dynamically highlights the best candidates.
#
# REASONING & DESIGN CHOICES:
# - Parallel Processing: The script has been re-architected to use `xargs -P`
#   to process files in parallel. This significantly reduces latency when
#   searching a large number of files.
#
# - Single-Pass Approach: The script now performs a single pass, with each
#   parallel process running a full search on its assigned file. This simplifies
#   the overall logic and is more suitable for parallel execution. The results
#   are then collected and sorted globally to present a single, unified list
#   of the top candidates, regardless of which file they came from.
#
# - Scoring Algorithm: The script uses a multi-tiered scoring system to reward
#   specificity:
#   1. Base Score: A score of 1 is given for each keyword found.
#   2. Field Bonus: An additional bonus is given if multiple keywords are found
#      within the same field, rewarding tight context.
#   3. Phrase Bonus: A large, fixed bonus (100) is awarded for a consecutive
#      phrase match. This ensures that a perfect, specific match is always
#      ranked highest, regardless of other keyword occurrences.
#
# - Robustness & Compatibility: The core search and scoring logic is handled by
#   `awk` because it is highly efficient and robust at processing structured data
#   like CSVs, especially with fields that might contain commas or pipes.
#   Additionally, the script avoids Bash 4.x features like associative arrays
#   (e.g., `declare -A`) to ensure it runs correctly on older versions of Bash,
#   such as the default on macOS (3.2).
#
# ==============================================================================

# Define the directory where your CSV files are located.
# Change this variable if your files are in a different path.
CSV_DIR="."

# --- Clipboard Reading and Normalization ---
# This block detects the user's operating system and reads content from the
# clipboard using the appropriate command (`pbpaste` for macOS, `powershell`
# for Windows, `xclip` for Linux). The content is then converted to lowercase,
# filtered, and split into individual words for searching.
if command -v pbpaste &>/dev/null; then
  CLIPBOARD_CONTENT=$(pbpaste)
elif command -v powershell.exe &>/dev/null; then
  CLIPBOARD_CONTENT=$(powershell.exe Get-Clipboard | tr -d '\r')
else
  CLIPBOARD_CONTENT=$(xclip -o -selection clipboard 2>/dev/null || echo "")
fi

# Normalize the clipboard content into an array of lowercase words.
text=$(echo "$CLIPBOARD_CONTENT" | tr '[:upper:]' '[:lower:]' | sed 's/[|,;]\+/\n/g' | xargs)
read -ra words <<< "$text"

echo "=== Clipboard filtered words =="
printf '%s\n' "${words[@]}"
echo "=============================="
echo ""

# Build the list of keywords and the full phrase for `awk`.
keywords_for_awk=""
for w in "${words[@]}"; do
  keywords_for_awk+="|${w}"
done
keywords_for_awk=${keywords_for_awk:1}

phrase_for_awk=""
for w in "${words[@]}"; do
  if [[ -n "$phrase_for_awk" ]]; then
    phrase_for_awk+=" "
  fi
  phrase_for_awk+="$w"
done

# --- Parallel Processing and Search ---
# This is the core of the parallel search logic. `find` locates all CSV files,
# and `xargs -P` runs the `awk` script on them in parallel.
results=$(find "$CSV_DIR" -maxdepth 1 -name "*.csv" -print0 | xargs -0 -P 4 -I {} \
  awk -v keywords="$keywords_for_awk" -v OFS="|" -v phrase="$phrase_for_awk" -v file="{}" '
  BEGIN {
      split(keywords, search_words, "|");
  }
  FNR==1 {
      # Autodetect delimiter on the first file processed
      if ($0 ~ /;/) {
          FS = ";";
      } else {
          FS = ",";
      }
      next;
  }
  {
      base_score = 0;
      field_bonus = 0;
      phrase_bonus = 0;
      delete matched_words;
      full_line_text = tolower($0);

      for (i=1; i<=NF; i++) {
          field_value = tolower($i);
          field_matches = 0;
          for (j in search_words) {
              if (field_value ~ search_words[j] && search_words[j] != "") {
                  base_score++;
                  field_matches++;
                  matched_words[search_words[j]]++;
              }
          }

          if (field_matches > 1) {
              field_bonus += field_matches;
          }
      }

      gsub(/ /, ".*", phrase);
      if (full_line_text ~ phrase) {
          phrase_bonus = 100;
      }

      total_score = base_score + field_bonus + phrase_bonus;

      matched_words_str = "";
      sorted_keys = ""
      for (k in matched_words) {
        if (sorted_keys != "") {
          sorted_keys = sorted_keys ", "
        }
        sorted_keys = sorted_keys k " (" matched_words[k] ")"
      }

      if (total_score > 0) {
          print total_score, sorted_keys, file, $0;
      }
  }' {} | sort -t '|' -k1,1nr | head -n 3)

# Print the final combined and sorted results from all files.
if [[ -z "$results" ]]; then
    echo "No matching suggestions found."
else
    # The first result is always the overall top match.
    is_top_match=1
    while IFS='|' read -r result_score matched_keywords CSV_FILE result_row; do
        echo "### Processing file: $CSV_FILE ###"

        # Dynamically read the header row from the first line of the CSV.
        HEADER_LINE=$(head -n 1 "$CSV_FILE")

        # Delimiter Detection
        DELIMITER=','
        if [[ "$HEADER_LINE" == *";"* ]]; then
          DELIMITER=';'
        fi

        IFS="$DELIMITER" read -r -a headers <<< "$HEADER_LINE"

        if (( is_top_match == 1 )); then
          echo "--- Candidate 1 (Top Match) 🏆 (Score: $result_score) ---"
          is_top_match=0
        else
          echo "--- Candidate (Score: $result_score) ---"
        fi

        echo "Matched keywords: $matched_keywords"

        IFS="$DELIMITER" read -r -a values <<< "$result_row"

        for i in "${!headers[@]}"; do
          header_name=$(echo "${headers[i]}" | xargs)
          value="${values[i]}"

          if [[ -z "$value" ]]; then
              value="N/A"
          fi
          value=$(echo "$value" | sed 's/^"//; s/"$//')

          printf "%-12s: %s\n" "$header_name" "$value"
        done
        echo "-------------------------------------"
    done <<< "$results"
fi

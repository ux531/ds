#!/bin/sh

# ==============================================================================
# SCRIPT: md_to_json.sh
# DESCRIPTION:
# Converts a Markdown file with procedures into a JSON file.
# Now captures numbered steps and any indented substeps correctly.
# ==============================================================================

MD_FILE="./procedures.md"
JSON_FILE="./procedures.json"

if [ ! -f "$MD_FILE" ]; then
    echo "Error: Markdown file not found at $MD_FILE"
    exit 1
fi

awk '
BEGIN {
    in_code_block = 0;
    first_procedure = 1;
    block = "";
    print "{\n  \"procedures\": [";
}

/^[ \t]*```/ {
    in_code_block = !in_code_block;
    if (in_code_block == 0 && block != "") {
        if (!first_procedure) print ",\n";
        first_procedure = 0;
        print "    {";
        split(block, lines, "\n");
        first_section = 1;
        for (i=1; i<=length(lines); i++) {
            line = lines[i];
            gsub(/^[ \t]+|[ \t]+$/, "", line);

            if (line ~ /^# /) {
                name_line = line; sub(/^# /, "", name_line); sub(/:.*$/, "", name_line);
                printf "      \"name\": \"%s\",\n", name_line;
                print "      \"sections\": [";
            } else if (line ~ /^## /) {
                if (!first_section) print "            ]\n        },";
                first_section = 0;
                sub(/^## /, "", line);
                printf "        {\n          \"name\": \"%s\",\n          \"steps\": [\n", line;
                first_step = 1;
            } else if (line ~ /^[0-9]+\. /) {
                if (!first_step) print ",";
                first_step = 0;
                sub(/^[0-9]+\. /, "", line);
                gsub(/"/, "\\\"", line);
                step_text = line;

                # Capture any indented substeps
                substep_block = "";
                j = i+1;
                while (j <= length(lines) && lines[j] ~ /^[ \t]+[-*]/) {
                    subline = lines[j];
                    gsub(/^[ \t]+/, "", subline);
                    gsub(/"/, "\\\"", subline);
                    substep_block = substep_block "\\n  " subline;
                    j++;
                }
                step_text = step_text substep_block;
                i = j-1;
                printf "            \"%s\"", step_text;
            }
        }
        print "\n            ]\n        }\n      ]\n    }";
        block = "";
    }
    next;
}

{ if (in_code_block) block = block "\n" $0 }

END { print "\n  ]\n}" }
' "$MD_FILE" > "$JSON_FILE"

echo "Conversion complete. JSON data written to $JSON_FILE"
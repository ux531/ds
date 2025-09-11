# IT Procedures

## Overview

This project provides a command-line tool to efficiently search IT procedures stored in Markdown files. It converts Markdown content into structured JSON, scores matches intelligently (even for mixed Cyrillic and English input), and displays the top candidate procedures for quick access.

## File Structure

```
.
├── index.sh              # CLI script to search procedures
├── procedure_parser.sh   # Converts Markdown procedures to JSON
├── procedures.json       # Structured data generated from Markdown
└── procedures.md         # Source Markdown file containing procedures
```

## Workflow Map (ASCII)

```
procedures.md
     │
     ▼
procedure_parser.sh
     │
     ▼
procedures.json
     │
     ▼
index.sh (CLI)
     │
     ▼
Top 3 candidates
     │
     ▼
Press Enter → Full procedure output
```

## How it Works

1. **Markdown to JSON:** `procedure_parser.sh` reads `procedures.md`, including sections, substeps, and keywords, and converts it into `procedures.json`.
2. **Search CLI:** `index.sh` accepts input via command-line arguments or clipboard, normalizes text, and searches through the JSON.
3. **Scoring:**

   * Matches keywords, section names, step text, and procedure names.
   * Assigns weighted scores to prioritize more relevant results.
   * Exact phrase matches get a high bonus to rank top.
   * Supports Unicode (Cyrillic and English).
4. **Top 3 Candidates:** Displays top 3 candidates with matched keywords.
5. **Top Procedure:** Press Enter to display the full procedure for the top-ranked candidate, including substeps.

## Usage Examples

```
$ ./index.sh remote swift
=== Filtered input words ===
remote
swift
===========================

=== Top Candidates ===
--- Candidate 1 (Top Match) 🏆 ---
Name   : Сбо Remote Overwrite with Swift Бисера
Matched: remote, swift
-------------------------------------
--- Candidate (Score: 14) ---
Name   : Archimed - Access to SWIFT Transactions
Matched: swift
-------------------------------------
--- Candidate (Score: 10) ---
Name   : Access to CLAVIS
Matched: swift
-------------------------------------
Show procedure for 'Сбо Remote Overwrite with Swift Бисера' or exit
```

## Scoring & Matching Logic

* **Keywords:** Matches in `## keywords:` sections get higher weight.
* **Procedure Name:** Matches in the procedure title.
* **Section Name:** Matches in sections like keywords or other relevant headings.
* **Steps:** Matches in detailed instructions.
* **Exact Phrase:** Bonus score for the full phrase in order.
* **Unicode Support:** Works with Cyrillic, English, and mixed-language inputs.
* **Substeps:** All nested substeps are preserved and displayed.

## Notes & Pitfalls Considered

* Avoids misranking when Cyrillic words are used by applying Unicode-safe lowercasing.
* Preserves Markdown substeps when converting to JSON.
* Limits output to top 3 candidates to prevent overwhelming the user.
* Only shows full procedure for top candidate to reduce noise.
* Ensures input from clipboard or command-line arguments is normalized consistently.

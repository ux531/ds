# DSK Procedures Parser & Search Tool

## Overview

This project provides a **PowerShell-based parser and search tool** for managing DSK bank procedures stored in a Markdown file. It converts human-maintained Markdown procedure files into a structured JSON format, and allows searching through procedures based on keywords, names, and steps, including Cyrillic and English content.  

It is designed to be **robust, human-maintainable, and flexible** while maintaining minimal dependencies.  

---

## Features

- Converts `procedures.md` into `procedures.json` using clearly defined markers.
- Supports Unicode input (Cyrillic + English).
- Detects procedure name `[pn]`, keywords `[kw]`, procedure steps `[pr]`, replies `[re]`, and extra steps `[ext]`.
- `[pn]`, `[kw]`, and `[pr]` dominate scoring to determine the best candidate for search queries.
- `[re]` sections are captured but **not scored**, preserving replies without `-` bullet points.
- Supports interactive search via PowerShell.
- Displays top 3 matching procedures with matched words highlighted.
- Preserves original Markdown step formatting in output.

---

## Markdown Structure

Each procedure in the Markdown file is wrapped in:

```

\--- >
...
\--- <

````

### Supported markers:

| Marker | Purpose | Notes |
|--------|---------|-------|
| `[pn]` | Procedure Name | Main identifier, dominates scoring |
| `[kw]` | Keywords | High-weight search criteria |
| `[id]` | Procedure ID | Unique identifier |
| `[pr]` | Procedure Steps | Steps that are searched and scored |
| `[re]` | Replies | Captured as text but **not scored** |
| `[ext]` | Extra Steps | Included in scoring, low weight |
| `[other]` | Misc / fallback | Future extension |

**Example Procedure:**

```markdown
--- >

## [pn] Reset / Ресет пароли
### [kw] Keywords: Reset; Ресет; password reset; password; парола; акаунт; unlock
#### [id] R000002

### [pr] Procedure
- В AD ресет на паролата и задаване на default.
- Формат: SiLn@<timestamp>.

### [re] Email шаблон
- Акаунтът е възстановен.
- Назначена е нова парола SiLn@Parola1214 за AD, която трябва да се смени след първо влизане.
- Паролата се назначава от администратора.

--- <
````

---

## JSON Output Structure

After parsing, each procedure is represented as:

```json
{
    "name": "Reset / Ресет пароли",
    "id": "R000002",
    "keywords": "Reset; Ресет; password reset; password; парола; акаунт; unlock",
    "sections": [
        {
            "steps": [
                "- В AD ресет на паролата и задаване на default.",
                "- Формат: SiLn@<timestamp>."
            ]
        },
        {
            "reply": "Email шаблон",
            "steps": [
                "- Акаунтът е възстановен.",
                "- Назначена е нова парола SiLn@Parola1214 за AD, която трябва да се смени след първо влизане.",
                "- Паролата се назначава от администратора."
            ]
        }
    ]
}
```

---

## Scoring Algorithm

The search tool computes a **score per procedure** based on the query:

* `[pn]`, `[kw]`, `[pr]` matches: **100 points each**
* `[ext]` matches: 1 point each
* `[re]` matches: 0 points (ignored)

### Steps:

1. Input is normalized (lowercase, punctuation removed, split into words).
2. Each word is compared against procedure name, keywords, steps, and extra steps.
3. Matching keywords add high weight; partial matches in steps add low weight.
4. Results are sorted descending by score.
5. Top 3 candidates are displayed.

---

## Usage

### Parsing Markdown

```powershell
.\parser.ps1
```

* Converts `procedures.md` to `procedures.json`.
* Captures all markers (`[pn]`, `[kw]`, `[id]`, `[pr]`, `[re]`, `[ext]`).

### Searching Procedures

```powershell
.\index.ps1 <search-term>
```

* Example: `.\index.ps1 cas`
* If no search term is provided, clipboard content is used.
* Displays top 3 matching procedures and optionally prints full procedure steps.

---

## Design Notes

* The parser **does not rely on Markdown heading levels** (`##`, `###`) – only markers matter.
* `[re]` sections capture replies with or without bullet points.
* Extensible: add `[ext]` or `[other]` for future types of sections.
* Fully Unicode-safe for Cyrillic and English content.
* JSON output is human-readable and easy to extend for automation.

---

## Example Search

Input query:

```
cas
```

* `[kw]` in *DK / LOS groups (Кредитни карти – CAS)* matches → +100 points
* Extra steps in other procedures containing “CASH” → +1 each
* Result: top candidate is correctly `DK / LOS groups (Кредитни карти – CAS)`

---

## Flow Diagram

```
┌─────────────┐
│ Input Text  │
└─────┬───────┘
      │ Normalize & split words
      ▼
┌─────────────┐
│ Load JSON   │
└─────┬───────┘
      │ For each procedure
      ▼
┌─────────────┐
│ Collect     │
│ keywords,   │
│ steps, ext  │
└─────┬───────┘
      │ Score
      ▼
┌─────────────┐
│ Sort top 3  │
└─────┬───────┘
      │ Display
      ▼
┌─────────────┐
│ Optional:   │
│ Full output │
└─────────────┘


# Automated SVOD Template Creation - Business and Technical Documentation

## 1. Executive Summary

The SVOD automation supports template creation by collecting metadata from multiple sources, standardizing it, matching it to Foundry where needed, and generating client-ready SVOD template outputs. The business reference document explains that SVOD template creation is time-consuming because metadata must be collected across multiple languages and consolidated into a single sheet for each series or movie.

The automation is intended to reduce manual effort by dynamically handling multiple metadata sources such as WBTV, WB2B, and FOUNDRY, then generating templates based on the available source combinations.

> Source basis: This documentation combines the visible SVOD source extract with the business workflow described in `Automation Projects Documenation - Data Governance Team.pdf`.

---

## 2. Business Problem

The SVOD template creation process requires collecting metadata that satisfies client requirements, such as Amazon. The reference document states that this involves collecting data from multiple sources across different languages and consolidating them into one sheet for each series or movie.

The manual challenge increases as the number of requested languages increases in an SVOD request.

---

## 3. Business Solution

The reference workflow describes an automation solution that generates SVOD templates using available metadata source combinations. Example source combinations include:

- WBTV + FOUNDRY
- WB2B + FOUNDRY
- Only WB2B
- Other combinations

The solution dynamically detects available sources and runs the appropriate processing logic based on the input files.

---

## 4. Tools Used

| Tool | Purpose |
|---|---|
| Python | Core scripting and automation. |
| Transformers / AI Models | Semantic matching and title comparison. |
| SentenceTransformer("all-MiniLM-L6-v2") | Used for semantic title matching. |
| CrossEncoder("cross-encoder/stsb-distilroberta-base") | Used for deeper pairwise title comparison. |

---

## 5. End-to-End Workflow From Business Reference

### Step 1: Metadata Collection

Metadata is collected from:

- WBTV
- WB2B
- FOUNDRY

### Step 2: Input Preparation

All source files are placed into a single input folder. The script identifies available sources and decides the appropriate processing logic based on the inputs.

### Step 3: Data Cleaning and Standardization

The automation retains only required columns, removes unnecessary columns, and preserves data types across input files to maintain consistency.

### Step 4: Base SVOD Template Creation

English metadata from WBTV, WB2B, or FOUNDRY is used to create the base SVOD template format.

### Step 5: Metadata Merging

The base SVOD file is merged with localized language metadata from FOUNDRY.

The reference document describes two matching approaches:

1. Structured Matching for Series and Seasons
   - Uses season number and episode number.
2. Semantic Matching for Episodes
   - Used when structured matching is insufficient.
   - Uses `SentenceTransformer("all-MiniLM-L6-v2")` and `CrossEncoder("cross-encoder/stsb-distilroberta-base")`.
   - Titles are first matched within the same season.
   - If no match is found, the search expands across all seasons.
   - For generic episode titles, structured matching is prioritized.

### Step 6: Intermediate Output

The intermediate output includes:

- Titles
- Synopses, including all variations
- UUIDs
- Match types that indicate how the match was derived

### Step 7: Analyst Validation

The analyst reviews the output for accuracy. Once validated, UUIDs act as unique identifiers and are used to merge additional localized language CSVs from FOUNDRY.

### Step 8: Character Limit Processing

The reference document identifies these synopsis limits:

- Short synopsis: up to 150 characters
- Long synopsis: up to 400 characters

The visible SVOD main script has been updated for dynamic synopsis limits, meaning the user can enter the required limits at runtime instead of relying only on hardcoded short/long logic.

### Step 9: Final Output Generation

The final output includes:

- Separate sheets for each language template
- An Info Sheet summarizing missing metadata and synopsis character-limit violations

### Step 10: Final Review

The analyst performs final validation before delivering the SVOD template to the client.

---

## 6. Technical Source Files Reviewed

| File | Role |
|---|---|
| `SVOD_Functions.txt.txt` | Contains visible imports, model path constants, model initialization class, Foundry loading signature, and movie matching wrapper. |
| `SVOD_main.txt.txt` | Contains visible main script flow for prompts, pipeline execution, verification CSV output, helper function signatures, and template creation gate. |
| `Automation Projects Documenation - Data Governance Team.pdf` | Provides business workflow and expected SVOD automation behavior. |

---

## 7. Technical Flow Based on Available Source

```text
Start main script
  -> import libraries
  -> configure logger
  -> instantiate matching_pipeline
  -> collect dynamic synopsis limits
  -> ask content type
  -> run template pipeline
  -> select output folder
  -> write verification CSV
  -> analyst validates CSV
  -> continue to English/multilanguage template creation
```

---

## 8. Important Source Completeness Note

The available `SVOD_Functions.txt.txt` extract does not expose full implementations for several functions that the business reference implies should exist, such as loaders for WBTV and WB2B. It exposes only:

- imports
- `MODEL_PATH`
- `CROSS_PATH`
- `initial_class.__init__()`
- `load_foundry(...)` signature
- `matching_pipeline` class header
- `match_wbtv_to_foundry_movies(...)`

For complete function-by-function documentation of `load_WBTV`, `load_WB2B`, or similar source loaders, the full original Python code is required.

# Smart Title Matching (STM) - Business and Technical Documentation

## 1. Executive Summary

Smart Title Matching (STM) is an automation framework designed to identify existing or duplicate title records when a unique identifier is not available. The business documentation explains that manual title research may be manageable for small volumes, but becomes inefficient when the volume increases to 1,000-2,000+ records. The automation reduces manual effort by combining Snowflake-based candidate retrieval, Python orchestration, transformer-based semantic matching, rule-based classification, and analyst review.

The system uses a layered matching approach:

1. Snowflake retrieves and ranks possible candidates using title-similarity functions.
2. Python converts the Snowflake result into dataframes.
3. SentenceTransformer generates semantic similarity scores.
4. CrossEncoder performs deeper pairwise semantic scoring.
5. A rule engine separates results into Top Matches, Potential/Partial Matches, and No Matches.
6. Analysts review the results and decide whether a title already exists or a new profile should be created.

---

## 2. Business Problem

The main business problem is identifying existing or duplicate records using only titles, without unique identifiers. The reference documentation states that a small data volume, such as around 50-100 records, can be handled manually through research. However, larger volumes such as 1,000-2,000+ records become time-consuming and inefficient for a single analyst, slowing the overall process.

In practical terms, the problem is not just matching text. Analysts must determine whether an input title already exists in ATOM or whether a new profile is required. This creates risk because manual review can be slow, inconsistent, and difficult to scale.

---

## 3. Business Solution

STM solves this by automating candidate retrieval, scoring, ranking, and classification. The business documentation describes the solution as an automated approach where input titles, with optional year depending on IP type, are processed to generate possible matches. These matches are partitioned and ranked to identify the most relevant results.

The automation does not fully remove analyst judgment. Instead, it reduces the search space and presents structured output for review. Analysts then validate Top Matches and Potential Matches before deciding whether to use an existing ATOM record or create a new profile.

---

## 4. Tools Used

| Tool | Purpose |
|---|---|
| Snowflake | Integrated into the Python script for data retrieval and preprocessing. |
| Python | Used as the core programming language for processing, orchestration, dataframe handling, and output generation. |
| Transformers | Used for AI-based semantic title matching. |
| SentenceTransformer `all-MiniLM-L6-v2` | Converts input and ATOM titles into vector embeddings for similarity comparison. |
| CrossEncoder `cross-encoder/stsb-roberta-base` | Performs deeper semantic comparison by evaluating title pairs together. |
| Pandas | Used in the script workflow for dataframe creation, transformation, scoring output, and Excel preparation. |
| XlsxWriter / ExcelWriter | Used by the helper functions to create formatted Excel output sheets. |

---

## 5. End-to-End Business Workflow

### Step 1: Snowflake Layer

The business documentation states that data is retrieved from the ATOM_BI table. SQL processing identifies potential matches using Jaro-Winkler (JW) and Edit Distance (ED), which are distance metric functions used to measure similarity between two titles.

Each input title is partitioned and ranked based on similarity scores. The business documentation states that the top 20 closest matches are selected for each title. The STM workflow documentation also shows that the script uses a ranked candidate query and keeps candidates using ranking logic before Python-based AI scoring. If production behavior differs, confirm the current SQL limit in the active script.

### Step 2: Layer 1 - Initial AI Matching

The Snowflake output is converted into a pandas DataFrame in Python. Predefined functions apply `SentenceTransformer("all-MiniLM-L6-v2")`, which converts input titles and ATOM titles into vector embeddings and performs pairwise similarity comparison.

This layer reduces the candidate set before deeper scoring. The business document describes this as improving processing speed by filtering and reducing candidate titles passed to the next stage.

### Step 3: Layer 2 - Advanced Semantic Matching

Filtered results are passed to `CrossEncoder("cross-encoder/stsb-roberta-base")`. A CrossEncoder evaluates two titles together, which allows deeper contextual comparison than embedding-only similarity.

The CrossEncoder generates a refined score for candidate pairs and supports better decision-making for borderline or ambiguous title matches.

### Step 4: Layer 3 - Rule Engine

The rule engine classifies candidate matches into output categories. The business documentation lists three output sheets:

1. Top Matches
2. Potential Matches
3. No Matches

The STM script workflow documentation describes the final output as Top Match, Partial Match, and No Match sheets. These naming differences should be treated as output-label differences, not necessarily different concepts.

### Step 5: Decision Layer

This is the final analyst review step. The analyst reviews Top Matches and Potential/Partial Matches and decides whether the matching title already exists in ATOM or whether a new profile needs to be created.

---

## 6. Technical Architecture

### High-Level Architecture

```text
Excel input
  -> input mode selection
  -> title preparation and normalization
  -> Snowflake candidate retrieval
  -> semantic scoring with SentenceTransformer
  -> CrossEncoder validation
  -> rule-based decision logic
  -> ranking and explainability columns
  -> formatted Excel output
  -> analyst decision
```

### Key Technical Layers

| Layer | Responsibility |
|---|---|
| Input Layer | Reads Excel input and prepares title fields based on selected IP mode. |
| Snowflake Retrieval Layer | Retrieves candidate records from ATOM metadata and ranks likely candidates. |
| Semantic Matching Layer | Uses SentenceTransformer embeddings to calculate similarity scores. |
| CrossEncoder Layer | Applies deeper pairwise scoring to candidate title pairs. |
| Rule Engine Layer | Converts scores and business rules into match labels. |
| Output Layer | Produces formatted Excel sheets for analyst review. |

---

## 7. Processing Modes

The STM script workflow references three user-selected modes:

| Mode | Meaning / Use |
|---|---|
| `S` | Standalone processing. |
| `SE` | Series processing. |
| `ALL` | Series, Season, and Episodic processing. |

The workflow documentation shows that the selected mode controls title preparation, IP category filtering, candidate separation, scoring logic, and final output formatting.

---

## 8. Main Script Workflow Blocks

### Stage 1: Startup Imports and Helper Initialization

The script loads libraries for pandas, transformer models, warnings, file selection, OS operations, torch, tokenizer support, numpy, system utilities, and logging. It imports `all_functions` from `Packages.functions` and initializes `smart_title_matching_functions`.

### Stage 2: Processing Mode and IP Category Definitions

The script prompts the analyst to enter the IP category, using values such as `SE`, `S`, and `ALL`. It also defines IP category groupings for Series, Standalone, Seasons, Episodic, and combined Series/Season/Episode workflows.

### Stage 3: Input Workbook Selection and Loading

The script opens a file picker dialog and reads the selected Excel workbook into a pandas DataFrame. It preserves a copy of the original input as `INPUT_TITLES_0`.

### Stage 4: S and SE Preprocessing With AKA Expansion

For standalone or series-only modes, the script splits the `Features` field into multiple searchable rows using AKA expansion. This increases candidate recall because alternate titles are searched independently.

### Stage 5: ALL Mode Hierarchy-Aware Title Construction

When `ALL` mode is selected, the script builds `MATCH_TITLE_RAW` differently for series, season, and episode rows. Episodes can be enriched with series and season/episode context so generic titles such as “Episode 1” are less ambiguous.

### Stage 6: Title Normalization and SQL VALUES Payload Creation

Prepared titles are normalized and escaped for SQL usage. The script creates a Snowflake-friendly `VALUES` payload from the input titles and years.

### Stage 7: Snowflake Connection and Query Filter Setup

The script creates a Snowflake connection and prepares IP category filters and parent/child filters based on the selected processing mode.

### Stage 8: Snowflake Candidate Retrieval SQL

The SQL retrieves candidate records from ATOM metadata, builds hierarchy information, compares input words against title words, uses year and generic-title compatibility checks, and ranks candidates with similarity functions such as Jaro-Winkler and Edit Distance.

### Stage 9: Execute Snowflake Query and Build Candidate DataFrame

The query output is converted into `SnowFlake_Results`, a pandas DataFrame used for downstream matching.

### Stage 10: Separate Candidates by Processing Mode

The script separates candidates into different DataFrames depending on the selected mode. In `ALL` mode, it separates Series, Season, and Episode candidates.

### Stage 11: Output Folder and Model Setup

The script selects an output folder, loads `SentenceTransformer("all-MiniLM-L6-v2")`, sets the CrossEncoder model name, and prepares tokenizer configuration.

### Stage 12: Dynamic Token-Length Estimation and CrossEncoder Loading

The script estimates token lengths from actual candidate title pairs and sets CrossEncoder `max_length` accordingly. This helps handle longer candidate pairs while keeping model execution practical.

### Stage 13: S and SE Semantic Scoring and Final Decision Flow

For S and SE modes, the script normalizes input and ATOM titles, computes semantic scores, applies CrossEncoder scoring, generates final match labels, and adds explainability fields.

### Stage 14: S and SE Top, Partial, and No-Match Preparation

The script prepares Top Match, Partial Match, and No Match outputs. It keeps the strongest candidates, ranks them by input ID, and separates unresolved records into the No Match sheet.

### Stage 15: ALL Mode Series-First Scoring and Selection Workbook

In ALL mode, the script scores series candidates first and creates `Series_Selection.xlsx`. The analyst selects the correct parent series before child records are scored.

### Stage 16: ALL Mode Selected-Series Filtering and Child Scoring

The script reads selected parent series, filters season and episode candidates by selected parents, and scores child records.

### Stage 17: ALL Mode Ranking, Partial Matches, and No-Match Preparation

The selected series and scored child records are combined, ranked, and separated into Top Match, Partial Match, and No Match outputs.

### Stage 18: Final Excel Export

The script writes final output to `Output.xlsx`, with sheets for Top Match, Partial Match, and No Match. Helper formatting methods apply grouped headers, formatting, filters, column widths, hyperlinks, and styled identifier fields.

---

## 9. Important Functions and Logic Areas

### `split_aka()`

Splits a title field into multiple searchable values when AKA patterns or separators exist. This improves recall when titles have alternate names.

### `normalize_title()`

Standardizes title text by handling casing, accents, punctuation, version labels, trailing years, and whitespace. Normalization improves SQL lookup and semantic scoring consistency.

### `genric_merger()`

Enriches generic episode titles with series, season, and episode context. This is important for titles like “Episode 1,” which may exist across many series.

### `get_connection()`

Creates a Snowflake connection used to retrieve ATOM metadata.

### `apply_cross_encoder()`

Applies CrossEncoder scoring to candidate title pairs within a defined semantic score range.

### `final_decision()`

Combines semantic score, CrossEncoder score, numeric checks, season/episode extraction, and extra-word checks into match labels such as Perfect Match, Possible Match, and Reject.

### `combined_match_logic()`

Combines multiple signals in hierarchy-aware matching, especially for parent/child relationships in ALL mode.

### `top_n_per_id()`

Keeps the strongest candidates per input ID while preserving very high-confidence candidates.

### `add_explainability_columns()`

Adds analyst-friendly columns such as confidence, final reason, and match evidence.

### `write_series_selection_file()`

Creates the intermediate Series Selection workbook used in ALL mode for analyst validation of parent series.

### `apply_grouped_formatting()`

Writes match outputs into formatted Excel sheets with grouped headers, widths, hyperlinks, identifier formatting, and ingestion-priority logic.

---

## 10. Inputs, Outputs, and Side Effects

### Inputs

| Input | Description |
|---|---|
| Excel workbook | Input titles and optional year/IP information. |
| IP category | User-selected processing mode such as S, SE, or ALL. |
| Snowflake ATOM metadata | Candidate source for title matching. |
| Analyst Series Selection | Used in ALL mode to validate parent series. |

### Outputs

| Output | Description |
|---|---|
| `Series_Selection.xlsx` | Intermediate workbook for parent series validation in ALL mode. |
| `Output.xlsx` | Final workbook containing Top Match, Partial Match, and No Match sheets. |
| `Smart.log` | Log file created by the STM script. |

### Side Effects

- Opens file dialogs.
- Connects to Snowflake.
- Executes Snowflake SQL.
- Loads transformer models.
- Writes Excel output files.
- Opens intermediate Excel file for analyst review in ALL mode.

---

## 11. Key Concepts Explained

### Jaro-Winkler Similarity

Jaro-Winkler is used in the Snowflake layer to measure title similarity and rank likely matches before AI scoring.

### Edit Distance

Edit Distance measures how many character-level changes are needed to convert one title into another. It supports candidate ranking in Snowflake.

### SentenceTransformer Embeddings

SentenceTransformer converts titles into numerical vectors. Similar titles should produce vectors that are close together, allowing cosine similarity to estimate semantic closeness.

### CrossEncoder Pairwise Scoring

A CrossEncoder evaluates two titles together, which can better understand context and meaning than comparing separately encoded embeddings.

### Rule Engine

The rule engine applies business logic after scoring. It considers scores, numbers, season/episode values, extra words, and hierarchy consistency before assigning a match label.

### Analyst-in-the-Loop Validation

STM does not fully automate final business decisions. It reduces candidate volume and presents ranked evidence so the analyst can validate outcomes.

---

## 12. Reuse and Adaptation Guide

### Reuse the matching framework in another project

The STM pattern can be reused anywhere title-like records must be matched without unique IDs:

```text
Input records
  -> candidate retrieval
  -> text normalization
  -> embedding similarity
  -> pairwise CrossEncoder scoring
  -> business rules
  -> ranked analyst output
```

### Parameterize configuration

Move values such as Snowflake account details, model names, thresholds, output filenames, and IP category mappings into a config file.

### Separate script blocks into functions

The main script can be refactored into reusable functions:

- `load_input_file()`
- `prepare_titles()`
- `build_snowflake_query()`
- `execute_candidate_query()`
- `score_candidates()`
- `prepare_outputs()`
- `write_output_workbook()`

### Add stronger validation

Validate required input columns before processing. For example:

```python
def validate_columns(df, required_columns, dataframe_name):
    missing = [col for col in required_columns if col not in df.columns]
    if missing:
        raise ValueError(f"{dataframe_name} is missing required columns: {missing}")
```

---

## 13. Risks, Assumptions, and Improvements

| Area | Risk | Suggested Improvement |
|---|---|---|
| Hardcoded Snowflake connection values | Script is harder to reuse and maintain. | Move connection values to config or environment variables. |
| Interactive prompts | Workflow is difficult to automate. | Add command-line arguments or config-driven execution. |
| Model download/loading | Runtime may fail if model access is unavailable. | Cache models or configure local paths. |
| Manual series selection | Required for ALL mode continuity. | Keep analyst validation, but document expected selection behavior clearly. |
| Output terminology | Business doc says Potential Matches; script docs say Partial Match. | Standardize terminology across documentation and output sheets. |
| Candidate limits | Business doc says top 20; script workflow shows candidate ranking and script-specific limits. | Confirm current production SQL and align documentation. |

---

## 14. Appendix: Glossary

| Term | Meaning |
|---|---|
| STM | Smart Title Matching. |
| ATOM | Metadata source used for candidate retrieval. |
| JW | Jaro-Winkler similarity. |
| ED | Edit Distance. |
| S | Standalone processing mode. |
| SE | Series processing mode. |
| ALL | Series, Season, and Episodic processing mode. |
| Top Match | Highest-confidence candidate output set. |
| Partial / Potential Match | Candidate output requiring analyst review. |
| No Match | Input records where no suitable match was found. |
| CrossEncoder | Transformer model that scores title pairs together. |
| SentenceTransformer | Transformer model that creates embeddings for title similarity. |

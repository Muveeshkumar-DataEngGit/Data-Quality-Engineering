# STM Functions Package - Detailed Function Notes Above Code

This document analyzes each complete function before showing its code. It is designed for KT, maintenance, and developer handover.

## Function index

- `__init__()` lines 26-28
- `set_writer()` lines 30-385
- `extract_season_episode()` lines 388-428
- `confidence_bucket()` lines 431-445
- `get_match_reason()` lines 448-498
- `build_match_evidence()` lines 501-530
- `add_match_ranking()` lines 533-556
- `add_explainability_columns()` lines 558-595
- `split_aka()` lines 598-630
- `normalize_title()` lines 633-660
- `open_excel_file()` lines 663-672
- `write_series_selection_file()` lines 675-1229
- `try_number_preserve_decimals()` lines 791-822
- `extract_tt()` lines 1073-1077
- `rowwise_cosine()` lines 1232-1235
- `select_output_folder()` lines 1239-1268
- `genric_merger()` lines 1271-1307
- `get_connection()` lines 1311-1319
- `apply_cross_encoder()` lines 1326-1340
- `extra_word_ratio()` lines 1344-1349
- `extract_numbers()` lines 1352-1358
- `numbers_match()` lines 1360-1361
- `final_decision()` lines 1367-1413
- `combined_match_logic()` lines 1420-1516
- `top_n_per_id()` lines 1520-1533
- `filter_group()` lines 1523-1527
- `flatten_groups()` lines 1536-1540
- `try_number_preserve_decimals()` lines 1543-1585
- `convert_columns_try_number_preserve_decimals()` lines 1587-1591
- `apply_grouped_formatting()` lines 1594-1769
- `extract_tt()` lines 1683-1687
- `format_no_match()` lines 1771-1793
- `score_series_matches()` lines 1795-1874
- `score_child_matches()` lines 1877-2039
- `filter_children_by_selected_series()` lines 2042-2072

---

## `__init__()`

**Source lines:** 26-28

**Function signature inputs:** `self`

**Purpose:** Initializes instance-level state used by Excel-writing helper methods.

**Why this function is used in STM:** Several formatting methods need access to the active Excel writer and workbook. Keeping these as instance attributes avoids passing them repeatedly between helper methods.

**Inputs explained:** No external input except the new class instance.

**Outputs / side effects:** Prepared `all_functions` object with writer/workbook placeholders.

**Detailed algorithm / logic:**
- Sets `self.writer` to `None` until an ExcelWriter is provided.
- Sets `self.workbook` to `None` until workbook formatting is initialized.

**Important values created or updated:** `workbook, writer`

**Maintenance guidance:** Before changing this function, verify every downstream usage in the STM script and update related tests, especially if column names, thresholds, return shape, workbook formatting, or decision labels change.

```python
    def __init__(self):
        self.writer = None
        self.workbook = None
```

---

## `set_writer()`

**Source lines:** 30-385

**Function signature inputs:** `self, writer`

**Purpose:** Registers an active pandas ExcelWriter and builds reusable xlsxwriter formatting objects.

**Why this function is used in STM:** All output sheets need consistent colors, headers, borders, protection settings, dropdown styling, and section formatting. Defining formats once keeps output workbooks consistent.

**Inputs explained:** A live `pd.ExcelWriter` object using xlsxwriter.

**Outputs / side effects:** Updates instance state with writer, workbook, and formatting objects.

**Detailed algorithm / logic:**
- Stores the writer and workbook on the class instance.
- Creates reusable workbook formats for headers, locked/unlocked cells, subheaders, dropdowns, and grouped sections.
- Makes these formats available to downstream methods that write output sheets.

**Important calls detected inside:** `add_format`

**Important values created or updated:** `FIXED_WIDTHS, GROUPS, IMDB_BASE_URL, INGESTION_PRIORITY_LABELS, MAX_COL_WIDTH, MIN_COL_WIDTH, NUM_COERCE_COLS, RELTIO_BASE_URL, border_format, group_band_format, group_formats, header_format, header_format_match, id_green, id_yellow, link_format, no_id_red_format, pipe_red_format, workbook, writer`

**Maintenance guidance:** Before changing this function, verify every downstream usage in the STM script and update related tests, especially if column names, thresholds, return shape, workbook formatting, or decision labels change.

```python
    def set_writer(self, writer):
        self.writer = writer
        self.workbook = writer.book
        # -----------------------------
        # 1) Define column grouping rules (your requirement)
        # -----------------------------
        self.GROUPS = {

            "STANDALONE": [
                (
                    "MATCHED OUTPUT",
                    [
                        "ID",
                        "INPUT_TITLES",
                        "ATOM_TITLE",
                        "INPUT_YEAR",
                        "YEARS",
                        "TT_CODES",
                    ]
                ),

                (
                    "STANDALONE INFO",
                    [
                        "IP_TYPE",
                        "NODE_IDENTIFIER",
                        "LIBRARY_TITLE_FULL"
                    ]
                ),

                (
                    "PARENT INFO",
                    [
                        "PARENT_TITLE",
                        "PARENT_ENTITY",
                        "PARENT_MPM",
                    ]
                ),

                (
                    "SCORES",
                    [
                        "FINAL_SCORE",
                        "SEMANTIC_SCORE",
                        "MATCH_LEVEL",
                        "CONFIDENCE",
                        "FINAL_REASON",
                        "MATCH_RANK",
                        "MATCH_EVIDENCE",
                    ]
                ),

                (
                    "IDENTIFIERS",
                    [
                        "MPM_NUMBER",
                        "PI_UUID",
                        "PROPERTY_ID",
                        "HBO_ID",
                        "META_ID",
                        "TURNER_TITLEID",
                        "MMS3_MCODE",
                        "DASH_TITLE_ID",
                        "ALEPH_ID",
                        "IBROADCAST_EMEA_ID",
                        "IBROADCAST_APAC_ID",
                        "For Ingestion",
                    ]
                ),
            ],

            "SERIES": [
                (
                    "MATCHED OUTPUT",
                    [
                        "ID",
                        "INPUT_TITLES",
                        "ATOM_TITLE",
                        "INPUT_YEAR",
                        "YEARS",
                        "TT_CODES",
                    ]
                ),

                (
                    "SERIES INFO",
                    [
                        "IP_TYPE",
                        "NODE_IDENTIFIER",
                        "LIBRARY_TITLE_FULL",
                        "CHILDREN_STATUS",
                    ]
                ),

                (
                    "SCORES",
                    [
                        "FINAL_SCORE",
                        "SEMANTIC_SCORE",
                        "MATCH_LEVEL",
                        "CONFIDENCE",
                        "FINAL_REASON",
                        "MATCH_RANK",
                        "MATCH_EVIDENCE",
                    ]
                ),

                (
                    "IDENTIFIERS",
                    [
                        "MPM_NUMBER",
                        "PI_UUID",
                        "HBO_ID",
                        "META_ID",
                        "TURNER_TITLEID",
                        "MMS3_MCODE",
                        "DASH_TITLE_ID",
                        "ALEPH_ID",
                        "IBROADCAST_EMEA_ID",
                        "IBROADCAST_APAC_ID",
                        "For Ingestion"
                    ]
                ),
            ],

           "EPISODICS": [

            (
                "MATCHED OUTPUT",
                [
                    "ID",
                    "SERIES_TITLE",
                    "PARENT_TITLE",
                    "INPUT_TITLE",
                    "ATOM_TITLE",
                    "INPUT_YEAR",
                    "YEARS",
                    "TT_CODES",
                ]
            ),

            (
                "CONTENT INFO",
                [
                    "IP_TYPE",
                    "NODE_IDENTIFIER",
                    "LIBRARY_TITLE_FULL"
                ]
            ),

            (
                "PARENT INFO",
                [
                    "PARENT_ENTITY",
                    "PARENT_MPM",
                    "CHILDREN_STATUS"
                ]
            ),

            (
                "SCORES",
                [
                    "FINAL_SCORE",
                    "MATCH_LEVEL",
                    "CONFIDENCE",
                    "FINAL_REASON",
                    "MATCH_RANK",
                    "MATCH_EVIDENCE",
                ]
            ),

            (
                "IDENTIFIERS",
                [
                    "MPM_NUMBER",
                    "MPM_PRODUCT_NUMBER",
                    "PI_UUID",
                    "PROPERTY_ID",
                    "HBO_ID",
                    "META_ID",
                    "TURNER_TITLEID",
                    "MMS3_MCODE",
                    "DASH_TITLE_ID",
                    "ALEPH_ID",
                    "IBROADCAST_EMEA_ID",
                    "IBROADCAST_APAC_ID",
                    "For Ingestion",
                ]
            ),
        ]

        }

        # ✅ Priority columns + EXACT output labels you want
        self.INGESTION_PRIORITY_LABELS = [
            ("MPM_NUMBER",          "MPM_Number"),
            ("PI_UUID",             "PI_UUID"),
            ("PROPERTY_ID",         "Property_ID"),
            ("HBO_ID",              "HBO_ID"),
            ("META_ID",             "Meta_ID"),
            ("TURNER_TITLEID",      "Turner_TitleID"),
            ("MMS3_MCODE",          "MMS3_MCode"),
            ("DASH_TITLE_ID",       "DASH_Title_ID"),
            ("ALEPH_ID",            "Aleph_ID"),
            ("IBROADCAST_EMEA_ID",  "iBroadcast_EMEA_ID"),
            ("IBROADCAST_APAC_ID",  "iBroadcast_APAC_ID"),
        ]

        # ✅ Columns to normalize to numeric where possible:
        # - int if integer-like
        # - float if decimal
        # - else keep original
        self.NUM_COERCE_COLS = [
            "PROPERTY_ID",
            "HBO_ID",
            "META_ID",
            "TURNER_TITLEID",
            "MMS3_MCODE",
            "DASH_TITLE_ID",
            "ALEPH_ID",
            "IBROADCAST_EMEA_ID",
            "IBROADCAST_APAC_ID",
            "PARENT_MPM",
            "YEARS",
        ]
        # Base URLs
        self.RELTIO_BASE_URL = "https://361.reltio.com/nui/RohAASgkA5WQGA9/profile?entityUri=entities%2F"
        self.IMDB_BASE_URL   = "https://www.imdb.com/title/"

        # Formats
        self.header_format = self.workbook.add_format({
            "bold": True, "text_wrap": True, "valign": "middle", "align": "center",
            "border": 1, "bg_color": "#97F8A9"
        })
        self.border_format = self.workbook.add_format({"border": 1})

        self.id_green  = self.workbook.add_format({"bg_color": "#3BF160", "border": 1, "bold": True})
        self.id_yellow = self.workbook.add_format({"bg_color": "#FCFF34", "border": 1, "bold": True})

        self.group_band_format = self.workbook.add_format({
            "bold": True, "align": "center", "valign": "vcenter",
            "border": 1, "bg_color": "#279516", "font_color": "#FFFFFF"
        })

        # Row 1 Group Header Colors
        self.group_formats = {
            "MATCHED OUTPUT": self.workbook.add_format({
                "bold": True,
                "align": "center",
                "valign": "vcenter",
                "border": 1,
                "bg_color": "#4FC444",  # Blue
                "font_color": "#000000"
            }),

            "STANDALONE INFO": self.workbook.add_format({
                "bold": True,
                "align": "center",
                "valign": "vcenter",
                "border": 1,
                "bg_color": "#E8D90D",  # Green
                "font_color": "#000000"
            }),

            "CONTENT INFO": self.workbook.add_format({
                "bold": True,
                "align": "center",
                "valign": "vcenter",
                "border": 1,
                "bg_color": "#D4A796",
                "font_color": "#FFFFFF"
            }),

            "SERIES INFO": self.workbook.add_format({
                "bold": True,
                "align": "center",
                "valign": "vcenter",
                "border": 1,
                "bg_color": "#00FDF5",
                "font_color": "#000000"
            }),

            "PARENT INFO": self.workbook.add_format({
                "bold": True,
                "align": "center",
                "valign": "vcenter",
                "border": 1,
                "bg_color": "#ED7D31",  # Orange
                "font_color": "#FFFFFF"
            }),

            "SCORES": self.workbook.add_format({
                "bold": True,
                "align": "center",
                "valign": "vcenter",
                "border": 1,
                "bg_color": "#FFC000",  # Gold
                "font_color": "#000000"
            }),

            "IDENTIFIERS": self.workbook.add_format({
                "bold": True,
                "align": "center",
                "valign": "vcenter",
                "border": 1,
                "bg_color": "#C00000",  # Dark Red
                "font_color": "#FFFFFF"
            }),
        }

        self.header_format_match = self.workbook.add_format({
            "bold": True,
            "text_wrap": False,
            "valign": "middle",
            "align": "center",
            "border": 1,
            "bg_color": "#97F8A9"
        })

        self.link_format = self.workbook.add_format({
            "border": 1,
            "font_color": "#0563C1",
            "underline": 1
        })

        # ✅ red format for NO ID/NO_ID in For Ingestion
        self.no_id_red_format = self.workbook.add_format({
            "border": 1,
            "font_color": "#FF0000",
            "bold": True
        })

        # ✅ NEW: red highlight for any IDENTIFIERS value containing "|"
        self.pipe_red_format = self.workbook.add_format({
            "border": 1,
            "font_color": "#9C0006",
            "bg_color": "#FFC7CE",   # light red fill
            "bold": True
        })

        self.FIXED_WIDTHS = {
            "MPM_NUMBER": 16,
            "PARENT_MPM": 16,
            "MMS3_MCODE": 16,
            "NODE_IDENTIFIER": 28,
            "TT_CODES": 16,
            "PROPERTY_ID": 14,
            "TURNER_TITLEID": 14,
            "For Ingestion": 18,
            "CONFIDENCE": 14,
            "FINAL_REASON": 24,
            "MATCH_RANK": 12,
            "KEEP_RECOMMENDED": 18,
            "MATCH_EVIDENCE": 45}
        self.MIN_COL_WIDTH = 10
        self.MAX_COL_WIDTH = 60
```

---

## `extract_season_episode()`

**Source lines:** 388-428

**Function signature inputs:** `title`

**Purpose:** Extracts season and episode numbers from a text title when present.

**Why this function is used in STM:** Generic episode titles often include season/episode information in inconsistent formats. Extracting the numbers helps compare hierarchy-aware titles more reliably.

**Inputs explained:** A title string.

**Outputs / side effects:** Season and episode information or null-like values.

**Detailed algorithm / logic:**
- Scans supplied text with regular expressions.
- Looks for season-like and episode-like numeric patterns.
- Returns parsed values when found.

**Important calls detected inside:** `group, int, search, str`

**Important values created or updated:** `m, title`

**Return statements detected:**
- `(None, None)`
- `(int(m.group(1)), int(m.group(2)))`
- `(int(m.group(1)), int(m.group(2)))`
- `(int(m.group(1)), int(m.group(2)))`
- `(int(m.group(1)), int(m.group(2)))`

**Maintenance guidance:** Before changing this function, verify every downstream usage in the STM script and update related tests, especially if column names, thresholds, return shape, workbook formatting, or decision labels change.

```python
    def extract_season_episode(title):

        title = str(title)

        # S5E09
        m = re.search(
            r'\bS(\d+)\s*E(\d+)\b',
            title,
            re.IGNORECASE
        )

        if m:
            return int(m.group(1)), int(m.group(2))

        # S5 Episode 09
        m = re.search(
            r'\bS(\d+)\s*(?:Episode|Ep|E)\s*(\d+)\b',
            title,
            re.IGNORECASE
        )

        if m:
            return int(m.group(1)), int(m.group(2))

        # Season 5 Episode 09
        m = re.search(
            r'Season\s*(\d+)\s*Episode\s*(\d+)',
            title,
            re.IGNORECASE
        )

        if m:
            return int(m.group(1)), int(m.group(2))

        # 509 => S5E09
        m = re.search(r'\b(\d)(\d{2})\b', title)

        if m:
            return int(m.group(1)), int(m.group(2))

        return None, None
```

---

## `confidence_bucket()`

**Source lines:** 431-445

**Function signature inputs:** `score`

**Purpose:** Converts a numeric score into a human-readable confidence level.

**Why this function is used in STM:** Analysts reviewing output need simple labels instead of interpreting raw scores only.

**Inputs explained:** Numeric match score.

**Outputs / side effects:** Confidence label used in Excel output.

**Detailed algorithm / logic:**
- Checks score against thresholds.
- Returns the matching bucket.

**Important calls detected inside:** `isna`

**Return statements detected:**
- `'Low'`
- `''`
- `'Very High'`
- `'High'`
- `'Medium'`

**Maintenance guidance:** Before changing this function, verify every downstream usage in the STM script and update related tests, especially if column names, thresholds, return shape, workbook formatting, or decision labels change.

```python
    def confidence_bucket(score):

        if pd.isna(score):
            return ""

        if score >= 98:
            return "Very High"

        if score >= 95:
            return "High"

        if score >= 85:
            return "Medium"

        return "Low"
```

---

## `get_match_reason()`

**Source lines:** 448-498

**Function signature inputs:** `result, semantic_score, cross_score, aka, numbers_pass, parent_pass`

**Purpose:** Creates a readable reason explaining a candidate decision.

**Why this function is used in STM:** The reviewer needs to know whether a result was accepted due to score strength, rejected due to extra words, or flagged as borderline.

**Inputs explained:** Title text, score fields, decision labels, and comparison signals.

**Outputs / side effects:** A final reason string.

**Detailed algorithm / logic:**
- Combines match status, scores, and text signals.
- Returns a short explanation string.

**Return statements detected:**
- `'UNKNOWN'`
- `'NUMBER_MISMATCH'`
- `'PARENT_MISMATCH'`
- `'LOW_SCORE_REJECT'`
- `'CROSS_ENCODER_APPROVED'`
- `'REVIEW_REQUIRED'`
- `'AKA_REJECTED'`
- `'BUSINESS_RULE_REJECT'`
- `'AKA_PERFECT_MATCH'`
- `'EXACT_TITLE_MATCH'`

**Maintenance guidance:** Before changing this function, verify every downstream usage in the STM script and update related tests, especially if column names, thresholds, return shape, workbook formatting, or decision labels change.

```python
    def get_match_reason(
        result,
        semantic_score,
        cross_score=None,
        aka=False,
        numbers_pass=True,
        parent_pass=True
    ):

        # hard failures first
        if not numbers_pass:
            return "NUMBER_MISMATCH"

        if not parent_pass:
            return "PARENT_MISMATCH"

        if result == "Reject":

            if aka:
                return "AKA_REJECTED"

            if semantic_score >= 85:
                return "BUSINESS_RULE_REJECT"

            return "LOW_SCORE_REJECT"

        # accepted matches
        if result == "Perfect Match":

            if aka:
                return "AKA_PERFECT_MATCH"

            if semantic_score >= 97:
                return "EXACT_TITLE_MATCH"

            if semantic_score >= 95:
                return "HIGH_SEMANTIC_MATCH"

            return "CROSS_ENCODER_APPROVED"

        if result == "Possible Match":

            if aka:
                return "AKA_POSSIBLE_MATCH"

            if semantic_score >= 90:
                return "HIGH_CONFIDENCE_REVIEW"

            return "REVIEW_REQUIRED"

        return "UNKNOWN"    
```

---

## `build_match_evidence()`

**Source lines:** 501-530

**Function signature inputs:** `row`

**Purpose:** Builds compact evidence text for a candidate match.

**Why this function is used in STM:** Evidence helps analysts audit recommendations without inspecting scoring internals.

**Inputs explained:** Scored candidate row values.

**Outputs / side effects:** Evidence text for output workbook.

**Detailed algorithm / logic:**
- Collects score and text-comparison indicators.
- Formats them into readable evidence.

**Important calls detected inside:** `append, join, notna, round`

**Important values created or updated:** `evidence`

**Return statements detected:**
- `' | '.join(evidence)`

**Maintenance guidance:** Before changing this function, verify every downstream usage in the STM script and update related tests, especially if column names, thresholds, return shape, workbook formatting, or decision labels change.

```python
    def build_match_evidence(row):

        evidence = []

        if "SEMANTIC_SCORE" in row.index and pd.notna(row["SEMANTIC_SCORE"]):
            evidence.append(
                f"Semantic={round(row['SEMANTIC_SCORE'],1)}"
            )

        if "FINAL_SCORE" in row.index and pd.notna(row["FINAL_SCORE"]):
            evidence.append(
                f"Final={round(row['FINAL_SCORE'],1)}"
            )

        if "CROSS_SCORE" in row.index and pd.notna(row["CROSS_SCORE"]):
            evidence.append(
                f"Cross={round(row['CROSS_SCORE'],1)}"
            )

        if "MATCH_RESULT" in row.index:
            evidence.append(
                f"Decision={row['MATCH_RESULT']}"
            )

        if "FINAL_MATCH_RESULT" in row.index:
            evidence.append(
                f"Decision={row['FINAL_MATCH_RESULT']}"
            )

        return " | ".join(evidence)
```

---

## `add_match_ranking()`

**Source lines:** 533-556

**Function signature inputs:** `df, id_col, score_col`

**Purpose:** Assigns rank numbers within each input ID.

**Why this function is used in STM:** Each input title can have several candidates. Ranking shows the strongest result first.

**Inputs explained:** Scored DataFrame, ID column, score column.

**Outputs / side effects:** DataFrame with match-rank column.

**Detailed algorithm / logic:**
- Groups rows by input ID.
- Sorts candidates by score.
- Adds rank values.

**Important calls detected inside:** `copy, cumcount, groupby, sort_values, where`

**Important values created or updated:** `df, df['KEEP_RECOMMENDED'], df['MATCH_RANK']`

**Return statements detected:**
- `df`
- `df`

**Maintenance guidance:** Before changing this function, verify every downstream usage in the STM script and update related tests, especially if column names, thresholds, return shape, workbook formatting, or decision labels change.

```python
    def add_match_ranking(df, id_col, score_col):

        if df.empty:
            return df

        df = df.copy()

        df = df.sort_values(
            [id_col, score_col],
            ascending=[True, False]
        )

        df["MATCH_RANK"] = (
            df.groupby(id_col)
            .cumcount() + 1
        )

        df["KEEP_RECOMMENDED"] = np.where(
            df["MATCH_RANK"] == 1,
            "Yes",
            "No"
        )

        return df
```

---

## `add_explainability_columns()`

**Source lines:** 558-595

**Function signature inputs:** `self, df, score_col, result_col`

**Purpose:** Adds reviewer-friendly confidence, reason, evidence, and keep/reject guidance.

**Why this function is used in STM:** STM output must be understandable and auditable, not just numeric.

**Inputs explained:** Scored candidate DataFrame and score/result column names.

**Outputs / side effects:** DataFrame enriched with explainability columns.

**Detailed algorithm / logic:**
- Creates confidence buckets.
- Builds final reason and evidence text.
- Adds recommendation flags.

**Important calls detected inside:** `apply, copy, get, get_match_reason, str, upper`

**Important values created or updated:** `df, df['CONFIDENCE'], df['FINAL_REASON'], df['MATCH_EVIDENCE']`

**Return statements detected:**
- `df`
- `df`

**Maintenance guidance:** Before changing this function, verify every downstream usage in the STM script and update related tests, especially if column names, thresholds, return shape, workbook formatting, or decision labels change.

```python
    def add_explainability_columns(
        self,
        df,
        score_col,
        result_col
    ):

        if df.empty:
            return df

        df = df.copy()

        df["CONFIDENCE"] = (
            df[score_col]
            .apply(self.confidence_bucket)
        )

        df["FINAL_REASON"] = df.apply(
            lambda r:
            self.get_match_reason(
                r[result_col],
                r[score_col],
                r.get("CROSS_SCORE"),
                "AKA" in str(
                    r.get("INPUT_TITLE", "")
                ).upper()
            ),
            axis=1
        )

        df["MATCH_EVIDENCE"] = (
            df.apply(
                self.build_match_evidence,
                axis=1
            )
        )

        return df
```

---

## `split_aka()`

**Source lines:** 598-630

**Function signature inputs:** `title`

**Purpose:** Splits one title field into multiple searchable title values when AKA or separator patterns exist.

**Why this function is used in STM:** Metadata feeds often provide alternate titles in one field. Searching only the original value would miss candidates stored under aliases.

**Inputs explained:** Title string, blank value, or null.

**Outputs / side effects:** List of title variants.

**Detailed algorithm / logic:**
- Handles null and blank values defensively.
- Detects parenthetical AKA formats.
- Splits on AKA text, slashes, commas, and related separators.
- Trims whitespace and removes empty segments.

**Important calls detected inside:** `extend, group, isna, search, split, str, strip, sub`

**Important values created or updated:** `aka_list, aka_match, aka_part, main_parts, main_title, parts, result, title`

**Return statements detected:**
- `[p.strip() for p in parts if p.strip()]`
- `[title]`
- `result`

**Maintenance guidance:** Before changing this function, verify every downstream usage in the STM script and update related tests, especially if column names, thresholds, return shape, workbook formatting, or decision labels change.

```python
    def split_aka(title):
        if pd.isna(title):
            return [title]

        title = str(title).strip()

        result = []

        # ✅ Extract AKA content inside parentheses anywhere in string
        aka_match = re.search(r'\(\s*AKA\.?\s*(.*?)\)', title, flags=re.IGNORECASE)

        if aka_match:
            aka_part = aka_match.group(1)

            # Split aliases
            aka_list = re.split(r'[,/]', aka_part)
            aka_list = [x.strip() for x in aka_list if x.strip()]

            # Remove the (AKA...) part from main title
            main_title = re.sub(r'\(\s*AKA\.?.*?\)', '', title, flags=re.IGNORECASE).strip()

            # Now also split remaining title by '/'
            main_parts = re.split(r'\s*/\s*', main_title)
            main_parts = [p.strip() for p in main_parts if p.strip()]

            result.extend(main_parts)
            result.extend(aka_list)

            return result

        # ✅ fallback logic
        parts = re.split(r'\s*(?:/\s*|\bAKA\b)\s*', title, flags=re.IGNORECASE)
        return [p.strip() for p in parts if p.strip()]
```

---

## `normalize_title()`

**Source lines:** 633-660

**Function signature inputs:** `title`

**Purpose:** Standardizes title strings before SQL lookup and semantic scoring.

**Why this function is used in STM:** Different systems use different casing, punctuation, accents, and version labels. Normalization focuses matching on real title content.

**Inputs explained:** Any title-like value.

**Outputs / side effects:** Clean normalized title string.

**Detailed algorithm / logic:**
- Converts missing values to empty string.
- Normalizes unicode and removes accents.
- Lowercases text.
- Removes/standardizes punctuation and version phrases.
- Trims extra spaces and handles year patterns.

**Important calls detected inside:** `decode, encode, isna, join, lower, normalize, split, str, strip, sub`

**Important values created or updated:** `title`

**Return statements detected:**
- `title`
- `''`

**Maintenance guidance:** Before changing this function, verify every downstream usage in the STM script and update related tests, especially if column names, thresholds, return shape, workbook formatting, or decision labels change.

```python
    def normalize_title(title):
        if pd.isna(title):
            return ""
        # Trim space:
        title = title.strip()
        
        # 1️⃣ Normalize Unicode (NFKD separates accents)
        title = unicodedata.normalize('NFKD', str(title))
        
        # 2️⃣ Remove accent marks (convert → ASCII)
        title = title.encode('ascii', 'ignore').decode('utf-8')
        
        # 3️⃣ Lowercase
        title = title.lower()
        
        # 4️⃣ Remove punctuation
        title = re.sub(r"[^\w\s'\-]", '', title)
        
        # 5️⃣ Remove 4-digit year
        title = re.sub(r'\s+\b(19|20)\d{2}\b$', '', title)

        # 6️⃣ Remove EDITED VERSION and SUBTITLE VERSION
        title = re.sub(r'\b(SUBTITLED VERSION|EDITED VERSION|SUBTITLED|SUBTITLES)\b', '', title, flags=re.IGNORECASE).strip()
        
        # 7️⃣ Remove extra spaces
        title = " ".join(title.split())
        
        return title
```

---

## `open_excel_file()`

**Source lines:** 663-672

**Function signature inputs:** `path`

**Purpose:** Opens a generated Excel file for interactive analyst review.

**Why this function is used in STM:** ALL mode requires the analyst to inspect and choose parent series candidates before child matching continues.

**Inputs explained:** Path to Excel file.

**Outputs / side effects:** Side effect: opens file in system application.

**Detailed algorithm / logic:**
- Detects OS.
- Runs the appropriate command to open workbook.

**Important calls detected inside:** `call, startfile, startswith, warning`

**Maintenance guidance:** Before changing this function, verify every downstream usage in the STM script and update related tests, especially if column names, thresholds, return shape, workbook formatting, or decision labels change.

```python
    def open_excel_file(path):
        try:
            if sys.platform.startswith("win"):
                os.startfile(path)
            elif sys.platform == "darwin":
                subprocess.call(["open", path])
            else:
                subprocess.call(["xdg-open", path])
        except Exception as e:
            logger.warning(f"Could not open Excel file automatically: {e}")
```

---

## `write_series_selection_file()`

**Source lines:** 675-1229

**Function signature inputs:** `df, output_path`

**Purpose:** Creates the Series_Selection workbook used in ALL mode human validation.

**Why this function is used in STM:** Episodes and seasons are only reliable when matched under the correct series, so the analyst confirms parent series first.

**Inputs explained:** Series candidate DataFrame and output path.

**Outputs / side effects:** Excel workbook for parent-series selection.

**Detailed algorithm / logic:**
- Writes candidate series rows into a workbook.
- Applies headers, formatting, widths, freeze panes, filters, and validation dropdowns.
- Adds a `Select_Series` field for Yes/No analyst selection.
- Guides reviewer through protected or formatted columns.

**Important calls detected inside:** `ExcelWriter, add_format, append, apply, astype, autofilter, contains, copy, data_validation, enumerate, extract_tt, float, freeze_panes, fullmatch, get, get_loc, group, int, is_integer, isinf, isinstance, isna, isnan, len, lower` and 21 more

**Important values created or updated:** `border_format, clean_entity, col_positions, cond, conds, current_id_format, df, df['For Ingestion'], df['Select_Series'], df[col], end_col, excel_row, existing_preferred, f, fixed_widths, fmt, group_band_format, group_formats, groups, header_format, id_col_index, id_count, id_counts, id_green, id_yellow` and 5 more

**Return statements detected:**
- `x`
- `''`
- `int(x)`
- `int(x) if float(x).is_integer() else float(x)`
- `''`
- `m.group(1).lower() if m else None`
- `''`
- `int(s_clean)`
- `int(f) if float(f).is_integer() else f`
- `None`

**Maintenance guidance:** Before changing this function, verify every downstream usage in the STM script and update related tests, especially if column names, thresholds, return shape, workbook formatting, or decision labels change.

```python
    def write_series_selection_file(df, output_path):
        import pandas as pd
        import numpy as np
        import re
        import math

        df = df.copy()

        # -------------------------------------------------
        # 1) Ensure Select_Series column exists
        # -------------------------------------------------
        if "Select_Series" not in df.columns:
            df["Select_Series"] = "No"

        # -------------------------------------------------
        # 2) Keep original final-score column names
        # DO NOT rename FINAL_SCORE / FINAL_MATCH_RESULT
        # because your later code uses these names.
        # -------------------------------------------------

        # -------------------------------------------------
        # 3) Add For Ingestion column same like final output
        # -------------------------------------------------
        ingestion_priority = [
            ("MPM_NUMBER", "MPM_Number"),
            ("PI_UUID", "PI_UUID"),
            ("PROPERTY_ID", "Property_ID"),
            ("HBO_ID", "HBO_ID"),
            ("META_ID", "Meta_ID"),
            ("TURNER_TITLEID", "Turner_TitleID"),
            ("MMS3_MCODE", "MMS3_MCode"),
            ("DASH_TITLE_ID", "DASH_Title_ID"),
            ("ALEPH_ID", "Aleph_ID"),
            ("IBROADCAST_EMEA_ID", "iBroadcast_EMEA_ID"),
            ("IBROADCAST_APAC_ID", "iBroadcast_APAC_ID"),
        ]

        conds = []
        labels = []

        for col, label in ingestion_priority:
            if col in df.columns:
                s = df[col].astype("string").str.strip()
                cond = (
                    s.notna()
                    & (s != "")
                    & (~s.str.contains(r"\|", na=False))
                )
                conds.append(cond.to_numpy())
                labels.append(label)

        df["For Ingestion"] = np.select(conds, labels, default="NO ID") if conds else "NO ID"

        # -------------------------------------------------
        # 4) Correct preferred column order for Series Selection
        # -------------------------------------------------
        preferred_columns = [
            "ID",
            "MATCH_LEVEL",
            "INPUT_TITLE",
            "ATOM_TITLE",
            "INPUT_YEAR",
            "YEARS",
            "TT_CODES",

            "IP_TYPE",
            "NODE_IDENTIFIER",
            "LIBRARY_TITLE_FULL",
            "CHILDREN_STATUS",

            "FINAL_SCORE",
            "SEMANTIC_SCORE",
            "MATCH_LEVEL",
            "CONFIDENCE",
            "FINAL_REASON",
            "MATCH_RANK",
            "MATCH_EVIDENCE",

            "MPM_NUMBER",
            "PI_UUID",
            "PROPERTY_ID",
            "HBO_ID",
            "META_ID",
            "TURNER_TITLEID",
            "MMS3_MCODE",
            "DASH_TITLE_ID",
            "ALEPH_ID",
            "IBROADCAST_EMEA_ID",
            "IBROADCAST_APAC_ID",
            "For Ingestion",

            "Select_Series"
        ]

        existing_preferred = [c for c in preferred_columns if c in df.columns]
        remaining_columns = [c for c in df.columns if c not in existing_preferred]

        df = df[existing_preferred + remaining_columns]

        # -------------------------------------------------
        # 5) Numeric conversion same like final output
        # -------------------------------------------------
        num_cols = [
            "PROPERTY_ID",
            "HBO_ID",
            "META_ID",
            "TURNER_TITLEID",
            "MMS3_MCODE",
            "DASH_TITLE_ID",
            "ALEPH_ID",
            "IBROADCAST_EMEA_ID",
            "IBROADCAST_APAC_ID",
            "YEARS",
            "MPM_NUMBER",
        ]

        def try_number_preserve_decimals(x):
            if x is None or pd.isna(x):
                return ""

            if isinstance(x, (int, np.integer)):
                return int(x)

            if isinstance(x, (float, np.floating)):
                if math.isnan(x) or math.isinf(x):
                    return ""
                return int(x) if float(x).is_integer() else float(x)

            s = str(x).strip()
            if s == "":
                return ""

            s_clean = s.replace(",", "")

            if re.fullmatch(r"[+-]?\d+", s_clean):
                try:
                    return int(s_clean)
                except Exception:
                    return x

            if re.fullmatch(r"[+-]?\d+\.\d+", s_clean):
                try:
                    f = float(s_clean)
                    return int(f) if float(f).is_integer() else f
                except Exception:
                    return x

            return x

        for col in num_cols:
            if col in df.columns:
                df[col] = df[col].apply(try_number_preserve_decimals)

        # -------------------------------------------------
        # 6) Write Excel
        # -------------------------------------------------
        with pd.ExcelWriter(output_path, engine="xlsxwriter") as writer:
            sheet_name = "Series match"

            # row 0 = group headers
            # row 1 = column headers
            # row 2 onwards = data
            df.to_excel(
                writer,
                index=False,
                sheet_name=sheet_name,
                startrow=1
            )

            workbook = writer.book
            worksheet = writer.sheets[sheet_name]

            # -------------------------------------------------
            # 7) Formats same like final output
            # -------------------------------------------------
            group_band_format = workbook.add_format({
                "bold": True,
                "align": "center",
                "valign": "vcenter",
                "border": 1,
                "bg_color": "#279516",
                "font_color": "#FFFFFF"
            })

            header_format = workbook.add_format({
                "bold": True,
                "text_wrap": False,
                "valign": "middle",
                "align": "center",
                "border": 1,
                "bg_color": "#97F8A9"
            })

            border_format = workbook.add_format({
                "border": 1
            })

            id_green = workbook.add_format({
                "bg_color": "#3BF160",
                "border": 1,
                "bold": True
            })

            id_yellow = workbook.add_format({
                "bg_color": "#FCFF34",
                "border": 1,
                "bold": True
            })

            link_format = workbook.add_format({
                "border": 1,
                "font_color": "#0563C1",
                "underline": 1
            })

            no_id_red_format = workbook.add_format({
                "border": 1,
                "font_color": "#FF0000",
                "bold": True
            })

            pipe_red_format = workbook.add_format({
                "border": 1,
                "font_color": "#9C0006",
                "bg_color": "#FFC7CE",
                "bold": True
            })

            select_format = workbook.add_format({
                "border": 1,
                "bg_color": "#FFF2CC"
            })

            # -------------------------------------------------
            # 8) Correct group rules for Series Selection
            # -------------------------------------------------
            group_formats = {
                "MATCHED OUTPUT": workbook.add_format({
                    "bold": True,
                    "align": "center",
                    "valign": "vcenter",
                    "border": 1,
                    "bg_color": "#4472C4",
                    "font_color": "#FFFFFF"
                }),

                "SERIES INFO": workbook.add_format({
                    "bold": True,
                    "align": "center",
                    "valign": "vcenter",
                    "border": 1,
                    "bg_color": "#70AD47",
                    "font_color": "#000000"
                }),

                "SCORES": workbook.add_format({
                    "bold": True,
                    "align": "center",
                    "valign": "vcenter",
                    "border": 1,
                    "bg_color": "#FFC000",
                    "font_color": "#000000"
                }),

                "IDENTIFIERS": workbook.add_format({
                    "bold": True,
                    "align": "center",
                    "valign": "vcenter",
                    "border": 1,
                    "bg_color": "#C00000",
                    "font_color": "#FFFFFF"
                }),

                "USER SELECTION": workbook.add_format({
                    "bold": True,
                    "align": "center",
                    "valign": "vcenter",
                    "border": 1,
                    "bg_color": "#7030A0",
                    "font_color": "#FFFFFF"
                }),
            }

            # -------------------------------------------------
            # 9) First fill full group row
            # -------------------------------------------------
            groups = [
                ("MATCHED OUTPUT", [
                    "ID",
                    "MATCH_LEVEL",
                    "INPUT_TITLE",
                    "ATOM_TITLE",
                    "INPUT_YEAR",
                    "YEARS",
                    "TT_CODES"
                ]),

                ("SERIES INFO", [
                    "IP_TYPE",
                    "NODE_IDENTIFIER",
                    "LIBRARY_TITLE_FULL",
                    "CHILDREN_STATUS"
                ]),

                ("SCORES",
                    [
                        "FINAL_SCORE",
                        "SEMANTIC_SCORE",
                        "MATCH_LEVEL",
                        "CONFIDENCE",
                        "FINAL_REASON",
                        "MATCH_RANK",
                        "MATCH_EVIDENCE"
                    ]),

                ("IDENTIFIERS", [
                    "MPM_NUMBER",
                    "PI_UUID",
                    "PROPERTY_ID",
                    "HBO_ID",
                    "META_ID",
                    "TURNER_TITLEID",
                    "MMS3_MCODE",
                    "DASH_TITLE_ID",
                    "ALEPH_ID",
                    "IBROADCAST_EMEA_ID",
                    "IBROADCAST_APAC_ID",
                    "For Ingestion"
                ]),

                ("USER SELECTION", [
                    "Select_Series"
                ])
            ]
            for col_num in range(len(df.columns)):
                worksheet.write_blank(0, col_num, None, group_band_format)

            # Then merge group ranges
            col_positions = {col: idx for idx, col in enumerate(df.columns)}

            for group_name, group_cols in groups:
                present_cols = [c for c in group_cols if c in df.columns]

                if not present_cols:
                    continue

                start_col = col_positions[present_cols[0]]
                end_col = col_positions[present_cols[-1]]

                if start_col == end_col:
                    fmt = group_formats.get(group_name, group_band_format)
                    worksheet.write(0, start_col, group_name, fmt)
                else:
                    fmt = group_formats.get(group_name, group_band_format)

                    if start_col == end_col:
                        worksheet.write(0, start_col, group_name, fmt)
                    else:
                        worksheet.merge_range(
                            0,
                            start_col,
                            0,
                            end_col,
                            group_name,
                            fmt
                        )

            # -------------------------------------------------
            # 10) Actual headers
            # -------------------------------------------------
            for col_num, col_name in enumerate(df.columns):
                worksheet.write(1, col_num, col_name, header_format)

            # -------------------------------------------------
            # 11) Column indexes
            # -------------------------------------------------
            id_col_index = df.columns.get_loc("ID") if "ID" in df.columns else None
            node_col_index = df.columns.get_loc("NODE_IDENTIFIER") if "NODE_IDENTIFIER" in df.columns else None
            tt_col_index = df.columns.get_loc("TT_CODES") if "TT_CODES" in df.columns else None
            ingestion_col_index = df.columns.get_loc("For Ingestion") if "For Ingestion" in df.columns else None

            identifier_cols = {
                "MPM_NUMBER",
                "PI_UUID",
                "PROPERTY_ID",
                "HBO_ID",
                "META_ID",
                "TURNER_TITLEID",
                "MMS3_MCODE",
                "DASH_TITLE_ID",
                "ALEPH_ID",
                "IBROADCAST_EMEA_ID",
                "IBROADCAST_APAC_ID",
            }

            reltio_base_url = "https://361.reltio.com/nui/RohAASgkA5WQGA9/profile?entityUri=entities%2F"
            imdb_base_url = "https://www.imdb.com/title/"

            def extract_tt(s):
                if not s:
                    return None
                m = re.search(r"(tt\d+)", str(s), flags=re.IGNORECASE)
                return m.group(1).lower() if m else None

            # ID duplicate coloring same like final output
            if "ID" in df.columns:
                id_counts = df["ID"].value_counts(dropna=False).to_dict()
            else:
                id_counts = {}

            # -------------------------------------------------
            # 12) Write data rows with formatting
            # -------------------------------------------------
            for r in range(len(df)):
                excel_row = r + 2

                row_id = df.iloc[r]["ID"] if "ID" in df.columns else None
                id_count = id_counts.get(row_id, 0)
                current_id_format = id_green if id_count == 1 else id_yellow

                for c, col_name in enumerate(df.columns):
                    value = df.iloc[r, c]

                    if value is None or pd.isna(value):
                        value = ""

                    value_str = str(value).strip()

                    # ID highlight
                    if id_col_index is not None and c == id_col_index:
                        worksheet.write(excel_row, c, value, current_id_format)
                        continue

                    # Select_Series yellow
                    if col_name == "Select_Series":
                        worksheet.write(excel_row, c, value, select_format)
                        continue

                    # For Ingestion red NO ID
                    if ingestion_col_index is not None and c == ingestion_col_index:
                        if value_str.upper() in ["NO ID", "NO_ID"]:
                            worksheet.write(excel_row, c, value_str, no_id_red_format)
                        else:
                            worksheet.write(excel_row, c, value, border_format)
                        continue

                    # Pipe highlight for identifiers
                    if col_name in identifier_cols and "|" in value_str:
                        worksheet.write(excel_row, c, value, pipe_red_format)
                        continue

                    # NODE_IDENTIFIER hyperlink
                    if node_col_index is not None and c == node_col_index:
                        if value_str:
                            clean_entity = value_str.replace("entities/", "")
                            worksheet.write_url(
                                excel_row,
                                c,
                                reltio_base_url + clean_entity,
                                link_format,
                                string=value_str
                            )
                        else:
                            worksheet.write(excel_row, c, "", border_format)
                        continue

                    # TT_CODES hyperlink
                    if tt_col_index is not None and c == tt_col_index:
                        tt = extract_tt(value_str)
                        if tt:
                            worksheet.write_url(
                                excel_row,
                                c,
                                imdb_base_url + tt + "/",
                                link_format,
                                string=tt
                            )
                        else:
                            worksheet.write(excel_row, c, value_str, border_format)
                        continue

                    # default
                    worksheet.write(excel_row, c, value, border_format)

            # -------------------------------------------------
            # 13) Dropdown for Select_Series
            # -------------------------------------------------
            if "Select_Series" in df.columns:
                select_col_idx = df.columns.get_loc("Select_Series")

                worksheet.data_validation(
                    2,
                    select_col_idx,
                    max(len(df) + 1, 2),
                    select_col_idx,
                    {
                        "validate": "list",
                        "source": ["Yes", "No"],
                        "input_title": "Select Series",
                        "input_message": "Choose Yes if this is the correct Series match.",
                        "error_title": "Invalid value",
                        "error_message": "Please select only Yes or No."
                    }
                )

            # -------------------------------------------------
            # 14) Widths same final style
            # -------------------------------------------------
            fixed_widths = {
                "ID": 12,
                "MATCH_LEVEL": 16,
                "INPUT_TITLE": 38,
                "ATOM_TITLE": 38,
                "INPUT_YEAR": 14,
                "YEARS": 14,
                "TT_CODES": 16,
                "IP_TYPE": 18,
                "NODE_IDENTIFIER": 28,
                "CHILDREN_STATUS": 35,
                "FINAL_SCORE": 16,
                "FINAL_MATCH_RESULT": 22,
                "MPM_NUMBER": 16,
                "PROPERTY_ID": 14,
                "TURNER_TITLEID": 16,
                "MMS3_MCODE": 16,
                "For Ingestion": 18,
                "Select_Series": 18,
            }

            min_width = 10
            max_width = 60

            for col_idx, col_name in enumerate(df.columns):
                if col_name in fixed_widths:
                    width = fixed_widths[col_name]
                else:
                    try:
                        max_len = max(
                            df[col_name].astype(str).map(len).max(),
                            len(str(col_name))
                        )
                        width = min(max(max_len + 2, min_width), max_width)
                    except Exception:
                        width = 22

                worksheet.set_column(col_idx, col_idx, width)

            # -------------------------------------------------
            # 15) Final sheet settings
            # -------------------------------------------------
            worksheet.freeze_panes(2, 0)
            worksheet.autofilter(1, 0, len(df) + 1, len(df.columns) - 1)

            worksheet.set_row(0, 24)
            worksheet.set_row(1, 28)
```

---

## `try_number_preserve_decimals()`

**Source lines:** 791-822

**Function signature inputs:** `x`

**Purpose:** Converts numeric-looking values while preserving meaningful decimal formatting.

**Why this function is used in STM:** Metadata identifiers and season/episode values can appear as strings, ints, or floats. Bad conversion can corrupt IDs.

**Inputs explained:** Single value.

**Outputs / side effects:** Converted or original value.

**Detailed algorithm / logic:**
- Attempts safe numeric conversion.
- Preserves meaningful decimals.
- Avoids destructive conversion for non-numeric or identifier-like values.

**Important calls detected inside:** `float, fullmatch, int, is_integer, isinf, isinstance, isna, isnan, replace, str, strip`

**Important values created or updated:** `f, s, s_clean`

**Return statements detected:**
- `x`
- `''`
- `int(x)`
- `int(x) if float(x).is_integer() else float(x)`
- `''`
- `''`
- `int(s_clean)`
- `int(f) if float(f).is_integer() else f`
- `x`
- `x`

**Maintenance guidance:** Before changing this function, verify every downstream usage in the STM script and update related tests, especially if column names, thresholds, return shape, workbook formatting, or decision labels change.

```python
        def try_number_preserve_decimals(x):
            if x is None or pd.isna(x):
                return ""

            if isinstance(x, (int, np.integer)):
                return int(x)

            if isinstance(x, (float, np.floating)):
                if math.isnan(x) or math.isinf(x):
                    return ""
                return int(x) if float(x).is_integer() else float(x)

            s = str(x).strip()
            if s == "":
                return ""

            s_clean = s.replace(",", "")

            if re.fullmatch(r"[+-]?\d+", s_clean):
                try:
                    return int(s_clean)
                except Exception:
                    return x

            if re.fullmatch(r"[+-]?\d+\.\d+", s_clean):
                try:
                    f = float(s_clean)
                    return int(f) if float(f).is_integer() else f
                except Exception:
                    return x

            return x
```

---

## `extract_tt()`

**Source lines:** 1073-1077

**Function signature inputs:** `s`

**Purpose:** Implements the `extract_tt` helper used by STM.

**Why this function is used in STM:** This helper isolates reusable STM logic so the main script can stay readable and consistent.

**Inputs explained:** Function parameters from the signature.

**Outputs / side effects:** Return value or side effect depending on implementation.

**Detailed algorithm / logic:**
- Reads parameters and any instance state.
- Performs the function-specific transformation, scoring, validation, formatting, or filtering.
- Returns a value or updates DataFrame/workbook state.

**Important calls detected inside:** `group, lower, search, str`

**Important values created or updated:** `m`

**Return statements detected:**
- `m.group(1).lower() if m else None`
- `None`

**Maintenance guidance:** Before changing this function, verify every downstream usage in the STM script and update related tests, especially if column names, thresholds, return shape, workbook formatting, or decision labels change.

```python
            def extract_tt(s):
                if not s:
                    return None
                m = re.search(r"(tt\d+)", str(s), flags=re.IGNORECASE)
                return m.group(1).lower() if m else None
```

---

## `rowwise_cosine()`

**Source lines:** 1232-1235

**Function signature inputs:** `a, b`

**Purpose:** Computes cosine similarity for corresponding embedding pairs.

**Why this function is used in STM:** SentenceTransformer returns vectors. Cosine similarity converts vector closeness into semantic score.

**Inputs explained:** Two aligned embedding tensors.

**Outputs / side effects:** Tensor of cosine similarity scores.

**Detailed algorithm / logic:**
- Normalizes both embedding tensors.
- Multiplies corresponding rows.
- Sums vectors row-wise.

**Important calls detected inside:** `normalize, sum`

**Important values created or updated:** `a, b`

**Return statements detected:**
- `(a * b).sum(dim=1)`

**Maintenance guidance:** Before changing this function, verify every downstream usage in the STM script and update related tests, especially if column names, thresholds, return shape, workbook formatting, or decision labels change.

```python
    def rowwise_cosine(a, b):
        a = torch.nn.functional.normalize(a, p=2, dim=1)
        b = torch.nn.functional.normalize(b, p=2, dim=1)
        return (a * b).sum(dim=1)
```

---

## `select_output_folder()`

**Source lines:** 1239-1268

**Function signature inputs:** `No parameters`

**Purpose:** Prompts the analyst to choose an output location.

**Why this function is used in STM:** Output location changes by run, project, or analyst. A folder picker avoids hardcoded paths.

**Inputs explained:** User folder selection.

**Outputs / side effects:** Selected output folder path.

**Detailed algorithm / logic:**
- Opens folder selection dialog.
- Returns selected path or exits if none chosen.

**Important calls detected inside:** `Tk, askdirectory, attributes, destroy, isdir, isfile, islink, join, listdir, print, remove, rmtree, update, withdraw`

**Important values created or updated:** `folder_path, item_path, root`

**Return statements detected:**
- `folder_path`
- `None`

**Maintenance guidance:** Before changing this function, verify every downstream usage in the STM script and update related tests, especially if column names, thresholds, return shape, workbook formatting, or decision labels change.

```python
    def select_output_folder():
        root = tk.Tk()
        root.withdraw()
        root.attributes("-topmost", True)
        root.update()

        print("Select folder to save output files...")
        folder_path = filedialog.askdirectory(title="Select folder to save output files")
        root.destroy()

        if not folder_path:
            print("No folder selected!")
            return None

        # ✅ Clear folder contents
        for item in os.listdir(folder_path):
            item_path = os.path.join(folder_path, item)

            try:
                if os.path.isfile(item_path) or os.path.islink(item_path):
                    os.remove(item_path)   # delete file
                elif os.path.isdir(item_path):
                    shutil.rmtree(item_path)  # delete folder
            except Exception as e:
                print(f"❌ Failed to delete {item_path}: {e}")

        print("✅ Folder cleaned successfully")
        print("Selected Output Folder:", folder_path)

        return folder_path
```

---

## `genric_merger()`

**Source lines:** 1271-1307

**Function signature inputs:** `title, series_title, season_number, episode_number`

**Purpose:** Adds series and season/episode context to generic episode titles.

**Why this function is used in STM:** Titles such as `Episode 1` can exist across many series. Adding context improves matching precision.

**Inputs explained:** Episode title, series title, season number, episode number.

**Outputs / side effects:** Original or enriched title string.

**Detailed algorithm / logic:**
- Validates title, season number, and episode number.
- Normalizes numeric season/episode values when possible.
- Combines original title with AKA context.
- Falls back to original title when data is missing or invalid.

**Important calls detected inside:** `float, int, is_integer, isna, str, strip`

**Important values created or updated:** `ep_num, num, s_num, season_num, season_text, series_title`

**Return statements detected:**
- `title`
- `f'{title} (AKA. {series_title} {season_text}Episode {ep_num})'`
- `f'{title} (AKA. {season_text}Episode {ep_num})'`
- `title`

**Maintenance guidance:** Before changing this function, verify every downstream usage in the STM script and update related tests, especially if column names, thresholds, return shape, workbook formatting, or decision labels change.

```python
    def genric_merger(title, series_title, season_number, episode_number):
        """Generates a merged title based on the provided information."""
        # ✅ Require BOTH season and episode
        if (
            pd.isna(episode_number) or str(episode_number).strip() == "" or
            pd.isna(season_number) or str(season_number).strip() == ""
        ):
            return title

        ep_num = str(episode_number).strip()
        season_num = str(season_number).strip()

        series_title = "" if pd.isna(series_title) else str(series_title).strip()

        try:
            # ✅ normalize episode number
            num = float(ep_num)
            if num.is_integer():
                ep_num = str(int(num))

            # ✅ normalize season number
            try:
                s_num = float(season_num)
                if s_num.is_integer():
                    season_num = str(int(s_num))
            except:
                pass

            season_text = f"S{season_num} "

            if series_title:
                return f"{title} (AKA. {series_title} {season_text}Episode {ep_num})"
            else:
                return f"{title} (AKA. {season_text}Episode {ep_num})"

        except ValueError:
            return title
```

---

## `get_connection()`

**Source lines:** 1311-1319

**Function signature inputs:** `No parameters`

**Purpose:** Creates a Snowflake connection.

**Why this function is used in STM:** Snowflake contains the ATOM metadata used for candidate retrieval.

**Inputs explained:** Connection parameters inside function/configuration.

**Outputs / side effects:** Snowflake connection object.

**Detailed algorithm / logic:**
- Calls Snowflake connector with configured parameters.
- Returns the connection object.
- Raises failures to caller.

**Important calls detected inside:** `connect`

**Return statements detected:**
- `snowflake.connector.connect(user='MUVEESHKUMAR.SHANMUGAM@WBD.COM', account='WBD-COMMONDATAPROD', database='BOLT_MSC_CDS_PROD', schema='ATOM_BI', role='PUBLIC', authenticator='externalbrowser')`

**Maintenance guidance:** Before changing this function, verify every downstream usage in the STM script and update related tests, especially if column names, thresholds, return shape, workbook formatting, or decision labels change.

```python
    def get_connection():
        return snowflake.connector.connect(
            user='MUVEESHKUMAR.SHANMUGAM@WBD.COM',
            account='WBD-COMMONDATAPROD',   
            database='BOLT_MSC_CDS_PROD',
            schema='ATOM_BI',
            role='PUBLIC',
            authenticator='externalbrowser'
        )
```

---

## `apply_cross_encoder()`

**Source lines:** 1326-1340

**Function signature inputs:** `df, colA, colB, semantic_col, out_col, cross_model, low, high`

**Purpose:** Applies pairwise CrossEncoder scoring to candidate title pairs.

**Why this function is used in STM:** Embedding similarity is useful for recall; CrossEncoder scoring is more precise because it evaluates two titles together.

**Inputs explained:** Candidate DataFrame, title columns, score columns, CrossEncoder model.

**Outputs / side effects:** DataFrame with CrossEncoder score column.

**Detailed algorithm / logic:**
- Builds title pairs from two DataFrame columns.
- Runs CrossEncoder model.
- Stores the score in target column.

**Important calls detected inside:** `list, predict, round, zip`

**Important values created or updated:** `df.loc[mask, out_col], df[out_col], mask, pairs, scores`

**Return statements detected:**
- `df`
- `df`

**Maintenance guidance:** Before changing this function, verify every downstream usage in the STM script and update related tests, especially if column names, thresholds, return shape, workbook formatting, or decision labels change.

```python
    def apply_cross_encoder(df, colA, colB, semantic_col, out_col, cross_model, low=80, high=88):

        df[out_col] = None

        mask = (df[semantic_col] >= low) & (df[semantic_col] < high)

        pairs = list(zip(df.loc[mask, colA], df.loc[mask, colB]))

        if not pairs:
            return df
        
        scores = cross_model.predict(pairs)
        df.loc[mask, out_col] = [round(s * 100, 2) for s in scores]

        return df
```

---

## `extra_word_ratio()`

**Source lines:** 1344-1349

**Function signature inputs:** `input_title, candidate_title`

**Purpose:** Measures additional wording difference between input and candidate titles.

**Why this function is used in STM:** Extra words can indicate different edition, subtitle, or wrong candidate even when semantic score is high.

**Inputs explained:** Two normalized title strings.

**Outputs / side effects:** Numeric extra-word ratio.

**Detailed algorithm / logic:**
- Splits normalized titles into word sets.
- Compares excess words between sides.
- Returns mismatch ratio.

**Important calls detected inside:** `len, lower, set, split`

**Important values created or updated:** `extra, t1, t2`

**Return statements detected:**
- `extra`

**Maintenance guidance:** Before changing this function, verify every downstream usage in the STM script and update related tests, especially if column names, thresholds, return shape, workbook formatting, or decision labels change.

```python
    def extra_word_ratio(input_title, candidate_title):
        t1 = set(input_title.lower().split())
        t2 = set(candidate_title.lower().split())

        extra = len(t2 - t1)
        return extra
```

---

## `extract_numbers()`

**Source lines:** 1352-1358

**Function signature inputs:** `text, ignore_year`

**Purpose:** Extracts numeric tokens from a title.

**Why this function is used in STM:** Numbers often represent seasons, episodes, years, or sequel indicators. Numeric compatibility helps avoid bad matches.

**Inputs explained:** Title text.

**Outputs / side effects:** List/set of numbers.

**Detailed algorithm / logic:**
- Uses regular expressions to find numbers.
- Returns comparable numeric tokens.

**Important calls detected inside:** `findall, int`

**Important values created or updated:** `nums`

**Return statements detected:**
- `nums`

**Maintenance guidance:** Before changing this function, verify every downstream usage in the STM script and update related tests, especially if column names, thresholds, return shape, workbook formatting, or decision labels change.

```python
    def extract_numbers(text, ignore_year=True):
        nums = re.findall(r'\d+', text)
        
        if ignore_year:
            nums = [n for n in nums if not (1900 <= int(n) <= 2099)]
        
        return nums
```

---

## `numbers_match()`

**Source lines:** 1360-1361

**Function signature inputs:** `self, a, b`

**Purpose:** Checks whether important numeric tokens agree between two titles.

**Why this function is used in STM:** A pair can be semantically similar but wrong if episode or sequel numbers differ.

**Inputs explained:** Two title strings.

**Outputs / side effects:** True/False style numeric-compatibility result.

**Detailed algorithm / logic:**
- Extracts numbers from both titles.
- Compares overlap/equality depending on implementation.
- Returns compatibility signal.

**Important calls detected inside:** `extract_numbers`

**Return statements detected:**
- `self.extract_numbers(a) == self.extract_numbers(b)`

**Maintenance guidance:** Before changing this function, verify every downstream usage in the STM script and update related tests, especially if column names, thresholds, return shape, workbook formatting, or decision labels change.

```python
    def numbers_match(self, a, b):
        return self.extract_numbers(a) == self.extract_numbers(b)
```

---

## `final_decision()`

**Source lines:** 1367-1413

**Function signature inputs:** `self, input_title, candidate_title, semantic_score, cross_score`

**Purpose:** Converts semantic score, CrossEncoder score, text checks, extra words, and numeric signals into a final match label.

**Why this function is used in STM:** The workbook needs business-readable decisions, not just raw metrics.

**Inputs explained:** Normalized input title, normalized atom title, semantic score, CrossEncoder score.

**Outputs / side effects:** Final match-result label.

**Detailed algorithm / logic:**
- Checks strong title agreement.
- Uses semantic and CrossEncoder scores as evidence.
- Applies penalties for extra words or numeric mismatch.
- Returns labels such as Perfect Match, Possible Match, or Reject.

**Important calls detected inside:** `extra_word_ratio, extract_numbers, extract_season_episode, issubset, len, set, split, strip, upper`

**Important values created or updated:** `candidate_nums, candidate_title, extra_words, input_nums, input_title`

**Return statements detected:**
- `'Reject'`
- `'Perfect Match'`
- `'Possible Match'`
- `'Reject'`
- `'Reject'`
- `'Reject'`
- `'Possible Match'`
- `'Reject'`
- `'Perfect Match'`
- `'Possible Match'`

**Maintenance guidance:** Before changing this function, verify every downstream usage in the STM script and update related tests, especially if column names, thresholds, return shape, workbook formatting, or decision labels change.

```python
    def final_decision(self, input_title, candidate_title, semantic_score, cross_score=None):

        input_title = input_title.strip()
        candidate_title = candidate_title.strip()
        extra_words = self.extra_word_ratio(input_title, candidate_title)
        
        input_s, input_e = self.extract_season_episode(input_title)
        cand_s, cand_e = self.extract_season_episode(candidate_title)

        if input_s is not None and cand_s is not None:

            if input_s != cand_s:
                return "Reject"

            if input_e != cand_e:
                return "Reject"

        else:

            input_nums = self.extract_numbers(input_title)
            candidate_nums = self.extract_numbers(candidate_title)

            if not set(input_nums).issubset(set(candidate_nums)):
                return "Reject"
        
        if "AKA" in input_title.upper():
            if semantic_score >= 50:
                return "Possible Match"

        if len(input_title.split()) <= 2:
            if extra_words > 2 and semantic_score < 90:
                return "Reject"

        if semantic_score >= 88:
            return "Perfect Match"

        if 70 <= semantic_score < 88:
            if cross_score is not None:
                if cross_score >= 85:
                    return "Perfect Match"
                elif cross_score >= 75:
                    return "Possible Match"
                else:
                    return "Reject"
            return "Possible Match"

        return "Reject"
```

---

## `combined_match_logic()`

**Source lines:** 1420-1516

**Function signature inputs:** `self, row`

**Purpose:** Combines multiple matching signals into an overall score or decision workflow.

**Why this function is used in STM:** Title matching is safer when exact text, fuzzy similarity, semantic score, numeric compatibility and extra-word checks are considered together.

**Inputs explained:** Candidate title fields and score inputs.

**Outputs / side effects:** Combined match result or score.

**Detailed algorithm / logic:**
- Calculates/combines comparison signals.
- Applies thresholds and business rules.
- Returns final score/decision structure.

**Important calls detected inside:** `extract_numbers, extract_season_episode, get, issubset, len, set, split, str, strip, upper`

**Important values created or updated:** `c0, c1, candidate_nums, candidate_title, e0, e1, input_nums, input_title, r0, r1, s0, s1`

**Return statements detected:**
- `'Reject'`
- `'Reject'`
- `'Reject'`
- `'Perfect Match'`
- `'Reject'`
- `'Possible Match'`
- `'Possible Match'`
- `'Possible Match'`
- `'Reject'`
- `'Reject'`

**Maintenance guidance:** Before changing this function, verify every downstream usage in the STM script and update related tests, especially if column names, thresholds, return shape, workbook formatting, or decision labels change.

```python
    def combined_match_logic(self,row):
        r0 = row.get("MATCH_RESULT_0")   # series_title vs parent_title result
        r1 = row.get("MATCH_RESULT_1")   # input_title vs atom_title result

        s0 = row.get("SEMANTIC_SCORE_0", 0)
        s1 = row.get("SEMANTIC_SCORE_1", 0)
        c0 = row.get("CROSS_SCORE_0")
        c1 = row.get("CROSS_SCORE_1")
        e0 = row.get("EXTRA_WORDS_0", 0)
        e1 = row.get("EXTRA_WORDS_1", 0)

        input_title = str(row.get("INPUT_TITLE", "")).strip()
        candidate_title = str(row.get("ATOM_TITLE", "")).strip()

        # -------------------------------------------------
        # 1) HARD RULE: numbers must match (same as final_decision)
        # -------------------------------------------------
        input_s, input_e = self.extract_season_episode(input_title)
        cand_s, cand_e = self.extract_season_episode(candidate_title)

        if input_s is not None and cand_s is not None:

            if input_s != cand_s:
                return "Reject"

            if input_e != cand_e:
                return "Reject"

        else:
            input_nums = self.extract_numbers(input_title)
            candidate_nums = self.extract_numbers(candidate_title)

            if not set(input_nums).issubset(set(candidate_nums)):
                return "Reject"

        # -------------------------------------------------
        # 2) Extra word controls for episodic logic
        # -------------------------------------------------
        if len(input_title.split()) <= 2:
            if e1 > 2 and s1 < 90:
                return "Reject"

        if e0 > 3:
            return "Reject"

        if e1 > 4 and s1 < 85:
            return "Reject"

        # -------------------------------------------------
        # 3) If both individual decisions are perfect
        # -------------------------------------------------
        if r0 == "Perfect Match" and r1 == "Perfect Match":
            return "Perfect Match"

        # -------------------------------------------------
        # 4) If one side is rejected, overall should usually reject
        #    unless cross score strongly rescues it
        # -------------------------------------------------
        if r0 == "Reject" or r1 == "Reject":
            # Optional rescue logic
            if r0 == "Perfect Match" and r1 == "Reject":
                if c1 is not None and c1 >= 85:
                    return "Possible Match"
            if r1 == "Perfect Match" and r0 == "Reject":
                if c0 is not None and c0 >= 85:
                    return "Possible Match"
            return "Reject"

        # -------------------------------------------------
        # 5) Perfect + Possible combinations
        # -------------------------------------------------
        if r0 == "Perfect Match" and r1 == "Possible Match":
            if c1 is not None and c1 >= 85:
                return "Perfect Match"
            return "Possible Match"

        if r0 == "Possible Match" and r1 == "Perfect Match":
            if c0 is not None and c0 >= 85:
                return "Perfect Match"
            return "Possible Match"

        # -------------------------------------------------
        # 6) Both are Possible Match
        # -------------------------------------------------
        if r0 == "Possible Match" and r1 == "Possible Match":
            if (c0 is not None and c0 >= 85) and (c1 is not None and c1 >= 85):
                return "Perfect Match"
            return "Possible Match"

        # -------------------------------------------------
        # 7) AKA support
        # -------------------------------------------------
        if "AKA" in input_title.upper():
            if r1 in ("Perfect Match", "Possible Match") and s0 >= 75:
                return "Possible Match"

        return "Reject"
```

---

## `top_n_per_id()`

**Source lines:** 1520-1533

**Function signature inputs:** `df, id_col, score_col, n`

**Purpose:** Returns strongest candidates per input ID while preserving very high-confidence records.

**Why this function is used in STM:** Analysts need a focused list, but if more than N candidates score extremely high they should not be dropped.

**Inputs explained:** Candidate DataFrame, ID column, score column, N value.

**Outputs / side effects:** Reduced ranked DataFrame.

**Detailed algorithm / logic:**
- Groups DataFrame by input ID.
- If candidates meet high threshold, keeps those.
- Otherwise keeps top N by score.
- Recombines groups.

**Important calls detected inside:** `apply, groupby, head, reset_index, sort_values`

**Important values created or updated:** `df, high_score`

**Return statements detected:**
- `df.groupby(id_col, group_keys=False).apply(filter_group).reset_index(drop=True)`
- `group.head(n)`
- `high_score`

**Maintenance guidance:** Before changing this function, verify every downstream usage in the STM script and update related tests, especially if column names, thresholds, return shape, workbook formatting, or decision labels change.

```python
    def top_n_per_id(df, id_col, score_col, n):
        df = df.sort_values([id_col, score_col], ascending=[True, False])

        def filter_group(group):
            high_score = group[group[score_col] >= 90]
            if not high_score.empty:
                return high_score
            return group.head(n)

        return (
            df.groupby(id_col, group_keys=False)
            .apply(filter_group)
            .reset_index(drop=True)
        )
```

---

## `filter_group()`

**Source lines:** 1523-1527

**Function signature inputs:** `group`

**Purpose:** Implements the `filter_group` helper used by STM.

**Why this function is used in STM:** This helper isolates reusable STM logic so the main script can stay readable and consistent.

**Inputs explained:** Function parameters from the signature.

**Outputs / side effects:** Return value or side effect depending on implementation.

**Detailed algorithm / logic:**
- Reads parameters and any instance state.
- Performs the function-specific transformation, scoring, validation, formatting, or filtering.
- Returns a value or updates DataFrame/workbook state.

**Important calls detected inside:** `head`

**Important values created or updated:** `high_score`

**Return statements detected:**
- `group.head(n)`
- `high_score`

**Maintenance guidance:** Before changing this function, verify every downstream usage in the STM script and update related tests, especially if column names, thresholds, return shape, workbook formatting, or decision labels change.

```python
        def filter_group(group):
            high_score = group[group[score_col] >= 90]
            if not high_score.empty:
                return high_score
            return group.head(n)
```

---

## `flatten_groups()`

**Source lines:** 1536-1540

**Function signature inputs:** `groups`

**Purpose:** Flattens grouped intermediate results into a single DataFrame.

**Why this function is used in STM:** Output sheets need normal tabular data after grouped ranking operations.

**Inputs explained:** Grouped or listed DataFrames.

**Outputs / side effects:** Single flattened DataFrame.

**Detailed algorithm / logic:**
- Iterates group outputs.
- Concatenates into one DataFrame.

**Important calls detected inside:** `extend`

**Important values created or updated:** `ordered`

**Return statements detected:**
- `ordered`

**Maintenance guidance:** Before changing this function, verify every downstream usage in the STM script and update related tests, especially if column names, thresholds, return shape, workbook formatting, or decision labels change.

```python
    def flatten_groups(groups):
        ordered = []
        for _, cols in groups:
            ordered.extend(cols)
        return ordered
```

---

## `try_number_preserve_decimals()`

**Source lines:** 1543-1585

**Function signature inputs:** `x`

**Purpose:** Converts numeric-looking values while preserving meaningful decimal formatting.

**Why this function is used in STM:** Metadata identifiers and season/episode values can appear as strings, ints, or floats. Bad conversion can corrupt IDs.

**Inputs explained:** Single value.

**Outputs / side effects:** Converted or original value.

**Detailed algorithm / logic:**
- Attempts safe numeric conversion.
- Preserves meaningful decimals.
- Avoids destructive conversion for non-numeric or identifier-like values.

**Important calls detected inside:** `float, fullmatch, int, is_integer, isinf, isinstance, isna, isnan, replace, str, strip`

**Important values created or updated:** `f, s, s_clean`

**Return statements detected:**
- `x`
- `pd.NA`
- `int(x)`
- `int(x) if float(x).is_integer() else float(x)`
- `pd.NA`
- `pd.NA`
- `int(s_clean)`
- `int(f) if float(f).is_integer() else f`
- `x`
- `x`

**Maintenance guidance:** Before changing this function, verify every downstream usage in the STM script and update related tests, especially if column names, thresholds, return shape, workbook formatting, or decision labels change.

```python
    def try_number_preserve_decimals(x):
        """
        Convert only when safely numeric:
        - integer-like -> int
        - decimal -> float (preserve decimals)
        Otherwise keep value as-is.
        Empty -> NA (writes blank).
        """
        if x is None or pd.isna(x):
            return pd.NA

        # ints
        if isinstance(x, (int, np.integer)):
            return int(x)

        # floats
        if isinstance(x, (float, np.floating)):
            if math.isnan(x) or math.isinf(x):
                return pd.NA
            return int(x) if float(x).is_integer() else float(x)

        s = str(x).strip()
        if s == "":
            return pd.NA

        s_clean = s.replace(",", "")

        # pure integer string
        if re.fullmatch(r"[+-]?\d+", s_clean):
            try:
                return int(s_clean)
            except:
                return x

        # decimal string -> float
        if re.fullmatch(r"[+-]?\d+\.\d+", s_clean):
            try:
                f = float(s_clean)
                return int(f) if float(f).is_integer() else f
            except:
                return x

        return x
```

---

## `convert_columns_try_number_preserve_decimals()`

**Source lines:** 1587-1591

**Function signature inputs:** `self, df, cols`

**Purpose:** Applies safe numeric conversion to selected DataFrame columns.

**Why this function is used in STM:** Excel output should display numeric fields cleanly without corrupting identifiers.

**Inputs explained:** DataFrame and column list.

**Outputs / side effects:** DataFrame with safely converted values.

**Detailed algorithm / logic:**
- Loops through columns.
- Applies safe conversion to each value.
- Returns adjusted DataFrame.

**Important calls detected inside:** `apply`

**Important values created or updated:** `df[col]`

**Return statements detected:**
- `df`

**Maintenance guidance:** Before changing this function, verify every downstream usage in the STM script and update related tests, especially if column names, thresholds, return shape, workbook formatting, or decision labels change.

```python
    def convert_columns_try_number_preserve_decimals(self,df, cols):
        for col in cols:
            if col in df.columns:
                df[col] = df[col].apply(self.try_number_preserve_decimals)
        return df
```

---

## `apply_grouped_formatting()`

**Source lines:** 1594-1769

**Function signature inputs:** `self, df, sheet_name, ip_mode`

**Purpose:** Writes match DataFrames to Excel with grouped formatting.

**Why this function is used in STM:** Readable workbook formatting is essential for manual review.

**Inputs explained:** DataFrame, sheet name, IP mode.

**Outputs / side effects:** Formatted worksheet.

**Detailed algorithm / logic:**
- Writes DataFrame to specified sheet.
- Applies headers, formats, widths, frozen panes, filters and grouping.
- Uses IP mode to adjust formatting.

**Important calls detected inside:** `add_worksheet, append, astype, autofilter, contains, convert_columns_try_number_preserve_decimals, enumerate, extract_tt, flatten_groups, get, get_loc, group, isinf, isinstance, isna, isnan, len, lower, map, max, merge_range, min, notna, range, reindex` and 14 more

**Important values created or updated:** `col_name, col_positions, cols_present, cond, conds, count, df2, df2['For Ingestion'], end, existing_order, final_cols, fmt, groups, id_col_index, id_counts, id_fmt, identifier_cols_set, identifiers_cols, ingestion_col_index, labels, leftovers, leftovers_now, m, max_len, node_col_index` and 5 more

**Return statements detected:**
- `df2`
- `m.group(1).lower() if m else None`
- `None`

**Maintenance guidance:** Before changing this function, verify every downstream usage in the STM script and update related tests, especially if column names, thresholds, return shape, workbook formatting, or decision labels change.

```python
    def apply_grouped_formatting(self, df, sheet_name, ip_mode):
        
        groups = self.GROUPS.get(ip_mode, self.GROUPS["STANDALONE"])
        ordered_cols = self.flatten_groups(groups)

        existing_order = [c for c in ordered_cols if c in df.columns]
        leftovers = [c for c in df.columns if c not in existing_order]
        final_cols = existing_order + leftovers
        df2 = df.reindex(columns=final_cols)

        # numeric conversion (int if integer-like else float if decimal else keep)
        df2 = self.convert_columns_try_number_preserve_decimals(df2, self.NUM_COERCE_COLS)

        # ✅ IDENTIFIERS columns list for this mode (used for pipe highlighting)
        identifiers_cols = []
        for gname, cols in groups:
            if gname == "IDENTIFIERS":
                identifiers_cols = cols
                break
        identifier_cols_set = set([c for c in identifiers_cols if c in df2.columns])

        # For Ingestion: identifier NAME
        # Ignore values containing "|" for ingestion decision
        conds = []
        labels = []

        for col, out_label in self.INGESTION_PRIORITY_LABELS:
            if col in df2.columns:
                s_str = df2[col].astype("string").str.strip()
                cond = (
                    s_str.notna()
                    & (s_str != "")
                    & (~s_str.str.contains(r"\|", na=False))
                )
                conds.append(cond.to_numpy())
                labels.append(out_label)

        df2["For Ingestion"] = np.select(conds, labels, default="NO ID") if conds else "NO ID"

        # Ensure ordering follows GROUPS
        ordered_now = [c for c in ordered_cols if c in df2.columns]
        leftovers_now = [c for c in df2.columns if c not in ordered_cols]
        df2 = df2.reindex(columns=ordered_now + leftovers_now)

        worksheet = self.workbook.add_worksheet(sheet_name)
        self.writer.sheets[sheet_name] = worksheet

        worksheet.set_row(0, 20)
        worksheet.set_row(1, 30)

        col_positions = {c: i for i, c in enumerate(df2.columns)}

        # group bands
        for group_name, cols in groups:
            cols_present = [c for c in cols if c in df2.columns]
            if not cols_present:
                continue
            start = col_positions[cols_present[0]]
            end   = col_positions[cols_present[-1]]
            fmt = self.group_formats.get(group_name, self.group_band_format)

            if start == end:
                worksheet.write(0, start, group_name, fmt)
            else:
                worksheet.merge_range(0, start, 0, end, group_name, fmt)

        # headers
        for col_num, col_name in enumerate(df2.columns):
            fmt = self.header_format if col_name == "Sno" else self.header_format_match
            worksheet.write(1, col_num, col_name, fmt)

        worksheet.autofilter(1, 0, 1, len(df2.columns) - 1)

        # widths
        for col_num, col in enumerate(df2.columns):
            if col in self.FIXED_WIDTHS:
                width = self.FIXED_WIDTHS[col]
            else:
                max_len = max(df2[col].astype(str).map(len).max(), len(col)) + 2
                width = min(max_len, self.MAX_COL_WIDTH)
                width = max(width, self.MIN_COL_WIDTH)
            worksheet.set_column(col_num, col_num, width)

        # column indexes
        node_col_index = df2.columns.get_loc("NODE_IDENTIFIER") if "NODE_IDENTIFIER" in df2.columns else None
        tt_col_index   = df2.columns.get_loc("TT_CODES") if "TT_CODES" in df2.columns else None
        ingestion_col_index = df2.columns.get_loc("For Ingestion") if "For Ingestion" in df2.columns else None
        

        def extract_tt(s: str):
            if not s:
                return None
            m = re.search(r"(tt\d+)", s, flags=re.IGNORECASE)
            return m.group(1).lower() if m else None

        # data rows from row 2
        if "ID" in df2.columns:
            id_col_index = df2.columns.get_loc("ID")
            id_counts = df2["ID"].value_counts(dropna=False).to_dict()

            for r in range(len(df2)):
                row_id = df2.iloc[r]["ID"]
                count = id_counts.get(row_id, 0)
                id_fmt = self.id_green if count == 1 else self.id_yellow

                for c in range(len(df2.columns)):
                    value = df2.iloc[r, c]

                    # blanks / NaN / Inf
                    if value is None or (isinstance(value, float) and (math.isnan(value) or math.isinf(value))) or pd.isna(value):
                        worksheet.write(r + 2, c, "", id_fmt if c == id_col_index else self.border_format)
                        continue

                    # 🔴 Highlight NO ID / NO_ID in For Ingestion
                    if ingestion_col_index is not None and c == ingestion_col_index:
                        vstr = str(value).strip()
                        if vstr in ("NO ID", "NO_ID"):
                            worksheet.write(r + 2, c, vstr, self.no_id_red_format)
                        else:
                            worksheet.write(r + 2, c, value, self.border_format)
                        continue

                    # 🔴 NEW: If IDENTIFIERS cell contains "|", highlight in red
                    col_name = df2.columns[c]
                    if col_name in identifier_cols_set and "|" in str(value):
                        worksheet.write(r + 2, c, value, self.pipe_red_format)
                        continue

                    # NODE_IDENTIFIER hyperlink
                    if node_col_index is not None and c == node_col_index:
                        s = str(value).strip()
                        if s.startswith("entities/"):
                            node_id = s.replace("entities/", "", 1)
                            url = self.RELTIO_BASE_URL + node_id
                            worksheet.write_url(r + 2, c, url, self.link_format, node_id)
                        else:
                            worksheet.write(r + 2, c, s, self.border_format)
                        continue

                    # TT_CODES hyperlink (IMDb)
                    if tt_col_index is not None and c == tt_col_index:
                        s = str(value).strip()
                        tt = extract_tt(s)
                        if tt:
                            url = f"{self.IMDB_BASE_URL}{tt}/"
                            worksheet.write_url(r + 2, c, url, self.link_format, tt)
                        else:
                            worksheet.write(r + 2, c, s, self.border_format)
                        continue

                    # normal write
                    worksheet.write(r + 2, c, value, id_fmt if c == id_col_index else self.border_format)

        else:
            for r in range(len(df2)):
                for c in range(len(df2.columns)):
                    value = df2.iloc[r, c]
                    if value is None or (isinstance(value, float) and (math.isnan(value) or math.isinf(value))) or pd.isna(value):
                        worksheet.write(r + 2, c, "", self.border_format)
                        continue

                    # For Ingestion highlight
                    if ingestion_col_index is not None and c == ingestion_col_index:
                        vstr = str(value).strip()
                        worksheet.write(r + 2, c, vstr, self.no_id_red_format if vstr in ("NO ID", "NO_ID") else self.border_format)
                        continue

                    # IDENTIFIERS pipe highlight
                    col_name = df2.columns[c]
                    if col_name in identifier_cols_set and "|" in str(value):
                        worksheet.write(r + 2, c, value, self.pipe_red_format)
                        continue

                    worksheet.write(r + 2, c, value, self.border_format)

        return df2
```

---

## `extract_tt()`

**Source lines:** 1683-1687

**Function signature inputs:** `s`

**Purpose:** Implements the `extract_tt` helper used by STM.

**Why this function is used in STM:** This helper isolates reusable STM logic so the main script can stay readable and consistent.

**Inputs explained:** Function parameters from the signature.

**Outputs / side effects:** Return value or side effect depending on implementation.

**Detailed algorithm / logic:**
- Reads parameters and any instance state.
- Performs the function-specific transformation, scoring, validation, formatting, or filtering.
- Returns a value or updates DataFrame/workbook state.

**Important calls detected inside:** `group, lower, search`

**Important values created or updated:** `m`

**Return statements detected:**
- `m.group(1).lower() if m else None`
- `None`

**Maintenance guidance:** Before changing this function, verify every downstream usage in the STM script and update related tests, especially if column names, thresholds, return shape, workbook formatting, or decision labels change.

```python
        def extract_tt(s: str):
            if not s:
                return None
            m = re.search(r"(tt\d+)", s, flags=re.IGNORECASE)
            return m.group(1).lower() if m else None
```

---

## `format_no_match()`

**Source lines:** 1771-1793

**Function signature inputs:** `self, df, sheet_name`

**Purpose:** Writes and formats the No Match worksheet.

**Why this function is used in STM:** Unmatched records require manual investigation and must be separated.

**Inputs explained:** No-match DataFrame and sheet name.

**Outputs / side effects:** Formatted No Match worksheet.

**Detailed algorithm / logic:**
- Writes no-match rows.
- Applies header formatting and column sizing.

**Important calls detected inside:** `add_worksheet, astype, convert_columns_try_number_preserve_decimals, copy, enumerate, isinf, isinstance, isna, isnan, len, map, max, min, range, set_column, write`

**Important values created or updated:** `df_nm, max_len, self.writer.sheets[sheet_name], value, width, worksheet`

**Maintenance guidance:** Before changing this function, verify every downstream usage in the STM script and update related tests, especially if column names, thresholds, return shape, workbook formatting, or decision labels change.

```python
    def format_no_match(self,df, sheet_name):
        worksheet = self.workbook.add_worksheet(sheet_name)
        self.writer.sheets[sheet_name] = worksheet

        df_nm = df.copy()
        df_nm = self.convert_columns_try_number_preserve_decimals(df_nm, self.NUM_COERCE_COLS)

        for col_num, col_name in enumerate(df_nm.columns):
            worksheet.write(0, col_num, col_name, self.header_format)

        for col_num, col in enumerate(df_nm.columns):
            max_len = max(df_nm[col].astype(str).map(len).max(), len(col)) + 2
            width = min(max_len, self.MAX_COL_WIDTH)
            width = max(width, self.MIN_COL_WIDTH)
            worksheet.set_column(col_num, col_num, width)

        for r in range(len(df_nm)):
            for c in range(len(df_nm.columns)):
                value = df_nm.iloc[r, c]
                if value is None or (isinstance(value, float) and (math.isnan(value) or math.isinf(value))) or pd.isna(value):
                    worksheet.write(r + 1, c, "", self.border_format)
                else:
                    worksheet.write(r + 1, c, value, self.border_format)
```

---

## `score_series_matches()`

**Source lines:** 1795-1874

**Function signature inputs:** `self, series_df, input_titles_0, model, cross_model`

**Purpose:** Scores series-level candidates for ALL mode.

**Why this function is used in STM:** Parent series must be validated before seasons/episodes are matched to protect hierarchy accuracy.

**Inputs explained:** Series candidate DataFrame, original input DataFrame, embedding model, CrossEncoder model.

**Outputs / side effects:** Scored series candidates.

**Detailed algorithm / logic:**
- Maps original series titles to candidates.
- Normalizes input and candidate titles.
- Computes semantic and CrossEncoder scores.
- Applies decision and explainability logic.

**Important calls detected inside:** `add_explainability_columns, add_match_ranking, apply, apply_cross_encoder, astype, copy, cpu, drop, encode, fillna, final_decision, map, numpy, pairwise_cos_sim, round, set_index, to_numeric, tolist`

**Important values created or updated:** `atom_emb, input_emb, series_df, series_df['ATOM_TITLE'], series_df['ATOM_TITLE_NORM'], series_df['FINAL_MATCH_RESULT'], series_df['FINAL_SCORE'], series_df['ID'], series_df['INPUT_SERIES_TITLE'], series_df['INPUT_SERIES_TITLE_NORM'], series_df['INPUT_TITLE'], series_df['MATCH_LEVEL'], series_df['SEMANTIC_SCORE'], series_title_map`

**Return statements detected:**
- `series_df`
- `series_df`

**Maintenance guidance:** Before changing this function, verify every downstream usage in the STM script and update related tests, especially if column names, thresholds, return shape, workbook formatting, or decision labels change.

```python
    def score_series_matches(self,series_df, input_titles_0, model, cross_model):
        series_df = series_df.copy()

        if series_df.empty:
            series_df = self.add_match_ranking(
                series_df,
                "ID",
                "FINAL_SCORE"
            )

            series_df = self.add_explainability_columns(
                series_df,
                "FINAL_SCORE",
                "FINAL_MATCH_RESULT"
)
            return series_df

        series_df["ID"] = pd.to_numeric(series_df["ID"], errors="coerce").astype("Int64")

        series_title_map = input_titles_0.set_index("Sno")["SERIES_TITLE"]
        series_df["INPUT_SERIES_TITLE"] = series_df["ID"].map(series_title_map)

        series_df["INPUT_SERIES_TITLE"] = series_df["INPUT_SERIES_TITLE"].fillna("")
        series_df["ATOM_TITLE"] = series_df["ATOM_TITLE"].fillna("")

        series_df["INPUT_SERIES_TITLE_NORM"] = series_df["INPUT_SERIES_TITLE"].apply(self.normalize_title
        )
        series_df["ATOM_TITLE_NORM"] = series_df["ATOM_TITLE"].apply(self.normalize_title
        )

        input_emb = model.encode(series_df["INPUT_SERIES_TITLE_NORM"].tolist(), convert_to_tensor=True)
        atom_emb = model.encode(series_df["ATOM_TITLE_NORM"].tolist(), convert_to_tensor=True)
        series_df["SEMANTIC_SCORE"] = (util.pairwise_cos_sim(input_emb, atom_emb).cpu().numpy() * 100)


        series_df["SEMANTIC_SCORE"] = (util.pairwise_cos_sim(input_emb, atom_emb).cpu().numpy() * 100)

        series_df = self.apply_cross_encoder(
            series_df,
            "INPUT_SERIES_TITLE_NORM",
            "ATOM_TITLE_NORM",
            "SEMANTIC_SCORE",
            "CROSS_SCORE",
            cross_model
        )

        series_df["FINAL_MATCH_RESULT"] = series_df.apply(
            lambda r: self.final_decision(
                r["INPUT_SERIES_TITLE_NORM"],
                r["ATOM_TITLE_NORM"],
                r["SEMANTIC_SCORE"],
                r["CROSS_SCORE"]
            ),
            axis=1
        )

        series_df["SEMANTIC_SCORE"] = series_df["SEMANTIC_SCORE"].round(1)

        series_df = series_df.drop(
            columns=["INPUT_SERIES_TITLE_NORM", "ATOM_TITLE_NORM"],
            errors="ignore"
        )

        series_df["FINAL_SCORE"] = series_df["SEMANTIC_SCORE"]
        series_df["INPUT_TITLE"] = series_df["INPUT_SERIES_TITLE"]
        series_df["MATCH_LEVEL"] = "Series"

        series_df = self.add_match_ranking(
            series_df,
            "ID",
            "FINAL_SCORE"
        )

        series_df = self.add_explainability_columns(
            series_df,
            "FINAL_SCORE",
            "FINAL_MATCH_RESULT"
        )

        return series_df
```

---

## `score_child_matches()`

**Source lines:** 1877-2039

**Function signature inputs:** `self, child_df, input_titles_0, model, cross_model`

**Purpose:** Scores season and episode candidates after parent filtering.

**Why this function is used in STM:** Child records need their own logic because titles can be generic and depend on hierarchy context.

**Inputs explained:** Season/episode candidates, original input DataFrame, embedding model, CrossEncoder model.

**Outputs / side effects:** Scored child candidates.

**Detailed algorithm / logic:**
- Maps child input titles.
- Normalizes input and candidate titles.
- Computes semantic and CrossEncoder scores.
- Applies final decision and explainability.

**Important calls detected inside:** `add_explainability_columns, add_match_ranking, apply, apply_cross_encoder, astype, copy, cpu, drop, encode, error, extra_word_ratio, fillna, final_decision, get, map, numpy, pairwise_cos_sim, round, set_index, to_numeric, tolist`

**Important values created or updated:** `atom_emb, child_df, child_df['ATOM_TITLE_NORM'], child_df['EXTRA_WORDS_0'], child_df['EXTRA_WORDS_1'], child_df['FINAL_MATCH_RESULT'], child_df['FINAL_SCORE'], child_df['ID'], child_df['INPUT_TITLE'], child_df['INPUT_TITLE_NORM'], child_df['MATCH_RESULT_0'], child_df['MATCH_RESULT_1'], child_df['PARENT_TITLE_NORM'], child_df['SEMANTIC_SCORE_0'], child_df['SEMANTIC_SCORE_1'], child_df['SERIES_TITLE'], child_df['SERIES_TITLE_NORM'], child_df[c], input_emb, input_match_title_map, input_series_map, input_titles_0, parent_emb, series_emb`

**Return statements detected:**
- `child_df`
- `child_df`

**Maintenance guidance:** Before changing this function, verify every downstream usage in the STM script and update related tests, especially if column names, thresholds, return shape, workbook formatting, or decision labels change.

```python
    def score_child_matches(self,child_df, input_titles_0, model, cross_model):
        child_df = child_df.copy()

        if child_df.empty:
            child_df = self.add_match_ranking(
                child_df,
                "ID",
                "FINAL_SCORE"
            )

            child_df = self.add_explainability_columns(
                child_df,
                "FINAL_SCORE",
                "FINAL_MATCH_RESULT"
            )
            return child_df

        child_df["ID"] = pd.to_numeric(child_df["ID"], errors="coerce").astype("Int64")

        input_titles_0 = input_titles_0.copy()

        
        if "MATCH_TITLE_RAW" not in input_titles_0.columns:
            logger.error("MATCH_TITLE_RAW column missing from INPUT_TITLES_0")
            
        input_series_map = input_titles_0.set_index("Sno")["SERIES_TITLE"]
        input_match_title_map = input_titles_0.set_index("Sno")["MATCH_TITLE_RAW"]

        child_df["SERIES_TITLE"] = child_df["ID"].map(input_series_map)
        child_df["INPUT_TITLE"] = child_df["ID"].map(input_match_title_map)

        for c in ["PARENT_TITLE", "SERIES_TITLE", "INPUT_TITLE", "ATOM_TITLE"]:
            if c not in child_df.columns:
                child_df[c] = ""
            child_df[c] = child_df[c].fillna("").astype(str)

        child_df["SERIES_TITLE_NORM"] = child_df["SERIES_TITLE"].apply(
            self.normalize_title
        )
        child_df["PARENT_TITLE_NORM"] = child_df["PARENT_TITLE"].apply(
            self.normalize_title
        )
        child_df["INPUT_TITLE_NORM"] = child_df["INPUT_TITLE"].apply(
            self.normalize_title
        )
        child_df["ATOM_TITLE_NORM"] = child_df["ATOM_TITLE"].apply(
            self.normalize_title
        )

        series_emb = model.encode(
            child_df["SERIES_TITLE_NORM"].tolist(),
            convert_to_tensor=True
        )
        parent_emb = model.encode(
            child_df["PARENT_TITLE_NORM"].tolist(),
            convert_to_tensor=True
        )

        child_df["SEMANTIC_SCORE_0"] = (util.pairwise_cos_sim(series_emb, parent_emb).cpu().numpy() * 100)

        input_emb = model.encode(
            child_df["INPUT_TITLE_NORM"].tolist(),
            convert_to_tensor=True
        )
        atom_emb = model.encode(
            child_df["ATOM_TITLE_NORM"].tolist(),
            convert_to_tensor=True
        )

        child_df["SEMANTIC_SCORE_1"] = (util.pairwise_cos_sim(input_emb, atom_emb).cpu().numpy() * 100)


        child_df = self.apply_cross_encoder(
            child_df,
            "SERIES_TITLE_NORM",
            "PARENT_TITLE_NORM",
            "SEMANTIC_SCORE_0",
            "CROSS_SCORE_0",
            cross_model,
            75,
            88
        )

        child_df = self.apply_cross_encoder(
            child_df,
            "INPUT_TITLE_NORM",
            "ATOM_TITLE_NORM",
            "SEMANTIC_SCORE_1",
            "CROSS_SCORE_1",
            cross_model,
            75,
            88
        )

        child_df["MATCH_RESULT_0"] = child_df.apply(
            lambda row: self.final_decision(
                row["SERIES_TITLE_NORM"],
                row["PARENT_TITLE_NORM"],
                row["SEMANTIC_SCORE_0"],
                row.get("CROSS_SCORE_0", row["SEMANTIC_SCORE_0"])
            ),
            axis=1
        )

        child_df["MATCH_RESULT_1"] = child_df.apply(
            lambda row: self.final_decision(
                row["INPUT_TITLE_NORM"],
                row["ATOM_TITLE_NORM"],
                row["SEMANTIC_SCORE_1"],
                row.get("CROSS_SCORE_1", row["SEMANTIC_SCORE_1"])
            ),
            axis=1
        )

        child_df["EXTRA_WORDS_0"] = child_df.apply(
            lambda row: self.extra_word_ratio(
                row["SERIES_TITLE_NORM"],
                row["PARENT_TITLE_NORM"]
            ),
            axis=1
        )

        child_df["EXTRA_WORDS_1"] = child_df.apply(
            lambda row: self.extra_word_ratio(
                row["INPUT_TITLE_NORM"],
                row["ATOM_TITLE_NORM"]
            ),
            axis=1
        )

        child_df["FINAL_MATCH_RESULT"] = child_df.apply(
            self.combined_match_logic,
            axis=1
        )

        child_df["SEMANTIC_SCORE_0"] = child_df["SEMANTIC_SCORE_0"].round(1)
        child_df["SEMANTIC_SCORE_1"] = child_df["SEMANTIC_SCORE_1"].round(1)

        child_df = child_df.drop(
            columns=[
                "INPUT_TITLE_NORM",
                "ATOM_TITLE_NORM",
                "PARENT_TITLE_NORM",
                "SERIES_TITLE_NORM"
            ],
            errors="ignore"
        )

        child_df["FINAL_SCORE"] = child_df["SEMANTIC_SCORE_1"]

        child_df = self.add_match_ranking(
            child_df,
            "ID",
            "FINAL_SCORE"
        )

        child_df = self.add_explainability_columns(
            child_df,
            "FINAL_SCORE",
            "FINAL_MATCH_RESULT"
        )

        return child_df
```

---

## `filter_children_by_selected_series()`

**Source lines:** 2042-2072

**Function signature inputs:** `child_df, selected_parent_ids`

**Purpose:** Restricts season and episode candidates to analyst-selected parent series.

**Why this function is used in STM:** Without parent filtering, generic episodes could match the wrong series.

**Inputs explained:** Child candidate DataFrame and selected parent IDs.

**Outputs / side effects:** Filtered child candidate DataFrame.

**Detailed algorithm / logic:**
- Reads selected parent identifiers.
- Keeps child candidates whose parent belongs to selected set.

**Important calls detected inside:** `astype, concat, copy, drop, dropna, fillna, isin, notna, set, str, unique`

**Important values created or updated:** `child_df, child_df['PARENT_ENTITY_STR'], fallback, final_child_df, ids_with_scoped_candidates, scoped, selected_parent_ids`

**Return statements detected:**
- `final_child_df`
- `child_df`
- `child_df`
- `child_df`

**Maintenance guidance:** Before changing this function, verify every downstream usage in the STM script and update related tests, especially if column names, thresholds, return shape, workbook formatting, or decision labels change.

```python
    def filter_children_by_selected_series(child_df, selected_parent_ids):
        child_df = child_df.copy()

        if child_df.empty:
            return child_df

        if "PARENT_ENTITY" not in child_df.columns:
            return child_df

        if not selected_parent_ids:
            return child_df

        selected_parent_ids = set(str(x) for x in selected_parent_ids if pd.notna(x))

        child_df["PARENT_ENTITY_STR"] = child_df["PARENT_ENTITY"].fillna("").astype(str)

        scoped = child_df[
            child_df["PARENT_ENTITY_STR"].isin(selected_parent_ids)
        ].copy()

        ids_with_scoped_candidates = set(scoped["ID"].dropna().unique())

        fallback = child_df[
            (~child_df["ID"].isin(ids_with_scoped_candidates))
            & (~child_df["PARENT_ENTITY_STR"].isin(selected_parent_ids))
        ].copy()

        final_child_df = pd.concat([scoped, fallback], ignore_index=True, sort=False)
        final_child_df = final_child_df.drop(columns=["PARENT_ENTITY_STR"], errors="ignore")

        return final_child_df
```

---


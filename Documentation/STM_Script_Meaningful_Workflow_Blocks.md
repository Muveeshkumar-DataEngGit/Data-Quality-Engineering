# STM Script - Meaningful Workflow Blocks with Notes Above Code

This documentation separates the main script into meaningful workflow stages. It focuses on why each stage exists and how the stage changes the data.

## High-level data flow

Excel input → mode-specific title preparation → Snowflake candidate retrieval → semantic scoring → CrossEncoder validation → ranking → Top/Partial/No Match output.

## Workflow block index

1. **Startup imports and helper initialization** lines 1-24
2. **Processing mode and IP category definitions** lines 25-37
3. **Input workbook selection and loading** lines 38-55
4. **S and SE preprocessing with AKA expansion** lines 56-74
5. **ALL mode hierarchy-aware title construction** lines 75-109
6. **Title normalization and SQL VALUES payload creation** lines 110-134
7. **Snowflake connection and query filter setup** lines 135-153
8. **Snowflake candidate retrieval SQL** lines 154-668
9. **Execute Snowflake query and build candidate DataFrame** lines 669-680
10. **Separate candidates by processing mode** lines 681-720
11. **Output folder and model setup** lines 721-756
12. **Dynamic token-length estimation and CrossEncoder loading** lines 757-853
13. **S and SE semantic scoring and final decision flow** lines 854-1018
14. **S and SE top, partial, and no-match preparation** lines 1019-1183
15. **ALL mode series-first scoring and selection workbook** lines 1184-1270
16. **ALL mode selected-series filtering and child scoring** lines 1271-1335
17. **ALL mode ranking, partial matches, and no-match preparation** lines 1336-1390
18. **Final Excel export** lines 1391-1437

---

## Stage 1: Startup imports and helper initialization

**Source lines:** 1-24

**Purpose:** Loads all libraries needed for tabular processing, model scoring, file dialogs, logging, and project helper functions.

**Outputs / impact:** Makes pandas, torch, transformer models, tkinter, logging, and `all_functions` available; initializes the helper object and logger.

```python
    #==================================
    #LIBRARY IMPORTS
    #==================================

    import pandas as pd
    from sentence_transformers import SentenceTransformer, CrossEncoder
    import warnings
    warnings.filterwarnings("ignore")
    from tkinter import Tk
    from tkinter.filedialog import askopenfilename
    import os
    import torch
    from transformers import AutoTokenizer
    import numpy as np
    import sys
    import logging

    #=================================
    # OWN FUNCTIONS
    #=================================

    from Packages.functions import all_functions
    smart_title_matching_functions=all_functions()

```

---

## Stage 2: Processing mode and IP category definitions

**Source lines:** 25-37

**Purpose:** Collects the analyst-selected mode and defines which ATOM IP_TYPE values are valid for each workflow.

**Outputs / impact:** Produces `IP` plus Series, Standalone, Seasons, Episodic, and combined category lists that control downstream filtering.

```python
    logger = logging.getLogger(__name__)
    logger.setLevel(logging.INFO)
    f = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    fh = logging.FileHandler('Smart.log', mode='w')   # ✅ overwrite file
    fh.setFormatter(f)
    logger.addHandler(fh)


    IP = input("Enter the IP_Category [SE-Series, S-Standalone, ALL-Series_Season_Episodic]: ").strip().upper()
    valid_ip_values = {"S", "SE", "ALL"}
    if IP not in valid_ip_values:
        raise ValueError("Invalid IP value. Please enter only S, SE, or ALL.")

```

---

## Stage 3: Input workbook selection and loading

**Source lines:** 38-55

**Purpose:** Lets the analyst choose an Excel file and loads it into pandas.

**Outputs / impact:** Creates `INPUT_TITLES` as the working DataFrame and `INPUT_TITLES_0` as the preserved original copy.

```python
    Series= ["Series",'Mini Series','Feature','Special','Short','TV Movie','Made For Video']
    Standalone=['Special','Feature | Special','Feature | TV Movie','Short','TV Movie','Feature','Made For Video','Feature | Short','Supplemental','']
    Seasons=['Season','Supplemental','Non-IP','Term Deal','Ancillary/Derivative','Consumer Products','Live Stage','Mini Series','Special']
    Episodic=['Episode','Special','Short','Segment','Music','Publishing','Pilot','Game','']
    Series_Season_Episode=["Series",'Mini Series','Feature','Special','Short','TV Movie','Made For Video','Season','Supplemental','Non-IP','Term Deal','Ancillary/Derivative','Consumer Products','Live Stage','Mini Series','Episode','Special','Short','Segment','Music','Publishing','Pilot','Game','']

    # Hide the root window
    Tk().withdraw()

    # Open file picker dialog
    file_path = askopenfilename(title="Select Excel file", filetypes=[("Excel files", "*.xlsx")])

    # Load CSV into DataFrame
    try:
        if file_path:
            INPUT_TITLES = pd.read_excel(file_path)
            INPUT_TITLES_0=INPUT_TITLES.copy()
        else:
```

---

## Stage 4: S and SE preprocessing with AKA expansion

**Source lines:** 56-74

**Purpose:** For standalone or series-only modes, splits the Features field into multiple searchable rows.

**Outputs / impact:** Expands AKA titles so Snowflake can search each variant.

```python
            logger.info("No file selected.")
            sys.exit(0)
    except Exception as e:
        logger.error(f"Error loading file: {e}")
        sys.exit(1)

    ## Reset index and create Sno
    if IP in ("S", "SE"):
        INPUT_TITLES["Features"] = INPUT_TITLES["Features"].astype(str)
        INPUT_TITLES["Features"] = INPUT_TITLES["Features"].apply(smart_title_matching_functions.split_aka)
        INPUT_TITLES = INPUT_TITLES.explode("Features").reset_index(drop=True)

    elif IP == "ALL":
        episode_col = "EPISODE_TITLE" if "EPISODE_TITLE" in INPUT_TITLES.columns else "Episode"

        if "SERIES_TITLE" not in INPUT_TITLES.columns:
            INPUT_TITLES["SERIES_TITLE"] = ""

        if episode_col not in INPUT_TITLES.columns:
```

---

## Stage 5: ALL mode hierarchy-aware title construction

**Source lines:** 75-109

**Purpose:** Builds MATCH_TITLE_RAW for Series, Season, and Episode rows using different logic for each hierarchy level.

**Outputs / impact:** Ensures series, season, and episode records use the correct searchable title source and context.

```python
            INPUT_TITLES[episode_col] = ""

        INPUT_TITLES["SERIES_TITLE"] = INPUT_TITLES["SERIES_TITLE"].fillna("").astype(str)
        INPUT_TITLES[episode_col] = INPUT_TITLES[episode_col].fillna("").astype(str)

        INPUT_TITLES["MATCH_TITLE_RAW"] = ""
        series_mask  = INPUT_TITLES["IP_TYPE"].isin(Series)
        season_mask  = INPUT_TITLES["IP_TYPE"].isin(Seasons)
        episode_mask = INPUT_TITLES["IP_TYPE"].isin(Episodic)


        INPUT_TITLES.loc[series_mask, "MATCH_TITLE_RAW"] = INPUT_TITLES.loc[
            series_mask, "SERIES_TITLE"
        ]

        INPUT_TITLES.loc[season_mask, "MATCH_TITLE_RAW"] = INPUT_TITLES.loc[
            season_mask, "EPISODE_TITLE"
        ]

        INPUT_TITLES.loc[episode_mask, "MATCH_TITLE_RAW"] = INPUT_TITLES.loc[
            episode_mask
        ].apply(
            lambda row: smart_title_matching_functions.genric_merger(
                row[episode_col],
                row["SERIES_TITLE"],
                row.get("SeasonNumber"),
                row.get("EpisodeNumber")
            ),
            axis=1
        )

        # Important: preserve raw title in INPUT_TITLES_0 before split/explode
        INPUT_TITLES_0 = INPUT_TITLES.copy()

        INPUT_TITLES["MATCH_TITLE"] = INPUT_TITLES["MATCH_TITLE_RAW"].apply(
```

---

## Stage 6: Title normalization and SQL VALUES payload creation

**Source lines:** 110-134

**Purpose:** Normalizes prepared titles and converts them into a Snowflake-friendly SQL VALUES string.

**Outputs / impact:** Creates `Input_titles`, the payload injected into the Snowflake query.

```python
            smart_title_matching_functions.split_aka
        )
        INPUT_TITLES = INPUT_TITLES.explode("MATCH_TITLE").reset_index(drop=True)

    ## Normalize titles and escape single quotes for SQL
    if IP in ("S","SE"):
        INPUT_TITLES["Features"]=INPUT_TITLES["Features"].apply(smart_title_matching_functions.normalize_title)
        INPUT_TITLES["Features"] = INPUT_TITLES["Features"].str.replace("'", "''")

        Input_titles = ",".join([
            f"('{i}', '{j}', {int(k)})" if not pd.isna(k) else f"('{i}', '{j}', {0})"
            for i, j, k in zip(
                INPUT_TITLES["Sno"],
                INPUT_TITLES["Features"],
                INPUT_TITLES["Years"]
            )
        ])
    elif IP == "ALL":
        INPUT_TITLES["MATCH_TITLE"] = INPUT_TITLES["MATCH_TITLE"].apply(smart_title_matching_functions.normalize_title)
        INPUT_TITLES["MATCH_TITLE"] = INPUT_TITLES["MATCH_TITLE"].str.replace("'", "''")

        Input_titles = ",".join([
            f"('{i}', '{j}', {int(k)})" if not pd.isna(k) else f"('{i}', '{j}', {0})"
            for i, j, k in zip(
                INPUT_TITLES["Sno"],
```

---

## Stage 7: Snowflake connection and query filter setup

**Source lines:** 135-153

**Purpose:** Opens the Snowflake connection and prepares IP category / parent-child filters for candidate retrieval.

**Outputs / impact:** Produces connection/cursor objects and SQL filter variables.

```python
                INPUT_TITLES["MATCH_TITLE"],
                INPUT_TITLES["Years"]
            )
        ])

    ## Filtered data from snowflake and check all the Pid's present:

    # Create connection
    conn = smart_title_matching_functions.get_connection()

    # Create a cursor
    cur = conn.cursor()


    # Convert list to SQL-friendly string
    if IP=="SE":
        IP_Category = ",".join(f"'{pid}'" for pid in Series)
    elif IP=="S":
        IP_Category = ",".join(f"'{pid}'" for pid in Standalone)
```

---

## Stage 8: Snowflake candidate retrieval SQL

**Source lines:** 154-668

**Purpose:** Builds the main SQL query that reduces the ATOM catalog into likely candidates before AI scoring.

**Outputs / impact:** Creates `query`, which returns candidate rows with hierarchy, identifiers, similarity fields, and match flags.

**Detailed SQL reading guide:**
- `ATOM_DATA` starts from episodic hierarchy metadata.
- Hierarchy CTEs fill missing series/season/episode identifiers.
- `raw_inputs` injects Excel titles into Snowflake.
- Token-based CTEs compare input words to ATOM title words.
- `Final_matches` applies year and generic-episode compatibility filters.
- `ranked_candidates` uses Snowflake similarity functions to keep candidates for AI scoring.

```python
    elif IP=="ALL":
        IP_Category = ",".join(f"'{pid}'" for pid in Series_Season_Episode)

    #MPM_Episode_str = ",".join(f"'{pid}'" for pid in Episode)
    if IP == "ALL":
        IS_PARENTS = "'P','C'"
    elif IP == "SE":
        IS_PARENTS = "'P','C'"
    else:
        IS_PARENTS = "'C'"

    # First query
    logger.info("Loading snowflake data..")
    query = fr"""
    WITH ATOM_DATA AS (
        SELECT 
            E.SERIES_IDENTIFIER,
            E.NODE_IDENTIFIER,
            E.IP_TYPE,
            E.MPM_NUMBER,
            E.SEASON_MPM_NUMBER,
            E.SERIES_MPM_NUMBER
        FROM BOLT_MSC_CDS_PROD.ATOM_BI.EPISODIC_TITLE_HIERARCHY_VW E
    ),

    HIERARCHY_INFO1 AS (
        SELECT
            E.SERIES_IDENTIFIER,
            E.NODE_IDENTIFIER,
            E.IP_TYPE,
            COALESCE(E.MPM_NUMBER, T.MPM_NUMBER) AS EPISODE_MPM_NUMBER,
            COALESCE(E.SEASON_MPM_NUMBER, T.MPM_PRODUCT_NUMBER) AS SEASON_MPM_NUMBER,
            COALESCE(E.SERIES_MPM_NUMBER, T.MPM_FAMILY_NUMBER) AS SERIES_MPM_NUMBER,
            T.PROPERTY_ID,
            T.PI_UUID
        FROM ATOM_DATA E
        LEFT JOIN BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE T
            ON E.NODE_IDENTIFIER = T.NODE_IDENTIFIER
    ),

    SERIES_LOOKUP AS (
        SELECT
            SERIES_MPM_NUMBER,
            MAX(SERIES_IDENTIFIER) AS SERIES_IDENTIFIER
        FROM HIERARCHY_INFO1
        GROUP BY SERIES_MPM_NUMBER
    ),

    FILLING_IDENTIFIERS AS (
        SELECT
            SL.SERIES_MPM_NUMBER,
            T.NODE_IDENTIFIER AS SERIES_IDENTIFIER
        FROM SERIES_LOOKUP SL
        LEFT JOIN BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE T
            ON SL.SERIES_MPM_NUMBER = T.MPM_NUMBER
        WHERE T.NODE_IDENTIFIER IS NOT NULL
    ),

    HIERARCHY_INFO_F AS (
        SELECT
            COALESCE(H.SERIES_IDENTIFIER, SL.SERIES_IDENTIFIER, SSL.SERIES_IDENTIFIER) AS SERIES_IDENTIFIER,
            SSL.SEASON_IDENTIFIER,
            H.NODE_IDENTIFIER,
            H.IP_TYPE,
            H.EPISODE_MPM_NUMBER,
            H.SEASON_MPM_NUMBER,
            COALESCE(H.SERIES_MPM_NUMBER, SSL.SERIES_MPM_NUMBER) AS SERIES_MPM_NUMBER,
            H.PROPERTY_ID,
            H.PI_UUID
        FROM HIERARCHY_INFO1 H
        LEFT JOIN FILLING_IDENTIFIERS SL
            ON H.SERIES_MPM_NUMBER = SL.SERIES_MPM_NUMBER
        LEFT JOIN (
            SELECT
                SEASON_IDENTIFIER,
                SEASON_MPM_NUMBER,
                SERIES_IDENTIFIER,
                SERIES_MPM_NUMBER
            FROM (
                SELECT
                    H2.SEASON_MPM_NUMBER,
                    T.NODE_IDENTIFIER AS SEASON_IDENTIFIER,
                    T.MPM_FAMILY_NUMBER AS SERIES_MPM_NUMBER,
                    T.NODE_IDENTIFIER AS SERIES_IDENTIFIER,
                    ROW_NUMBER() OVER (
                        PARTITION BY H2.SEASON_MPM_NUMBER
                        ORDER BY T.NODE_IDENTIFIER
                    ) AS RN
                FROM HIERARCHY_INFO1 H2
                LEFT JOIN BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE T
                    ON H2.SEASON_MPM_NUMBER = T.MPM_NUMBER
            )
            WHERE RN = 1
        ) SSL
            ON H.SEASON_MPM_NUMBER = SSL.SEASON_MPM_NUMBER
    ),

    Heirachy_Integrity1 AS (
        SELECT 
            CASE 
                WHEN HF.NODE_IDENTIFIER = HF.SERIES_IDENTIFIER THEN NULL 
                ELSE HF.SERIES_IDENTIFIER 
            END AS SERIES_IDENTIFIER,
            HF.SEASON_IDENTIFIER,
            HF.NODE_IDENTIFIER,
            HF.IP_TYPE,
            T.MPM_FAMILY_NUMBER,
            T.MPM_PRODUCT_NUMBER,
            T.MPM_NUMBER
        FROM HIERARCHY_INFO_F HF
        LEFT JOIN BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE T
            ON HF.NODE_IDENTIFIER = T.NODE_IDENTIFIER
    ),

    Heirachy_Integrity1_series AS (
        SELECT 
            H1.SERIES_IDENTIFIER, H1.SEASON_IDENTIFIER, H1.NODE_IDENTIFIER, H1.IP_TYPE,
            H1.MPM_FAMILY_NUMBER, H1.MPM_PRODUCT_NUMBER, H1.MPM_NUMBER,
            COALESCE(T.TITLE, T.LIBRARY_TITLE_FULL, T.LIBRARY_TITLE_SHORT) AS SERIES_TITLE
        FROM Heirachy_Integrity1 H1
        LEFT JOIN BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE T
            ON H1.SERIES_IDENTIFIER = T.NODE_IDENTIFIER
    ),

    Heirachy_Integrity1_season AS (
        SELECT 
            H1.SERIES_IDENTIFIER, H1.SEASON_IDENTIFIER, H1.NODE_IDENTIFIER, H1.IP_TYPE,
            H1.MPM_FAMILY_NUMBER, H1.MPM_PRODUCT_NUMBER, H1.MPM_NUMBER,
            H1.SERIES_TITLE,
            COALESCE(T.TITLE, T.LIBRARY_TITLE_FULL, T.LIBRARY_TITLE_SHORT) AS SEASON_TITLE
        FROM Heirachy_Integrity1_series H1
        LEFT JOIN BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE T
            ON H1.SEASON_IDENTIFIER = T.NODE_IDENTIFIER
    ),

    Heirachy_Integrity_episode AS (
        SELECT 
            H1.SERIES_IDENTIFIER, H1.SEASON_IDENTIFIER, H1.NODE_IDENTIFIER, H1.IP_TYPE,
            H1.MPM_FAMILY_NUMBER, H1.MPM_PRODUCT_NUMBER, H1.MPM_NUMBER,
            H1.SERIES_TITLE, H1.SEASON_TITLE,
            COALESCE(T.TITLE, T.LIBRARY_TITLE_FULL, T.LIBRARY_TITLE_SHORT) AS EPISODE_TITLE
        FROM Heirachy_Integrity1_season H1
        LEFT JOIN BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE T
            ON H1.NODE_IDENTIFIER = T.NODE_IDENTIFIER
    ),

    Heirachy_Integrity AS (
        SELECT *,
        CASE
            WHEN IP_TYPE IN ('Episode','Special','Short','Segment','Music','Publishing','Pilot','Game','') AND REGEXP_LIKE(UPPER(COALESCE(EPISODE_TITLE,'')),
                '^(S\\d+\\s*)?(EPISODE|EPI|EP|E)\\s*#?\\s*\\d+$|^(SEASON|EPISODE|EPI|EP|E|S)$')
            THEN COALESCE(SEASON_TITLE, SERIES_TITLE) || ' ' || EPISODE_TITLE

            WHEN IP_TYPE IN ('Season','Supplemental','Non-IP','Term Deal','Ancillary/Derivative','Consumer Products','Live Stage') AND REGEXP_LIKE(UPPER(COALESCE(EPISODE_TITLE,'')),
                '^(SEASON|SEA|S)\\s*#?\\s*\\d+$|^(SEASON|EPISODE|EPI|EP|E|S)$')
            THEN COALESCE(SERIES_TITLE, SEASON_TITLE) || ' ' || EPISODE_TITLE

            WHEN REGEXP_LIKE(UPPER(COALESCE(EPISODE_TITLE,'')),
                '^(S\\d+\\s*)?(EPISODE|EPI|EP|E)\\s*#?\\s*\\d+$|^(SEASON|SEA|S)\\s*#?\\s*\\d+$|^(SEASON|EPISODE|EPI|EP|E|S)$')
            THEN COALESCE(SERIES_TITLE, SEASON_TITLE) || ' ' || EPISODE_TITLE

            ELSE EPISODE_TITLE
        END AS Titles_heirachy
        FROM Heirachy_Integrity_episode
    ),

    /* ATOM Search (optimized — single D_TITLE scan): */
    raw_inputs AS (
        SELECT 
            column1 AS id,
            column2 AS input_title,
            column3 AS input_year,
            CASE
                WHEN REGEXP_LIKE(
                    UPPER(REGEXP_REPLACE(column2, '[^A-Z0-9 ]', ' ')),
                    '(^| )((SEASON|SEA|S) *[0-9]+ *(EPISODE|EPI|EP|E) *#? *[0-9]+|S[0-9]+ *E[0-9]+|(EPISODE|EPI|EP|E) *#? *[0-9]+)( |$)'
                )
                THEN 1
                ELSE 0
            END AS INPUT_IS_GENERIC_EPISODE
        FROM VALUES 
            {Input_titles}
    ),
    input_words AS (
        SELECT DISTINCT
            r.id,
            r.input_title,
            r.input_year,
            r.INPUT_IS_GENERIC_EPISODE,
            TRIM(f.value::string) AS input_word
        FROM raw_inputs r,
        LATERAL FLATTEN(
            INPUT => SPLIT(
                REGEXP_REPLACE(LOWER(r.input_title), '[^a-z0-9à-ÿ ]', ''),
                ' '
            )
        ) f
        WHERE TRIM(f.value::string) <> ''
    ),

    input_word_count AS (
        SELECT 
            id,
            COUNT(*) AS total_input_words
        FROM input_words
        GROUP BY id
    ),

    title_base AS (

        /* Primary: TITLE */
        SELECT DISTINCT
            m.NODE_IDENTIFIER,
            m.TITLE AS LIBRARY_TITLE,
            m.pi_uuid,
            m.MPM_NUMBER,
            m.ip_type,
            COALESCE(m.ORIGINAL_RELEASE_YEAR, m.PRODUCTION_YEAR) AS YEARS,
            TRIM(f.value::string) AS title_word,
            CASE
                WHEN REGEXP_LIKE(
                    UPPER(REGEXP_REPLACE(COALESCE(m.TITLE, ''), '[^A-Z0-9 ]', ' ')),
                    '(^| )((SEASON|SEA|S) *[0-9]+ *(EPISODE|EPI|EP|E) *#? *[0-9]+|S[0-9]+ *E[0-9]+|(EPISODE|EPI|EP|E) *#? *[0-9]+)( |$)'
                )
                THEN 1
                ELSE 0
            END AS ATOM_IS_GENERIC_EPISODE
        FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE m,
        LATERAL FLATTEN(
            INPUT => SPLIT(
                REGEXP_REPLACE(LOWER(m.TITLE), '[^[:alnum:] ]', ''),
                ' '
            )
        ) f
        WHERE COALESCE(TRIM(m.IP_TYPE), '') IN ({IP_Category})
        AND TRIM(f.value::string) <> ''

        UNION ALL

        /* Secondary: AKA_PKA_TITLES */
        SELECT DISTINCT
            m.NODE_IDENTIFIER,
            m.AKA_PKA_TITLES AS LIBRARY_TITLE,
            m.pi_uuid,
            m.MPM_NUMBER,
            m.ip_type,
            COALESCE(m.ORIGINAL_RELEASE_YEAR, m.PRODUCTION_YEAR) AS YEARS,
            TRIM(f.value::string) AS title_word,
            CASE
                WHEN REGEXP_LIKE(
                    UPPER(REGEXP_REPLACE(COALESCE(m.AKA_PKA_TITLES, ''), '[^A-Z0-9 ]', ' ')),
                    '(^| )((SEASON|SEA|S) *[0-9]+ *(EPISODE|EPI|EP|E) *#? *[0-9]+|S[0-9]+ *E[0-9]+|(EPISODE|EPI|EP|E) *#? *[0-9]+)( |$)'
                )
                THEN 1
                ELSE 0
            END AS ATOM_IS_GENERIC_EPISODE
        FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE m,
        LATERAL FLATTEN(
            INPUT => SPLIT(
                REGEXP_REPLACE(LOWER(m.AKA_PKA_TITLES), '[^a-z0-9à-ÿ ]', ''),
                ' '
            )
        ) f
        WHERE COALESCE(TRIM(m.IP_TYPE), '') IN ({IP_Category})
        AND TRIM(f.value::string) <> ''

        UNION ALL

        /* Third: LIBRARY_TITLE_FULL */
        SELECT DISTINCT
            m.NODE_IDENTIFIER,
            COALESCE(m.LIBRARY_TITLE_FULL, m.library_title_short) AS LIBRARY_TITLE,
            m.pi_uuid,
            m.MPM_NUMBER,
            m.ip_type,
            COALESCE(m.ORIGINAL_RELEASE_YEAR, m.PRODUCTION_YEAR) AS YEARS,
            TRIM(f.value::string) AS title_word,
            CASE
                WHEN REGEXP_LIKE(
                    UPPER(REGEXP_REPLACE(COALESCE(COALESCE(m.LIBRARY_TITLE_FULL, m.library_title_short), ''), '[^A-Z0-9 ]', ' ')),
                    '(^| )((SEASON|SEA|S) *[0-9]+ *(EPISODE|EPI|EP|E) *#? *[0-9]+|S[0-9]+ *E[0-9]+|(EPISODE|EPI|EP|E) *#? *[0-9]+)( |$)'
                )
                THEN 1
                ELSE 0
            END AS ATOM_IS_GENERIC_EPISODE
        FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE m,
        LATERAL FLATTEN(
            INPUT => SPLIT(
                REGEXP_REPLACE(LOWER(COALESCE(m.LIBRARY_TITLE_FULL, m.library_title_short)), '[^a-z0-9à-ÿ ]', ''),
                ' '
            )
        ) f
        WHERE COALESCE(TRIM(m.IP_TYPE), '') IN ({IP_Category})
        AND TRIM(f.value::string) <> ''

        UNION ALL

        /* Fourth: Generic titles */
        SELECT DISTINCT
            m.NODE_IDENTIFIER,
            H.Titles_heirachy AS LIBRARY_TITLE,
            m.pi_uuid,
            m.MPM_NUMBER,
            m.ip_type,
            COALESCE(m.ORIGINAL_RELEASE_YEAR, m.PRODUCTION_YEAR) AS YEARS,
            TRIM(f.value::string) AS title_word,
            CASE
                WHEN REGEXP_LIKE(
                    UPPER(REGEXP_REPLACE(COALESCE(H.Titles_heirachy, ''), '[^A-Z0-9 ]', ' ')),
                    '(^| )((SEASON|SEA|S) *[0-9]+ *(EPISODE|EPI|EP|E) *#? *[0-9]+|S[0-9]+ *E[0-9]+|(EPISODE|EPI|EP|E) *#? *[0-9]+)( |$)'
                )
                THEN 1
                ELSE 0
            END AS ATOM_IS_GENERIC_EPISODE
        FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE m
        LEFT JOIN Heirachy_Integrity H
            ON m.NODE_IDENTIFIER = H.NODE_IDENTIFIER,
        LATERAL FLATTEN(
            INPUT => SPLIT(
                REGEXP_REPLACE(LOWER(H.Titles_heirachy), '[^a-z0-9à-ÿ ]', ''),
                ' '
            )
        ) f
        WHERE COALESCE(TRIM(m.IP_TYPE), '') IN ({IP_Category})
        AND TRIM(f.value::string) <> ''
    ),

    title_words AS (
        SELECT DISTINCT
            NODE_IDENTIFIER,
            LIBRARY_TITLE,
            PI_UUID,
            MPM_NUMBER,
            IP_TYPE,
            YEARS,
            title_word,
            ATOM_IS_GENERIC_EPISODE
        FROM title_base
    ),
    matched_titles AS (
        SELECT 
            i.id,
            t.NODE_IDENTIFIER,
            t.LIBRARY_TITLE,
            t.PI_UUID,
            t.MPM_NUMBER,
            t.IP_TYPE,
            t.YEARS,
            i.input_title,
            i.input_year,
            MAX(COALESCE(r.INPUT_IS_GENERIC_EPISODE, 0)) AS INPUT_IS_GENERIC_EPISODE,
            MAX(COALESCE(t.ATOM_IS_GENERIC_EPISODE, 0)) AS ATOM_IS_GENERIC_EPISODE,
            COUNT(DISTINCT t.title_word) AS matched_words
        FROM input_words i
        JOIN raw_inputs r
            ON i.id = r.id
        JOIN title_words t
            ON i.input_word = t.title_word
        GROUP BY 
            i.id,
            t.NODE_IDENTIFIER,
            t.LIBRARY_TITLE,
            t.PI_UUID,
            t.MPM_NUMBER,
            t.IP_TYPE,
            t.YEARS,
            i.input_title,
            i.input_year
    ),

    Final_matches AS (
        SELECT 
            m.id,
            m.input_title AS Input_title,
            m.input_year,
            m.LIBRARY_TITLE AS Atom_title,
            m.YEARS,
            m.IP_TYPE,
            m.NODE_IDENTIFIER,
            m.MPM_NUMBER,
            m.PI_UUID,
            CASE 
                WHEN m.YEARS IS NULL THEN 'NULL'
                WHEN m.input_year = 0 THEN 'NULL'
                WHEN SPLIT_PART(m.YEARS, '|', 1) BETWEEN m.input_year - 3 AND m.input_year + 3 
                    THEN 'GOOD_MATCH'
                ELSE 'CHECK_YEAR'
            END AS YEAR_MATCH_FLAG
        FROM matched_titles m
        JOIN input_word_count iwc
            ON m.id = iwc.id
        WHERE m.matched_words >= CEIL(0.20 * iwc.total_input_words)

        -- ✅ Generic input must match only generic ATOM title
        AND (
                '{IP}' <> 'ALL'
                OR NOT REGEXP_LIKE(
                        UPPER(REGEXP_REPLACE(COALESCE(m.input_title, ''), '[^A-Z0-9 ]', ' ')),
                        '(^| )((SEASON|SEA|S) *[0-9]+ *(EPISODE|EPI|EP|E) *#? *[0-9]+|S[0-9]+ *E[0-9]+|(EPISODE|EPI|EP|E) *#? *[0-9]+)( |$)'
                    )
                OR REGEXP_LIKE(
                        UPPER(REGEXP_REPLACE(COALESCE(m.LIBRARY_TITLE, ''), '[^A-Z0-9 ]', ' ')),
                        '(^| )((SEASON|SEA|S) *[0-9]+ *(EPISODE|EPI|EP|E) *#? *[0-9]+|S[0-9]+ *E[0-9]+|(EPISODE|EPI|EP|E) *#? *[0-9]+)( |$)'
                    )
            )
    ),


    Atom_title_matching AS (
        SELECT *
        FROM Final_matches
        WHERE YEAR_MATCH_FLAG IN ('NULL', 'GOOD_MATCH')
    ),

    FINAL_OUTPUT AS (
        SELECT 
            A.*,
            CASE
                WHEN EXISTS (
                    SELECT 1 FROM Heirachy_Integrity H
                    WHERE H.SERIES_IDENTIFIER = A.NODE_IDENTIFIER
                ) THEN 'P'
                ELSE 'C'
            END AS IS_PARENT
        FROM Atom_title_matching A
    ),

    Final_matching_titles AS (
        SELECT
            id,
            input_title,
            Atom_title,
            input_year,
            YEARS,
            F.IP_TYPE,
            F.NODE_IDENTIFIER,
            F.MPM_NUMBER,
            F.PI_UUID,
            H.SERIES_IDENTIFIER,
            F.IS_PARENT
        FROM FINAL_OUTPUT F
        LEFT JOIN Heirachy_Integrity H
            ON F.NODE_IDENTIFIER = H.NODE_IDENTIFIER
        WHERE IS_PARENT IN ({IS_PARENTS})
    ),

    FINAL_OUTPUT_last1 AS (
        SELECT
            id,
            input_title,
            Atom_title,
            A1.LIBRARY_TITLE_FULL,
            input_year,
            YEARS,
            CASE
            WHEN REGEXP_LIKE(COALESCE(A1.ALTERNATE_IDENTIFIERS_VALUE,''), 'tt[0-9]+', 'i')
            THEN REGEXP_SUBSTR(A1.ALTERNATE_IDENTIFIERS_VALUE, 'tt[^ ]+', 1, 1, 'i')
            END AS TT_CODES,
            F.IP_TYPE,
            F.NODE_IDENTIFIER,
            F.MPM_NUMBER,
            A1.MPM_PRODUCT_NUMBER,
            F.PI_UUID,
            A1.PROPERTY_ID,
            A1.HBO_ID,
            A1.META_ID,
            A1.TURNER_TITLEID,
            A1.MMS3_MCode,
            A1.DASH_Title_ID,
            A1.Aleph_ID,
            A1.iBroadcast_EMEA_ID,
            A1.iBroadcast_APAC_ID,
            A.NODE_IDENTIFIER AS PARENT_ENTITY,
            COALESCE(A.LIBRARY_TITLE_FULL, A.LIBRARY_TITLE_SHORT) AS PARENT_TITLE,
            A.MPM_NUMBER AS PARENT_MPM,
            CASE WHEN (UPPER(A1.LIBRARY_TITLE_FULL) LIKE 'SDS%' OR UPPER(A1.LIBRARY_TITLE_FULL) LIKE '%SDS%' OR UPPER(A1.LIBRARY_TITLE_FULL) LIKE '%DO NOT USE%') OR
                    (UPPER(A1.LIBRARY_TITLE_SHORT) LIKE 'SDS%' OR UPPER(A1.LIBRARY_TITLE_SHORT) LIKE '%SDS%' OR UPPER(A1.LIBRARY_TITLE_SHORT) LIKE '%DO NOT USE%') OR
                    (UPPER(A1.TITLE) LIKE 'SDS%' OR UPPER(A1.TITLE) LIKE '%SDS%' OR UPPER(A1.TITLE) LIKE '%DO NOT USE%') 
                THEN 'Reject'
                ELSE 'Pass' 
            END AS SDS_CHECK_FLAG,
            F.IS_PARENT
        FROM Final_matching_titles F
        LEFT JOIN BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE A1
            ON F.NODE_IDENTIFIER = A1.NODE_IDENTIFIER
        LEFT JOIN BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE A
            ON F.SERIES_IDENTIFIER = A.NODE_IDENTIFIER
    ),
    FINAL_OUTPUT_last as (
    SELECT * 
    FROM FINAL_OUTPUT_last1
    WHERE SDS_CHECK_FLAG='Pass'
    ),
    children_summary AS (
        SELECT
            SERIES_IDENTIFIER,
            LISTAGG(IP_TYPE || '[' || cnt || ']', ' + ') WITHIN GROUP (ORDER BY IP_TYPE) AS CHILDREN_COUNT
        FROM (
            SELECT SERIES_IDENTIFIER, IP_TYPE, COUNT(*) AS cnt
            FROM Heirachy_Integrity
            GROUP BY SERIES_IDENTIFIER, IP_TYPE
        )
        GROUP BY SERIES_IDENTIFIER
    ),
    Snowflake_final_result AS (
        SELECT 
            r.id,
            r.input_title,
            F.ATOM_TITLE,
            F.LIBRARY_TITLE_FULL,
            r.input_year,
            F.YEARS,
            F.TT_CODES,
            F.IP_TYPE,
            F.NODE_IDENTIFIER,
```

---

## Stage 9: Execute Snowflake query and build candidate DataFrame

**Source lines:** 669-680

**Purpose:** Runs the candidate SQL and converts Snowflake rows into pandas.

**Outputs / impact:** Creates `SnowFlake_Results` and closes Snowflake resources.

```python
            F.MPM_NUMBER,
            F.MPM_PRODUCT_NUMBER,
            F.PI_UUID,
            F.PROPERTY_ID,
            F.HBO_ID,
            F.META_ID,
            F.TURNER_TITLEID,
            F.MMS3_MCode,
            F.DASH_Title_ID,
            F.Aleph_ID,
            F.iBroadcast_EMEA_ID,
            F.iBroadcast_APAC_ID,
```

---

## Stage 10: Separate candidates by processing mode

**Source lines:** 681-720

**Purpose:** Splits Snowflake candidates into mode-specific DataFrames for standalone/series or ALL hierarchy processing.

**Outputs / impact:** Creates mode-specific candidate DataFrames.

```python
            F.PARENT_ENTITY,
            F.PARENT_TITLE,
            F.PARENT_MPM,
            CS.CHILDREN_COUNT AS CHILDREN_STATUS,
            F.IS_PARENT
        FROM raw_inputs r
        LEFT JOIN FINAL_OUTPUT_last F
            ON r.id = F.id
        LEFT JOIN children_summary CS
            ON F.NODE_IDENTIFIER = CS.SERIES_IDENTIFIER
    ),

    ranked_candidates AS (
        SELECT
            F.*,
            JAROWINKLER_SIMILARITY(LOWER(F.input_title), LOWER(F.ATOM_TITLE)) AS JW,
            EDITDISTANCE(LOWER(F.input_title), LOWER(F.ATOM_TITLE)) AS ED,
            ROW_NUMBER() OVER (
                PARTITION BY F.id
                ORDER BY
                    JAROWINKLER_SIMILARITY(LOWER(F.input_title), LOWER(F.ATOM_TITLE)) DESC,
                    EDITDISTANCE(LOWER(F.input_title), LOWER(F.ATOM_TITLE)) ASC
            ) AS RN
        FROM Snowflake_final_result F
    )

    SELECT *,
    CASE WHEN NODE_IDENTIFIER IS NULL THEN 'No match' ELSE 'Match' END AS MATCHES
    FROM ranked_candidates
    WHERE JW >= 50
    AND RN <= 30
    ORDER BY id, JW DESC, ED ASC;
    """

    try:
        logger.info("Executing query on Snowflake...")
        with conn.cursor() as cur:
            cur.execute(query)
            rows = cur.fetchall()
            cols = [c[0] for c in cur.description]
```

---

## Stage 11: Output folder and model setup

**Source lines:** 721-756

**Purpose:** Selects output folder and prepares NLP model/tokenizer settings.

**Outputs / impact:** Creates `Output_folder`, model variables, tokenizer, and token-length inputs.

```python
    except Exception as e:
        logger.error(f"Error executing query check the VPN (or credentials): {e}")
        sys.exit(1)

    SnowFlake_Results = pd.DataFrame(rows, columns=cols)


    # Close connection
    cur.close()
    conn.close()


    if IP == "ALL":
        # Separating Seasons and Epiosdes
        Series_id = [str(i) for i in INPUT_TITLES_0[INPUT_TITLES_0["IP_TYPE"]=="Series"]["Sno"].to_list()]
        Seasons_id = [str(i) for i in INPUT_TITLES_0[INPUT_TITLES_0["IP_TYPE"]=="Season"]["Sno"].to_list()]
        Episodes_id = [str(i) for i in INPUT_TITLES_0[INPUT_TITLES_0["IP_TYPE"]=="Episode"]["Sno"].to_list()]
        SnowFlake_Results["ID"] = SnowFlake_Results["ID"].astype(str)

        Series_id = [str(i) for i in INPUT_TITLES_0[INPUT_TITLES_0["IP_TYPE"].eq("Series")]["Sno"].to_list()]
        Seasons_id = [str(i) for i in INPUT_TITLES_0[INPUT_TITLES_0["IP_TYPE"].eq("Season")]["Sno"].to_list()]
        Episodes_id = [str(i) for i in INPUT_TITLES_0[INPUT_TITLES_0["IP_TYPE"].eq("Episode")]["Sno"].to_list()]

        Series_SnowFlake_Results = SnowFlake_Results[
            SnowFlake_Results["ID"].isin(Series_id)
            & SnowFlake_Results["IP_TYPE"].isin(Series)
            & SnowFlake_Results["IS_PARENT"].isin(["P","C"])
            & SnowFlake_Results["MATCHES"].eq("Match")
        ].copy()

        Season_SnowFlake_Results = SnowFlake_Results[
            SnowFlake_Results["ID"].isin(Seasons_id)
            & SnowFlake_Results["IP_TYPE"].isin(Seasons)
            & SnowFlake_Results["MATCHES"].eq("Match")
        ].copy()

```

---

## Stage 12: Dynamic token-length estimation and CrossEncoder loading

**Source lines:** 757-853

**Purpose:** Calculates safe CrossEncoder max length based on actual candidate title pairs.

**Outputs / impact:** Creates `chosen_len` and `cross_model`.

```python
        Episode_SnowFlake_Results = SnowFlake_Results[
            SnowFlake_Results["ID"].isin(Episodes_id)
            & SnowFlake_Results["IP_TYPE"].isin(Episodic)
            & SnowFlake_Results["IS_PARENT"].isin(["C"])
            & SnowFlake_Results["MATCHES"].eq("Match")
        ].copy()

    elif IP in ("S","SE"):
        No_matches=SnowFlake_Results[SnowFlake_Results["MATCHES"]=="No match"]
        Matches=SnowFlake_Results[SnowFlake_Results["MATCHES"]=="Match"]
        Matches["ID"] = pd.to_numeric(Matches["ID"], errors="coerce").astype("Int64")
    else:
        No_matches=SnowFlake_Results[SnowFlake_Results["MATCHES"]=="No match"]
        Matches=SnowFlake_Results[SnowFlake_Results["MATCHES"]=="Match"]
        Matches["ID"] = pd.to_numeric(Matches["ID"], errors="coerce").astype("Int64")
        Matches=pd.merge(Matches,INPUT_TITLES,how="left",left_on="ID",right_on="Sno")
        Matches=Matches[["ID","SERIES_TITLE","PARENT_TITLE","INPUT_TITLE","ATOM_TITLE","INPUT_YEAR","TT_CODES","YEARS","IP_TYPE","NODE_IDENTIFIER","MPM_NUMBER","MPM_PRODUCT_NUMBER","PI_UUID","PROPERTY_ID","HBO_ID","META_ID","TURNER_TITLEID",'MMS3_MCODE', 'DASH_TITLE_ID', 'ALEPH_ID', 'IBROADCAST_EMEA_ID','IBROADCAST_APAC_ID',"PARENT_ENTITY","PARENT_MPM"]]
    ## DEFS:

    ## SEMANTIC SCORING:

    Output_folder=smart_title_matching_functions.select_output_folder()
    # Step 0: Semantic Matching (AI)
    logger.info("Loading the Model...")

    os.environ["TRANSFORMERS_NO_TF"] = "1"

    model = SentenceTransformer("all-MiniLM-L6-v2")

    model_name = "cross-encoder/stsb-roberta-base"
    tokenizer = AutoTokenizer.from_pretrained(model_name)

    model_max = tokenizer.model_max_length
    if model_max is None or model_max > 10000:
        model_max = 512

    token_length_source = pd.DataFrame()

    if IP in ("S", "SE"):
        token_length_source = Matches[["INPUT_TITLE", "ATOM_TITLE"]].copy()

    elif IP == "ALL":
        token_frames = []

        if not Series_SnowFlake_Results.empty:
            temp = Series_SnowFlake_Results.copy()
            temp["ID_INT"] = pd.to_numeric(temp["ID"], errors="coerce").astype("Int64")
            series_title_map = INPUT_TITLES_0.set_index("Sno")["SERIES_TITLE"]
            temp["INPUT_TITLE_FOR_TOKEN"] = temp["ID_INT"].map(series_title_map)
            token_frames.append(
                temp[["INPUT_TITLE_FOR_TOKEN", "ATOM_TITLE"]].rename(
                    columns={"INPUT_TITLE_FOR_TOKEN": "INPUT_TITLE"}
                )
            )

        if not Season_SnowFlake_Results.empty:
            temp = Season_SnowFlake_Results.copy()
            temp["ID_INT"] = pd.to_numeric(temp["ID"], errors="coerce").astype("Int64")
            match_title_map = INPUT_TITLES_0.set_index("Sno")["MATCH_TITLE_RAW"]
            temp["INPUT_TITLE_FOR_TOKEN"] = temp["ID_INT"].map(match_title_map)
            token_frames.append(
                temp[["INPUT_TITLE_FOR_TOKEN", "ATOM_TITLE"]].rename(
                    columns={"INPUT_TITLE_FOR_TOKEN": "INPUT_TITLE"}
                )
            )

        if not Episode_SnowFlake_Results.empty:
            temp = Episode_SnowFlake_Results.copy()
            temp["ID_INT"] = pd.to_numeric(temp["ID"], errors="coerce").astype("Int64")
            match_title_map = INPUT_TITLES_0.set_index("Sno")["MATCH_TITLE_RAW"]
            temp["INPUT_TITLE_FOR_TOKEN"] = temp["ID_INT"].map(match_title_map)
            token_frames.append(
                temp[["INPUT_TITLE_FOR_TOKEN", "ATOM_TITLE"]].rename(
                    columns={"INPUT_TITLE_FOR_TOKEN": "INPUT_TITLE"}
                )
            )

        if token_frames:
            token_length_source = pd.concat(token_frames, ignore_index=True, sort=False)

    token_lengths = []

    if not token_length_source.empty:
        token_length_source["INPUT_TITLE"] = token_length_source["INPUT_TITLE"].fillna("").astype(str)
        token_length_source["ATOM_TITLE"] = token_length_source["ATOM_TITLE"].fillna("").astype(str)

        for t1, t2 in zip(
            token_length_source["INPUT_TITLE"].tolist(),
            token_length_source["ATOM_TITLE"].tolist()
        ):
            enc = tokenizer(
                t1,
                t2,
                truncation=True,
                max_length=model_max
            )
            token_lengths.append(len(enc["input_ids"]))
```

---

## Stage 13: S and SE semantic scoring and final decision flow

**Source lines:** 854-1018

**Purpose:** Normalizes title pairs, computes embedding cosine similarity, applies CrossEncoder, and creates match decisions.

**Outputs / impact:** Creates scored `Matches` with scores, labels, and explainability fields.

**Why this stage is important:** This is where STM changes from raw candidate retrieval into analyst-ready decision support by reducing noise, ranking options, and separating top, partial, and unresolved cases.

```python

    if token_lengths:
        p95 = int(np.percentile(token_lengths, 95))
        chosen_len = min(p95, model_max)
    else:
        chosen_len = min(128, model_max)


    cross_model = CrossEncoder(model_name, max_length=chosen_len+20)  # +10 for safety margin

    ## SEMANTIC MATCHING IN ACTION:


    PARTIAL_THRESHOLD = 50


    if IP in ("S", "SE"):
        # ----------------------------
        # STANDALONE
        # ----------------------------

        Matches["INPUT_TITLE"] = Matches["INPUT_TITLE"].fillna("")
        Matches["ATOM_TITLE"]  = Matches["ATOM_TITLE"].fillna("")

        Matches["INPUT_TITLE_NORM"] = Matches["INPUT_TITLE"].apply(smart_title_matching_functions.normalize_title)
        Matches["ATOM_TITLE_NORM"]  = Matches["ATOM_TITLE"].apply(smart_title_matching_functions.normalize_title)

        # Semantic similarity
        def rowwise_cosine(a, b):
            a = torch.nn.functional.normalize(a, p=2, dim=1)
            b = torch.nn.functional.normalize(b, p=2, dim=1)
            return (a * b).sum(dim=1)

        colA_emb = model.encode(Matches["INPUT_TITLE_NORM"].tolist(), convert_to_tensor=True)
        colB_emb = model.encode(Matches["ATOM_TITLE_NORM"].tolist(),  convert_to_tensor=True)

        pair_scores = rowwise_cosine(colA_emb, colB_emb)
        Matches["SEMANTIC_SCORE"] = (pair_scores.cpu().numpy() * 100)

        # Cross encoder
        Matches = smart_title_matching_functions.apply_cross_encoder(
            Matches, "INPUT_TITLE_NORM", "ATOM_TITLE_NORM",
            "SEMANTIC_SCORE", "CROSS_SCORE", cross_model
        )

        # Final decision
        Matches["MATCH_RESULT"] = Matches.apply(
            lambda r: smart_title_matching_functions.final_decision(
                r["INPUT_TITLE_NORM"], r["ATOM_TITLE_NORM"],
                r["SEMANTIC_SCORE"], r["CROSS_SCORE"]
            ),
            axis=1
        )

        Matches["SEMANTIC_SCORE"] = Matches["SEMANTIC_SCORE"].round(1)
        Matches["EXTRA_WORDS"] = Matches.apply(
            lambda row: smart_title_matching_functions.extra_word_ratio(row["INPUT_TITLE_NORM"], row["ATOM_TITLE_NORM"]),
            axis=1
        )
        Matches["FINAL_SCORE"] = Matches["SEMANTIC_SCORE"]

        Matches = smart_title_matching_functions.add_explainability_columns(
            Matches,
            "FINAL_SCORE",
            "MATCH_RESULT"
        )
        Matches = Matches.drop(columns=["INPUT_TITLE_NORM", "ATOM_TITLE_NORM"], errors="ignore")

        # Keep scored universe (avoid full .copy() unless you need to mutate independently)
        Matches_scored_all = Matches

        # -------- Top match (Top3, non-reject) --------
        Matches_valid = Matches_scored_all[Matches_scored_all["MATCH_RESULT"] != "Reject"]

        Matches_top3 = smart_title_matching_functions.top_n_per_id(Matches_valid, "ID", "SEMANTIC_SCORE", 3)
        Matches_top3 = smart_title_matching_functions.add_match_ranking(
            Matches_top3,
            "ID",
            "SEMANTIC_SCORE"
        )


        # Convert MPM_NUMBER safely (fast + stable)
        if "MPM_NUMBER" in Matches_top3.columns:
            Matches_top3["MPM_NUMBER"] = [(i if "/" in str(i) else int(i)) if pd.notna(i) else "" for i in Matches_top3["MPM_NUMBER"]]

        # Dedupe after shrinking
        if "NODE_IDENTIFIER" in Matches_top3.columns:
            Matches_top3 = Matches_top3.drop_duplicates(subset=["ID", "NODE_IDENTIFIER"], keep="first")

        # Add INPUT title/features using map (faster than merge)
        features_map = INPUT_TITLES_0.set_index("Sno")["Features"]
        Matches_top3["INPUT_TITLES"] = Matches_top3["ID"].map(features_map)

        # Select final columns (only existing)
        if IP == "SE":
            desired_cols_top = [
                "ID", "INPUT_TITLES", "ATOM_TITLE", "INPUT_YEAR", "YEARS", "TT_CODES", "IP_TYPE",
                "NODE_IDENTIFIER","LIBRARY_TITLE_FULL", "MPM_NUMBER", "SEMANTIC_SCORE", "MATCH_RESULT",
                "CONFIDENCE",
                "FINAL_REASON",
                "MATCH_RANK",
                "KEEP_RECOMMENDED",
                "MATCH_EVIDENCE",
                "CHILDREN_STATUS",
                "PI_UUID","HBO_ID","META_ID","TURNER_TITLEID",
                'MMS3_MCODE', 'DASH_TITLE_ID', 'ALEPH_ID', 'IBROADCAST_EMEA_ID','IBROADCAST_APAC_ID'
            ]
        else:
            desired_cols_top = [
                "ID", "INPUT_TITLES", "ATOM_TITLE", "INPUT_YEAR", "YEARS", "TT_CODES", "IP_TYPE",
                "NODE_IDENTIFIER","LIBRARY_TITLE_FULL", "MPM_NUMBER", "PARENT_TITLE","PARENT_ENTITY","PARENT_MPM",
                "SEMANTIC_SCORE", "MATCH_RESULT",
                "CONFIDENCE",
                "FINAL_REASON",
                "MATCH_RANK",
                "KEEP_RECOMMENDED",
                "MATCH_EVIDENCE",
                "PI_UUID","PROPERTY_ID","HBO_ID","META_ID","TURNER_TITLEID",
                'MMS3_MCODE', 'DASH_TITLE_ID', 'ALEPH_ID', 'IBROADCAST_EMEA_ID','IBROADCAST_APAC_ID'
            ]
        Matches_top3 = Matches_top3[[c for c in desired_cols_top if c in Matches_top3.columns]]

        top_ids = set(Matches_top3["ID"].dropna().unique())

        # -------- Partial match (Top4 per ID, score>=threshold, excluding top IDs) --------
        Partial_pool = Matches_scored_all[
            (Matches_scored_all["SEMANTIC_SCORE"] >= PARTIAL_THRESHOLD) &
            (~Matches_scored_all["ID"].isin(top_ids))
        ]

        # If you want to exclude rejects in partial too, uncomment:
        # Partial_pool = Partial_pool[Partial_pool["MATCH_RESULT"] != "Reject"]

        Partial_matches = smart_title_matching_functions.top_n_per_id(Partial_pool, "ID", "SEMANTIC_SCORE", 4)
        Partial_matches = smart_title_matching_functions.add_match_ranking(
            Partial_matches,
            "ID",
            "SEMANTIC_SCORE"
        )

        if "MPM_NUMBER" in Partial_matches.columns:
            Partial_matches["MPM_NUMBER"] = [(i if "/" in str(i) else int(i)) if pd.notna(i) else "" for i in Partial_matches["MPM_NUMBER"]]

        if "NODE_IDENTIFIER" in Partial_matches.columns:
            Partial_matches = Partial_matches.drop_duplicates(subset=["ID", "NODE_IDENTIFIER"], keep="first")

        Partial_matches["INPUT_TITLES"] = Partial_matches["ID"].map(features_map)
        if IP == "SE":
            desired_cols_partial = [
                "ID", "INPUT_TITLES", "ATOM_TITLE", "INPUT_YEAR", "YEARS", "TT_CODES", "IP_TYPE","LIBRARY_TITLE_FULL",
                "NODE_IDENTIFIER", "MPM_NUMBER", "SEMANTIC_SCORE", "MATCH_RESULT",
                "CONFIDENCE",
                "FINAL_SCORE",
                "FINAL_REASON",
                "MATCH_RANK",
                "KEEP_RECOMMENDED",
                "MATCH_EVIDENCE",
                "CHILDREN_STATUS",
                "PI_UUID","HBO_ID","META_ID","TURNER_TITLEID",
                'MMS3_MCODE', 'DASH_TITLE_ID', 'ALEPH_ID', 'IBROADCAST_EMEA_ID','IBROADCAST_APAC_ID'
            ]
        else:
            desired_cols_partial = [
                "ID", "INPUT_TITLES", "ATOM_TITLE", "INPUT_YEAR", "YEARS", "TT_CODES", "IP_TYPE","LIBRARY_TITLE_FULL",
```

---

## Stage 14: S and SE top, partial, and no-match preparation

**Source lines:** 1019-1183

**Purpose:** Builds Top Match, Partial Match, and No Match outputs for standalone/series modes.

**Outputs / impact:** Creates `Matches_top3`, `Partial_matches`, and `No_match_sheet`.

**Why this stage is important:** This is where STM changes from raw candidate retrieval into analyst-ready decision support by reducing noise, ranking options, and separating top, partial, and unresolved cases.

```python
                "NODE_IDENTIFIER", "MPM_NUMBER", "PARENT_TITLE","PARENT_ENTITY","PARENT_MPM",
                "SEMANTIC_SCORE", "MATCH_RESULT",
                "CONFIDENCE",
                "FINAL_SCORE",
                "FINAL_REASON",
                "MATCH_RANK",
                "KEEP_RECOMMENDED",
                "MATCH_EVIDENCE",
                "PI_UUID","PROPERTY_ID","HBO_ID","META_ID","TURNER_TITLEID",
                'MMS3_MCODE', 'DASH_TITLE_ID', 'ALEPH_ID', 'IBROADCAST_EMEA_ID','IBROADCAST_APAC_ID'
                
            ]
        Partial_matches = Partial_matches[[c for c in desired_cols_partial if c in Partial_matches.columns]]
        perfects=Partial_matches[(Partial_matches["MATCH_RESULT"]=="Perfect Match")|(Partial_matches["MATCH_RESULT"]=="Possible Match")|(Partial_matches["SEMANTIC_SCORE"]>=85)]
        perfects["MATCH_RESULT"]=["Possible Match" if i=="Reject" else i for i in perfects["MATCH_RESULT"]]
        Matches_top3=pd.concat([Matches_top3,perfects])
        Matches_top3 = Matches_top3.sort_values(
        ["ID","MATCH_RANK"],
        ascending=[True,True])
        top_ids = set(Matches_top3["ID"].dropna().unique())
        Partial_matches = Partial_matches[~Partial_matches["ID"].isin(perfects["ID"].unique())]
        Partial_matches = Partial_matches.sort_values(
        ["ID","MATCH_RANK"],
        ascending=[True,True])
        partial_ids = set(Partial_matches["ID"].dropna().unique())
        Matches_top3 = Matches_top3.drop(
            columns=["MATCH_RESULT", "KEEP_RECOMMENDED","FINAL_SCORE"],
            errors="ignore"
        )
        Partial_matches = Partial_matches.drop(
            columns=["MATCH_RESULT", "KEEP_RECOMMENDED","FINAL_SCORE"],
            errors="ignore"
        )

        # -------- No match --------
        all_input_ids = set(INPUT_TITLES_0["Sno"].dropna().unique())
        no_match_ids = sorted(INPUT_TITLES_0[~INPUT_TITLES_0["Sno"].isin(top_ids.union(partial_ids))]["Sno"])

        No_match_sheet = (
            INPUT_TITLES_0[INPUT_TITLES_0["Sno"].isin(no_match_ids)][["Sno", "Features","Years"]]
            .rename(columns={"Sno": "ID", "Features": "INPUT_TITLE"})
            .sort_values("ID")
            .reset_index(drop=True)
        )


    else:
        # ----------------------------
        # ALL: SERIES FIRST, USER SELECTION, THEN SEASON + EPISODE
        # ----------------------------

        logger.info("Processing ALL flow: Series first, then Season/Episode based on user selection...")

        # 1. Score Series candidates first
        Series_scored_all = smart_title_matching_functions.score_series_matches(
        Series_SnowFlake_Results,
        INPUT_TITLES_0,
        model,
        cross_model)

        if Series_scored_all.empty or "FINAL_MATCH_RESULT" not in Series_scored_all.columns:
            Series_top3_for_selection = pd.DataFrame(
                columns=[
                    "ID",
                    "INPUT_TITLE",
                    "ATOM_TITLE",
                    "LIBRARY_TITLE_FULL",
                    "INPUT_YEAR",
                    "YEARS",
                    "TT_CODES",
                    "IP_TYPE",
                    "NODE_IDENTIFIER",
                    "MPM_NUMBER",
                    "FINAL_SCORE",
                    "FINAL_MATCH_RESULT",
                    "CHILDREN_STATUS",
                    "Select_Series"
                ]
            )
        else:
            Series_valid = Series_scored_all[
                Series_scored_all["FINAL_MATCH_RESULT"] != "Reject"
            ].copy()

            Series_top3_for_selection = smart_title_matching_functions.top_n_per_id(
                Series_valid,
                "ID",
                "FINAL_SCORE",
                3
            )


        if "NODE_IDENTIFIER" in Series_top3_for_selection.columns:
            Series_top3_for_selection = Series_top3_for_selection.drop_duplicates(
                subset=["ID", "NODE_IDENTIFIER"],
                keep="first"
            )

        series_selection_cols = [
            "ID",
            "INPUT_TITLE",
            "ATOM_TITLE",
            "INPUT_YEAR",
            "YEARS",
            "TT_CODES",
            "IP_TYPE",
            "LIBRARY_TITLE_FULL",
            "NODE_IDENTIFIER",
            "MPM_NUMBER",
            "CONFIDENCE",
            "FINAL_SCORE",
            "FINAL_REASON",
            "MATCH_RANK",
            "KEEP_RECOMMENDED",
            "MATCH_EVIDENCE",
            "CHILDREN_STATUS",
            "PI_UUID",
            "PROPERTY_ID",
            "HBO_ID",
            "META_ID",
            "TURNER_TITLEID",
            "MMS3_MCODE",
            "DASH_TITLE_ID",
            "ALEPH_ID",
            "IBROADCAST_EMEA_ID",
            "IBROADCAST_APAC_ID"
        ]

        Series_top3_for_selection = Series_top3_for_selection[
            [c for c in series_selection_cols if c in Series_top3_for_selection.columns]
        ].copy()

        Series_top3_for_selection["Select_Series"] = "No"

        series_selection_path = os.path.join(Output_folder, "Series_Selection.xlsx")

        smart_title_matching_functions.write_series_selection_file(
            Series_top3_for_selection,
            series_selection_path
        )

        logger.info(f"Series selection file created: {series_selection_path}")

        print("\nSeries selection file created:")
        print(series_selection_path)
        print("\nPlease open the file, select Yes/No in Select_Series column, save and close Excel.")
        print("After saving the file, come back here and press Enter.\n")

        smart_title_matching_functions.open_excel_file(series_selection_path)

        input("Press Enter after you saved the Series_Selection.xlsx file...")

        # 2. Read user selected Series file
        selected_series_file = pd.read_excel(
        series_selection_path,
        sheet_name="Series match",
        header=1)

        if "Select_Series" not in selected_series_file.columns:
            selected_series_file["Select_Series"] = "No"

        if "NODE_IDENTIFIER" not in selected_series_file.columns:
            selected_series_file["NODE_IDENTIFIER"] = np.nan

        selected_series_file["Select_Series"] = (
```

---

## Stage 15: ALL mode series-first scoring and selection workbook

**Source lines:** 1184-1270

**Purpose:** Scores series candidates first and creates `Series_Selection.xlsx` for analyst validation.

**Outputs / impact:** Produces a parent-series review file for Yes/No selection.

**Why this stage is important:** This is where STM changes from raw candidate retrieval into analyst-ready decision support by reducing noise, ranking options, and separating top, partial, and unresolved cases.

```python
            selected_series_file["Select_Series"]
            .fillna("No")
            .astype(str)
            .str.strip()
            .str.upper()
        )

        selected_series = selected_series_file[
            selected_series_file["Select_Series"].eq("YES")
        ].copy()

        selected_parent_ids = selected_series["NODE_IDENTIFIER"].dropna().astype(str).unique().tolist()

        logger.info(f"Selected Series NODE_IDENTIFIER count: {len(selected_parent_ids)}")

        # 3. Final selected series output
        selected_series_output = selected_series.copy()
        selected_series_output["MATCH_LEVEL"] = "Series"

        # Keep Yes-selected rows as Top matches
        selected_series_output["FINAL_SCORE"] = selected_series_output["FINAL_SCORE"].round(1)

        # 4. Filter Season/Episode based on selected Series NODE_IDENTIFIER
        Season_candidates = smart_title_matching_functions.filter_children_by_selected_series(
            Season_SnowFlake_Results,
            selected_parent_ids
        )

        Episode_candidates = smart_title_matching_functions.filter_children_by_selected_series(
            Episode_SnowFlake_Results,
            selected_parent_ids
        )

        Season_candidates["MATCH_LEVEL"] = "Season"
        Episode_candidates["MATCH_LEVEL"] = "Episode"

        # 5. Score Season and Episode candidates
        Season_scored_all = smart_title_matching_functions.score_child_matches(
            Season_candidates,
            INPUT_TITLES_0,
            model,
            cross_model
        )

        Episode_scored_all = smart_title_matching_functions.score_child_matches(
            Episode_candidates,
            INPUT_TITLES_0,
            model,
            cross_model
        )

        # 6. Combine Series + Season + Episode scored results
        Matches_scored_all = pd.concat(
            [
                selected_series_output,
                Season_scored_all,
                Episode_scored_all
            ],
            ignore_index=True,
            sort=False
        )

        Matches_scored_all["ID"] = pd.to_numeric(
            Matches_scored_all["ID"],
            errors="coerce"
        ).astype("Int64")

        # 7. Top match
        Matches_valid = Matches_scored_all[
            Matches_scored_all["FINAL_MATCH_RESULT"] != "Reject"
        ].copy()

        Matches_top3 = smart_title_matching_functions.top_n_per_id(
            Matches_valid,
            "ID",
            "FINAL_SCORE",
            3
        )
        Matches_top3 = smart_title_matching_functions.add_match_ranking(
            Matches_top3,
            "ID",
            "FINAL_SCORE"
        )
        if "NODE_IDENTIFIER" in Matches_top3.columns:
            Matches_top3 = Matches_top3.drop_duplicates(
                subset=["ID", "NODE_IDENTIFIER"],
                keep="first"
```

---

## Stage 16: ALL mode selected-series filtering and child scoring

**Source lines:** 1271-1335

**Purpose:** Reads selected parent series and filters season/episode candidates before scoring children.

**Outputs / impact:** Creates scored children restricted to selected hierarchy parents.

**Why this stage is important:** This is where STM changes from raw candidate retrieval into analyst-ready decision support by reducing noise, ranking options, and separating top, partial, and unresolved cases.

```python
            )

        # 8. Partial match
        top_ids = set(Matches_top3["ID"].dropna().unique())

        Partial_pool = Matches_scored_all[
            (Matches_scored_all["FINAL_SCORE"] >= PARTIAL_THRESHOLD)
            & (~Matches_scored_all["ID"].isin(top_ids))
        ].copy()

        Partial_matches = smart_title_matching_functions.top_n_per_id(
            Partial_pool,
            "ID",
            "FINAL_SCORE",
            4
        )
        Partial_matches = smart_title_matching_functions.add_match_ranking(
            Partial_matches,
            "ID",
            "FINAL_SCORE"
        )
        if "NODE_IDENTIFIER" in Partial_matches.columns:
            Partial_matches = Partial_matches.drop_duplicates(
                subset=["ID", "NODE_IDENTIFIER"],
                keep="first"
            )

        perfects = Partial_matches[
            (Partial_matches["FINAL_MATCH_RESULT"].eq("Perfect Match"))
            | (
                Partial_matches["FINAL_MATCH_RESULT"].eq("Possible Match")
                & (Partial_matches["FINAL_SCORE"] >= 85)
            )
        ].copy()

        perfects["FINAL_MATCH_RESULT"] = [
            "Possible Match" if i == "Reject" else i
            for i in perfects["FINAL_MATCH_RESULT"]
        ]

        Matches_top3 = pd.concat([Matches_top3, perfects], ignore_index=True, sort=False)
        #Matches_top3 = Matches_top3.sort_values(by="PARENT_TITLE")
        Matches_top3 = Matches_top3.sort_values(
                                            ["SERIES_TITLE","ID","MATCH_RANK"],
                                            ascending=[True,True,True]
                                        )
        Partial_matches = Partial_matches[
            ~Partial_matches["ID"].isin(perfects["ID"].unique())
        ].copy()
        #Partial_matches= Partial_matches.sort_values(by="PARENT_TITLE")
        Partial_matches = Partial_matches.sort_values(
        ["SERIES_TITLE","ID","MATCH_RANK"],
        ascending=[True,True,True])
        top_ids = set(Matches_top3["ID"].dropna().unique())
        partial_ids = set(Partial_matches["ID"].dropna().unique())

        # 9. No match
        no_match_ids = sorted(
            INPUT_TITLES_0[
                ~INPUT_TITLES_0["Sno"].isin(top_ids.union(partial_ids))
            ]["Sno"]
        )

        no_match_cols = [
            c for c in [
```

---

## Stage 17: ALL mode ranking, partial matches, and no-match preparation

**Source lines:** 1336-1390

**Purpose:** Combines selected series and scored children, ranks top matches, prepares partials and no matches.

**Outputs / impact:** Creates final ALL-mode output DataFrames.

**Why this stage is important:** This is where STM changes from raw candidate retrieval into analyst-ready decision support by reducing noise, ranking options, and separating top, partial, and unresolved cases.

```python
                "Sno",
                "IP_TYPE",
                "SERIES_TITLE",
                "SeasonNumber",
                "EpisodeNumber",
                "Episode",
                "EPISODE_TITLE",
                "Years"
            ]
            if c in INPUT_TITLES_0.columns
        ]

        No_match_sheet = INPUT_TITLES_0[
            INPUT_TITLES_0["Sno"].isin(no_match_ids)
        ][no_match_cols].copy()

        No_match_sheet = No_match_sheet.sort_values(by="SERIES_TITLE")

        No_match_sheet = No_match_sheet.rename(
            columns={
                "Sno": "ID",
                "Episode": "INPUT_TITLE",
                "EPISODE_TITLE": "INPUT_TITLE"
            }
        )

        No_match_sheet = No_match_sheet.sort_values("ID").reset_index(drop=True)

        # 10. Final column arrangement
        desired_cols_all = [
        "ID",
        "INPUT_TITLE",
        "SERIES_TITLE",
        "PARENT_TITLE",
        "ATOM_TITLE",
        "INPUT_YEAR",
        "YEARS",
        "TT_CODES",

        "IP_TYPE",
        "NODE_IDENTIFIER",
        "LIBRARY_TITLE_FULL",

        "PARENT_ENTITY",
        "PARENT_MPM",
        "CHILDREN_STATUS",

        "FINAL_SCORE",
        "MATCH_LEVEL",
        "CONFIDENCE",
        "FINAL_REASON",
        "MATCH_RANK",
        "MATCH_EVIDENCE",

        "MPM_NUMBER",
```

---

## Stage 18: Final Excel export

**Source lines:** 1391-1437

**Purpose:** Writes final workbook with Top Match, Partial Match, and No Match tabs using helper formatting.

**Outputs / impact:** Creates `Output.xlsx` in selected folder.

```python
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
        "IBROADCAST_APAC_ID"]

        Matches_top3 = Matches_top3[
            [c for c in desired_cols_all if c in Matches_top3.columns]
        ].copy()

        Partial_matches = Partial_matches[
            [c for c in desired_cols_all if c in Partial_matches.columns]
        ].copy()


    # -----------------------------
    # Export
    # -----------------------------
    with pd.ExcelWriter(Output_folder + "/Output.xlsx", engine="xlsxwriter") as writer:
        smart_title_matching_functions.set_writer(writer)

        workbook = writer.book

        # Decide mode (as in your code)
        ip_mode_map = {
        "S": "STANDALONE",
        "SEA": "SEASON",
        "SE": "SERIES",
        "E": "EPISODICS",
        "ALL": "EPISODICS"
        }
        ip_mode = ip_mode_map.get(IP, "STANDALONE")
    

        # SHEET ORDER: Top match -> Partial match -> No match
        smart_title_matching_functions.apply_grouped_formatting(Matches_top3, "Top match", ip_mode)
        smart_title_matching_functions.apply_grouped_formatting(Partial_matches, "Partial match", ip_mode)
        smart_title_matching_functions.format_no_match(No_match_sheet, "No match")
        

    logger.info("Final output is ready...")
```

---


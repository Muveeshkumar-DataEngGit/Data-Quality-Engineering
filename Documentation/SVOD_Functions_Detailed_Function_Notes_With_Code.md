# SVOD Functions Package - Detailed Function Notes Above Code With Source Code

This document follows the STM reference style: every visible function/class/code block is explained first, then the available source code is attached directly below the explanation.

> Important limitation: The attached `SVOD_Functions.txt.txt` extract contains only partial function bodies for several functions/classes. For those items, the **full code available in the extracted file** is included exactly as visible. Functions referenced but not defined in the extract are documented as dependencies/verification points.

---

## Function / Class Index

- Library imports
- `MODEL_PATH` and `CROSS_PATH`
- `initial_class.__init__()`
- `load_and_match.load_foundry()`
- `matching_pipeline`
- `matching_pipeline.match_wbtv_to_foundry_movies()`
- Referenced but not visible functions

---

## 1. Library Imports

**Purpose:**  
Loads all libraries required for dataframe processing, local file/folder selection, semantic model loading, torch-based transformer execution, text normalization, regex cleanup, Excel styling, and file operations.

**Why this block is used in SVOD:**  
The SVOD workflow needs to load source/Foundry files, normalize title text, run semantic matching, and prepare formatted Excel-style outputs. These imports support those responsibilities.

**Inputs explained:**  
No runtime inputs. This block only imports dependencies.

**Outputs / side effects:**  
Makes the imported libraries available for later classes and functions.

**Detailed logic:**

- `pandas` and `numpy` support tabular data operations.
- `tkinter` and `filedialog` support analyst-driven file/folder selection.
- `SentenceTransformer` and `CrossEncoder` support semantic title matching.
- `torch` supports model execution.
- `unicodedata` and `re` support title normalization and cleanup.
- `openpyxl` styling objects support workbook formatting.
- `shutil` supports file/folder operations.

**Risk if this block fails:**  
If any required package is missing, the script may fail before model loading or data processing starts.

**Maintenance guidance:**  
Keep imports grouped by purpose. If you remove an import, check the full package first because some usages are not visible in the extracted file.

### Source code

```python
import pandas as pd
import os
import tkinter as tk
from tkinter import filedialog
from tkinter.filedialog import askdirectory
import numpy as np
from sentence_transformers import SentenceTransformer, util
import torch
import unicodedata
import re
from openpyxl.styles import Font, Alignment, PatternFill, Border, Side
from openpyxl.utils import get_column_letter
from sentence_transformers import CrossEncoder
import shutil
import re
```

---

## 2. Model Path Constants: `MODEL_PATH` and `CROSS_PATH`

**Purpose:**  
Stores local Hugging Face snapshot paths for the bi-encoder and cross-encoder models.

**Why this block is used in SVOD:**  
The pipeline uses semantic models for matching title text. These constants allow the initializer to load the same local model snapshots each time.

**Inputs explained:**  
No function inputs. These are hardcoded string constants.

**Outputs / side effects:**  
The values are consumed by `SentenceTransformer(MODEL_PATH)` and `CrossEncoder(CROSS_PATH)`.

**Detailed logic:**

- `MODEL_PATH` points to the local `all-MiniLM-L6-v2` snapshot.
- `CROSS_PATH` points to the local `cross-encoder/stsb-distilroberta-base` snapshot.

**Risk if this block fails:**  
If these paths do not exist on the machine where the script runs, pipeline initialization will fail.

**Maintenance guidance:**  
Move these paths into a config file, environment variables, or constructor parameters to make the code portable.

### Source code

```python
MODEL_PATH = r"C:\Users\mshanmugam.cache\huggingface\hub\models--sentence-transformers--all-MiniLM-L6-v2\snapshots\1110a243fdf4706b3f48f1d95db1a4f5529b4d41"

CROSS_PATH = r"C:\Users\mshanmugam.cache\huggingface\hub\models--cross-encoder--stsb-distilroberta-base\snapshots\6b71347df6e2b34246b53e06d6bce70ef67de368"
```

---

## 3. `initial_class.__init__()`

**Function signature inputs:**  
`self`, `bi_encoder_name="all-MiniLM-L6-v2"`, `cross_encoder_name="cross-encoder/stsb-distilroberta-base"`

**Purpose:**  
Initializes the model objects used by the SVOD semantic matching pipeline.

**Why this function is used in SVOD:**  
Semantic matching requires a bi-encoder model and a cross-encoder model. Storing these models on `self` makes them reusable by child classes and matching functions.

**Inputs explained:**

| Input | Explanation |
|---|---|
| `self` | The current class instance. |
| `bi_encoder_name` | Default model-name parameter. In the visible code, this parameter is not used directly. |
| `cross_encoder_name` | Default cross-model-name parameter. In the visible code, this parameter is not used directly. |

**Outputs / side effects:**

- Creates `self.model`.
- Creates `self.cross_model`.
- Loads two transformer models from local paths.

**Detailed algorithm / logic:**

1. Load the SentenceTransformer model from `MODEL_PATH`.
2. Load the CrossEncoder model from `CROSS_PATH`.
3. Assign both model objects to the class instance.

**Important values created or updated:**

- `self.model`
- `self.cross_model`

**Risk if this function fails:**  
The full matching pipeline cannot be initialized.

**Maintenance guidance:**  
If you change model loading, update every downstream method that expects `self.model` and `self.cross_model` to exist.

### Source code

```python
class initial_class:
    def __init__(self, bi_encoder_name="all-MiniLM-L6-v2", cross_encoder_name="cross-encoder/stsb-distilroberta-base"):
        self.model = SentenceTransformer(MODEL_PATH)
        self.cross_model = CrossEncoder(CROSS_PATH)
```

---

## 4. `load_and_match.load_foundry()`

**Function signature inputs:**  
`self`, `foundry_path: str`, `content_type: str = "series"`

**Purpose:**  
Loads Foundry data for matching. The source heading says this supports both series and movie workflows.

**Why this function is used in SVOD:**  
Foundry appears to be the reference metadata file/dataset that source records are matched against. Without loading Foundry metadata, movie or series matching cannot run.

**Inputs explained:**

| Input | Explanation |
|---|---|
| `foundry_path` | Path to the Foundry source file or data source. |
| `content_type` | Indicates whether the load should prepare series or movie data. Default is `series`. |

**Outputs / side effects:**  
The return value is not visible in the extracted code. Based on the function name and heading, it likely returns one or more Foundry dataframes.

**Detailed algorithm / logic:**  
The full function body is not available in the extracted source. The visible code confirms only the class, heading, and function signature.

**Risk if this function fails:**  
The pipeline may not have Foundry reference data to match against.

**Maintenance guidance:**  
Add a docstring to the real function body that lists required columns, accepted file formats, and return values.

### Source code available in extracted file

```python
class load_and_match(initial_class):
    # ============================================================
    # ✅ LOAD FOUNDRY (SERIES + MOVIE SUPPORT)
    # ============================================================
    def load_foundry(self, foundry_path: str, content_type: str = "series"):
```

---

## 5. `matching_pipeline`

**Purpose:**  
Defines the main matching pipeline class. It inherits from `load_and_match`, which inherits from `initial_class`.

**Why this class is used in SVOD:**  
The main SVOD script imports and instantiates `matching_pipeline`. This class acts as the reusable package interface used by the orchestration script.

**Inputs explained:**  
No visible class-level inputs. It inherits initialization behavior from parent classes.

**Outputs / side effects:**  
Creating an instance loads semantic models through the inherited initializer.

**Detailed logic:**

- Inherits model initialization from `initial_class`.
- Inherits Foundry loading behavior from `load_and_match`.
- Adds higher-level pipeline wrappers such as movie matching.

**Risk if this class fails:**  
The main script cannot create the `pipeline` object.

**Maintenance guidance:**  
If renamed, update `from Packages import matching_pipeline` in the main script.

### Source code available in extracted file

```python
class matching_pipeline(load_and_match):
```

---

## 6. `matching_pipeline.match_wbtv_to_foundry_movies()`

**Function signature inputs:**  
`self`, `WBTV_0`, `Movies`, `model=None`, `cross_model=None`, `top_k=5`, `ce_threshold=0.75`

**Purpose:**  
Matches WBTV movie source records to Foundry movie records using semantic matching.

**Why this function is used in SVOD:**  
This wrapper keeps WBTV-specific and Foundry-specific column mapping in one place. It passes those mappings into a generic semantic movie merge function.

**Inputs explained:**

| Input | Explanation |
|---|---|
| `WBTV_0` | Source dataframe containing WBTV movie records. |
| `Movies` | Foundry movie dataframe. |
| `model` | Optional bi-encoder override. |
| `cross_model` | Optional cross-encoder override. |
| `top_k` | Number of top candidate matches. Default is 5. |
| `ce_threshold` | Cross-encoder threshold. Default is 0.75. |

**Outputs / side effects:**  
Returns the result from `self.semantic_movie_match_and_merge(...)`. The full return structure is not visible.

**Detailed algorithm / logic:**

1. Pass `WBTV_0` as the left/source dataframe.
2. Pass `Movies` as the right/reference dataframe.
3. Use `self.normalize_title` as the title normalization function.
4. Use `MPM Number` as the source ID column.
5. Use `*Title name` as the source title column.
6. Use `main-title` as the Foundry title column.
7. Pull Foundry metadata columns such as UUID, asset type, title, descriptions, season, and episode.
8. Pass `top_k`, `ce_threshold`, and optional model overrides into the semantic merge method.

**Important values passed:**

| Parameter | Value |
|---|---|
| `left_id_col` | `MPM Number` |
| `left_title_col` | `*Title name` |
| `right_title_col` | `main-title` |
| `right_pull_cols` | Foundry metadata columns listed in code |
| `top_k` | Function argument, default 5 |
| `ce_threshold` | Function argument, default 0.75 |

**Risk if this function fails:**  
Movie records may not get correct Foundry UUID/title/description metadata.

**Maintenance guidance:**  
Add schema validation before this wrapper calls `semantic_movie_match_and_merge()`.

### Source code

```python
class matching_pipeline(load_and_match):
    # ============================================================
    # ✅ MOVIE WRAPPERS
    # ============================================================
    def match_wbtv_to_foundry_movies(self, WBTV_0, Movies, model=None, cross_model=None, top_k=5, ce_threshold=0.75):
        return self.semantic_movie_match_and_merge(
            left_df=WBTV_0,
            right_df=Movies,
            normalize_title_fn=self.normalize_title,
            left_id_col="MPM Number",
            left_title_col="*Title name",
            right_title_col="main-title",
            right_pull_cols=(
                "uuid", "asset-type", "main-title",
                "description-400", "listings-description",
                "long-description", "main-description", "short-description",
                "Season", "Episode"
            ),
            top_k=top_k,
            ce_threshold=ce_threshold,
            model=model,
            cross_model=cross_model,
        )
```

---

## 7. Referenced But Not Visible Functions

The visible code references several functions or methods whose bodies are not included in the extracted file.

### Referenced names

- `semantic_movie_match_and_merge`
- `normalize_title`
- `ask_content_type`
- `run_template_pipeline`
- `select_output_folder`

**Purpose:**  
These appear to support semantic matching, title normalization, user input, main pipeline execution, and output folder selection.

**Why this matters:**  
A complete developer handoff should include these function bodies. They are required to fully document the SVOD package behavior.

**Maintenance guidance:**  
Provide the original `.py` source file or a fuller export if you want these functions documented with their full code.

# SVOD Main Script - Meaningful Workflow Blocks With Source Code

This document follows the STM workflow-block documentation style. The main script is explained as meaningful processing stages. Each stage explains the purpose, why it exists, what it changes, and then attaches the available source code for that block.

> Important limitation: The attached `SVOD_main.txt.txt` extract contains only partial downstream code for some helper functions and template-creation logic. The **full code available in the extracted file** is included below.

---

## High-Level Data Flow

Dynamic synopsis input → content type selection → template pipeline execution → output folder selection → verification CSV creation → verification prompt → English / multilanguage template creation.

---

## Workflow Block Index

- Stage 1: Startup imports and environment setup
- Stage 2: Logging setup
- Stage 3: Own function import and pipeline initialization
- Stage 4: Dynamic synopsis input collection
- Stage 5: Content type selection and pipeline execution
- Stage 6: Output folder selection and verification CSV creation
- Stage 7: Helper function definitions
- Stage 8: Main template creation gate

---

## Stage 1: Startup Imports and Environment Setup

**Purpose:**  
Imports the libraries required by the main script and suppresses warnings.

**Why this stage exists:**  
The main script needs OS path handling, warnings control, logging, pandas dataframe operations, and Excel workbook utilities.

**Inputs:**  
No user input in this stage.

**Outputs / impact:**

- Required libraries become available.
- Python warnings are suppressed.
- `TRANSFORMERS_NO_TF` is set to `1`.

**Detailed logic:**

1. Import standard libraries.
2. Import pandas and openpyxl helpers.
3. Suppress warnings.
4. Set an environment flag to avoid TensorFlow usage in transformers.

**Risk if this stage fails:**  
The script may fail immediately during imports.

**Maintenance guidance:**  
Move environment setup into a config/startup function if the script becomes a reusable package.

### Source code

```python
import os
import time
import warnings
import logging

import pandas as pd
from openpyxl import load_workbook
from openpyxl.utils import get_column_letter

warnings.filterwarnings("ignore")
os.environ["TRANSFORMERS_NO_TF"] = "1"
```

---

## Stage 2: Logging Setup

**Purpose:**  
Creates a logger and configures a file handler that writes to `SVOD.log`.

**Why this stage exists:**  
The pipeline has multiple user-input and file-output stages. Logging helps troubleshoot execution failures and confirms important milestones.

**Inputs:**  
No user input.

**Outputs / impact:**

- Creates a logger for the module.
- Sets log level to INFO.
- Writes log messages to `SVOD.log`.
- Uses write mode, so old logs are overwritten.

**Detailed logic:**

1. Get logger by module name.
2. Set level to INFO.
3. If no handlers exist, create a formatter.
4. Create a file handler for `SVOD.log`.
5. Attach formatter to file handler.
6. Add handler to logger.

**Risk if this stage fails:**  
Pipeline failures may be harder to debug because no log is written.

**Maintenance guidance:**  
Use timestamped log files if multiple run histories must be retained.

### Source code

```python
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

if not logger.handlers:
    formatter = logging.Formatter(
        "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
    )
    file_handler = logging.FileHandler("SVOD.log", mode="w")
    file_handler.setFormatter(formatter)
    logger.addHandler(file_handler)
```

---

## Stage 3: Own Function Import and Pipeline Initialization

**Purpose:**  
Imports the reusable matching pipeline and initializes the pipeline object.

**Why this stage exists:**  
The main script should orchestrate workflow. The reusable logic lives in the package class `matching_pipeline`.

**Inputs:**  
No direct user input.

**Outputs / impact:**  
Creates `pipeline`, which is used throughout the script.

**Detailed logic:**

1. Import `matching_pipeline` from `Packages`.
2. Instantiate it.
3. Use the instance for content-type selection, pipeline execution, and folder selection.

**Risk if this stage fails:**  
If `Packages` cannot be imported or model initialization fails, the script cannot continue.

**Maintenance guidance:**  
Keep the import path stable or expose the class through `Packages/__init__.py`.

### Source code

```python
from Packages import matching_pipeline

pipeline = matching_pipeline()
```

---

## Stage 4: Dynamic Synopsis Input Collection

**Purpose:**  
Collects runtime synopsis-column requirements from the user.

**Why this stage exists:**  
The SVOD output template supports dynamic synopsis columns. Instead of hardcoding short/long synopsis columns, the user enters how many are needed and their character limits.

**Inputs explained:**

| Input | Meaning |
|---|---|
| `synopsis_count` | Number of synopsis columns needed. |
| `limit` | Character limit for each synopsis column. |

**Outputs / impact:**

- Creates `synopsis_limits` list.
- This list is used later by dynamic synopsis and summary functions.

**Detailed logic:**

1. Log that dynamic synopsis input is starting.
2. Ask user for number of synopsis columns.
3. Convert input to integer.
4. Create an empty list.
5. Loop through the requested count.
6. Ask for each synopsis character limit.

**Risk if this stage fails:**  
Invalid input can stop the script before output generation.

**Maintenance guidance:**  
Add validation around number conversion and positive values.

### Source code available in extracted file

```python
logger.info("Enter dynamic synopsis column details")

while True:
    try:
        synopsis_count = int(input("Enter number of synopsis columns needed: ").strip())

        synopsis_limits = []

        for i in range(1, synopsis_count + 1):
            while True:
                try:
                    limit = int(input(f"Enter character limit for synopsis column : ").strip())
```

---

## Stage 5: Content Type Selection and Template Pipeline Execution

**Purpose:**  
Asks the pipeline for the content/template type and runs the main template pipeline.

**Why this stage exists:**  
The processing logic depends on whether the user is creating a specific type of content template. Semantic matching parameters are passed here.

**Inputs explained:**

| Input | Meaning |
|---|---|
| `template_type` | Content type returned by `pipeline.ask_content_type()`. |
| `top_k` | Number of candidate matches considered. |
| `ce_threshold` | Cross-encoder threshold for candidate acceptance. |

**Outputs / impact:**  
Creates `final_df`, the dataframe later written to the verification CSV.

**Detailed logic:**

1. Ask for content type.
2. Run `pipeline.run_template_pipeline()` with selected content type.
3. Use `top_k=5`.
4. Use `ce_threshold=0.75`.
5. Store output dataframe in `final_df`.

**Risk if this stage fails:**  
No verification CSV or final template can be generated.

**Maintenance guidance:**  
Move `top_k` and `ce_threshold` into configuration if analysts change them between runs.

### Source code

```python
template_type = pipeline.ask_content_type()

final_df = pipeline.run_template_pipeline(
    content_type=template_type,
    top_k=5,
    ce_threshold=0.75
)
```

---

## Stage 6: Output Folder Selection and Verification CSV Creation

**Purpose:**  
Selects an output folder and writes a verification CSV for analyst review.

**Why this stage exists:**  
The script creates a verification checkpoint before final template creation. This gives the analyst a chance to validate the matched/processed data.

**Inputs explained:**

| Input | Meaning |
|---|---|
| `output_folder` | Folder selected by the user. |
| `final_df` | Pipeline output dataframe. |

**Outputs / impact:**

- Creates `WBTVD or WB2B or FOUNDRY - Format.csv`.
- Sets `english_path` to the same CSV path.
- Sets `temp_path` to the output folder.

**Detailed logic:**

1. Ask the user to select output folder.
2. Build the verification CSV path.
3. Assign path variables.
4. Write dataframe to CSV with `index=False`.
5. Log and print verification prompt.

**Risk if this stage fails:**  
User cannot verify the data, and template creation should not proceed.

**Maintenance guidance:**  
Validate that `output_folder` exists and `final_df` is not empty before saving.

### Source code

```python
output_folder = pipeline.select_output_folder()
format_check_path = os.path.join(output_folder, "WBTVD or WB2B or FOUNDRY - Format.csv")
english_path = format_check_path
temp_path = output_folder

final_df.to_csv(format_check_path, index=False)

logger.info("File verification Done")
verify = input("File verification Done [y/n]: ").strip().lower()
```

---

## Stage 7: Helper Function Definitions

This stage contains reusable helper functions used during template preparation and formatting.

---

### 7.1 `get_base_columns()`

**Purpose:**  
Returns the fixed base columns used in the output template.

**Why this function is used in SVOD:**  
Base columns provide a stable template foundation before dynamic synopsis fields are added.

**Inputs:**  
No inputs.

**Outputs:**  
Returns a list of column names.

**Detailed logic:**

- Return common template columns in fixed order.

**Risk if this function fails:**  
Template output structure may not match expected downstream format.

**Maintenance guidance:**  
If business template columns change, update this function and verify all downstream dataframe preparation functions.

#### Source code

```python
def get_base_columns():
    return [
        "Sr.No.",
        "Category",
        "Season",
        "Episode",
        "Source Title (Long Description)",
        "Localized Title",
        "WM Internal Reference",
        "US Release Date"
    ]
```

---

### 7.2 `apply_dynamic_synopsis_columns()`

**Function signature inputs:**  
`df`, `source_df`, `synopsis_limits`, `is_translation=False`

**Purpose:**  
Creates dynamic synopsis source and translation columns.

**Why this function is used in SVOD:**  
The user enters synopsis character limits at runtime. This function likely converts those limits into output columns.

**Inputs explained:**

| Input | Meaning |
|---|---|
| `df` | Target dataframe to update. |
| `source_df` | Source dataframe containing synopsis text. |
| `synopsis_limits` | List of character limits entered by user. |
| `is_translation` | Controls whether translation-specific columns are created. |

**Outputs / impact:**  
The exact returned dataframe is not visible in the extracted code.

**Detailed logic:**  
The full body is not visible. The docstring confirms this function dynamically creates synopsis source and translation columns.

**Risk if this function fails:**  
Output templates may miss required synopsis fields.

**Maintenance guidance:**  
Add tests for one synopsis limit, multiple limits, English mode, and translation mode.

#### Source code available in extracted file

```python
def apply_dynamic_synopsis_columns(df, source_df, synopsis_limits, is_translation=False):
    """
    Dynamically creates synopsis source and translation columns.
    """
```

---

### 7.3 `prepare_english_dataframe()`

**Function signature inputs:**  
`df`, `template_type`, `synopsis_limits`

**Purpose:**  
Prepares the English-language output dataframe.

**Why this function is used in SVOD:**  
English output appears to be the baseline template before translation output is prepared.

**Inputs explained:**

| Input | Meaning |
|---|---|
| `df` | Source dataframe. |
| `template_type` | Selected template/content type. |
| `synopsis_limits` | Runtime synopsis character limits. |

**Outputs / impact:**  
The exact return is not visible. The visible code copies the dataframe to avoid mutating the original.

**Detailed logic visible:**

- Copy the input dataframe.

**Risk if this function fails:**  
English template output may be incomplete or incorrectly formatted.

**Maintenance guidance:**  
Preserve defensive copying unless mutation is intentionally required.

#### Source code available in extracted file

```python
def prepare_english_dataframe(df, template_type, synopsis_limits):
    df = df.copy()
```

---

### 7.4 `prepare_translation_dataframe()`

**Function signature inputs:**  
`df_trans`, `english_df`, `template_type`, `synopsis_limits`, `lang_name`

**Purpose:**  
Prepares a translation-language dataframe aligned to the English dataframe.

**Why this function is used in SVOD:**  
Multilanguage SVOD templates must preserve English structure while adding translated/localized values.

**Inputs explained:**

| Input | Meaning |
|---|---|
| `df_trans` | Translation dataframe. |
| `english_df` | English reference dataframe. |
| `template_type` | Selected template/content type. |
| `synopsis_limits` | Runtime synopsis limits. |
| `lang_name` | Language name for the translation output. |

**Outputs / impact:**  
The exact return is not visible. The visible code copies both input dataframes.

**Detailed logic visible:**

- Copy translation dataframe.
- Copy English dataframe.

**Risk if this function fails:**  
Translation output may not align with English source rows.

**Maintenance guidance:**  
Document language folder/file naming rules when the full body is available.

#### Source code available in extracted file

```python
def prepare_translation_dataframe(
    df_trans,
    english_df,
    template_type,
    synopsis_limits,
    lang_name
):
    df_trans = df_trans.copy()
    english_df = english_df.copy()
```

---

### 7.5 `create_dynamic_summary()`

**Function signature inputs:**  
`output_file`, `synopsis_limits`

**Purpose:**  
Creates a dynamic Info sheet based on user-entered synopsis limits.

**Why this function is used in SVOD:**  
The summary sheet should reflect the actual runtime synopsis limits rather than hardcoded categories.

**Inputs explained:**

| Input | Meaning |
|---|---|
| `output_file` | Workbook/output path to update. |
| `synopsis_limits` | User-entered synopsis limits. |

**Outputs / impact:**  
The exact workbook changes are not visible in the extracted code.

**Detailed logic visible:**

- The docstring confirms there is no hardcoded short/long/too_long logic.

**Risk if this function fails:**  
The Info sheet may not describe dynamic synopsis limits correctly.

**Maintenance guidance:**  
Keep this function driven by `synopsis_limits`.

#### Source code available in extracted file

```python
def create_dynamic_summary(output_file, synopsis_limits):
    """
    Creates dynamic Info sheet based on the synopsis limits entered by user.
    No hardcoded short / long / too_long logic.
    """
```

---

### 7.6 `format_sheet_safely()`

**Function signature inputs:**  
`ws`

**Purpose:**  
Safely applies formatting to a worksheet.

**Why this function is used in SVOD:**  
Formatted output sheets are easier for analysts to review. The word “safely” suggests the function is intended to avoid breaking the pipeline on formatting issues.

**Inputs explained:**

| Input | Meaning |
|---|---|
| `ws` | Worksheet object. |

**Outputs / impact:**  
The exact formatting actions are not visible in the extracted code.

**Detailed logic visible:**

- The docstring states the worksheet is formatted safely.

**Risk if this function fails:**  
Workbook output may be harder to read or may fail during formatting.

**Maintenance guidance:**  
When the full body is available, document exact formatting rules such as widths, fills, borders, freeze panes, and alignments.

#### Source code available in extracted file

```python
def format_sheet_safely(ws):
    """
    Safely apply formatting to a worksheet.
    """
```

---

## Stage 8: Main Template Creation Gate

**Purpose:**  
Controls whether final template creation continues after the verification CSV is reviewed.

**Why this stage exists:**  
The verification gate prevents the script from creating final templates when the analyst has not confirmed the intermediate CSV.

**Inputs explained:**

| Input | Meaning |
|---|---|
| `verify` | User confirmation after reviewing verification CSV. |
| `only_english` | User response about multilanguage folder availability. |

**Outputs / impact:**

- If `verify == "y"`, the script asks whether a multilanguage folder is available.
- Otherwise, template creation stops.

**Detailed logic:**

1. Check verification response.
2. If yes, ask about multilanguage folder availability.
3. If no, print stop message.

**Risk if this stage fails:**  
Unverified data may continue, or valid data may be blocked by manual input.

**Maintenance guidance:**  
Add a non-interactive flag for automated runs.

### Source code available in extracted file

```python
# ============================================================
# MAIN TEMPLATE CREATION
# ============================================================

if verify == "y":
    only_english = input("Is the multilanguage folder available? [y/n]: ").strip().lower()
    path = None
else:
    print("❌ File verification was not confirmed. Template creation stopped.")
```

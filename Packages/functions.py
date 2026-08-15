"""
--       This module contains a collection of utility functions and classes for handling various data processing tasks.       --

"""

import snowflake.connector
# Used to connect to Snowflake and execute SQL queries

import re
# Used for pattern matching and text processing with regular expressions

import math
# Used for built-in mathematical functions and calculations

import numpy as np
# Used for numerical operations, arrays, and mathematical computations

import pandas as pd
# Used for data manipulation, analysis, and tabular data processing with DataFrames

from sentence_transformers import SentenceTransformer, CrossEncoder, util
# SentenceTransformer is used to generate semantic text embeddings.
# CrossEncoder is used for pairwise similarity scoring and re-ranking.
# util provides helper functions such as cosine similarity computation.

import unicodedata
# Used for Unicode normalization and standardizing special characters

import tkinter as tk
# Used to create GUI elements and initialize the Tkinter interface

from tkinter import filedialog
# Used to open file selection dialogs in the GUI

import os
# Used for file paths, directory handling, and operating system interactions

import shutil
# Used for high-level file operations such as copying, moving, and deleting files or folders in windows

import subprocess
# Used to run external commands or scripts from within Python

import sys
# Used for system-specific parameters and functions, such as exiting the script

import logging
# Used to record logs for debugging, monitoring, and tracking script execution

import torch
# Used for PyTorch tensor operations and GPU acceleration when available

"""
                   -- Custom logger configuration. --

This logger is created using the current module name, configured with an
INFO log level, and attached to a file handler that writes log messages
to 'Smart.log'. The log file is opened in write mode, so it is overwritten
each time the script starts.

"""

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)
f = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
fh = logging.FileHandler('Smart.log', mode='w')   # ✅ overwrite file
fh.setFormatter(f)
logger.addHandler(fh)



"""
-- AllFunctions class provides helper methods for title matching, scoring,explainability, Snowflake connectivity, and formatted Excel report generation. --

It initializes Excel writer and workbook attributes, defines reusable formatting
rules, prepares matching outputs, calculates semantic and CrossEncoder scores,
generates match decisions, ranks candidates, and writes formatted Excel sheets.

The utility methods support:
- Season and episode extraction.
- AKA title splitting.
- Title normalization.
- Numeric value extraction and comparison.
- Confidence and reason-code generation.
- Match evidence creation.
- Candidate ranking and top-N filtering.
- Series and episodic match scoring.
- Child candidate filtering by selected parent series.
- Safe numeric conversion for Excel output.
- Grouped Excel formatting with hyperlinks and warning highlights.
- No-match and Series selection Excel sheet creation.
"""
class all_functions:
    def __init__(self):
        """
        Initializes the class-level Excel writer and workbook attributes.

        The writer and workbook are set to None during object creation because
        they will be assigned later when the Excel output file is created or
        loaded. This ensures the attributes are available across different class
        methods and prevents undefined attribute errors.
        """
        self.writer = None
        self.workbook = None

    def set_writer(self, writer):
        """
        Sets the Excel writer object and initializes workbook-level formatting rules.

        This method receives an existing Excel writer object, stores it at the class
        level, and extracts the underlying workbook object from `writer.book`. The
        workbook is then used to create reusable Excel formats such as header styles,
        border styles, hyperlink styles, score/group header colors, ID highlights,
        and warning formats.

        The method also defines report configuration rules, including:
            - Column grouping rules for STANDALONE, SERIES, and EPISODICS outputs.
            - Priority identifier columns used for ingestion.
            - Columns that should be converted to numeric values where possible.
            - Base URLs used for hyperlink generation.
            - Header, border, group, hyperlink, and warning formats.
            - Fixed column widths and minimum/maximum width limits.

        This setup allows other class methods to reuse a common workbook configuration
        while writing formatted Excel sheets.
        """
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
    
    @staticmethod
    def extract_season_episode(title):
        """
        Extracts season and episode numbers from a title string.

        This function checks whether the given title contains season and episode
        information in common formats such as:
            - S5E09
            - S5 Episode 09
            - S5 Ep 09
            - Season 5 Episode 09
            - 509, interpreted as Season 5 Episode 09

        If a matching pattern is found, the function returns the season and episode
        numbers as integers. If no pattern is found, it returns `(None, None)`.

        Parameters:
            title:
                The input title or text value from which season and episode numbers
                need to be extracted.

        Returns:
            tuple:
                A tuple in the format `(season_number, episode_number)`.
                If no valid season or episode pattern is found, returns
                `(None, None)`.
        """

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
    
    @staticmethod
    def confidence_bucket(score):
        """
        Converts a numeric match score into a confidence category.

        This function is used to classify match scores into readable confidence
        levels such as Very High, High, Medium, or Low. If the score is missing,
        the function returns a blank value.

        Score rules:
            - 98 and above  : Very High
            - 95 to 97.99   : High
            - 85 to 94.99   : Medium
            - Below 85      : Low

        Parameters:
            score:
                Numeric score value, usually a semantic score or final match score.

        Returns:
            str:
                Confidence label based on the score.
                Returns an empty string if the score is missing.
        """

        if pd.isna(score):
            return ""

        if score >= 98:
            return "Very High"

        if score >= 95:
            return "High"

        if score >= 85:
            return "Medium"

        return "Low"
    
    @staticmethod
    def get_match_reason(
        result,
        semantic_score,
        cross_score=None,
        aka=False,
        numbers_pass=True,
        parent_pass=True
    ):
        """
        Returns a standardized reason code explaining the final match decision.

        This function evaluates the match result, semantic similarity score, AKA
        status, number validation, and parent validation to generate a clear reason
        for why a match was accepted, rejected, or marked for manual review.

        The function gives priority to hard failure rules first, such as number
        mismatch or parent mismatch. If no hard failure exists, it evaluates the
        final match result and returns a reason code based on the match type and
        score thresholds.

        Parameters:
            result:
                Final match decision, such as "Reject", "Perfect Match", or
                "Possible Match".

            semantic_score:
                Numeric semantic similarity score between the input title and the
                candidate title.

            cross_score:
                Optional cross-encoder score. This parameter is currently accepted
                by the function but is not directly used in the current logic.

            aka:
                Boolean flag indicating whether the input title is related to an
                AKA or alternate title scenario.

            numbers_pass:
                Boolean flag indicating whether number-based validation passed.
                For example, season, episode, or other numeric values matched.

            parent_pass:
                Boolean flag indicating whether parent-title or parent-entity
                validation passed.

        Returns:
            str:
                A reason code such as NUMBER_MISMATCH, EXACT_TITLE_MATCH,
                HIGH_CONFIDENCE_REVIEW, REVIEW_REQUIRED, or UNKNOWN.
        """

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
    
    @staticmethod
    def build_match_evidence(row):
        """
        Builds a human-readable evidence summary for a matched record.

        This function checks whether score and decision columns are available in
        the given row. If available, it collects values such as semantic score,
        final score, cross-encoder score, and match decision into a single text
        string.

        The output is useful for explaining why a match was selected, rejected, or
        marked for review in the final Excel report.

        Parameters:
            row:
                A pandas Series representing one row from the matching DataFrame.

        Returns:
            str:
                A pipe-separated evidence string containing available score and
                decision values.

                Example:
                    "Semantic=96.4 | Final=97.1 | Cross=88.5 | Decision=Perfect Match"
        """

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
    
    @staticmethod
    def add_match_ranking(df, id_col, score_col):
        """
        Adds match ranking and keep recommendation columns to a DataFrame.

        This function ranks candidate matches within each ID group based on the
        provided score column. The highest-scoring candidate for each ID receives
        rank 1 and is marked as the recommended match to keep.

        The function is useful when multiple candidate records are available for
        the same input ID and the output needs to identify the best match based on
        score.

        Parameters:
            df:
                Input pandas DataFrame containing match candidates.

            id_col:
                Column name used to group related match candidates.
                For example, "ID".

            score_col:
                Column name used to rank matches within each ID group.
                Higher scores are ranked first.

        Returns:
            pandas.DataFrame:
                A copy of the input DataFrame with two additional columns:
                    - MATCH_RANK: Rank of each candidate within its ID group.
                    - KEEP_RECOMMENDED: "Yes" for rank 1, otherwise "No".
        """

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
    
    def add_explainability_columns(
        self,
        df,
        score_col,
        result_col
    ):
        """
        Adds explainability columns to the matching results DataFrame.

        This method enriches the match output by adding confidence, reason, and
        evidence columns. These columns help users understand why a title match was
        accepted, rejected, or marked for review.

        The method creates:
            - CONFIDENCE:
                A readable confidence category generated from the score column.
                Example values include Very High, High, Medium, and Low.

            - FINAL_REASON:
                A standardized reason code generated from the match result,
                score, optional cross score, and AKA status.

            - MATCH_EVIDENCE:
                A compact evidence string that combines available scores and match
                decisions into one readable text value.

        Parameters:
            df:
                Input pandas DataFrame containing match results.

            score_col:
                Name of the score column used to calculate confidence and reason.
                Example: "FINAL_SCORE" or "SEMANTIC_SCORE".

            result_col:
                Name of the result column used to determine the match reason.
                Example: "FINAL_MATCH_RESULT" or "MATCH_RESULT".

        Returns:
            pandas.DataFrame:
                A copy of the input DataFrame with added explainability columns.
                If the input DataFrame is empty, it is returned unchanged.
        """

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

    @staticmethod
    def split_aka(title):
        """
        Splits a title into separate searchable title variants.

        This function handles titles that contain AKA values, alternate names,
        or slash-separated title variants. If the title contains an AKA section
        inside parentheses, the function extracts the AKA values, removes the
        AKA section from the main title, and returns both the main title and
        alias titles as a list.

        examples:
            - "Movie Title *AKA. Alternate Title)"
            - "Movie Title (AKA Alternate Title / the Title)"
            - "Movie Titl* / Alternate Title"
            - "Mov*e Title AKA Alternate Title"

        Parameters:
            title:
                Input title value, usually from*a pandas DataFrame column.

        Re*urns:
            list:
                A List of cleaned title variants. If the input is missing, the
                function returns the original missing value inside a list.
        """
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
    
    @staticmethod
    def normalize_title(title):
        """
        Normalizes a title string for consistent matching and comparison.

        This function cleans and standardizes input titles by handling missing
        values, trimming spaces, normalizing Unicode characters, removing accent
        marks, converting text to lowercase, removing unwanted punctuation,
        removing trailing release years, removing version labels, and collapsing
        extra spaces.

        This is useful before title matching because different title formats can
        refer to the same content. For example, "Café Society (2016)" and
        "Cafe Society" can be normalized into a more comparable form.

        Parameters:
            title:
                Input title value, usually from a pandas DataFrame column.

        Returns:
            str:
                A cleaned and normalized title string. Returns an empty string
                if the input title is missing.
        """
        if pd.isna(title):
            return ""
        # Trim space:
        title = title.strip()
        
        # 1️⃣ Normalize Unicode (NFKD separates accents: "café" ==> After NFKD: é = two codepoints — e (U+0065) + ´ combining accent (U+0301))
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
    
    @staticmethod
    def open_excel_file(path):
        """
        Opens an Excel file automatically using the default application for the
        current operating system.

        This function checks the operating system and uses the appropriate command
        to open the file:
            - Windows: uses os.startfile()
            - macOS: uses the open command
            - Linux or other Unix-like systems: uses xdg-open

        If the file cannot be opened automatically, the function catches the error
        and writes a warning message to the logger instead of stopping the script.

        Parameters:
            path:
                Full file path of the Excel file that should be opened.

        Returns:
            None
        """

        try:
            if sys.platform.startswith("win"):
                os.startfile(path)
            elif sys.platform == "darwin":
                subprocess.call(["open", path])
            else:
                subprocess.call(["xdg-open", path])
        except Exception as e:
            logger.warning(f"Could not open Excel file automatically: {e}")

    @staticmethod
    def write_series_selection_file(df, output_path):
        """
        Creates a formatted Excel file for manual Series match selection.

        This function prepares a Series match review file from the provided
        DataFrame and writes it to an Excel workbook. It adds a `Select_Series`
        column, derives a `For Ingestion` column based on available identifier
        fields, reorders columns into business-friendly groups, normalizes numeric
        identifier values, and applies Excel formatting for review.

        The final Excel sheet includes:
            - Grouped header bands for matched output, series information, scores,
            identifiers, and user selection.
            - A dropdown list in the `Select_Series` column with Yes or No values.
            - Hyperlinks for Reltio entity identifiers and IMDb title codes.
            - Highlighting for duplicate IDs, missing ingestion IDs, and identifier
            values containing pipe characters.
            - Auto-adjusted column widths, filters, frozen panes, and styled headers.

        Parameters:
            df:
                pandas DataFrame containing candidate series match records.

            output_path:
                Full path where the generated Excel file should be saved.

        Returns:
            None
                The function writes the formatted Excel file directly to
                `output_path`.
        """

        df = df.copy()

        # -------------------------------------------------
        # 1) Ensure Select_Series column exists
        # -------------------------------------------------
        if "Select_Series" not in df.columns:
            df["Select_Series"] = "No"

        # -------------------------------------------------
        # 2) Keep original final-score column names
        # DO NOT rename FINAL_SCORE / FINAL_MATCH_RESULT
        # because the later code uses these names.
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
            """
            Safely converts numeric-looking values into int or float while preserving
            non-numeric values as-is.

            This function is useful when preparing data for Excel output. It converts
            clean integer values to int, decimal values to float, and blank or missing
            values to an empty string. If the value is not safely numeric, the original
            value is returned unchanged.

            Conversion rules:
                - None, NaN, or blank values are returned as an empty string.
                - Integer values remain integers.
                - Float values are converted to int if they have no decimal part.
                - Decimal float values retain their decimal portion.
                - Numeric strings such as "12345" are converted to integers.
                - Numeric strings with commas such as "12,345" are converted to integers.
                - Decimal strings such as "123.45" are converted to floats.
                - Non-numeric values such as "ABC123" are returned unchanged.

            Parameters:
                x:
                    Input value to convert.

            Returns:
                int, float, str, or original value:
                    Converted numeric value when safe, otherwise the original value.
            """
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
                """
                Extracts an IMDb title code from a given text value.

                This function searches the input text for an IMDb title identifier in the
                format `tt` followed by one or more digits, such as `tt1234567`. If a valid
                IMDb title code is found, it returns the code in lowercase. If no code is
                found, it returns None.

                Parameters:
                    s:
                        Input text that may contain an IMDb title code.

                Returns:
                    str or None:
                        The extracted IMDb title code in lowercase if found.
                        Returns None if the input is empty or no IMDb code is detected.
                """
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

    @staticmethod
    def rowwise_cosine(a, b):
        """
        Computes row-wise cosine similarity between two embedding tensors.

        This function compares each row in tensor `a` with the corresponding row
        in tensor `b`. Both tensors are first L2-normalized so each row has unit
        length. After normalization, cosine similarity can be calculated by
        multiplying the corresponding values and summing across each row.

        This is useful for comparing aligned title embeddings, where each input
        title should be compared only with the candidate title in the same row.

        Parameters:
            a:
                First tensor containing embeddings.
                Expected shape: [number_of_rows, embedding_dimension].

            b:
                Second tensor containing embeddings.
                Expected shape should match tensor `a`.

        Returns:
            torch.Tensor:
                A one-dimensional tensor containing one cosine similarity score
                for each row pair.
        """
        a = torch.nn.functional.normalize(a, p=2, dim=1)
        b = torch.nn.functional.normalize(b, p=2, dim=1)
        return (a * b).sum(dim=1)


    @staticmethod
    def select_output_folder():
        """
        Opens a folder selection dialog and prepares the selected folder for output.

        This function uses Tkinter to display a folder picker dialog. After the user
        selects an output folder, the function deletes all existing files, links, and
        subfolders inside that folder so new output files can be saved into a clean
        location.

        If no folder is selected, the function returns None.

        Returns:
            str or None:
                The selected folder path if a folder is selected.
                Returns None if the user cancels the folder selection.
        """
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
    
    @staticmethod
    def genric_merger(title, series_title, season_number, episode_number):
        """
        Builds an AKA-style merged title using series, season, and episode details.

        This function appends season and episode information to the original title
        in an AKA format. It is mainly useful for episodic matching scenarios where
        an episode title needs to include its related series title, season number,
        and episode number for better matching.

        If either season number or episode number is missing, the original title is
        returned unchanged.

        Parameters:
            title:
                Original title value.

            series_title:
                Parent or series title to include in the AKA text, if available.

            season_number:
                Season number used to create the S{season} text.

            episode_number:
                Episode number used to create the Episode {episode} text.

        Returns:
            str:
                The merged title with AKA season and episode information, or the
                original title if required values are missing or invalid.
        """
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
        

    @staticmethod
    def get_connection():
        "Used to connect to Snowflake database"
        return snowflake.connector.connect(
            user='MUVEESHKUMAR.SHANMUGAM@WBD.COM',
            account='WBD-COMMONDATAPROD',   
            database='BOLT_MSC_CDS_PROD',
            schema='ATOM_BI',
            role='PUBLIC',
            authenticator='externalbrowser'
        )

    # =========================================================
    # Step 1: Cross‑Encoder Utility
    # =========================================================

    @staticmethod
    def apply_cross_encoder(df, colA, colB, semantic_col, out_col, cross_model, low=80, high=88):
        """
        Applies a CrossEncoder model to borderline semantic matches.

        This function identifies rows where the semantic similarity score falls
        within a specified score range. For those rows, it creates text pairs from
        two selected columns and sends them to a CrossEncoder model for more
        accurate pairwise scoring.

        The CrossEncoder score is written into a new output column. Rows outside
        the selected semantic score range are not scored by the CrossEncoder and
        remain as None in the output column.

        Parameters:
            df:
                Input pandas DataFrame containing match candidate records.

            colA:
                Name of the first text column used for pairwise comparison.
                Example: "INPUT_TITLE_NORM".

            colB:
                Name of the second text column used for pairwise comparison.
                Example: "ATOM_TITLE_NORM".

            semantic_col:
                Name of the column containing semantic similarity scores.

            out_col:
                Name of the output column where CrossEncoder scores will be stored.

            cross_model:
                CrossEncoder model object with a `.predict()` method.

            low:
                Lower inclusive semantic score threshold.
                Default is 80.

            high:
                Upper exclusive semantic score threshold.
                Default is 88.

        Returns:
            pandas.DataFrame:
                The input DataFrame with an added CrossEncoder score column.
        """

        df[out_col] = None

        mask = (df[semantic_col] >= low) & (df[semantic_col] < high)

        pairs = list(zip(df.loc[mask, colA], df.loc[mask, colB]))

        if not pairs:
            return df
        
        scores = cross_model.predict(pairs)
        df.loc[mask, out_col] = [round(s * 100, 2) for s in scores]

        return df

    # Step 2: Control Extra Words (CRITICAL)
    @staticmethod
    def extra_word_ratio(input_title, candidate_title):
        """
        Counts the number of extra words in the candidate title compared with the
        input title.

        This function converts both titles to lowercase, splits them into words,
        and compares the unique word sets. It returns the count of words that are
        present in the candidate title but not present in the input title.

        This is useful in title matching to control false positives where a
        candidate title contains too many additional words beyond the input title.

        Parameters:
            input_title:
                Original input title used for matching.

            candidate_title:
                Candidate title returned from the library or matching source.

        Returns:
            int:
                Number of extra unique words found in the candidate title.
        """
        t1 = set(input_title.lower().split())
        t2 = set(candidate_title.lower().split())

        extra = len(t2 - t1)
        return extra

    @staticmethod
    def extract_numbers(text, ignore_year=True):
        """
        Extracts numeric values from a text string.

        This function searches the input text and returns all digit sequences found.
        By default, it ignores year-like values between 1900 and 2099 so that
        release years do not affect title matching logic.

        This is useful when validating whether important numbers in an input title
        also appear in a candidate title, such as season numbers, episode numbers,
        part numbers, or installment numbers.

        Parameters:
            text:
                Input text from which numbers should be extracted.

            ignore_year:
                Boolean flag that controls whether year-like numbers from 1900 to
                2099 should be excluded. Defaults to True.

        Returns:
            list:
                A list of extracted numbers as strings.
        """
        nums = re.findall(r'\d+', text)
        
        if ignore_year:
            nums = [n for n in nums if not (1900 <= int(n) <= 2099)]
        
        return nums
    
    def numbers_match(self, a, b):
        "Checking if the numbers in two titles match."
        return self.extract_numbers(a) == self.extract_numbers(b)
    # =========================================================
    # Step 4: Final Decision (Single Title)
    # =========================================================
    
    
    def final_decision(self, input_title, candidate_title, semantic_score, cross_score=None):
        """
        Determines the final match decision between an input title and a candidate title.

        This method applies a set of business rules to decide whether a candidate
        title should be treated as a Perfect Match, Possible Match, or Reject.

        The decision logic checks:
            - Whether season and episode numbers match when both titles contain them.
            - Whether numeric values from the input title are present in the candidate title.
            - Whether the input title is an AKA title.
            - Whether short input titles have too many extra words in the candidate title.
            - Whether the semantic similarity score is high enough for acceptance.
            - Whether a CrossEncoder score can improve the decision for borderline cases.

        Parameters:
            input_title:
                The original or normalized input title.

            candidate_title:
                The candidate title being compared against the input title.

            semantic_score:
                The semantic similarity score, usually scaled from 0 to 100.

            cross_score:
                Optional CrossEncoder score used for borderline semantic matches.
                If provided, it can upgrade or reject matches in the 70 to 88 score range.

        Returns:
            str:
                One of the following decision labels:
                    - "Perfect Match"
                    - "Possible Match"
                    - "Reject"
        """

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

    # =========================================================
    # Step 5: Combined Series + Episode Logic
    # =========================================================
    

    def combined_match_logic(self,row):
        """
        Combines series-level and episode-level matching results into one final
        episodic match decision.

        This method is used for episodic matching where two relationships must be
        evaluated together:
            - Series title compared with parent title.
            - Input episode title compared with candidate Atom title.

        The method first applies hard validation rules for season, episode, and
        other numeric values. It then applies extra-word controls to reduce false
        positives. After validation, it combines the two individual match decisions
        and optionally uses CrossEncoder scores to upgrade borderline cases.

        Parameters:
            row:
                A pandas Series representing one candidate match row. The row is
                expected to contain intermediate match result, semantic score,
                cross score, and extra-word columns.

        Returns:
            str:
                Final combined match decision:
                    - "Perfect Match"
                    - "Possible Match"
                    - "Reject"
        """
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

    # Small helper: Top-N per ID by score using one sort + groupby.head (fast)
    @staticmethod
    def top_n_per_id(df, id_col, score_col, n):
        """
        Filters match candidates by keeping high-scoring rows or the top N rows per ID.

        This function sorts the DataFrame by the given ID column and score column.
        For each ID group, it keeps all rows where the score is 90 or higher. If no
        rows in that ID group meet the high-score threshold, it keeps only the top
        N rows based on the score.

        This is useful in matching workflows where strong matches should always be
        retained, while weaker candidate groups should be limited to a manageable
        number of review records.

        Parameters:
            df:
                Input pandas DataFrame containing candidate match records.

            id_col:
                Column name used to group records.
                Example: "ID".

            score_col:
                Column name used to rank records within each ID group.
                Example: "FINAL_SCORE" or "SEMANTIC_SCORE".

            n:
                Number of top rows to keep for an ID group when no score is 90 or
                above.

        Returns:
            pandas.DataFrame:
                Filtered DataFrame containing either all high-score rows per ID or
                the top N rows when no high-score records exist.
        """
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
    
    @staticmethod
    def flatten_groups(groups):
        """
        Flattens grouped column definitions into a single ordered column list.

        This helper takes a list of grouped column configurations, where each group
        contains a group name and a list of column names. It ignores the group names
        and returns one combined list of columns in the same order as they appear in
        the group configuration.

        Parameters:
            groups:
                A list of tuples in the format:
                    [
                        ("GROUP NAME", ["COL1", "COL2"]),
                        ("ANOTHER GROUP", ["COL3", "COL4"])
                    ]

        Returns:
            list:
                A single ordered list of column names.
        """
        ordered = []
        for _, cols in groups:
            ordered.extend(cols)
        return ordered

    @staticmethod
    def try_number_preserve_decimals(x):
        """
        Converts safely numeric values into int or float while preserving non-numeric
        values unchanged.

        This helper is used before writing data to Excel. It converts integer-like
        values to int, decimal values to float, and missing or blank values to
        pd.NA so they appear as blank cells. If a value is not clearly numeric, it
        is returned as-is.

        Parameters:
            x:
                Input value to be converted.

        Returns:
            int, float, pd.NA, or original value:
                Converted numeric value when safe, missing value as pd.NA, or the
                original value if conversion is not safe.
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
    
    def convert_columns_try_number_preserve_decimals(self,df, cols):
        """
        Applies safe numeric conversion to selected DataFrame columns.

        This method loops through a list of column names and applies
        try_number_preserve_decimals() only to columns that exist in the DataFrame.
        It is useful for cleaning numeric identifier columns before writing the
        final output to Excel.

        Parameters:
            df:
                pandas DataFrame containing output data.

            cols:
                List of column names that should be converted where possible.

        Returns:
            pandas.DataFrame:
                The DataFrame with selected columns safely converted.
        """
        for col in cols:
            if col in df.columns:
                df[col] = df[col].apply(self.try_number_preserve_decimals)
        return df
    
  
    def apply_grouped_formatting(self, df, sheet_name, ip_mode):
        """
        Applies grouped Excel formatting to a DataFrame and writes it to a worksheet.

        This method prepares a DataFrame for final Excel output by ordering columns
        according to the selected IP mode, converting numeric-looking identifier
        columns, creating a `For Ingestion` column, applying grouped header bands,
        formatting column headers, setting column widths, and writing data rows
        with conditional formatting.

        The formatting behavior depends on `ip_mode`, which determines which column
        groups are used. Supported modes are expected to come from `self.GROUPS`,
        such as STANDALONE, SERIES, or EPISODICS.

        The method also adds special formatting for:
            - Duplicate or unique IDs.
            - Missing ingestion identifiers.
            - Identifier values containing pipe characters.
            - Reltio entity hyperlinks.
            - IMDb title hyperlinks.

        Parameters:
            df:
                pandas DataFrame containing the output data to write.

            sheet_name:
                Name of the Excel worksheet to create.

            ip_mode:
                Key used to select the appropriate column grouping configuration
                from `self.GROUPS`.

        Returns:
            pandas.DataFrame:
                The reordered and cleaned DataFrame that was written to Excel.
        """
        
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

    def format_no_match(self,df, sheet_name):
        """
        Writes no-match records into a formatted Excel worksheet.

        This method creates a new worksheet for records that did not receive a
        valid match. It applies numeric cleanup to selected columns, writes
        formatted headers, adjusts column widths, and writes each data cell with
        border formatting.

        Parameters:
            df:
                DataFrame containing no-match records.

            sheet_name:
                Name of the worksheet to create.

        Returns:
            None
                The method writes directly to the workbook.
        """
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

    def score_series_matches(self,series_df, input_titles_0, model, cross_model):
        """
        Scores candidate series matches against input series titles.

        This method maps each candidate row back to its input series title, normalizes
        both input and candidate titles, generates embeddings, calculates semantic
        similarity, applies CrossEncoder scoring for borderline matches, assigns a
        final match result, ranks candidates per ID, and adds explainability columns.

        Parameters:
            series_df:
                DataFrame containing candidate series records.

            input_titles_0:
                DataFrame containing original input title data keyed by Sno.

            model:
                SentenceTransformer model used to generate title embeddings.

            cross_model:
                CrossEncoder model used to rescore borderline matches.

        Returns:
            pandas.DataFrame:
                Series match DataFrame with scores, final decisions, rankings,
                confidence labels, reasons, and evidence.
       """
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


    def score_child_matches(self,child_df, input_titles_0, model, cross_model):
        """
        Scores episodic or child-title candidates using both parent-series and
        episode-title matching logic.

        This method compares the input series title against the candidate parent
        title, and also compares the input episode title against the candidate Atom
        title. It calculates semantic scores, optional CrossEncoder scores, individual
        match results, extra-word counts, and a combined final match decision.

        Parameters:
            child_df:
                DataFrame containing child or episodic candidate records.

            input_titles_0:
                DataFrame containing original input data, including SERIES_TITLE
                and MATCH_TITLE_RAW.

            model:
                SentenceTransformer model used to generate embeddings.

            cross_model:
                CrossEncoder model used for borderline match rescoring.

        Returns:
            pandas.DataFrame:
                Child match DataFrame with parent and episode scores, combined
                match result, ranking, confidence, reason, and evidence columns.
        """
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

    @staticmethod
    def filter_children_by_selected_series(child_df, selected_parent_ids):
        """
        Filters child candidate records based on selected parent series entities.

        This method keeps child records whose PARENT_ENTITY matches the selected
        parent IDs. If some input IDs do not have candidates under the selected
        parents, fallback candidates are retained so those IDs are not completely
        lost from downstream processing.

        Parameters:
            child_df:
                DataFrame containing child candidate records.

            selected_parent_ids:
                Collection of parent entity IDs selected by the user.

        Returns:
            pandas.DataFrame:
                Filtered child candidate DataFrame.
        """

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

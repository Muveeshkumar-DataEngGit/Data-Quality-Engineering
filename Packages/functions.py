# AKA split
import snowflake.connector
import re
import math
import numpy as np
import pandas as pd
from sentence_transformers import SentenceTransformer, CrossEncoder, util
import unicodedata
import tkinter as tk
from tkinter import filedialog
import os
import shutil



class all_functions:
    def __init__(self):
        self.writer = None
        self.workbook = None

    def set_writer(self, writer):
        self.writer = writer
        self.workbook = writer.book
        # -----------------------------
        # 1) Define column grouping rules (your requirement)
        # -----------------------------
        self.GROUPS = {
            "STANDALONE": [
                ("MATCHED OUTPUT", ["ID","INPUT_TITLES","ATOM_TITLE","INPUT_YEAR","YEARS","TT_CODES"]),
                ("STANDALONE INFO", ["IP_TYPE","NODE_IDENTIFIER"]),
                ("PARENT INFO", ["PARENT_TITLE","PARENT_ENTITY","PARENT_MPM"]),
                ("SCORES", ["SEMANTIC_SCORE","MATCH_RESULT"]),
                ("IDENTIFIERS", ["MPM_NUMBER","PI_UUID","PROPERTY_ID","HBO_ID","META_ID","TURNER_TITLEID","MMS3_MCODE",
                                "DASH_TITLE_ID","ALEPH_ID","IBROADCAST_EMEA_ID","IBROADCAST_APAC_ID",
                                "For Ingestion"])
            ],

            "SERIES": [
                ("MATCHED OUTPUT", ["ID","INPUT_TITLES","ATOM_TITLE","INPUT_YEAR","YEARS","TT_CODES"]),
                ("SERIES INFO", ["IP_TYPE","NODE_IDENTIFIER","CHILDREN_STATUS"]),
                ("SCORES", ["SEMANTIC_SCORE","MATCH_RESULT"]),
                ("IDENTIFIERS", ["MPM_NUMBER","PI_UUID","HBO_ID","META_ID","TURNER_TITLEID","MMS3_MCODE",
                                "DASH_TITLE_ID","ALEPH_ID","IBROADCAST_EMEA_ID","IBROADCAST_APAC_ID",
                                "For Ingestion"])
            ],

            "SEASON": [
                ("MATCHED OUTPUT", ["ID","INPUT_TITLES","ATOM_TITLE","INPUT_YEAR","YEARS","TT_CODES"]),
                ("SEASON INFO", ["IP_TYPE","NODE_IDENTIFIER","CHILDREN_STATUS"]),
                ("PARENT INFO", ["PARENT_TITLE","PARENT_ENTITY","PARENT_MPM"]),
                ("SCORES", ["SEMANTIC_SCORE","MATCH_RESULT"]),
                ("IDENTIFIERS", ["MPM_NUMBER","PI_UUID","PROPERTY_ID","HBO_ID","META_ID","TURNER_TITLEID","MMS3_MCODE",
                                "DASH_TITLE_ID","ALEPH_ID","IBROADCAST_EMEA_ID","IBROADCAST_APAC_ID",
                                "For Ingestion"])
            ],

            "EPISODICS": [
                ("MATCHED OUTPUT", ["ID","SERIES_TITLE","PARENT_TITLE","INPUT_TITLE","ATOM_TITLE","INPUT_YEAR","YEARS","TT_CODES"]),
                ("EPISODE INFO", ["IP_TYPE","NODE_IDENTIFIER"]),
                ("PARENT INFO", ["PARENT_ENTITY","PARENT_MPM"]),
                ("SCORES", ["SEMANTIC_SCORE_1","FINAL_MATCH_RESULT"]),
                ("IDENTIFIERS", ["MPM_NUMBER","PI_UUID","PROPERTY_ID","HBO_ID","META_ID","TURNER_TITLEID","MMS3_MCODE",
                                "DASH_TITLE_ID","ALEPH_ID","IBROADCAST_EMEA_ID","IBROADCAST_APAC_ID",
                                "For Ingestion"])
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
        }
        self.MIN_COL_WIDTH = 10
        self.MAX_COL_WIDTH = 60

    @staticmethod
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
    
    @staticmethod
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

    @staticmethod
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
    
    @staticmethod
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
        

    @staticmethod
    def get_connection():
        return snowflake.connector.connect(
            user='MUVEESHKUMAR.SHANMUGAM@WBD.COM',
            password='MUVEE@23devamanohari', # optional
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
        t1 = set(input_title.lower().split())
        t2 = set(candidate_title.lower().split())

        extra = len(t2 - t1)
        return extra

    @staticmethod
    def extract_numbers(text, ignore_year=True):
        nums = re.findall(r'\d+', text)
        
        if ignore_year:
            nums = [n for n in nums if not (1900 <= int(n) <= 2099)]
        
        return nums
    
    def numbers_match(self, a, b):
        return self.extract_numbers(a) == self.extract_numbers(b)
    # =========================================================
    # Step 4: Final Decision (Single Title)
    # =========================================================
    
    
    def final_decision(self, input_title, candidate_title, semantic_score, cross_score=None):

        input_title = input_title.strip()
        candidate_title = candidate_title.strip()
        extra_words = self.extra_word_ratio(input_title, candidate_title)
        
        # 🔴 HARD RULE: numbers must match
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
        ordered = []
        for _, cols in groups:
            ordered.extend(cols)
        return ordered

    @staticmethod
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
    
    def convert_columns_try_number_preserve_decimals(self,df, cols):
        for col in cols:
            if col in df.columns:
                df[col] = df[col].apply(self.try_number_preserve_decimals)
        return df
    
  
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
            worksheet.merge_range(0, start, 0, end, group_name, self.group_band_format)

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
        
        @staticmethod
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
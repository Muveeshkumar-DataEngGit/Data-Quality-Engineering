# Upload ML model zip files from local machine to Snowflake user stage
# Co-authored with CoCo
"""
Run this script on your LOCAL machine (not in Snowflake) to upload model zip files.

Prerequisites:
  - pip install snowflake-connector-python
  - Two zip files ready:
      all-MiniLM-L6-v2.zip
      stsb-roberta-base.zip

Usage:
  python upload_models_to_stage.py
"""

import os
import snowflake.connector

# ─── Configuration ────────────────────────────────────────────────────────────
# Update these paths to match where your zip files are located
MODEL_DIR = os.path.expanduser(r"C:\Users\mshanmugam\OneDrive - Warner Bros. Discovery\JUPYTER_PY\AI Projects\Model")  # Change this to your folder path

BIENCODER_ZIP = os.path.join(MODEL_DIR, "all-MiniLM-L6-v2.zip")
CROSSENCODER_ZIP = os.path.join(MODEL_DIR, "stsb-roberta-base.zip")

STAGE_PATH = "@~/ml_models/"

# ─── Connect to Snowflake ─────────────────────────────────────────────────────
print("Connecting to Snowflake (browser auth will open)...")
conn = snowflake.connector.connect(
    user="MUVEESHKUMAR.SHANMUGAM@WBD.COM",
    account="WBD-COMMONDATAPROD",
    database="BOLT_MSC_CDS_PROD",
    schema="ATOM_BI",
    role="PUBLIC",
    authenticator="externalbrowser"
)
cur = conn.cursor()
print("Connected successfully!\n")

# ─── Upload Files ─────────────────────────────────────────────────────────────
for zip_path in [BIENCODER_ZIP, CROSSENCODER_ZIP]:
    filename = os.path.basename(zip_path)

    if not os.path.exists(zip_path):
        print(f"ERROR: File not found: {zip_path}")
        print(f"  Please update MODEL_DIR variable to point to your zip files folder.")
        continue

    size_mb = os.path.getsize(zip_path) / (1024 * 1024)
    print(f"Uploading {filename} ({size_mb:.1f} MB)...")

    # Use PUT to upload - AUTO_COMPRESS=FALSE keeps the zip as-is
    zip_path_sql = zip_path.replace("\\", "/")

    put_sql = f"""
    PUT 'file:///{zip_path_sql}'
    {STAGE_PATH}
    AUTO_COMPRESS=FALSE
    OVERWRITE=TRUE
    """
    cur.execute(put_sql)

    result = cur.fetchall()
    for row in result:
        print(f"  Status: {row[6]}")  # status column

    print(f"  Done!\n")

# ─── Verify Upload ────────────────────────────────────────────────────────────
print("Verifying files on stage...")
cur.execute(f"LS {STAGE_PATH}")
files = cur.fetchall()

if files:
    print(f"\nFiles on {STAGE_PATH}:")
    print(f"  {'Name':<50} {'Size (MB)':<12}")
    print(f"  {'-'*50} {'-'*12}")
    for row in files:
        name = row[0]
        size_mb = row[1] / (1024 * 1024)
        print(f"  {name:<50} {size_mb:.1f}")
    print(f"\nAll files uploaded successfully!")
else:
    print("WARNING: No files found on stage. Upload may have failed.")

# ─── Cleanup ──────────────────────────────────────────────────────────────────
cur.close()
conn.close()
print("\nDone. You can now run the Streamlit app in Snowflake.")

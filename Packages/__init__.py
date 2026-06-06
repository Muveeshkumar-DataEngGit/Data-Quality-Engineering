import logging

from Packages.functions import initial_class
from Packages.functions import matching_pipeline
from Packages.functions import load_and_match

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)
logger.filemode = 'w'
f = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
fh = logging.FileHandler('SVOD.log')
fh.setFormatter(f)
logger.addHandler(fh)

logger.info("All functions imported successfully from functions.py")
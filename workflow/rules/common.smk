import pandas as pd


# these two lines are for testing.  Comment out before distribution
from snakemake.io import load_configfile
config = load_configfile("config/config.yaml")

configfile: "config/config.yaml"  



# get the chromosome numbers we are doing
df = pd.read_csv(config["chrom_file"], header=None, delimiter=r"\s+")



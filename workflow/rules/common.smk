import pandas as pd


# these two lines are for testing.  Comment out before distribution
#from snakemake.io import load_configfile
#config = load_configfile("config/config.yaml")

configfile: "config/config.yaml"  



# get the chromosome numbers we are doing
df = pd.read_csv(config["chrom_file"], header=None, sep = "\t")

chrom_list = df.iloc[:, 1].tolist()

chrom_table = df.set_axis(['orig_chrom', 'integer_chrom'], axis=1).set_index("integer_chrom", drop = False)


def orig_chrom_from_integer_chrom(wildcards):
	return chrom_table.loc[int(wildcards.chrom), "orig_chrom"]


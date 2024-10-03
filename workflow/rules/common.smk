import pandas as pd


# these two lines are for testing.  Comment out before distribution
#from snakemake import load_configfile
#from snakemake.common.configfile import _load_configfile
#config = _load_configfile(".test/config-test-beagle/config.yaml")



# get the chromosome numbers we are doing for eagle
if config["method"] == "eagle":
	df = pd.read_csv(config["eagle_chrom_file"], header=None, sep = "\t")
	chrom_list = df.iloc[:, 1].tolist()
	chrom_table = df.set_axis(['orig_chrom', 'integer_chrom'], axis=1).set_index("integer_chrom", drop = False)
	def orig_chrom_from_integer_chrom(wildcards):
		return chrom_table.loc[int(wildcards.chrom), "orig_chrom"]



if config["method"] == "beagle":
	df = pd.read_csv(config["beagle_regions"], header=None, sep = "\t")
	beagle_regions = df[0].tolist()


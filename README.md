mega-impute-and-phase-snakeflows
================

- [BEAGLE](#beagle)
- [EAGLE](#eagle)
- [Command line invocation](#command-line-invocation)
  - [Running Under SLURM](#running-under-slurm)
- [Rule Graphs](#rule-graphs)
  - [Eagle rulegraph](#eagle-rulegraph)
  - [Beagle rulegraph](#beagle-rulegraph)

<!-- README.md is generated from README.Rmd. Please edit that file -->
<!-- badges: start -->
<!-- badges: end -->

The goal of **mega-impute-and-phase-snakeflows** is to provide a simple
snakemake workflow for phasing whole genome sequencing data,
parallelized over chromosomes. It is product of the **M**olecular
**E**cology and **G**enetic **A**nalysis Team at the Southwest Fisheries
Science Center’s Santa Cruz Lab.

The basic input is a VCF file and a text file with a list of chromosomes
or regions to be done.

Currently, there are two methods implemented: `eagle`, which is suitable
for higher read depth data with reliable genotype calls, and `beagle`,
which is suitable for lower coverage data with genotype likelihoods (but
unreliable genotype calls) in the VCF. Note that `beagle` does not
accept BCF files. It has be to be a .VCF.gz file, and it should be
indexed.

## BEAGLE

The easiest way to see how to configure the workflow for `beagle` is to
see the small test config in `.test/config-test-beagle` that uses the
data in `.test/data/small.vcf.gz`. The comments in
`.test/config-test-beagle/config.yaml` contain all you need to know to
set up the run. You should copy the config file and use it as a template
for setting up your own run.

``` yaml
method: beagle

# path to the VCF file of all the genotypes you want phased.
# This must be indexed (i.e. with bcftools).  Note that it is
# up to the user to do any filtering of sites of individuals desired
# outside of this workflow.  You should probably filter it down to
# biallelic sites, and maybe do a MAF filter if you want.  For BEAGLE,
# I think this thing needs to be a VCF.gz
vcf_input: ".test/data/small.vcf.gz"


# path to a file with a single unnamed column of regions specified the
# way you can with beagle:  chrom:start-end, chrom, chrom:-end,
# or chrom:start-
# These should be in genomic order since things will be catenated at the end.
beagle_regions: .test/config-test-beagle/beagle_regions.txt


# these are required and should be adjusted to correspond to
# the architecture and number of threads being used.  For example,
# on SEDNA, since each core is about 4.8 Gb, you could reasonably give
# 4 Gb for each core to the Java virtual machine heap.  So, if you
# are doing 5 threads for these jobs, then you would use 5 * 4 = 20 for
# the Java heap.  Thus setting it to -Xmx20g.
beagle_impute_mem: "–Xmx1g"
beagle_phase_mem: "–Xmx1g"
```

Basically, you just need an indexed vcf.gz file, an appropriate config
file, and a file of regions that is a single column, and will look like
this, for example:

    omy01
    omy03
    omy04
    omy05
    omy06
    omy07
    omy08

where those are chromosome names.

The steps done with the beagle workflow are:

1.  Impute the genotypes using Beagle 4.1 for each chromosome.
2.  Phase the output from the previous step.
3.  Catenate the results VCFs back together.

## EAGLE

For using eagle, study, copy and modify the config file at
`.test/config-test-eagle/config.yaml` that looks like this:

``` yaml
method: eagle

# path to the VCF file of all the genotypes you want phased.
# This must be indexed (i.e. with bcftools).
vcf_input: ".test/data/small.vcf.gz"

# path to the Eagle executable. (Only runs on Linux)
eagle_path: bin/eagle-Linux

# path to the two columns TSV file (with no column names). The first
# column is the chromosome name as it appears in the input VCF/BCF
# file and the second is the integer equivalent
eagle_chrom_file: .test/config-test-eagle/mykiss_chroms.tsv


# A map file that specifies 1 centiMorgan per megabase on all chromosomes.
# This is used by eagle if a good recombination map is not available for your
# species.
eagle_map_input: "inputs/genetic_map_1cMperMb.txt"
```

The basic idea is that you give it:

1.  The path to a vcf.gz or bcf file (it must have an index, .tbi or
    .csi) with all the genotypes,
2.  a white-space delimited file with no column names where the first
    column holds the chromosome names (corresponding to what you have in
    the VCF file) and the second holds the integer equivalent, for the
    chromosomes that you want to phase. For example if we wanted to do
    the first 7 chromosomes of *O. mykiss* that file would look like:

<!-- -->

    omy01 1
    omy02 2
    omy03 3
    omy04 4
    omy05 5
    omy06 6
    omy07 7

I think this is necessary for `eagle` because it needs integer
chromosome names.

The steps that the workflow does in `eagle` mode are:

1.  Break the VCF file up into a bunch of smaller BCF files, one per
    chromosome that you want to phase, and the chromosomes in each to
    use simple integers. Then index each of those. These go into the
    `resources/rcBCF` directory.
2.  Launch a separate job to phase each chromosome, by default using 20
    threads.
3.  In the end, the phased BCF file for each chromosome gets indexed by
    bcftools.

## Command line invocation

**To dry-run the eagle test case**

``` sh
 snakemake -np --configfile .test/config-test-eagle/config.yaml
```

**To dry-run the eagle test case**

``` sh
 snakemake -np --configfile .test/config-test-beagle/config.yaml
```

**To run the eagle test case on a node with 20 cores**

``` sh
 snakemake -p --cores 20 --set-threads phase_chromosomes=2 --use-conda  --configfile .test/config-test-eagle/config.yaml
```

Note that the `--set-threads phase_chromosomes=2` is there because each
of the jobs is quite small.

Also note that the `.test/config-test-eagle/mykiss_chroms.tsv` file
omits chromosomes 2 and 13 because, in this small version of the
dataset, those chromosomes cause eagle (and beagle) to throw errors.

### Running Under SLURM

A SLURM profile is included. See
`hpcc-profiles/slurm/sedna/config.v8+.yaml` for snakemake 8+ and
`hpcc-profiles/slurm/sedna/config.yaml` for Snakemake \<= 7.

You will need to set resources as appropriate. Setting threads of the
beagle rules can be done easily in the profile:

``` yaml
set-threads:
  beagle_impute: 5
  beagle_phase: 5
```

For Beagle, be sure to set the Java heap as appropriate for the number
of threads in the run configfile itself. i.e.,:

``` yaml
beagle_impute_mem: "–Xmx20g"
beagle_phase_mem: "–Xmx20g"
```

## Rule Graphs

Here is the rulegraph for this simple workflow, made with the commands:

``` sh
snakemake --rulegraph --configfile .test/config-test-eagle/config.yaml | dot -Tsvg > figs/rulegraph-eagle.svg
snakemake --rulegraph --configfile .test/config-test-beagle/config.yaml | dot -Tsvg > figs/rulegraph-beagle.svg
```

### Eagle rulegraph

<img src="figs/rulegraph-eagle.svg" width="25%" style="display: block; margin: auto;" />

### Beagle rulegraph

<img src="figs/rulegraph-beagle.svg" width="25%" style="display: block; margin: auto;" />

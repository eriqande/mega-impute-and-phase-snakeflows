# rules for imputing and phasing from genotype likelihoods
# using beagle 4.1.




rule beagle_impute:
    input: 
        vcf = config["vcf_input"],
    params:
        region = "{beagle_region}",
        out = "results/{method}/impute/sections/{beagle_region}",
        mem = config["beagle_impute_mem"]
    output:
        vcfgz = "results/{method}/impute/sections/{beagle_region}.vcf.gz",
    log:
        "results/log/{method}/beagle_impute/{beagle_region}.log"
    threads: 1
    conda:
        "../envs/beagle41.yaml"
    shell:
        "  beagle {params.mem} gl={input.vcf}  out={params.out} "
        "  nthreads={threads} chrom={params.region} > {log} 2> {log} "    




rule beagle_phase:
    input: 
        "results/{method}/impute/sections/{beagle_region}.vcf.gz",
    params:
        region = "{beagle_region}",
        out = "results/{method}/phase/sections/{beagle_region}",
        mem = config["beagle_phase_mem"]
    output:
        vcfgz = "results/{method}/phase/sections/{beagle_region}.vcf.gz",
    log:
        "results/log/{method}/beagle_phase/{beagle_region}.log"
    threads: 1
    conda:
        "../envs/beagle41.yaml"
    shell:
        "  beagle {params.mem} gt={input}  out={params.out} "
        "  nthreads={threads} > {log} 2> {log} "    



rule beagle_concat_phased:
    input:
        vcfs = expand("results/{method}/phase/sections/{beagle_region}.vcf.gz", method = config["method"], beagle_region = beagle_regions)
    output:
        vcf = "results/{method}/all-beagle-phased.vcf.gz",
        idx = "results/{method}/all-beagle-phased.vcf.gz.tbi",
    log:
        "results/log/{method}/beagle_concat_phased/all.log"
    threads: 1
    conda:
        "../envs/bcftools.yaml"
    shell:
        " bcftools concat -n -Oz  {input.vcfs} > {output.vcf} 2> {log} && "
        " bcftools index -t {output.vcf}  "

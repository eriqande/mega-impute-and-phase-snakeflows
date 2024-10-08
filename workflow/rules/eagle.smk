

rule split_vcf_and_rename_chrs:
	input: 
		vcf = config["vcf_input"],
		chroms = config["eagle_chrom_file"]
	params:
		orig_chrom = orig_chrom_from_integer_chrom
	output:
		bcf = "results/{method}/rcBCF/chr-{chrom}.bcf",
		csi = "results/{method}/rcBCF/chr-{chrom}.bcf.csi"
	conda:
		"envs/bcftools.yaml"
	log:
		anno = "results/log/{method}/split_vcf_and_rename_chrs/bcftools-view-annotate-{chrom}.log",
		index = "results/log/{method}/split_vcf_and_rename_chrs/bcftools-index-{chrom}.log"
	shell:
		"bcftools view -Ou {input.vcf} {params.orig_chrom} | "
		"bcftools annotate --rename-chrs {input.chroms} -Ob > {output.bcf} 2> {log.anno}; "
		"bcftools index {output.bcf} 2> {log.index}"


rule phase_chromosomes:
	input:
		bcf = "results/{method}/rcBCF/chr-{chrom}.bcf",
		csi =  "results/{method}/rcBCF/chr-{chrom}.bcf.csi"
	output:
		bcf = "results/{method}/phased_bcf/chr-{chrom}.bcf"
	params:
		eagle = config["eagle_path"],
		mapfile = config["eagle_map_input"]
	threads: 20
	resources:
		mem_mb = 92000
	log:
		"results/log/{method}/phase_chromosomes/eagle-{chrom}.log"
	shell:
		"{params.eagle} --vcf {input.bcf} --vcfOutFormat b "
		"--geneticMapFile {params.mapfile} "
		"--numThreads {threads} "
		"--chromX 35 "
		"--outPrefix results/{wildcards.method}/phased_bcf/chr-{wildcards.chrom} > {log} 2>&1 "


rule index_phased_chrom_bcfs:
	input:
		"results/{method}/phased_bcf/chr-{chrom}.bcf"
	output:
		"results/{method}/phased_bcf/chr-{chrom}.bcf.csi"
	conda:
		"envs/bcftools.yaml"
	shell:
		"bcftools index {input}"



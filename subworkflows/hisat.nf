include { HISAT_GENOTYPE } from "./../modules/hisat/genotype"
include { HISAT_REPORT } from "./../modules/hisat/report"
include { FASTQ_MERGE } from "./../modules/fastq_merge"

workflow HISAT_TYPING {

	take:
		reads

	main:

	reads.map { meta, l, r ->
                        new_meta = [:]
                        new_meta.patient_id = meta.patient_id
                        new_meta.sample_id = meta.sample_id
                        def groupKey = meta.sample_id
                        tuple( groupKey, new_meta, l, r)
                }.groupTuple(by: [0,1]).map { g ,new_meta ,l,r -> [ new_meta,l,r ] }.branch {
                        single:   it[1].size() == 1
                        multiple: it[1].size() > 1
                }.set { reads_to_merge }

        FASTQ_MERGE(
                reads_to_merge.multiple
        )
	
	HISAT_GENOTYPE(
		reads_to_merge.single.mix(FASTQ_MERGE.out.reads)
	)
	
	HISAT_REPORT(
		HISAT_GENOTYPE.out.results
	)

	emit:
	results = HISAT_GENOTYPE.out.results
	report = HISAT_REPORT.out.tsv

}

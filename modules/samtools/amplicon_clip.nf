process AMPLICON_CLIP {

        tag "${meta.patient_id}|${meta.sample_id}"

        publishDir "${params.outdir}/${meta.patient_id}/${meta.sample_id}/", mode: 'copy'

        input:
        tuple val(meta),path(bam),path(bai)
        path(bed)

        output:
        tuple val(meta),path(bam_masked),path(bam_masked_bai)

        script:
        bam_masked = bam.getBaseName() + ".amplicon_clipped.bam"
        bam_masked_bai = bam_masked + ".bai"

        """
                samtools ampliconclip -b $bed -o $bam_masked $bam
                samtools index $bam_masked
        """

}

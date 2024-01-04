
def escape_invalid_chars(path){

}

process SKYLINE_EXPORT_REPORT {
    publishDir "${params.result_dir}/skyline/reports", failOnError: true, mode: 'copy'
    label 'process_memory_high_constant'
    label 'error_retry'
    container 'quay.io/protio/pwiz-skyline-i-agree-to-the-vendor-licenses:3.0.23187-2243781'

    input:
        tuple val(study_name), path(skyline_zipfile)
        path report_template

    output:
        tuple val(study_name), path("${report_name}.tsv")

    script:
        report_name = "${study_name}_${report_template.baseName}"
        """
        # unzip skyline input file
        unzip ${skyline_zipfile}| grep 'inflating'| sed -E 's/\s?inflating:\s?//' > archive_files.txt

        wine SkylineCmd --in="${skyline_zipfile.baseName}" \
            --report-add="${report_template}" \
            --report-conflict-resolution="overwrite" --report-format="tsv" --report-invariant \
            --report-name="${report_template.baseName}" --report-file="${report_name}.tsv"

            # --log-file=skyline-export-report.log \

        cat archive_files.txt|xargs rm -fv
        """

    stub:
        """
        touch "${study_name}_${report_template.baseName}.tsv"
        """
}

process MERGE_REPORTS {
    publishDir "${params.result_dir}/skyline/reports", failOnError: true, mode: 'copy'
    label 'process_medium'
    label 'error_retry'
    container 'mauraisa/dia_qc_report:0.3'

    input:
        val study_names
        path replicate_reports
        path precursor_reports
        path metadatas

    output:
        path('data.db3'), emit: final_db

    shell:
        '''
        study_names_array=( '!{study_names.join("' '")}' )
        replicate_reports_array=( '!{replicate_reports.join("' '")}' )
        precursor_reports_array=( '!{precursor_reports.join("' '")}' )
        metadata_array=( '!{metadatas.join("' '")}' )

        for i in ${!study_names_array[@]} ; do
            echo "Working on ${study_names_array[$i]}..."

            parse_data --overwriteMode=append \
                --projectName="${study_names_array[$i]}" \
                --metadata="${metadata_array[$i]}" \
                "${replicate_reports_array[$i]}" \
                "${precursor_reports_array[$i]}"

            echo "Done!"
        done
        '''

    stub:
        """
        touch data.db3
        """
}



process UNZIP_SKY_FILE {
    publishDir "${params.result_dir}/skyline/unzip", failOnError: true, pattern: '*.archive_files.txt', mode: 'copy'
    label 'process_high_memory'
    container 'mauraisa/aws_bash:0.5'

    input:
        tuple val(study_name), path(sky_zip_file)

    output:
        tuple val(study_name), path("*.sky"), path("*.skyd"), path("*.[eb]lib"), emit: files
        path("*.archive_files.txt"), emit: log

    script:
    """
    unzip ${sky_zip_file} |tee ${sky_zip_file.baseName}.archive_files.txt
    """

    stub:
    """
    touch ${sky_zip_file.baseName}
    touch ${sky_zip_file.baseName}d
    touch lib.blib
    touch ${sky_zip_file.baseName}.archive_files.txt
    """
}

process SKYLINE_EXPORT_REPORT {
    publishDir "${params.result_dir}/skyline/reports", failOnError: true, mode: 'copy'
    label 'process_high_memory'
    // label 'error_retry'
    container 'quay.io/protio/pwiz-skyline-i-agree-to-the-vendor-licenses:3.0.23187-2243781'

    input:
        tuple val(study_name), path(sky_file), path(skyd_file), path(lib_file)
        path report_template

    output:
        tuple val(study_name), path("*.tsv")

    script:
    """
    wine SkylineCmd --in="${sky_file}" \
        --report-add="${report_template}" \
        --report-conflict-resolution="overwrite" --report-format="tsv" --report-invariant \
        --report-name="${report_template.baseName}" \
        --report-file="${study_name}_${report_template.baseName}.tsv"
    """

    stub:
    """
    touch "${study_name}_${report_template.baseName}.tsv"
    touch skyline-export-report.log
    """
}



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

process SKYLINE_EXPORT_REPORTS {
    publishDir "${params.result_dir}/skyline/reports", failOnError: true, mode: 'copy'
    label 'process_high_memory'
    // label 'error_retry'
    container 'quay.io/protio/pwiz-skyline-i-agree-to-the-vendor-licenses:3.0.24020-c3a52ef'

    input:
        tuple val(study_name), path(sky_file), path(skyd_file), path(lib_file)
        path replicate_report_template
        path precursor_report_template

    output:
        tuple val(study_name), path("*_replicate_quality.tsv"), path("*_precursor_quality.tsv"), emit: reports
        path("*.stdout"), emit: stdout
        path("*.stderr"), emit: stderr

    script:
    """
    # Write batch commands to file
    echo '--in=${sky_file}' > batch_commands.bat
    echo '--report-add=${replicate_report_template} --report-conflict-resolution="overwrite"' >> batch_commands.bat
    echo '--report-add=${precursor_report_template} --report-conflict-resolution="overwrite"' >> batch_commands.bat
    echo '--report-format="tsv" --report-invariant --report-name="${replicate_report_template.baseName}" --report-file="${study_name}_${replicate_report_template.baseName}.tsv"' >> batch_commands.bat
    echo '--report-format="tsv" --report-invariant --report-name="${precursor_report_template.baseName}" --report-file="${study_name}_${precursor_report_template.baseName}.tsv"' >> batch_commands.bat

    # Export reports
    wine SkylineCmd --batch-commands='batch_commands.bat' \
        > >(tee 'export_reports.stdout') 2> >(tee 'export_reports.stderr' >&2)
    '''

    stub:
    """
    touch "${study_name}_${replicate_report_template.baseName}.tsv"
    touch "${study_name}_${precursor_report_template.baseName}.tsv"
    touch stub.stdout stub.stderr
    """
}


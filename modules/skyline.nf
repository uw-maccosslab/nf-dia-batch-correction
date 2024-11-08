
process UNZIP_SKY_FILE {
    publishDir "${params.result_dir}/skyline/unzip", failOnError: true, pattern: '*.archive_files.txt', mode: 'copy'
    label 'process_high_memory'
    container params.images.linux

    input:
        tuple val(study_name), path(sky_zip_file)

    output:
        tuple val(study_name), path("*.sky"), path("*.{skyd,[eb]lib,[eb]libc,protdb,sky.view}"), emit: files
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

process SKYLINE_EXPORT_ANNOTATIONS {
    publishDir "${params.result_dir}/skyline/reports", failOnError: true, mode: 'copy'
    label 'process_high_memory'
    label 'error_retry'
    container params.images.proteowizard

    input:
        tuple val(study_name), path(sky_file), path(sky_artifacts)

    output:
        tuple val(study_name), path('*_annotations.csv'), emit: reports

    shell:
    '''
    wine SkylineCmd --in="!{sky_file}" \
        --exp-annotations="!{study_name}_annotations.csv" \
        --exp-annotations-include-object=Replicate \
        > >(tee 'export_annotations.stdout') 2> >(tee 'export_annotations.stderr' >&2)
    '''

    stub:
    """
    touch "${study_name}_annotations.csv"
    touch stub.stdout stub.stderr
    """
}

process SKYLINE_EXPORT_REPORTS {
    publishDir "${params.result_dir}/skyline/reports", failOnError: true, mode: 'copy'
    label 'process_high_memory'
    label 'error_retry'
    container params.images.proteowizard

    input:
        tuple val(study_name), path(sky_file), path(sky_artifacts)
        path replicate_report_template
        path precursor_report_template

    output:
        tuple val(study_name), path("*_replicate_quality.tsv"), path("*_precursor_quality.tsv"), emit: reports
        path("*.stdout"), emit: stdout
        path("*.stderr"), emit: stderr

    shell:
    '''
    # Write batch commands to file
    echo "--in=\\"!{sky_file}\\"" | sed 's/\\\\//g' > batch_commands.bat

    for report in !{replicate_report_template} !{precursor_report_template} ; do
        echo "--report-add=\\"$report\\" --report-conflict-resolution=overwrite" | sed 's/\\\\//g' >> batch_commands.bat
    done

    for name in '!{replicate_report_template.baseName}' '!{precursor_report_template.baseName}' ; do
        echo "--report-format=tsv --report-invariant --report-name=\\"$name\\" --report-file=\\"!{study_name}_${name}.tsv\\"" | sed 's/\\\\//g' >> batch_commands.bat
    done

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


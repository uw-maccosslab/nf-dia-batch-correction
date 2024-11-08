
def format_flag(var, flag) {
    ret = (var == null ? "" : "${flag} ${var}")
    return ret
}

def format_flags(vars, flag) {
    if(vars instanceof List) {
        return (vars == null ? "" : "${flag} \'${vars.join('\' ' + flag + ' \'')}\'")
    }
    return format_flag(vars, flag)
}

process NORMALIZE_DB {
    publishDir "${params.result_dir}/normalize_db", failOnError: true, mode: 'copy'
    label 'process_high_memory'
    container params.images.batch_report
    stageInMode 'copy'

    input:
        path batch_db

    output:
        path("${batch_db.baseName}.db3"), emit: normalized_db
        path("*.stdout"), emit: stdout
        path("*.stderr"), emit: stderr

    script:
        """
        dia_qc normalize \
            ${format_flag(params.normalize_db.method, "--method")} \
            ${format_flags(params.normalize_db.exclude_replicates, "--excludeRep")} \
            ${format_flags(params.normalize_db.exclude_projects, "--excludeProject")} \
            "${batch_db}" \
            > >(tee "normalize_db.stdout") 2> >(tee "normalize_db.stderr" >&2)
        """

    stub:
        """
        touch "normalized_${batch_db.baseName}.db3"
        touch stub.stdout stub.stderr
        """
}

process GENERATE_BATCH_RMD {
    publishDir "${params.result_dir}/batch_report", failOnError: true, mode: 'copy'
    label 'process_low'
    container params.images.batch_report

    input:
        path normalized_db

    output:
        path("bc_report.rmd"), emit: bc_rmd
        path("*.stdout"), emit: stdout
        path("*.stderr"), emit: stderr

    script:
        """
        dia_qc batch_rmd \
            ${format_flag(params.bc.method, "--bcMethod")} \
            ${format_flag(params.bc.batch1, "--batch1")} \
            ${format_flag(params.bc.batch2, "--batch2")} \
            ${format_flags(params.bc.color_vars, "--addColor")} \
            ${format_flag(params.bc.control_key, "--controlKey")} \
            ${format_flags(params.bc.control_values, "--addControlValue")} \
            ${format_flags(params.bc.covariate_vars, "--addCovariate")} \
            ${format_flag(params.bc.plot_ext, "--savePlots")} \
            --precursorTables 70 --proteinTables 70 \
            ${normalized_db} \
        > >(tee "generate_batch_rmd.stdout") 2> >(tee "generate_batch_rmd.stderr" >&2)
        """

    stub:
        """
        touch bc_report.rmd
        touch stub.stdout stub.stderr
        """
}


process RENDER_BATCH_RMD {
    publishDir "${params.result_dir}/batch_report/rmd", failOnError: true, mode: 'copy'
    publishDir "${params.result_dir}/batch_report/rmd/tables", pattern: '*.tsv', failOnError: true, mode: 'copy'
    publishDir "${params.result_dir}/batch_report/rmd", pattern: '*.stdout', failOnError: true, mode: 'copy'
    publishDir "${params.result_dir}/batch_report/rmd", pattern: '*.stderr', failOnError: true, mode: 'copy'
    label 'process_high_memory'
    container params.images.batch_report

    input:
        path batch_rmd
        path normzlize_db

    output:
        path("bc_report.html"), emit: bc_html
        path("*.tsv"), emit: tsv_reports, optional: true
        path("plots/*"), emit: bc_plots, optional: true
        path("*.stdout"), emit: stdout
        path("*.stderr"), emit: stderr

    script:
        """
        mkdir plots
        Rscript -e "rmarkdown::render('${batch_rmd}')" \
            > >(tee -a "render_batch_rmd.stdout") 2> >(tee -a "render_batch_rmd.stderr" >&2)
        """

    stub:
        """
        touch bc_report.html
        touch stub.stdout stub.stderr
        """
}


process MERGE_REPORTS {
    publishDir "${params.result_dir}/merge_reports", failOnError: true, mode: 'copy'
    label 'process_high_memory'
    container params.images.batch_report

    input:
        val study_names
        path replicate_reports
        path precursor_reports
        path metadatas

    output:
        path('data.db3'), emit: final_db
        path("*.stdout"), emit: stdout
        path("*.stderr"), emit: stderr

    shell:
        '''
        study_names_array=( '!{study_names.join("' '")}' )
        replicate_reports_array=( '!{replicate_reports.join("' '")}' )
        precursor_reports_array=( '!{precursor_reports.join("' '")}' )
        metadata_array=( '!{metadatas.join("' '")}' )

        for i in ${!study_names_array[@]} ; do
            echo "Working on ${study_names_array[$i]}..."

            dia_qc parse --overwriteMode=append \
                --projectName="${study_names_array[$i]}" \
                --metadata="${metadata_array[$i]}" \
                !{params.skyline.group_by_gene ? "--groupBy=gene" : ""} \
                "${replicate_reports_array[$i]}" \
                "${precursor_reports_array[$i]}" \
                > >(tee -a "parse_data.stdout") 2> >(tee -a "parse_data.stderr" >&2)

            echo "Done!"
        done
        '''

    stub:
        """
        touch data.db3
        touch stub.stdout stub.stderr
        """
}


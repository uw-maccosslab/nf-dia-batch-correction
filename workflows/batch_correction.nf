
include { MERGE_REPORTS } from "../nf-submodules/modules/qc_report.nf"
include { NORMALIZE_DB } from "../nf-submodules/modules/qc_report.nf"
include { GENERATE_BATCH_RMD } from "../nf-submodules/modules/qc_report.nf"
include { RENDER_BATCH_RMD } from "../nf-submodules/modules/qc_report.nf"

workflow batch_correction {
    take:
        study_names
        metadatas
        replicate_reports
        precursor_reports

    emit:
        normalized_db
        bc_rmd
        bc_html
        bc_tsv_reports

    main:
        
        // Merge tsv reports into database and render rmd report
        MERGE_REPORTS(study_names.collect(), replicate_reports.collect(),
                      precursor_reports.collect(), metadatas.collect())
        NORMALIZE_DB(MERGE_REPORTS.out.final_db) | GENERATE_BATCH_RMD
        RENDER_BATCH_RMD(GENERATE_BATCH_RMD.out.bc_rmd, NORMALIZE_DB.out.normalized_db)

        normalized_db = NORMALIZE_DB.out.normalized_db
        bc_rmd = GENERATE_BATCH_RMD.out.bc_rmd
        bc_html = RENDER_BATCH_RMD.out.bc_html
        bc_tsv_reports = RENDER_BATCH_RMD.out.tsv_reports
}

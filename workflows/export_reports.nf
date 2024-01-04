
include { SKYLINE_EXPORT_REPORT as export_replicate_report } from "../modules/skyline.nf"
include { SKYLINE_EXPORT_REPORT as export_precursor_report } from "../modules/skyline.nf"
include { PANORAMA_GET_FILE as PANORAMA_GET_SKYLINE_DOC } from "../modules/panorama.nf"
include { PANORAMA_GET_FILE as PANORAMA_GET_METADATA } from "../modules/panorama.nf"

workflow export_reports {
    take:
        skyline_paths
        metadata_paths

    // emit:
    //     replicate_reports
    //     precursor_reports
    //     metadatas
    
    main:

        // collect skyline files
        skyline_paths.branch{
            panorama_files: it[1].startsWith("https://")
            local_files: true
                return [it[0], file(it[1], checkIfExists: true)]
            }.set{skyline_files}

        PANORAMA_GET_SKYLINE_DOC(skyline_files.panorama_files)
        skyline_docs = PANORAMA_GET_SKYLINE_DOC.out.concat(skyline_files.local_files)

        skyline_docs.view()
        
        // collect metadata files
        metadata_paths.branch{
            panorama_files: it[1].startsWith("https://")
            local_files: true
                return [it[0], file(it[1], checkIfExists: true)]
            }.set{metadata_files}

        PANORAMA_GET_METADATA(metadata_files.panorama_files)
        metadata = PANORAMA_GET_METADATA.out.concat(metadata_files.local_files)

        metadata.view()

        export_replicate_report(skyline_docs, params.replicate_report_template)
        // export_precursor_report(skyline_docs, params.precursor_report_template)

        // all_reports = export_replicate_report.out.join(export_precursor_report.out).join(metadata)
        // study_names = all_reports.map{ it[0] }
        // replicate_reports = all_reports.map{ it[1] }
        // precursor_reports = all_reports.map{ it[2] }
        // metadatas = all_reports.map{ it[3] }
}


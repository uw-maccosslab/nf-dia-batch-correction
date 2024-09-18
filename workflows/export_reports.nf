
include { SKYLINE_EXPORT_REPORTS } from "../modules/skyline.nf"
include { SKYLINE_EXPORT_ANNOTATIONS } from "../modules/skyline.nf"
include { UNZIP_SKY_FILE } from "../modules/skyline.nf"
include { PANORAMA_GET_FILE as PANORAMA_GET_SKYLINE_DOC } from "../modules/panorama.nf"
include { PANORAMA_GET_FILE as PANORAMA_GET_METADATA } from "../modules/panorama.nf"
include { PANORAMA_GET_FILE as PANORAMA_GET_PRECUSOR_SKYR } from "../nf-submodules/modules/panorama.nf"
include { PANORAMA_GET_FILE as PANORAMA_GET_REPLICATE_SKYR } from "../nf-submodules/modules/panorama.nf"

workflow export_reports {
    take:
        skyline_paths
        metadata_paths

    emit:
        study_names
        replicate_reports
        precursor_reports
        metadatas

    main:
        // get report templates
        if(params.replicate_report_template.startsWith("https://panoramaweb.org/_webdav")) {
            PANORAMA_GET_REPLICATE_SKYR(params.replicate_report_template)
            replicate_skyr = PANORAMA_GET_REPLICATE_SKYR.out.panorama_file
        } else {
            replicate_skyr = file(params.replicate_report_template, checkIfExists: true)
        }
        if(params.precursor_report_template.startsWith("https://panoramaweb.org/_webdav")) {
            PANORAMA_GET_PRECUSOR_SKYR(params.precursor_report_template)
            precursor_skyr = PANORAMA_GET_PRECUSOR_SKYR.out.panorama_file
        } else {
            precursor_skyr = file(params.precursor_report_template, checkIfExists: true)
        }

        // collect skyline files
        skyline_paths.branch{
            panorama_files: it[1].startsWith("https://")
            local_files: true
                return [it[0], file(it[1], checkIfExists: true)]
            }.set{skyline_files}

        PANORAMA_GET_SKYLINE_DOC(skyline_files.panorama_files)
        skyline_docs = PANORAMA_GET_SKYLINE_DOC.out.concat(skyline_files.local_files)

        UNZIP_SKY_FILE(skyline_docs)
        skyline_files = UNZIP_SKY_FILE.out.files

        // collect metadata files
        metadata_paths.branch{
            sky_metadata: it[1] == null
            panorama_files: it[1].startsWith("https://")
            local_files: true
                return [it[0], file(it[1], checkIfExists: true)]
            }.set{metadata_files}

        // export annotations from applicable skyline files
        metadata_files.sky_metadata.join(skyline_files).map{
            it -> tuple(it[0], it[2], it[3])
        } | SKYLINE_EXPORT_ANNOTATIONS

        PANORAMA_GET_METADATA(metadata_files.panorama_files)

        metadata = SKYLINE_EXPORT_ANNOTATIONS.out.concat(
            PANORAMA_GET_METADATA.out,
            metadata_files.local_files
        )

        SKYLINE_EXPORT_REPORTS(skyline_files, replicate_skyr, precursor_skyr)

        all_reports = SKYLINE_EXPORT_REPORTS.out.reports.join(metadata)

        study_names = all_reports.map{ it[0] }
        replicate_reports = all_reports.map{ it[1] }
        precursor_reports = all_reports.map{ it[2] }
        metadatas = all_reports.map{ it[3] }
}


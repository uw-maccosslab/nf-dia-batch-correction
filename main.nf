#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

// Sub workflows
include { export_reports } from "./workflows/export_reports.nf"
include { batch_correction } from "./workflows/batch_correction.nf"

include { GET_AWS_USER_ID } from "./modules/aws"
include { BUILD_AWS_SECRETS } from "./modules/aws"

workflow {

    // if accessing panoramaweb and running on aws, set up an aws secret
    if(workflow.profile == 'aws' && is_panorama_used) {
        GET_AWS_USER_ID()
        BUILD_AWS_SECRETS(GET_AWS_USER_ID.out)
        aws_secret_id = BUILD_AWS_SECRETS.out.aws_secret_id
    } else {
        aws_secret_id = Channel.of('none').collect()    // ensure this is a value channel
    }

    skyline_paths = Channel.fromList(params.documents.collect{k, v -> tuple(k, v['skyline'])})
    metadata_paths = Channel.fromList(params.documents.collect{
        k, v -> tuple(k, v.containsKey('metadata') ? v['metadata'] : null)
    })

    export_reports(skyline_paths, metadata_paths, aws_secret_id)

    batch_correction(export_reports.out.study_names, export_reports.out.metadatas,
                     export_reports.out.replicate_reports, export_reports.out.precursor_reports)
}

// return true if panoramaweb will be accessed by this Nextflow run
def is_panorama_used() {
    return params.documents.any{ it['skyline'].startsWith(params.panorama.domain) } ||
           params.documents.any{ it['metadata'] == null ? false : it['metadata'].startsWith(params.panorama.domain) } ||
           params.precursor_report_template.startsWith(params.panorama.domain) ||
           params.precursor_report_template.startsWith(params.panorama.donain)

}

#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

// Sub workflows
include { export_reports } from "./workflows/export_reports.nf"

// modules
include { MERGE_REPORTS } from "./modules/skyline"

workflow {

    skyline_paths = Channel.fromList(params.documents.collect{k, v -> tuple(k, v['skyline'])})
    metadata_paths = Channel.fromList(params.documents.collect{k, v -> tuple(k, v['metadata'])})

    export_reports(skyline_paths, metadata_paths) 
    
    // MERGE_REPORTS(study_names.collect(),
    //               replicate_reports.collect(),
    //               precursor_reports.collect(),
    //               metadatas.collect())
}

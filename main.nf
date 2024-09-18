#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

// Sub workflows
include { export_reports } from "./workflows/export_reports.nf"
include { batch_correction } from "./workflows/batch_correction.nf"

workflow {

    skyline_paths = Channel.fromList(params.documents.collect{k, v -> tuple(k, v['skyline'])})
    metadata_paths = Channel.fromList(params.documents.collect{
        k, v -> tuple(k, v.containsKey('metadata') ? v['metadata'] : null)
    })

    export_reports(skyline_paths, metadata_paths)

    batch_correction(export_reports.out.study_names, export_reports.out.metadatas,
                     export_reports.out.replicate_reports, export_reports.out.precursor_reports)
}

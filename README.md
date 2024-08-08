# nf-dia-batch-correction

This workflow performs normalization and batch correction on one or more Skyline documents.

## Workflow steps

1. Start from one or more Skyline documents stored locally or on PanoramaWeb
2. Exports precursor and replicate level `.tsv` reports from each document
3. Combine `.tsv` reports into a single `sqlite` batch database
4. Perform precursor median normalization and protein DirectLFQ normalization and store normalizaed values in batch database
5. Generate an Rmarkdown document which renders to a `.html` batch correction report

## How to run the workflow

```
nextflow run -r master uw-maccosslab/nf-dia-batch-correction -c pipeline.config
```

A template pipeline config is [here](https://raw.githubusercontent.com/uw-maccosslab/nf-dia-batch-correction/master/resources/pipeline.config). The required and optional parameters are described below.

## Replicate metadata format
Replicate metadata annotations can be given to specify variables to use in the batch correction report. The metadata files should be `.tsv` files where the first column has the header `Replicate` and additional columns for each metadata variable. The values in the `Replicate` column must match exactly the `mzML` or `raw` file names in the Skyline reports.

| Replicate | annotationKey1 | annotationKey2 | ... |
| --------- | -------------- | -------------- | ----|
| replicate1 | value | value | ... |
| replicate2 | value | value | ... |

## Workflow parameters 

| Parameter | Required | Type | Description |
| --------- | :----: | :----: | ----------- |
| `documents` | :white_check_mark: | `Map` | A nested `Map` of Skyline documents and metadata files with the following syntax: <pre>['<project_1>':<br>   ['skyline': '<path_to_skyline_doc>',<br>    'metadata': '<path_to_metadata_tsv>'] <br>['<project_2>':<br>   ['skyline': '<path_to_skyline_doc>',<br>    'metadata': '<path_to_metadata_tsv>'], <br>  ... ] </pre> There is a slot in the top level `Map` for each Skyline document. The key is a unique project name for the document. The sub-map should have at least 1 slot. The required slot has key `skyline` with the path to the Skyline document. Optionally, a second slot with the key `metadata` is the path to the replicate metadata annotations for the the document. If the `metadata` key is `null` or not included, the metadata annotations will be exported from the skyline document. File paths can be local file paths or Panorama WebDav urls. |
| `precursor_report_template` |  | `String` | Path to precursor quality report template. By default the report template in the [resources](https://github.com/uw-maccosslab/nf-dia-batch-correction/tree/master/resources) directory in the git repo is used. |
| `replicate_report_template` |  | `String` | Path to replicate quality report template. By default the report template in the [resources](https://github.com/uw-maccosslab/nf-dia-batch-correction/tree/master/resources) directory in the git repo is used. |
| `normalize_db.exclude_replicates` |  | `String`, `List` | Exclude replicate(s) from normalizaton and batch correction. If `null`, all replicates are included. Default is `null`. |
| `normalize_db.exclude_projects` |  | `String`, `List` | Exclude Skyline document(s) from normalizaton and batch correction. If `null`, all Skyline documents are included. Default is `null`. |
| `normalize_db.method` |  | `String` | Normalization method to use. Available options are `DirectLFQ` and `median`. Default is `DirectLFQ` |
| `bc.method` |  | `String` | Batch correction method. Either `combat` or `limma`. `combat` is the default. |
| `bc.batch1` |  | `String` | Metadata key for batch level 1. If `null`, the project name in `documents` is used as the batch variable. |
| `bc.batch2` |  | `String` | Metadata key for batch level 2. A second batch level is only supported with `limma` as the batch correction method. |
| `bc.color_vars` |  | `String`, `List` | Metadata key(s) used to color PCA plots. If `null`, batch and acquisition number are used to color plots. |
| `bc.covariate_vars` |  | `String`, `List` | Metadata key(s) to use as covariates for batch correction.  If `null`, no covariates are used. |
| `bc.control_key` |  | `String` | Metadata key indicating replicates which are controls for CV plots. If `null`, all replicates are used in CV distribution plot. |
| `bc.control_values` |  | `String` | Metadata value(s) mapping to `control_key` indicating whether a replicate is a control.
| `bc.plot_ext` |  | `String` | File extension for standalone plots. If `null`, no standalone plots are produced. |


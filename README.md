# nf-dia-batch-correction

This workflow performs normalization and batch correction on one or more Skyline documents.

## Workflow steps

1. Start from one or more Skyline documents stored locally or on PanoramaWeb
2. Exports precursor and replicate level `.tsv` reports from each document
3. Combine `.tsv` reports into a single `sqlite` batch database
4. Perform precursor median normalization and protein DirectLFQ normalization and store normalizaed values in batch database
5. Generate an Rmarkdown document which compiles to a batch correction report

# Replicate metadata format

Optional replicate annotations can be given to specify variabels to use in the batch correction report. The metadata files should be `.tsv` files where the first column has the header `Replicate` and additional columns for each metadata variable.

| Replicate | annotationKey1 | annotationKey2 | ... |
| --------- | -------------- | -------------- | ----|
| replicate1 | value | value | ... |
| replicate2 | value | value | ... |

# Workflow parameters 

| Parameter | Req? | Type | Description |
| --------- | ---- | ---- | ----------- |
| `documents` | :heavy_check_mark: | `Map` |  |
| `precursor_report_template` | :heavy_check_mark: | `String` | Precursor quality report template. |
| `replicate_report_template` | :heavy_check_mark: | `String` | Replicate quality report template. |
| `bc.method` |  | `String` | Batch correction method. Either `combat` or `limma`. `combat` is the default. |
| `bc.batch1` |  | `String` | Metadata key correction to batch level 1. If null, the project name in `documents` is used as the batch variable. |
| `bc.batch2` |  | `String` | Metadata key correction to batch level 1. A second batch level is only supported with `limma` as the batch correction method. |
| `bc.color_vars` |  | `String`, `List` | Metadata key(s) used to color PCA plots. If `null`, batch and acquisition number are used to color plots. |
| `bc.covariate_vars` |  | `String`, `List` | Metadata key(s) to use as covariates for batch correction.  If null, no covariates are used. |
| `bc.control_key` |  | `String` | Metadata key indicating replicates which are controls for CV plots. If null, all replicates are used in CV distribution plot. |
| `bc.control_values` |  | `String` | Metadata value(s) mapping to `control_key` indicating whether a replicate is a control.
| `plot_ext` |  | `String` | File extension for standalone plots. If null, no standalone plots are produced. |


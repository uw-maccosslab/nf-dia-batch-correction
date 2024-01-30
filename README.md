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

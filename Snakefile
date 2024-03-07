"""This file specifies the entire avian-flu pipeline that will be run, with
specific parameters for subsampling, tree building, and visualization. In this
build, you will generate 1 tree: an H5N1 tree for the HA genes. In this simple
build, clade annotation and cleavage site annotation have been removed. This
template should provide a reasonable starting place to customize your own build.
Simply edit and add components to this Snakefile."""

"""Replicates to assess reproducibility of subsampling. Using wildcards to
automatically repeat sampling steps."""
wildcard_constraints:
    replicate=".*"
REPLICATES = ["", "_alt1", "_alt2"]

"""This rule tells Snakemak that at the end of the pipeline, you should have
generated JSON files in the auspice folder for each subtype and segment."""
rule all:
    input:
        auspice_json = expand("auspice/epiworkshop_h5n1{replicate}.json", replicate=REPLICATES)

"""Specify all input files here. For this build, you'll start with input sequences
from the data folder, which contain metadata information in the
sequence header. Specify here files denoting specific strains to include or drop,
references sequences, and files for auspice visualization"""
rule files:
    params:
        input_sequences = "data/all_ha_seqs.fasta",
        metadata = "data/all_metadata.tsv",
        background_sequences = "data/background_ha_seqs.fasta",
        background_metadata = "data/background_metadata.tsv",
        dropped_strains = "config/dropped_strains_h5n1.txt",
        include_strains = "config/include_strains_h5n1.txt",
        reference = "config/reference_h5n1_ha.gb",
        auspice_config = "config/auspice_config_h5n1.json",
        colors = "config/colors.tsv",
        lat_longs = "config/lat_longs.tsv"


files = rules.files.params

"""Traits that should be inferred for reconstructed nodes."""
traits_columns = 'region'

"""Sampling info for samples of interest."""
group_by = 'region country'
sequences_per_group = '999'

"""Sampling scheme for background data."""
bg_group_by = 'region country month'
bg_sequences_per_group = '1'

"""Filter criteria."""
"""The minimum length required for sequences. Sequences shorter than these will be
subsampled out of the build."""
min_length = 1600

"""Sequences with sample collection dates earlier than these will be subsampled out of the build"""
min_date = '1990'

"""This rule specifies how to subsample the data for the region of interest"""
rule filter:
    message:
        """
        Filtering to
          - {params.sequences_per_group} sequence(s) per {params.group_by!s}
          - excluding strains in {input.exclude}
          - samples with missing region and country metadata
          - excluding strains prior to {params.min_date}
        """
    input:
        sequences = files.input_sequences,
        metadata = files.metadata,
        exclude = files.dropped_strains,
        include = files.include_strains
    output:
        sequences = "results/filtered_h5n1_ha{replicate}.fasta"
    params:
        group_by = group_by,
        sequences_per_group = sequences_per_group,
        min_date = min_date,
        min_length = min_length,
        exclude_where = "host=laboratoryderived host=ferret host=unknown host=other country=? region=?"

    shell:
        """
        augur filter \
            --sequences {input.sequences} \
            --metadata {input.metadata} \
            --exclude {input.exclude} \
            --include {input.include} \
            --output {output.sequences} \
            --group-by {params.group_by} \
            --sequences-per-group {params.sequences_per_group} \
            --min-date {params.min_date} \
            --exclude-where {params.exclude_where} \
            --min-length {params.min_length} \
            --non-nucleotide
        """

"""This rule filters and subsamples background datasets."""
rule filter_background:
    message:
        """
        Filtering background data to
          - {params.bg_sequences_per_group} sequence(s) per {params.bg_group_by!s}
          - excluding strains in {input.exclude}
          - samples with missing region and country metadata
          - excluding strains prior to {params.min_date}
        """
    input:
        bg_sequences = files.background_sequences,
        bg_metadata = files.background_metadata,
        exclude = files.dropped_strains,
        include = files.include_strains
    output:
        sequences = "results/filtered_bg_h5n1_ha{replicate}.fasta",
    params:
        bg_group_by = bg_group_by,
        bg_sequences_per_group = bg_sequences_per_group,
        min_date = min_date,
        min_length = min_length,
        exclude_where = "host=laboratoryderived host=ferret host=unknown host=other country=? region=?"

    shell:
        """
        augur filter \
            --sequences {input.bg_sequences} \
            --metadata {input.bg_metadata} \
            --exclude {input.exclude} \
            --include {input.include} \
            --output {output.sequences} \
            --group-by {params.bg_group_by} \
            --sequences-per-group {params.bg_sequences_per_group} \
            --min-date {params.min_date} \
            --exclude-where {params.exclude_where} \
            --min-length {params.min_length} \
            --non-nucleotide
        """

rule merge_metadata:
    message: "Merging metadata"
    input:
        metadata = files.metadata,
        background_metadata = files.background_metadata
    output:
        metadata = "results/merged_metadata_h5n1_ha.tsv"
    shell:
        """
        cat {input.metadata} {input.background_metadata} > {output.metadata}
        """

rule align:
    message:
        """
        Aligning sequences to {input.reference}
          - filling gaps with N
        """
    input:
        sequences = [rules.filter.output.sequences,
                     rules.filter_background.output.sequences],
        reference = files.reference
    output:
        alignment = "results/aligned_h5n1_ha{replicate}.fasta"
    shell:
        """
        augur align \
            --sequences {input.sequences} \
            --reference-sequence {input.reference} \
            --output {output.alignment} \
            --remove-reference \
            --nthreads 1
        """


rule tree:
    message: "Building tree"
    input:
        alignment = rules.align.output.alignment
    output:
        tree = "results/tree-raw_h5n1_ha{replicate}.nwk"
    params:
        method = "iqtree"
    shell:
        """
        augur tree \
            --alignment {input.alignment} \
            --output {output.tree} \
            --method {params.method} \
            --nthreads 1
        """

rule refine:
    message:
        """
        Refining tree
          - estimate timetree
          - use {params.coalescent} coalescent timescale
          - estimate {params.date_inference} node dates
        """
    input:
        tree = rules.tree.output.tree,
        alignment = rules.align.output,
        metadata = rules.merge_metadata.output.metadata
    output:
        tree = "results/tree_h5n1_ha{replicate}.nwk",
        node_data = "results/tree-branch-lengths_h5n1_ha{replicate}.json"
    params:
        coalescent = "const",
        date_inference = "marginal",
        clock_filter_iqd = 4
    shell:
        """
        augur refine \
            --tree {input.tree} \
            --alignment {input.alignment} \
            --metadata {input.metadata} \
            --output-tree {output.tree} \
            --output-node-data {output.node_data} \
            --timetree \
            --coalescent {params.coalescent} \
            --date-confidence \
            --date-inference {params.date_inference} \
            --clock-filter-iqd {params.clock_filter_iqd}
        """

rule ancestral:
    message: "Reconstructing ancestral sequences and mutations"
    input:
        tree = rules.refine.output.tree,
        alignment = rules.align.output
    output:
        node_data = "results/nt-muts_h5n1_ha{replicate}.json"
    params:
        inference = "joint"
    shell:
        """
        augur ancestral \
            --tree {input.tree} \
            --alignment {input.alignment} \
            --output-node-data {output.node_data} \
            --inference {params.inference}\
            --keep-ambiguous
        """

rule translate:
    message: "Translating amino acid sequences"
    input:
        tree = rules.refine.output.tree,
        node_data = rules.ancestral.output.node_data,
        reference = files.reference
    output:
        node_data = "results/aa-muts_h5n1_ha{replicate}.json"
    shell:
        """
        augur translate \
            --tree {input.tree} \
            --ancestral-sequences {input.node_data} \
            --reference-sequence {input.reference} \
            --output {output.node_data}
        """

rule traits:
    message: "Inferring ancestral traits for {params.columns!s}"
    input:
        tree = rules.refine.output.tree,
        metadata = rules.merge_metadata.output.metadata
    output:
        node_data = "results/traits_h5n1_ha{replicate}.json"
    params:
        columns = traits_columns,
    shell:
        """
        augur traits \
            --tree {input.tree} \
            --metadata {input.metadata} \
            --output {output.node_data} \
            --columns {params.columns} \
            --confidence
        """

"""This rule exports the results of the pipeline into JSON format, which is required
for visualization in auspice. To make changes to the categories of metadata
that are colored, or how the data is visualized, alter the auspice_config files"""
rule export:
    message: "Exporting data files for for auspice"
    input:
        tree = rules.refine.output.tree,
        metadata = rules.merge_metadata.output.metadata,
        node_data = [rules.refine.output.node_data,rules.traits.output.node_data,rules.ancestral.output.node_data,rules.translate.output.node_data],
        auspice_config = files.auspice_config,
        colors = files.colors,
        lat_longs = files.lat_longs
    output:
        auspice_json = "auspice/epiworkshop_h5n1{replicate}.json"
    shell:
        """
        augur export v2 \
            --tree {input.tree} \
            --metadata {input.metadata} \
            --node-data {input.node_data}\
            --auspice-config {input.auspice_config} \
            --colors {input.colors} \
            --lat-longs {input.lat_longs} \
            --output {output.auspice_json}
        """

rule clean:
    message: "Removing directories: {params}"
    params:
        "results ",
        "auspice"
    shell:
        "rm -rfv {params}"

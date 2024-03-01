"""This file specifies the entire avian-flu pipeline that will be run, with
specific parameters for subsampling, tree building, and visualization. In this
build, you will generate 1 tree: an H5N1 tree for the HA genes. In this simple
build, clade annotation and cleavage site annotation have been removed. This
template should provide a reasonable starting place to customize your own build.
Simply edit and add components to this Snakefile."""


"""Here, define your wildcards. To include more subtypes or gene segments, simply
add those to these lists, separated by commas"""
SUBTYPES = ["h5n1"]
SEGMENTS = ["ha"]

"""This rule tells Snakemak that at the end of the pipeline, you should have
generated JSON files in the auspice folder for each subtype and segment."""
rule all:
    input:
        auspice_json = expand("auspice/flu_avian_{subtype}_{segment}.json", subtype=SUBTYPES, segment=SEGMENTS)

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
        dropped_strains = "config/dropped_strains_{subtype}.txt",
        include_strains = "config/include_strains_{subtype}.txt",
        reference = "config/reference_{subtype}_{segment}.gb",
        auspice_config = "config/auspice_config_{subtype}.json"


files = rules.files.params


"""These functions allow for different rules for different wildcards. For example,
these groupby and sequences_per_group functions will result in h5n1 to be
subsampled down to 2 sequences per region, country, and month."""

def group_by(w):
    gb = {'h5n1': 'region country month'}
    return gb[w.subtype]

def sequences_per_group(w):
    spg = {'h5n1': '12'}
    return spg[w.subtype]

"""These variables set the sampling scheme for background data."""
bg_group_by = 'region country month'
bg_sequences_per_group = '1'

"""The minimum length required for sequences. Sequences shorter than these will be
subsampled out of the build. Here, we're requiring all segments to be basically
complete. To include partial genomes, shorten these to your desired length"""
def min_length(w):
    len_dict = {"ha":1600}
    length = len_dict[w.segment]
    return(length)

"""Sequences with sample collection dates earlier than these will be subsampled out of the build"""
def min_date(w):
    date = {'h5n1': '1990'}
    return date[w.subtype]

def traits_columns(w):
    traits = {'h5n1': 'region country'}
    return traits[w.subtype]

"""In this section of the Snakefile, rules are specified for each step of the pipeline.
Each rule has inputs, outputs, parameters, and the specific text for the commands in
bash. Rules reference each other, so altering one rule may require changing another
if they depend on each other for inputs and outputs. Notes are included for
specific rules."""


"""The parse rule is used to separate out sequences and metadata into 2 distinct
files. This rule assumes an input fasta file that contains metadata information
in the header. By specifying the order of those fields in the `fasta_fields` line,
`augur parse` will separate those fields into labeled columns in the output metadata
file."""
# rule parse:
#     message: "Parsing fasta into sequences and metadata"
#     input:
#         sequences = files.input_sequences
#     output:
#         sequences = "results/sequences_{subtype}_{segment}.fasta",
#     shell:
#         """
#         augur parse \
#             --sequences {input.sequences} \
#             --output-sequences {output.sequences} \
#         """

"""This rule specifies how to subsample data for the build, which is highly
customizable based on your desired tree."""
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
        sequences = "results/filtered_{subtype}_{segment}.fasta"
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
        sequences = "results/filtered_bg_{subtype}_{segment}.fasta"
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
        metadata = "results/merged_metadata_{subtype}_{segment}.tsv"
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
        alignment = "results/aligned_{subtype}_{segment}.fasta"
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
        tree = "results/tree-raw_{subtype}_{segment}.nwk"
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
        tree = "results/tree_{subtype}_{segment}.nwk",
        node_data = "results/branch-lengths_{subtype}_{segment}.json"
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
        node_data = "results/nt-muts_{subtype}_{segment}.json"
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
        node_data = "results/aa-muts_{subtype}_{segment}.json"
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
        node_data = "results/traits_{subtype}_{segment}.json",
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
        auspice_config = files.auspice_config
    output:
        auspice_json = "auspice/flu_avian_{subtype}_{segment}.json"
    shell:
        """
        augur export v2 \
            --tree {input.tree} \
            --metadata {input.metadata} \
            --node-data {input.node_data}\
            --auspice-config {input.auspice_config} \
            --include-root-sequence \
            --output {output.auspice_json}
        """

rule clean:
    message: "Removing directories: {params}"
    params:
        "results ",
        "auspice"
    shell:
        "rm -rfv {params}"

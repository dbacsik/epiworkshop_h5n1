# README
This data was downloaded manually from GISAID on 2024-02-26. All H5N1 HA seqeunces from North, South America, and Antarctica were downloaded from GISAID in FASTA format. Metadata was downloaded in XLS format.

The header for the original FASTA file from GISAID has the following format:
`Isolate name | Isolate ID |  Collection date | Originating lab |  Submitting lab`d

# Cleaning
Metadata is cleaned by (manually running) the Jupyter notebook `clean_metadata.py.ipynb`.
Sequences are cleaned by (manually running) the python script `sanitize_sequences.py`. Specifically, this must be run inside a Nextstrain shell using the following command:
```python3 sanitize_sequences.py --sequences southamerica_ha_seqs.fasta --output southamerica_ha_seqs_clean.fasta```

# Pruning
Manually removed strains labelled `A/Pelecanus/Peru/VFAR-140/2022` from metadata because they are duplicate in the dataset.

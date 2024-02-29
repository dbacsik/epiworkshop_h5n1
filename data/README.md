# README
This data was downloaded manually from GISAID on 2024-02-26. All H5N1 HA seqeunces from North, South America, and Antarctica were downloaded from GISAID in FASTA format. Metadata was downloaded in XLS format.

The header for the raw FASTA file from GISAID has the following format:
`Isolate name | Isolate ID |  Collection date | Originating lab |  Submitting lab`d

# Cleaning
Metadata is cleaned by (manually running) the Jupyter notebooks `clean_metadata.py.ipynb` in the `prep_data` directory.  
Sequences are cleaned by (manually running) the python script `sanitize_sequences.py` in the `prep_data` directory. Specifically, this must be run inside a Nextstrain shell using the following command:  
```python3 sanitize_sequences.py --sequences southamerica_ha_seqs.fasta --output southamerica_ha_seqs_clean.fasta```

# Concatentating
Metadata and sequences are concatenated manually into single file (each) by running the following commands:  
1. ```cat data/clean/southamerica_metadata_clean.tsv data/clean/antarctica_metadata_clean.tsv > data/all_metadata.tsv```  

2. ```cat data/clean/southamerica_ha_seqs_clean.fasta data/clean/antarctica_ha_seqs_clean.fasta > data/all_ha_seqs.fasta```


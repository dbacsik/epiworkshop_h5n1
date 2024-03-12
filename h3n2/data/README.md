# README
This data was downloaded manually from GISAID on 2024-03-08. All H3N2 HA sequences from 2018-06-01 to 2024-03-08 were downloaded from GISAID in FASTA format. Metadata was downloaded in XLS format.

The header for the raw FASTA file from GISAID has the following format:
`Isolate name`  

# Cleaning
Metadata is cleaned by (manually running) the Jupyter notebooks `clean_metadata.py.ipynb` in the `prep_data` directory.  

Sequences are first concatenated by country by running the following command:  
`cat data/raw/country*.fasta > data/raw/country_cat.fasta`

Then, sequences are cleaned by (manually running) the python script `clean_seqs.py` in the `prep_data` directory. **This script must be run inside a Nextstrain shell**. Use the following command format:  
```python3 clean_seqs.py --sequences southamerica_ha_seqs.fasta --output southamerica_ha_seqs_clean.fasta```

# Concatentating
Metadata and sequences are concatenated manually into single file for the region of interest and a single file for background data. The commands are as follows:

1. Metadata for region of interest  
```cat south_america_clean.tsv > roi.tsv```  

2. Sequences for region of interest  
```cat south_america_clean.fasta > roi.fasta```

<!-- 3. Metadata for background data  
```cat data/clean/northmerica_metadata_clean.tsv > data/background_metadata.tsv```  

4. Sequences for background data
```cat data/clean/northamerica_ha_seqs_clean.fasta > data/background_ha_seqs.fasta``` -->


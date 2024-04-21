# README
This data was downloaded manually from GISAID. All H3N2 HA sequences from 2018-06-01 to 2024-04-14 were downloaded from GISAID in FASTA format. Metadata was downloaded in XLS format.

The header for the raw FASTA file from GISAID has the following format:
`Isolate name`  

## Updating data source
Data was last downloaded from GISAID on April 13th, 2024. Latest data source includes sequences uploaded between 2024-03-08 and 2024-04-13.

## Cleaning
Metadata is cleaned by (manually running) the Jupyter notebooks `clean_metadata.py.ipynb` in the `prep_data` directory.  There is one file for the region of interest and one for all background regions.

To clean sequences, first, all ROI FASTA files are concatenated. Likewise, all background FASTA files are concatenated:  
`cat data/raw/roi/*.fasta > results/roi.fasta`  
`cat data/raw/background/*.fasta > results/background.fasta`

Then, sequences are cleaned using the `clean_seqs.py` script:  
`python data/clean_seqs.py --input results/roi.fasta --output clean_roi.fasta`  
`python data/clean_seqs.py --input results/background.fasta --output clean_background.fasta`
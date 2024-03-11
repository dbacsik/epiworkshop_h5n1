# %%
# Imports
from Bio import SeqIO
import argparse
import pandas as pd
import re
import sys

# Parse command line arguments
parser=argparse.ArgumentParser()

parser.add_argument("--input",
                    type=str,
                    required=True,
                    help="Input file in FASTA format")
parser.add_argument("--output",
                    type=str,
                    required=True,
                    help="Output path")

#args=parser.parse_args("--input h3n2/data/raw/south_america_Jun2018_Now.fasta --output tmp2.fasta".split())
args=parser.parse_args()
input_file = args.input
output_file = args.output

# Cleaning functions
def clean_strain_names(id):
    output_id = id.strip()
    output_id = re.sub(r'\s', '_', output_id)
    output_id = re.sub(r"'", '-', output_id)
    output_id = re.sub(r'ñ', 'n', output_id)
    output_id = re.sub(r'ã', 'a', output_id)
    return output_id

def deduplicate(df, column):
    output_df = df.drop_duplicates(subset=column, keep='first')
    return output_df

# IO Functions
def write_fasta(df, filename):
    with open(filename, "w") as output_handle:
        for index, row in df.iterrows():
            header = ">" + row["id"]
            sequence = row["seq"]
            output_handle.write(header + "\n")
            output_handle.write(sequence + "\n")

# Actions
## Open and clean strain names
print(f"Opening {input_file}\n\tCleaning strain names.")
records = list()
with open(input_file) as handle:
    for record in SeqIO.parse(handle, "fasta"):
        id = record.id.split("|")[0]
        id = clean_strain_names(id)
        seq = str(record.seq)
        records.append([id,seq])

print("\tDeduplicating.")
## Deduplicate
working_df = pd.DataFrame(records, columns=["id", "seq"])
output_df = deduplicate(working_df, "id")

## Print metrics
print(f"Originally, there were {len(working_df)} records.")
print(f"\tThere were {working_df['id'].nunique()} unique records.")
print(f"\tAfter cleaning, there were {len(output_df)} records remaining.")

## Output cleaned FASTA
print(f"Writing output FASTA file to {output_file}")
output_df.set_index(keys='id')
write_fasta(output_df, output_file)

# %%




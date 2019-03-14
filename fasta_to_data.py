import re
from Bio import SeqIO
from Bio.Blast import NCBIWWW
from Bio import SearchIO

blast_test = SeqIO.parse(open("TEST/TEST_BLAST.fasta"),"fasta")
for record in blast_test:
    print(record.id, len(record))

    result_handle = NCBIWWW.qblast("blastn","nr", record, hitlist_size=5, alignments=10, word_size=32, results_file="TEST/TEST_BLAST.fasta")

    blast_qresult = SearchIO.read(result_handle, "blast-xml")
    
    term_to_count = "plasmid"
    term_count = 0

    for hit in blast_qresult:
        if re.search(term_to_count, hit.description, re.IGNORECASE):
            term_count = term_count + 1

        genus = hit.description.split(" ")[0]
        species = hit.description.split(" ")[1]
        print("%s %s %s %i"  % (hit.accession, genus, species, hit.seq_len))
        print(hit.description)
    print("TERM:%s found %i times" % (term_to_count, term_count))
print("\n\n")
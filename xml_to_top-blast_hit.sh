#!/bin/sh
#process xml blast results into top blast hit
#run from within directory where blast xml file is stored
#usage bash xml_to_top-blast.sh PATH/TO/BLAST-RESULTS.XML PATH/TO/NCBI/TAXONOMY/DIRECTORY ABS/PATH/TO/ENTREZ_QIIME.PY/DIRECTORY


cat $1 | grep -A5 "  <Iteration_query-def>" | grep -v "  <Iteration_query-len>" | grep -v "^<Iteration_hits>\|^<Hit>" | grep -n -B1 "^</Iteration_hits>" | grep "<Iteration_query-def>" | cut -d ">" -f 2 | cut -d "<" -f 1 | cut -d " " -f 1 > no_hit_otus
grep "  <Iteration_query-def>" $1 | cut -d ">" -f2 | cut -d " " -f1 > ALL_OTUIDs
grep -v -Fwf no_hit_otus ALL_OTUIDs > OTUIDs
rm ALL_OTUIDs
grep -A2 "<Hit_num>1</Hit_num>" $1 | grep -v "<Hit_num>1</Hit_num>" | grep "  <Hit_id>" | cut -d ">" -f2 | cut -d "<" -f1 | cut -d "|" -f2 > GIs
grep -A2 "<Hit_num>1</Hit_num>" $1 | grep -v "<Hit_num>1</Hit_num>" | grep "  <Hit_id>" | cut -d ">" -f2 | cut -d "<" -f1 | cut -d "|" -f4 > accession_list
grep -A2 "<Hit_num>1</Hit_num>" $1 | grep -v "<Hit_num>1</Hit_num>" | grep "  <Hit_def>" | sed 's/  <Hit_def>//' > GB_Names

python $3/entrez_qiime.py -L $PWD/accession_list -n $2 -r kingdom,phylum,class,order,family,genus,species -a $2nucl_gb.accession2taxid -o $PWD/$1_accession_to_tax_lineage.txt

#add QIIME format labels to each taxonomy level
cat $PWD/$1_accession_to_tax_lineage.txt | sed 's/\t/\tk__/' | sed 's/;/+/'| sed 's/;/+/'| sed 's/;/+/'| sed 's/;/+/'| sed 's/;/+/'| sed 's/;/;s__/'| sed 's/+/;p__/'|sed 's/+/;c__/'| sed 's/+/;o__/'| sed 's/+/;f__/'| sed 's/+/;g__/' > $PWD/$1_accession_to_ncbi_lineage.txt

paste <(grep -v -Fwf otus_with_no_hits query_names) top_blast_hits > otu_to_top_blast

echo -e "OTU_ID\tNCBI_ACCESSION\tNCBI_LINEAGE" > otu_to_ncbi_lineage.tsv
paste OTUIDs <(while read ID; do grep $ID $1_accession_to_ncbi_lineage.txt; done < accession_list) >> otu_to_ncbi_lineage.tsv

#cleanup intermediate files
mv accession_list.log entrez_qiime.log
#rm blast_no_uncultured_or_unknown.txt accession_list $1_accession_to_tax_lineage.txt query_names top_blast_hits $1_accession_to_ncbi_lineage.txt otus_with_no_hits sequential_hits


echo "Process complete.  Check ERRORS.txt for OTUs that were not assigned a blast hit."
echo "Main output file is otu_to_ncbi_lineage.tsv - A tab-separated file listing OTU_ID, NCBI_ACCESSION for top blast hit, and NCBI_LINEAGE in QIIME-compatible format"



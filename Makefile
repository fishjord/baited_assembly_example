IN_SEQ_FILES=/scratch/fishjord/user_files/russell/analysis/../D0EAEACXX_s6_1_2074-MB_002_SL29256.fastq.clean.fastq.final.fastq /scratch/fishjord/user_files/russell/analysis/../D0EAEACXX_s6_2_2074-MB_002_SL29256.fastq.clean.fastq.final.fastq
IN_REF_FILES=/scratch/fishjord/user_files/russell/analysis/../Spsittacina-for-capture5.fasta /scratch/fishjord/user_files/russell/analysis/../Spurpurea-for-capture5.fasta

BOWTIE=/scratch/fishjord/apps/bowtie2-2.1.0/bowtie2
SAMTOOLS=/opt/local/bin/samtools

NAME= capture
K_SIZE= 60
FILTER_SIZE= 34 # 2**FILTER_SIZE, 38 = 32 gigs, 37 = 16 gigs, 36 = 8 gigs, 35 = 4 gigs

## Filtering Params
MIN_LENGTH= 150  # in nucleotides
MIN_MEDIAN_COV= 3 
MIN_MAPPED_RATIO= 1 #Ratio of the contig that must have reads mapped to it

######################################################################################

SEQFILE= $(NAME)_reads.fasta
REFFILE= $(NAME)_refs.fasta
JAR_DIR=$(realpath jars)
GLOWING_SAKANA=$(realpath glowing_sakana)
ASSEMBLY_FILE= $(NAME)_baited_assembly.fasta
BWT_PREFIX= $(NAME)_bwt

all: $(ASSEMBLY_FILE) $(NAME)_mapping_coverage.txt $(NAME)_final_seqs.fasta

.PHONY: $(genes) clean bloom bowtie_build

bloom: $(NAME).bloom

$(NAME).bloom: $(SEQFILE)
	java -Xmx4g -jar $(JAR_DIR)/hmmgs.jar build $(SEQFILE) $(NAME).bloom $(K_SIZE) $(FILTER_SIZE)

$(NAME)_baited_assembly.fasta: $(NAME).bloom $(REFFILE)
	java -Xmx4g -cp $(JAR_DIR)/hmmgs.jar edu.msu.cme.rdp.graph.sandbox.BaitedAssembly $(NAME).bloom $(REFFILE) > $(ASSEMBLY_FILE) 2> $(NAME)_baited_assembly.txt

$(SEQFILE): $(IN_SEQ_FILES)
	java -Xmx2g -jar $(JAR_DIR)/ReadSeq.jar $(IN_SEQ_FILES) > $(SEQFILE)

$(REFFILE): $(IN_REF_FILES)
	java -Xmx2g -jar $(JAR_DIR)/ReadSeq.jar $(IN_REF_FILES) > $(REFFILE)

bowtie_build: $(BWT_PREFIX).1.bt2

$(BWT_PREFIX).1.bt2: $(ASSEMBLY_FILE)
	$(BOWTIE)-build $(ASSEMBLY_FILE) $(BWT_PREFIX)

$(NAME)_mapped_reads.bam: $(BWT_PREFIX).1.bt2
	$(BOWTIE) -f -x $(BWT_PREFIX) -U $(SEQFILE) | $(SAMTOOLS) view -S -F4 -b - > $(NAME)_mapped_reads.bam

$(NAME)_sorted_hits.bam: $(NAME)_mapped_reads.bam
	$(SAMTOOLS) sort $(NAME)_mapped_reads.bam $(NAME)_sorted_hits

$(NAME)_mapping_coverage_details.txt: $(NAME)_sorted_hits.bam
	$(SAMTOOLS) mpileup $(NAME)_sorted_hits.bam > $(NAME)_mapping_coverage_details.txt

$(NAME)_mapping_coverage.txt: $(NAME)_mapping_coverage_details.txt $(ASSEMBLY_FILE)
	$(GLOWING_SAKANA)/misc/mpileup_ref_coverage.py --min-mapped-ratio $(MIN_MAPPED_RATIO) --min-median-cov $(MIN_MEDIAN_COV) --min-length $(MIN_LENGTH) $(NAME)_mapping_coverage_details.txt $(ASSEMBLY_FILE) > $(NAME)_mapping_coverage.txt

$(NAME)_final_seqs.fasta: $(NAME)_mapping_coverage.txt $(ASSEMBLY_FILE)
	cut -f1 $(NAME)_mapping_coverage.txt | grep -v '#' > final_seqids.tmp && $(GLOWING_SAKANA)/seq_utils/find_seqs.py final_seqids.tmp keep $(ASSEMBLY_FILE) > $(NAME)_final_seqs.fasta && rm final_seqids.tmp

clean:
	rm $(NAME)*

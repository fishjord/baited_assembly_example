An example baited assembly pipeline using De Bruijn Graphs.

Required Software
==================
* samtools
* bowtie2
* biopython
* numpy 

Quick Start
============
0. git clone https://github.com/fishjord/baited_assembly_example
1. cd baited_assembly_example
2. git submodule init && git submodule update
3. Edit make file variables
  * _MUST CHANGE_
    * IN_SEQ_FILES to point to the reads (more than one file is fine)
    * IN_REF_FILES to point to the baits (more than one file is fine)
    * BOWTIE to point to the bowtie2 executable
    * SAMTOOLS to point to the samtools executable
  * Can Change
    * NAME - used to prefix some files
    * K_SIZE - Kmer size to assemble at
    * FILTER_SIZE - How much space the bloom filter will occupy
4. make

Workflow Outline
=================
0. Prep seq files (quality trimming, combine references in to a single file)
1. Build De Bruijn Graph (in a bloom filter)
2. Using bait sequences, assemble from the last kmer in the bait present in the bloom filter
3. Map reads back to the assemblies
4. Filter assemblies based on coverage

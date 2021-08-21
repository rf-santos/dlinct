#!/bin/bash

workdir=$1
sra=$2
appdir=$3

cd $workdir

### Assemble transcriptome from mapped reads for each sample ###
mkdir assemblies &> /dev/null
while read i
do
   echo ----- TRANSCRIPTOME ASSEMBLY OF $i -----
   stringtie $workdir/data/$i/$i'.sorted.bam' -G $appdir/genome/genome.gtf -o $workdir/assemblies/$i'.rna.gtf' 2> $workdir/assemblies/stringtie.outtxt 1> /dev/null
   echo 'Done'
done < $sra

### Merge all generated .gtf files into a single non-redundant .gtf file ###
echo ----- MERGING TRANSCRIPTOME -----
cd assemblies

### POSSIBLE ERROR ON $workdir VAR
ls | grep '.rna.gtf$' | perl -ne 'print "$workdir$_"' > gtf-to-merge.txt
stringtie --merge $workdir/assemblies/gtf-to-merge.txt -G $appdir/genome/genome.gtf -o $workdir/assemblies/merged.gtf 2> stringtie-merge.outtxt 1> /dev/null
echo 'Done'

## Clean-up
rm -rf gtf-to-merge.txt
rm -rf *.rna.gtf

cd ..

echo ----- COMPARING ASSEMBLY TO REFERENCE -----
mkdir cuffcompare &> /dev/null
### Compare the merged assembly to the reference .gtf ###
cuffcompare -R -r $appdir/genome/genome.gtf $workdir/assemblies/merged.gtf -o $workdir/cuffcompare/cuffcomp.gtf 2> $workdir/cuffcompare/cuffcomp.outtxt 1> /dev/null
echo 'Done'

### Extract transcript sequences from the assembled transcriptome ###
gffread -w $workdir/assemblies/assembled-transcripts.fa -g $appdir/genome/genome.fa $workdir/assemblies/merged.gtf 2> $workdir/assemblies/gffread.outtxt 1> /dev/null

### CPAT analysis (coding probability assessment tool) ###
mkdir cpat &> /dev/nul
cd cpat
## Get Dmel CPAT files
# logitModel
wget -q https://sourceforge.net/projects/rna-cpat/files/v1.2.2/prebuilt_model/Fly_logitModel.RData/download -O Fly_logitModel.RData
# hexamer.tsv
wget -q https://sourceforge.net/projects/rna-cpat/files/v1.2.2/prebuilt_model/fly_Hexamer.tsv/download -O fly_Hexamer.tsv
# fly_cutoff - probability cpat values below this cutoff are considered non-coding
wget -q https://sourceforge.net/projects/rna-cpat/files/v1.2.2/prebuilt_model/fly_cutoff.txt/download -O fly_cutoff.txt

## Run CPAT - Minimum ORF size = 25; Top ORFs to retain =1 
cpat.py --verbose false -x $workdir/cpat/fly_Hexamer.tsv -d $workdir/cpat/Fly_logitModel.RData -g $workdir/assemblies/assembled-transcripts.fa -o $workdir/cpat/cpat --min-orf 25 --top-orf 1 2> cpat.outtxt 1> /dev/null
echo 'Done'
echo 'Assembly and coding probability done'
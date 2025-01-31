#!/usr/bin/env bash

## COLORS ##
BOLD='\033[1m'
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
PURPLE='\033[1;35m'
NC='\033[0m'

## VARIABLES ##
workdir=$1

mkdir -p $workdir
touch "$workdir"/run.log

sra=$2
threads=$3
appdir=$4
metadata=$5
if [[ $metadata == 'None' ]]; then
  unset metadata
fi
paired=$6

if [[ -z $paired ]]; then
  echo -e "!!!WARNING!!! Read layout is unset by user, this is required if providing .fastq.gz files instead of SRA accessions" >> $workdir/run.log
  jobs=$(cat $sra | wc -l)
  fastq=0
else
  fastq=1
  if [[ $paired == 'True' || $paired == 'TRUE' || $paired == 'true' || $paired == 1 ]]; then
    layout=PAIRED
    fq_files=$(ls $sra/*_1.fastq.gz)
    jobs=$(ls $sra/*_1.fastq.gz | wc -l)
  elif [[ $paired == 'False' || $paired == 'FALSE' || $paired == 'false' || $paired == 0 ]]; then
    fq_files=$(ls $sra/*.fastq.gz )
    layout=SINGLE
    jobs=$(ls $sra/*.fastq.gz | wc -l)
  else
    echo "Paresed argument for -p/--paired is invalid. Please choose <True>/<False>"
    exit 2
  fi
fi

if [[ -z ${bed+x} ]]; then
  bed=$workdir/results/new-non-coding.chr.bed
  USER_PREDICT=0
else
  bed=$(readlink -f $7) &>> $workdir/run.log
  USER_PREDICT=1
  PIPE_STEP=7
fi

#genome=$(readlink -f $8)
#annot=$(readlink -f $9)

## ANIMATED OUTPUT ##
# Load in the functions and animations
source "$appdir"/scripts/anime.sh
# Run BLA::stop_loading_animation if the script is interrupted
trap BLA::stop_loading_animation SIGINT

# BLA::start_loading_animation "${BLA_braille_whitespace[@]}"
# BLA::stop_loading_animation

## PREPARE CONDA ##
conda_path=$(conda info | grep -i 'base environment' | awk '{print$(4)}')
conda_sh=$conda_path'/etc/profile.d/conda.sh'

source $conda_sh
conda init $(echo $SHELL | awk -F'[/]' '{print$(NF)}') &> $appdir/cmd.out

function clean_up {

    # Perform program exit housekeeping
    # kill $(ps -s $$ -o pid=)
    pkill -P $$
    exit 2
}

export -f clean_up

trap clean_up SIGHUP SIGINT SIGTERM

## DEFINE THREADS FOR RUUNING PIPELINE ##
conda activate mapMod
echo 'Threads available: ' $threads &>> $workdir/run.log
echo 'Number of samples for this run: ' $jobs &>> $workdir/run.log
if [[ $threads -ge $jobs ]]; then
  downstream_threads=$(bc -l <<< 'scale=2; '$threads'/'$jobs'')
  downstream_threads=${downstream_threads%.*}
else
  jobs=$threads
  downstream_threads=1
fi
echo 'Number of threads per running sample: ' $downstream_threads &>> $workdir/run.log
conda deactivate

## INITIATE PIPELINE ##
PIPE_STEP=1
BLA::start_loading_animation "${BLA_braille_whitespace[@]}"
while true;
do
  if [[ PIPE_STEP -eq 0 ]]; then
    BLA::stop_loading_animation
    echo -e "\r\e[10A\e[K[🦟] ${BOLD}${PURPLE}FLYNC is processing your samples:${NC}
${GREEN}[🧬] Preparing reference genome files${NC}
${GREEN}[📑] Gathering sample information from SRA database {flync sra}${NC}
${GREEN}[🧩] Mapping samples to reference genome${NC}
${GREEN}[🧱] Building transcriptomes${NC}
${GREEN}[🎲] Calculating conding probability of new transcripts${NC}
${GREEN}[📈] Differential transcript expressions analysis (if -m)${NC}
${GREEN}[📡] Extracting candidate features from databases${NC}
${GREEN}[🧠] Predicting non-coding gene probability${NC}"
    echo -e "${YELLOW}Program terminated. If you ran into any errors check${NC} run.log ${YELLOW}on the output directory${NC}"
    break
  elif [[ PIPE_STEP -eq 1 ]]; then
    echo -e "\r[🦟] ${BOLD}${PURPLE}FLYNC is processing your samples:${NC}
${CYAN}[-] Preparing reference genome files${NC}
${CYAN}[ ] Gathering sample information from SRA database {flync sra}${NC}
${CYAN}[ ] Mapping samples to reference genome${NC}
${CYAN}[ ] Building transcriptomes${NC}
${CYAN}[ ] Calculating conding probability of new transcripts${NC}
${CYAN}[ ] Differential transcript expressions analysis (if -m)${NC}
${CYAN}[ ] Extracting candidate features from databases${NC}
${CYAN}[ ] Predicting non-coding gene probability${NC}"
  elif [[ PIPE_STEP -eq 2 ]]; then
    echo -e "\r\e[9A\e[K[🦟] ${BOLD}${PURPLE}FLYNC is processing your samples:${NC}
${GREEN}[🧬] Preparing reference genome files${NC}
${CYAN}[-] Gathering sample information from SRA database {flync sra}${NC}
${CYAN}[ ] Mapping samples to reference genome${NC}
${CYAN}[ ] Building transcriptomes${NC}
${CYAN}[ ] Calculating conding probability of new transcripts${NC}
${CYAN}[ ] Differential transcript expressions analysis (if -m)${NC}
${CYAN}[ ] Extracting candidate features from databases${NC}
${CYAN}[ ] Predicting non-coding gene probability${NC}"
  elif [[ PIPE_STEP -eq 3 ]]; then
    echo -e "\r\e[9A\e[K[🦟] ${BOLD}${PURPLE}FLYNC is processing your samples:${NC}
${GREEN}[🧬] Preparing reference genome files${NC}
${GREEN}[📑] Gathering sample information from SRA database {flync sra}${NC}
${CYAN}[-] Mapping samples to reference genome${NC}
${CYAN}[ ] Building transcriptomes${NC}
${CYAN}[ ] Calculating conding probability of new transcripts${NC}
${CYAN}[ ] Differential transcript expressions analysis (if -m)${NC}
${CYAN}[ ] Extracting candidate features from databases${NC}
${CYAN}[ ] Predicting non-coding gene probability${NC}"
  elif [[ PIPE_STEP -eq 4 ]]; then
    echo -e "\r\e[9A\e[K[🦟] ${BOLD}${PURPLE}FLYNC is processing your samples:${NC}
${GREEN}[🧬] Preparing reference genome files${NC}
${GREEN}[📑] Gathering sample information from SRA database {flync sra}${NC}
${GREEN}[🧩] Mapping samples to reference genome${NC}
${CYAN}[-] Building transcriptomes${NC}
${CYAN}[ ] Calculating conding probability of new transcripts${NC}
${CYAN}[ ] Differential transcript expressions analysis (if -m)${NC}
${CYAN}[ ] Extracting candidate features from databases${NC}
${CYAN}[ ] Predicting non-coding gene probability${NC}"
  elif [[ PIPE_STEP -eq 5 ]]; then
    echo -e "\r\e[9A\e[K[🦟] ${BOLD}${PURPLE}FLYNC is processing your samples:${NC}
${GREEN}[🧬] Preparing reference genome files${NC}
${GREEN}[📑] Gathering sample information from SRA database {flync sra}${NC}
${GREEN}[🧩] Mapping samples to reference genome${NC}
${GREEN}[🧱] Building transcriptomes${NC}
${CYAN}[-] Calculating conding probability of new transcripts${NC}
${CYAN}[ ] Differential transcript expressions analysis (if -m)${NC}
${CYAN}[ ] Extracting candidate features from databases${NC}
${CYAN}[ ] Predicting non-coding gene probability${NC}"
  elif [[ PIPE_STEP -eq 6 ]]; then
    echo -e "\r\e[9A\e[K[🦟] ${BOLD}${PURPLE}FLYNC is processing your samples:${NC}
${GREEN}[🧬] Preparing reference genome files${NC}
${GREEN}[📑] Gathering sample information from SRA database {flync sra}${NC}
${GREEN}[🧩] Mapping samples to reference genome${NC}
${GREEN}[🧱] Building transcriptomes${NC}
${GREEN}[🎲] Calculating conding probability of new transcripts${NC}
${CYAN}[-] Differential transcript expressions analysis (if -m)${NC}
${CYAN}[ ] Extracting candidate features from databases${NC}
${CYAN}[ ] Predicting non-coding gene probability${NC}"
  elif [[ PIPE_STEP -eq 7 ]]; then
    echo -e "\r\e[9A\e[K[🦟] ${BOLD}${PURPLE}FLYNC is processing your samples:${NC}
${GREEN}[🧬] Preparing reference genome files${NC}
${GREEN}[📑] Gathering sample information from SRA database {flync sra}${NC}
${GREEN}[🧩] Mapping samples to reference genome${NC}
${GREEN}[🧱] Building transcriptomes${NC}
${GREEN}[🎲] Calculating conding probability of new transcripts${NC}
${GREEN}[📈] Differential transcript expressions analysis (if -m)${NC}
${CYAN}[-] Extracting candidate features from databases${NC}
${CYAN}[ ] Predicting non-coding gene probability${NC}"
  elif [[ PIPE_STEP -eq 8 ]]; then
    echo -e "\r\e[9A\e[K[🦟] ${BOLD}${PURPLE}FLYNC is processing your samples:${NC}
${GREEN}[🧬] Preparing reference genome files${NC}
${GREEN}[📑] Gathering sample information from SRA database {flync sra}${NC}
${GREEN}[🧩] Mapping samples to reference genome${NC}
${GREEN}[🧱] Building transcriptomes${NC}
${GREEN}[🎲] Calculating conding probability of new transcripts${NC}
${GREEN}[📈] Differential transcript expressions analysis (if -m)${NC}
${GREEN}[📡] Extracting candidate features from databases${NC}
${CYAN}[ ] Predicting non-coding gene probability${NC}"
  fi

  case $PIPE_STEP in
    exit) break ;;
    1)
      ## RUN SCRIPTS FOR GETTING GENOME AND INFO ON SRA RUNS
      conda activate infoMod &>> $workdir/run.log

      ## VALIDATE LINKS ##
      python3 $appdir/scripts/check-links.py &>> $workdir/run.log
      if [[ $? -eq 1 ]]; then
        echo -e "${RED}ERROR${NC}: Some links are broken. Please check the run.log file for more information"
        exit 1
      fi
      
      ## SILENCE PARALLEL FIRST RUN ##
      parallel --citation &> $appdir/cmd.out
      echo will cite &> $appdir/cmd.out
      rm $appdir/cmd.out

      mkdir -p $appdir/genome &>> $workdir/run.log
      $appdir/scripts/get-genome.sh $appdir &>> $workdir/run.log
      PIPE_STEP=2
      ;;
    2)
      mkdir -p $workdir/results
      if [[ $fastq == 0 ]]; then
        $appdir/scripts/get-sra-info.sh $workdir $sra &>> $workdir/run.log
      fi
      PIPE_STEP=3
      conda deactivate
      ;;
    3)
      conda activate mapMod &>> $workdir/run.log
      $appdir/scripts/build-index.sh $appdir $threads &>> $workdir/run.log

      if [[ $fastq == 1 ]]; then
        printf "%s\n" "${fq_files[@]}" > fq_files.txt
        parallel -k --lb -j $jobs -a $appdir/fq_files.txt $appdir/scripts/tux2map-fq.sh $workdir {} $downstream_threads $appdir $layout &>> $workdir/run.log
      else
        parallel -k --lb -j $jobs -a $sra $appdir/scripts/tux2map.sh $workdir {} $downstream_threads $appdir &>> $workdir/run.log
      fi
      PIPE_STEP=4
      conda deactivate
      ;;
    4)
      conda activate assembleMod &>> $workdir/run.log
      if [[ $fastq == 1 ]]; then
        parallel -k --lb -j $jobs -a fq_files.txt $appdir/scripts/tux2assemble.sh $workdir {} $downstream_threads $appdir &>> $workdir/run.log
        $appdir/scripts/tux2merge.sh $workdir fq_files.txt $threads $appdir &>> $workdir/run.log
        parallel -k --lb -j $jobs -a fq_files.txt $appdir/scripts/tux2count.sh $workdir {} &>> $workdir/run.log
      else
        parallel -k --lb -j $jobs -a $sra $appdir/scripts/tux2assemble.sh $workdir {} $downstream_threads $appdir &>> $workdir/run.log
        $appdir/scripts/tux2merge.sh $workdir $sra $threads $appdir &>> $workdir/run.log
        parallel -k --lb -j $jobs -a $sra $appdir/scripts/tux2count.sh $workdir {} &>> $workdir/run.log
      fi
      
      cd $workdir
      ls -d ${PWD}/cov/*/ | sort -V >> $workdir/cov/ballgown_paths.txt
      PIPE_STEP=5
      conda deactivate
      ;;
    5)
      conda activate codMod &>> $workdir/run.log
      $appdir/scripts/coding-prob.sh $workdir $appdir $threads &>> $workdir/run.log
      $appdir/scripts/class-new-transfrags.sh $workdir $threads $appdir &>> $workdir/run.log
      PIPE_STEP=6
      conda deactivate
      ;;
    6)
      conda activate dgeMod
      # ballgown for dge analysis
      if [[ -z ${metadata+x} ]]; then
          echo "Skipping DGE since no metadata file was provided..." &>> $workdir/run.log
      else
          Rscript $appdir/scripts/ballgown.R $(readlink -f $workdir) $(readlink -f $metadata) &>> $workdir/run.log
      fi

      PIPE_STEP=7
      conda deactivate
      ;;
    7)
      conda activate infoMod
      mkdir -p $workdir/results
      cd $workdir/results
      $appdir/scripts/gtf-to-bed.sh new-non-coding.gtf &>> $workdir/run.log
      conda deactivate

      cd $workdir
      conda activate mapMod
      
      mkdir -p $workdir/results/non-coding/features
      
      # Got 24% faster by parallelizing the get-features.sh script
      jobs2=$(cat $appdir/static/tracksFile.tsv | wc -l)
      downstream_threads=$(bc -l <<< 'scale=2; '$threads'/'$jobs2'')
      downstream_threads=${downstream_threads%.*}
      if [[ $downstream_threads < 1 ]]; then
        downstream_threads=1
      fi
      
      conda deactivate

      conda activate featureMod

      find $appdir -type f \( -name "*.bw" -o -name "*.bb" \) > $appdir/static/localTracks.txt

      if [[ $(cat $appdir/static/localTracks.txt | wc -l) -gt 0 ]]; then
        
        while read -r line; do
          track=$(basename $line | awk -F'[.]' '{print$1}') &>> $workdir/run.log
          echo -e "${track}\t${line}" >> $appdir/static/localTracks.tsv
        done < $appdir/static/localTracks.txt

        if [[ $(cat $appdir/static/localTracks.tsv | wc -l) -eq $(cat $appdir/static/localTracks.txt | wc -l) ]]; then
          rm $appdir/static/localTracks.txt &>> $workdir/run.log
          parallel --no-notice -k --lb -j $jobs2 -a $appdir/static/localTracks.tsv $appdir/scripts/get-features.sh {} $bed $workdir/results/non-coding $downstream_threads &>> $workdir/run.log
          rm $appdir/static/localTracks.tsv &>> $workdir/run.log
        else
          parallel --no-notice -k --lb -j $jobs2 -a $appdir/static/tracksFile.tsv $appdir/scripts/get-features.sh {} $bed $workdir/results/non-coding $downstream_threads &>> $workdir/run.log
          rm $appdir/static/localTracks.tsv &>> $workdir/run.log
        fi

      fi

      # Write a .csv file with the filepaths for the tables to be processed in python Pandas
      ls $workdir/results/non-coding/features | grep tsv | sed 's/.tsv//g' > names.tmp
      find $workdir/results/non-coding/features/*.tsv > path.tmp
      paste -d, names.tmp path.tmp > $workdir/results/non-coding/features/paths.csv
      rm names.tmp path.tmp &>> $workdir/run.log

      if [[ $fastq == 1 ]]; then
        rm $appdir/fq_files.txt
      fi

      conda deactivate
      PIPE_STEP=8
      ;;
    8)
      conda activate predictMod

      python3 $appdir/scripts/feature-table.py $appdir $workdir $bed &>> $workdir/run.log

      if [[ $USER_PREDICT = 0 ]]; then
        python3 $appdir/scripts/predict.py $appdir $workdir &>> $workdir/run.log
        python3 $appdir/scripts/final-table.py $appdir $workdir $bed &>> $workdir/run.log
      else
        python3 $appdir/scripts/predict.py $appdir $workdir "$(basename $bed | awk -F'[.]' '{print$1}')" &>> $workdir/run.log
      fi
      
      PIPE_STEP=0
      ;;
  esac
done

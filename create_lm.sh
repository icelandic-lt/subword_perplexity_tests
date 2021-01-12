#!/bin/bash 

set -o pipefail 

if [ $# -ne 2 ]; then
  echo "Usage: create_lm.sh <number of merges> <lang name>"
  echo "e.g.: create_lm.sh 1000 bpe_1000_test"
  exit 1;
fi

echo "`date`"
start=`date +%s`

# A parameter used to dicripe the current 
# test e.g. bpe1000 meaning bpe with 1000 merges.
lang=$1

# Language model order
order=$2

stage=0


if [ $stage -le 0 ]; then
  echo "=== Building a language model with KenLM"
  module load kenlm

  lmplz --skip_symbols \
        -o $order \
        -S 70% \
        -T /tmp \
        --prune 0 0 0 1 5 10\
        --discount_fallback 1 \
        --text $lang/rmh_training \
        --arpa $lang/kenlm_${order}g.arpa || error 1 "lmplz failed"
        
  build_binary $lang/kenlm_${order}g.arpa $lang/kenlm_${order}g.binary || error 1 "build_binary failed"

fi

building_lm=`date +%s`
runtime="Creating LM took $((building_lm-applying_time)) sek"
echo $runtime
echo "Total runtime is $((building_lm-start)) sek"

if [ $stage -le 3 ]; then
  echo "=== Calculating perplexity"
  module load kenlm
  
  query -v summary $lang/kenlm_${order}g.binary < $lang/rmh_test > $lang/perplexity || echo "query failed"

  cat $lang/perplexity
fi

calculating_perplexity=`date +%s`
runtime="Calculating perplexity took $((calculating_perplexity-building_lm)) sek"
echo $runtime

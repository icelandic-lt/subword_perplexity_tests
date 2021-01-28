#!/bin/bash 

#set -o pipefail 

if [ $# -ne 2 ]; then
  echo "Usage: bpe_perplexity_test.sh <number of merges> <lang name>"
  echo "e.g.: bpe_perplexity_test.sh 1000 bpe_1000_test"
  exit 1;
fi

# Lets clock the runtime
start=`date +%s`
# A parameter used to dicripe the current 
# test e.g. bpe1000 meaning bpe with 1000 merges.
lang=$1

# The parameter that we are going to change
num_merges=$2
lang="${num_merges}_${lang}"

# Path to the folder where the corpus is located
corpus_folder=/home/derik/work/language_models/LM_corpus

# Name of our training corpus
#training_corpus=${corpus_folder}/demo_files/small_train_corpus
#training_corpus=${corpus_folder}/rmh_train
training_corpus=${corpus_folder}/rmh_train_smaller

# Name of our test corpus 
#test_corpus=${corpus_folder}/demo_files/small_test_corpus
#test_corpus=${corpus_folder}/rmh_test
test_corpus=${corpus_folder}/rmh_test_smaller

order=6
stage=0
tool='KenLM'
mkdir -p $lang

echo "`date`"

if [ $stage -le 0 ]; then
  echo "$0: Getting PBE pairs from $training_corpus"
  python3 learn_bpe.py -i $training_corpus -s $num_merges > $lang/pair_codes
fi

creating_pairs_time=`date +%s`
runtime="Creating the pair codes took $((creating_pairs_time-start)) sek"
echo $runtime

if [ $stage -le 1 ]; then
  echo "$0: Applying PBE to training corpus"
  ./prepare_subword_text.sh $training_corpus \
                           $lang/pair_codes \
                           $lang/rmh_training || exit 1

  echo "$0: Applying PBE to test corpus"
  ./prepare_subword_text.sh $test_corpus \
                            $lang/pair_codes \
                            $lang/rmh_test || exit 1
fi

applying_time=`date +%s`
runtime="Applying BPE to text files took $((applying_time-creating_pairs_time)) sek"
echo $runtime
echo "Total runtime is $((applying_time-start)) sek"

if [ $stage -le 2 ]; then
  if [ $tool == "SRI" ]; then
  echo "=== Building a language model with SRI"
  ./../srilm_perplexity.sh $lang/rmh_training \
                           $lang/rmh_test \
                           $lang > $lang/perplexity
  cat $lang/perplexity

  else
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
echo "Total runtime is $((calculating_perplexity-start)) sek"
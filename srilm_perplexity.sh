#!/bin/bash 

set -o pipefail

if [ $# -ne 3 ]; then
  echo "Usage: srilm_perplexity_.sh <training corpus> <test corpus> <lang name>"
  exit 1;
fi

# Change this if the script can't find Kaldi
export KALDI_ROOT=/home/derik/work/kaldi

training_corpus=$1
test_corpus=$2
lang=$3
order=6 


loc=`which ngram-count`;
if [ -z $loc ]; then
  if uname -a | grep 64 >/dev/null; then # some kind of 64 bit...
    sdir=$KALDI_ROOT/tools/srilm/bin/i686-m64 
  else
    sdir=$KALDI_ROOT/tools/srilm/bin/i686
  fi
  if [ -f $sdir/ngram-count ]; then
    echo Using SRILM tools from $sdir
    export PATH=$PATH:$sdir
  else
    echo You appear to not have SRILM tools installed, either on your path,
    echo or installed in $sdir.  See tools/install_srilm.sh for installation
    echo instructions.
    exit 1
  fi
fi

ngram-count -text $training_corpus \
            -order $order \
            -vocab ${training_corpus}_tokens \
            -unk -map-unk "<UNK>" -wbdiscount1 \
            -kndiscount2 -kndiscount3 -kndiscount4 \
            -kndiscount5 -kndiscount6 -interpolate \
            -lm data/$lang/lm.gz || exit 1

# For perplexity calculations of the test set. 
ngram -order $order \
      -lm data/$lang/lm.gz \
      -ppl $test_corpus || exit 1



#!/bin/bash

code=smaller_corpus
for item in 20000 10000 5000 1000 100
do
  mkdir -p ${item}_${code}
  ./bpe_perplexity_test.sh $item $code &> ${item}_${code}/log
  echo "$item done"
done
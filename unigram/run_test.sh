#!/bin/bash

code=kenlm
for item in 10000 5000 1000 100
do
  mkdir -p ${code}_${item}
  python3 unigram.py $code $item &> ${code}_${item}/log
  echo "$item done"
done
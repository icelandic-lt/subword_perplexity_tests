#!/bin/bash

code=kenlm
for item in 20000 10000 1000 100
do
  mkdir -p $code
  python3 sp_bpe.py $code $item &> ${code}_${item}/log
  echo "$item done"
done
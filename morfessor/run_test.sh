#!/bin/bash

code=kenlm
for item in 20000 10000 1000 100
do
  mkdir -p ${item}_${code}
  ./morfessor.sh $code $item &> ${item}_${code}/log
  echo "$item done"
done
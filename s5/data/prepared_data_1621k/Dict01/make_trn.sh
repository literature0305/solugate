#!/bin/bash

# Speech/Acoustics/Audio Signal Processing Lab.
# Hanyang University
# Jan. 2016

while read line; do
  trn_dir=`echo $line | awk '{ print substr($0,index($0,$2)) }' | sed s/'.wav'/'.trn'/g`
  utt_id=`echo $line | awk '{ print $1 }' | sed s/' '//g` 
  cat text | grep $utt_id | head -n 1 | awk '{ print substr($0,index($0,$2)) }' > $trn_dir

done < wav.scp



exit 0

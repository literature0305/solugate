#!/bin/bash

. ./cmd.sh 
[ -f path.sh ] && . ./path.sh
set -e

data_dir=$1
lang=data/lang_chain
dir=exp/chain/tdnn_1a_sp

nj=1

steps/online/nnet3/prepare_online_decoding.sh \
  --mfcc-config conf/mfcc_hires.conf \
  --add-pitch true \
  $lang exp/nnet3/extractor ${dir} ${dir}_online

steps/online/nnet3/decode.sh \
  --online false \
  --acwt 1.0 --post-decode-acwt 10.0 \
  --nj $nj --cmd "run.pl" \
  $dir/graph $data_dir ${dir}_online/decode_result || exit 1

#!/bin/bash

stage=0
num_thread_feat=16
num_thread_train=16

if [ $stage -le 0 ]; then
echo 'start data prepare, make lm'
echo `date`
local/data_subset_ASML.sh
fi

. ./cmd.sh 
[ -f path.sh ] && . ./path.sh
set -e

echo 'start'
echo `date`

if [ $stage -le 0 ]; then

# create data folder tree and generate language model

utils/prepare_lang.sh data/local/dict '!SIL' data/local/lang data/lang
local/format_data.sh

# make train-set and valid-set
utils/subset_data_dir_tr_cv.sh --cv-spk-percent 5 data/ttrain \
  data/train data/dev || exit 1;

# make feats
featdir=mfcc
mfccdir=mfcc

for x in train dev test; do
  utils/data/get_reco2dur.sh data/$x
  steps/make_mfcc_pitch.sh --cmd "$train_cmd" --nj 60 data/$x exp/make_mfcc/$x $mfccdir || exit 1;
  steps/compute_cmvn_stats.sh data/$x exp/make_mfcc/$x $mfccdir || exit 1;
  utils/fix_data_dir.sh data/$x || exit 1;
done

utils/subset_data_dir.sh --shortest data/train 2000 data/train_2k
utils/subset_data_dir.sh --shortest data/train 5000 data/train_5k
utils/subset_data_dir.sh --shortest data/train 10000 data/train_10k

echo 'start monophone training'
echo `date`


# train mono
steps/train_mono.sh --cmd "$train_cmd" --nj 20 \
  data/train_2k data/lang exp/mono || exit 1;
steps/align_si.sh --cmd "$train_cmd" --nj 20 \
  data/train_2k data/lang exp/mono exp/mono_ali || exit 1;

echo 'start train_deltas'
echo `date`

# train tri1 [first triphone pass]
steps/train_deltas.sh --cmd "$train_cmd" \
 2500 20000 data/train_2k data/lang exp/mono_ali exp/tri1 || exit 1;
steps/align_si.sh --cmd "$train_cmd" --nj 20 \
  data/train_5k data/lang exp/tri1 exp/tri1_ali || exit 1;

# train tri2 [delta+delta-deltas]
steps/train_deltas.sh --cmd "$train_cmd" \
 2500 20000 data/train_5k data/lang exp/tri1_ali exp/tri2 || exit 1;

# train and decode tri2b [LDA+MLLT]
steps/align_si.sh --cmd "$train_cmd" --nj 20 \
  data/train_10k data/lang exp/tri2 exp/tri2_ali || exit 1;

echo 'start train_lda_mllt'
echo `date`

fi
# Train tri3a, which is LDA+MLLT,
steps/train_lda_mllt.sh --cmd "$train_cmd" \
 2500 20000 data/train_10k data/lang exp/tri2_ali exp/tri3a || exit 1;

# From now, we start building a more serious system (with SAT), and we'll
# do the alignment with fMLLR.
steps/align_fmllr.sh --cmd "$train_cmd" --nj 20 \
  data/train data/lang exp/tri3a exp/tri3a_ali || exit 1;

steps/train_sat.sh --cmd "$train_cmd" \
  2500 20000 data/train data/lang exp/tri3a_ali exp/tri4a || exit 1;

steps/align_fmllr.sh  --cmd "$train_cmd" --nj 20 \
  data/train data/lang exp/tri4a exp/tri4a_ali

echo 'start building a larger SAT system'
echo `date`

# Building a larger SAT system.
steps/train_sat.sh --cmd "$train_cmd" \
  3500 100000 data/train data/lang exp/tri4a_ali exp/tri5a || exit 1;

utils/mkgraph.sh data/lang exp/tri5a exp/tri5a/graph || exit 1;
steps/decode_fmllr.sh --cmd "$decode_cmd" --nj 18 --config conf/decode.config \
   exp/tri5a/graph data/dev exp/tri5a/decode_dev || exit 1;

steps/decode_fmllr.sh --cmd "$decode_cmd" --nj 18 --config conf/decode.config \
   exp/tri5a/graph data/test exp/tri5a/decode_test || exit 1;

steps/align_fmllr.sh --cmd "$train_cmd" --nj 18 \
  data/train data/lang exp/tri5a exp/tri5a_ali || exit 1;

echo 'start chain run_tdnn'
echo `date`


# train chain model
local/chain/run_tdnn.sh

echo 'train finishied'
echo `date`

exit 0

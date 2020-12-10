#!/bin/bash

# Copyright 2012-2014  Brno University of Technology (Author: Karel Vesely)
# Apache 2.0

# Inyoung Hwang (iyhwang88@hanyang.ac.kr)
# Speech/Acoustics/Audio Signal Processing Lab.
# Hanyang University
# Jan. 2016


# This example script trains a DNN on top of fMLLR features. 
# The training is done in 3 stages,
#
# 1) RBM pre-training:
#    in this unsupervised stage we train stack of RBMs, 
#    a good starting point for frame cross-entropy trainig.
# 2) frame cross-entropy training:
#    the objective is to classify frames to correct pdfs.
# 3) sequence-training optimizing sMBR: 
#    the objective is to emphasize state-sequences with better 
#    frame accuracy w.r.t. reference alignment.

# Note: With DNNs in RM, the optimal LMWT is 2-6. Don't be tempted to try acwt's like 0.2, 
# the value 0.1 is better both for decoding and sMBR.

. ./cmd.sh ## You'll want to change cmd.sh to something that will work on your system.
           ## This relates to the queue.

. ./path.sh ## Source the tools/utils (import the queue.pl)

set -eu

# Config:
gmm=exp/tri1
stage=0 # resume training with --stage=N
# End of config.
. utils/parse_options.sh
#

# Pre-train DBN, i.e. a stack of RBMs (small database, smaller DNN
dir=exp/dnn4b_pretrain-dbn
if [ $stage -le 1 ]; then
  $cuda_cmd $dir/log/pretrain_dbn.log \
    steps/nnet/pretrain_dbn.sh --hid-dim 1024 --rbm-iter 10 data/train $dir
fi

# Train the DNN optimizing per-frame cross-entropy.
dir=exp/dnn4b_pretrain-dbn_dnn
ali=${gmm}_ali
feature_transform=exp/dnn4b_pretrain-dbn/final.feature_transform
dbn=exp/dnn4b_pretrain-dbn/5.dbn
if [ $stage -le 2 ]; then
  $cuda_cmd $dir/log/train_nnet.log \
    steps/nnet/train.sh --feature-transform $feature_transform \
      --dbn $dbn --hid-layers 0 --learn-rate 0.008 \
      data/train_tr data/train_cv data/lang $ali $ali $dir
fi

# Sequence training using sMBR criterion, we do Stochastic-GD with per-utterance updates.
# Note: With DNNs in RM, the optimal LMWT is 2-6. Don't be tempted to try acwt's like 0.2, 
# the value 0.1 is better both for decoding and sMBR.
srcdir=exp/dnn4b_pretrain-dbn_dnn
acwt=0.1

if [ $stage -le 3 ]; then
  # First we generate lattices and alignments:
  steps/nnet/align.sh --nj 20 --cmd "$train_cmd" --use-gpu yes \
    data/train data/lang $srcdir ${srcdir}_ali
  steps/nnet/make_denlats.sh --nj 20 --cmd "$decode_cmd" --config \
    conf/decode_dnn.config --acwt $acwt --use-gpu yes \
    data/train data/lang $srcdir ${srcdir}_denlats
fi

dir=exp/dnn4b_pretrain-dbn_dnn_smbr
if [ $stage -le 4 ]; then
  # Re-train the DNN by 6 iterations of sMBR
  steps/nnet/train_mpe.sh --cmd "$cuda_cmd" --num-iters 6 --acwt $acwt --do-smbr true \
    data/train data/lang $srcdir ${srcdir}_ali ${srcdir}_denlats $dir
  utils/mkgraph.sh data/lang $dir $dir/graph
fi

exit 0


dir=exp/dnn4b_pretrain-dbn_dnn_mpe
if [ $stage -le 5 ]; then
  # Re-train the DNN by 6 iterations of mpe
  steps/nnet/train_mpe.sh --cmd "$cuda_cmd" --num-iters 6 --acwt $acwt --do-smbr false \
    data/train data/lang $srcdir ${srcdir}_ali ${srcdir}_denlats $dir
  utils/mkgraph.sh data/lang $dir $dir/graph
fi

dir=exp/dnn4b_pretrain-dbn_dnn_mmi
if [ $stage -le 6 ]; then
  # Re-train the DNN by 4 iterations of MMI
  steps/nnet/train_mmi.sh --cmd "$cuda_cmd" --num-iters 4 --acwt $acwt \
    data/train data/lang $srcdir ${srcdir}_ali ${srcdir}_denlats $dir
  utils/mkgraph.sh data/lang $dir $dir/graph
fi

dir=exp/dnn4b_pretrain-dbn_dnn_bmmi
if [ $stage -le 7 ]; then
  # Re-train the DNN by 4 iterations of BMMI
  steps/nnet/train_mmi.sh --cmd "$cuda_cmd" --num-iters 4 --acwt $acwt --boost 0.1 \
    data/train data/lang $srcdir ${srcdir}_ali ${srcdir}_denlats $dir
  utils/mkgraph.sh data/lang $dir $dir/graph
fi

exit 0

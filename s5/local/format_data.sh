#!/bin/bash

# Inyoung Hwang (iyhwang88@hanyang.ac.kr)
# Speech/Acoustics/Audio Signal Processing Lab.
# Hanyang University
# Jan. 2016

. ./path.sh || exit 1;

echo "Preparing train and test data"
srcdir=data/local
lmdir=data/local/lm
tmpdir=data/local/lm_tmp
lexicon=data/local/dict/lexiconp.txt
mkdir -p $tmpdir

echo "Preparing the grammar transducer (G.fst) for testing..."

langdir=data/lang
mkdir -p $langdir
for f in words.txt phones.txt L.fst L_disambig.fst oov.txt oov.int topo phones/; do
  cp -r data/lang/$f $langdir
done

cat $lmdir/lm.arpa | \
  utils/find_arpa_oovs.pl $langdir/words.txt > $tmpdir/oovs.txt

cat $lmdir/lm.arpa | \
  grep -v '<s> <s>' | \
  grep -v '</s> <s>' | \
  grep -v '</s> </s>' | \
  arpa2fst - | fstprint | \
  utils/remove_oovs.pl $tmpdir/oovs.txt | \
  utils/eps2disambig.pl | utils/s2eps.pl | fstcompile --isymbols=$langdir/words.txt \
    --osymbols=$langdir/words.txt --keep_isymbols=false --keep_osymbols=false | \
  fstrmepsilon > $langdir/G.fst
fstisstochastic $langdir/G.fst

mkdir -p $tmpdir/g
awk '{if(NF==1){ printf("0 0 %s %s\n", $1, $1); }} END{print "0 0 #0 #0"; print "0";}' \
  < "$lexicon" > $tmpdir/g/select_empty.fst.txt
fstcompile --isymbols=$langdir/words.txt --osymbols=$langdir/words.txt \
  $tmpdir/g/select_empty.fst.txt | \
  fstarcsort --sort_type=olabel | fstcompose - $langdir/G.fst > $tmpdir/g/empty_words.fst
#fstinfo $tmpdir/g/empty_words.fst | grep cyclic | grep -w 'y' &&
#  echo "Language model has cycles with empty words" || exit 1


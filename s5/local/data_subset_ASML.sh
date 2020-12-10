#!/usr/bin/env bash

train=data/ttrain
test=data/test

cpu_core=8

echo ============================================================================
echo "Data & Lexicon & Language Preparation                                     "
echo ============================================================================

data_dir=data/prepared_data_1621k

#input_data_dir01=data/prepared_data_1621k/KsponSpeech
#input_data_dir02=data/prepared_data_1621k/Seoul_nangdok
input_data_dir03=data/prepared_data_1621k/Dict01
input_data_dir04=data/prepared_data_1621k/KeywordSpottingDB

target_data_dir=data/Combined_data

utils/combine_data.sh $target_data_dir $input_data_dir03 $input_data_dir04 #$input_data_dir03

local/gen_lexicon.sh

utils/fix_data_dir.sh $target_data_dir

utils/subset_data_dir_tr_cv.sh --cv-utt-percent 2 $target_data_dir $train $test

dir=$target_data_dir
lmtmp=$dir/lm

mkdir -p $lmtmp
mkdir -p data/local/dict
mkdir -p data/local/lm

# lexicon (remove carriage return)
tr -d '\r' < $data_dir/lexicon.txt > data/local/dict/lexicon.txt

cp $dir/text.txt $lmtmp/text.txt

./../../../tools/srilm/bin/i686-m64/ngram-count -text $lmtmp/text.txt -write-vocab $lmtmp/training.vocab -write1 $lmtmp/unigram.freq
./../../../tools/srilm/bin/i686-m64/ngram-count -vocab $lmtmp/training.vocab -text $lmtmp/text.txt -order 3 -write $lmtmp/training.count
./../../../tools/srilm/bin/i686-m64/ngram-count -vocab $lmtmp/training.vocab -read $lmtmp/training.count -order 3 -lm data/local/lm/lm.arpa

rm -rf $lmtmp

# Get phone lists...
grep -v -w sil data/local/dict/lexicon.txt | \
  awk '{for(n=2;n<=NF;n++) { p[$n]=1; }} END{for(x in p) {print x}}' | \
  sort | uniq > data/local/dict/nonsilence_phones.txt

echo sil > data/local/dict/silence_phones.txt
echo sil > data/local/dict/optional_silence.txt
touch data/local/dict/extra_questions.txt
# no extra questions, as we have no stress or tone markers

echo "kor_data_prep succeeded."
# Replace dir name
#sed -e 's:/media/jpong-lab/backup/db:/media/moa/MOA_2TB/DB/db:g' data/am/train/wav.scp > wav
#rm data/am/train/wav.scp
#mv wav data/am/train/wav.scp
#sed -e 's:/media/jpong-lab/backup/db:/media/moa/MOA_2TB/DB/db:g' data/am/test/wav.scp > wav
#rm data/am/test/wav.scp
#mv wav data/am/test/wav.scp

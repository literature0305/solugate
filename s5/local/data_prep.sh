#!/bin/bash

# Inyoung Hwang (iyhwang88@hanyang.ac.kr)
# Speech/Acoustics/Audio Signal Processing Lab.
# Hanyang University
# Jan. 2016

dir=data/prepared_data_1621k/KeywordSpottingDB
lmtmp=$dir/lm
mkdir -p $dir
mkdir -p $lmtmp
mkdir -p data/local/dict
mkdir -p data/local/lm

db_dir=/DB/KeywordSpottingDB/HO

# wav.scp
find $db_dir/* -name '*.wav' | sort > $dir/wav_list.txt
cat $dir/wav_list.txt | sed -e 's:.*/\(.*\)/\(.*\).wav$:\1_\2:i' > $dir/wav_uttid.txt
paste $dir/wav_uttid.txt $dir/wav_list.txt | sort -k1 > $dir/wav.scp

# utt2spk, spk2utt
cat $dir/wav_list.txt | sed -e 's:.*/\(.*\)/\(.*\).wav$:\1:i' > $dir/wav_spkid.txt
paste $dir/wav_uttid.txt $dir/wav_spkid.txt | sort -k1 > $dir/utt2spk
utils/utt2spk_to_spk2utt.pl $dir/utt2spk > $dir/spk2utt

# text.scp
find $db_dir/* -name '*.txt' | sort > $dir/text_list.txt
cat $dir/text_list.txt | sed -e 's:.*/\(.*\)/\(.*\).txt:\1_\2:i' > $dir/text_uttid.txt

rm -f $dir/text.txt

while read line; do
    cat "$line"  | tr -d '?' | tr -d '.' | tr -d ',' | tr -d '!' | tr -d '\r' >> $dir/text_tmp.txt
    echo -e "\n" >> $dir/text_tmp.txt
done < $dir/text_list.txt
cat $dir/text_tmp.txt | sed -e s/'^ '/''/g | grep -v '^$' > $dir/text.txt
paste $dir/text_uttid.txt $dir/text.txt | sort -k1 > $dir/text


exit 0
while read line; do
	[ -f $line ] || error_exit "Cannot find transcription file '$line'";
	cat "$line"  | tr -d '?' | tr -d '.' | tr -d ',' | tr -d '!' | tr -d '\r'
        echo " "
done < $dir/text_list.txt > $dir/text.txt
paste $dir/text_uttid.txt $dir/text.txt | sort -k1 > $dir/text

exit 0

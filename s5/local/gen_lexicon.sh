#!/bin/bash

data_dir=data/prepared_data_1621k
target_data_dir=data/Combined_data

echo 'generate lexicon'

cat $target_data_dir/text | awk '{ print substr($0, index($0,$2)) }' > $target_data_dir/text.txt

cat $target_data_dir/text.txt | sed -e s/' '/'\n'/g | LC_COLLATE='utf-8' sort -u | grep -v '^$'> $data_dir/words.txt

cat $data_dir/words.txt | sed s/'▁'/''/g > words

python3 local/gen_lexicon.py

echo '!SIL	SIL' > $data_dir/lexicon.txt
echo '<SPOKEN_NOISE>	SPN' >> $data_dir/lexicon.txt
echo '<UNK>	SIL' >> $data_dir/lexicon.txt

paste $data_dir/words.txt decomposed_phone.txt >> $data_dir/lexicon.txt

rm -f words
rm -f decomposed_phone.txt

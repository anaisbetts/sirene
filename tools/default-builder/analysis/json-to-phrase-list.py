import json
import os
import nltk
import operator
import re

from nltk.collocations import *
from nltk.metrics import *
from nltk.tokenize import *
from nltk import precision

nltk.download("punkt")

data = []

with open(os.path.dirname(__file__) + "/../result.json", encoding="utf-8") as fp:
    data = json.load(fp)

show_words = []
sentence_freq = {}
tokenizer_words = TweetTokenizer()

print("Starting tokenize")
punct = re.compile(r"[.!?;]")
for show in data:
    words = []

    for line in show:
        # words.extend(nltk.tokenize.word_tokenize(line))
        # sentences = [tokenizer_words.tokenize(t) for t in nltk.sent_tokenize(line)]
        sentences = nltk.sent_tokenize(line)
        for s in sentences:
            s = punct.sub("", s)
            if not sentence_freq.__contains__(s):
                sentence_freq[s] = 0

            sentence_freq[s] = sentence_freq[s] + 1
            words.extend(tokenizer_words.tokenize(s))

    show_words.append(words)

print("Sorting")
sorted_sentence_freq = sorted(sentence_freq.items(), key=lambda kv: kv[1], reverse=True)
for x in sorted_sentence_freq[0:100]:
    print(json.dumps({"frequency": x[1], "text": x[0]}))

exit(0)

assoc = nltk.TrigramAssocMeasures()
colloc = TrigramCollocationFinder.from_documents(show_words)
trigram_measures = nltk.collocations.TrigramAssocMeasures()

print("raw freq")
print(colloc.nbest(trigram_measures.raw_freq, 30))

print("student t")
print(colloc.nbest(trigram_measures.student_t, 30))

print("likelihood ratio")
print(colloc.nbest(trigram_measures.likelihood_ratio, 30))

print("jaccard")
print(colloc.nbest(trigram_measures.jaccard, 30))


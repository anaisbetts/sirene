import json
import os

data = []
with open(os.path.dirname(__file__) + "/../result.json", encoding="utf-8") as fp:
    data = json.load(fp)

for show in data:
    for line in show:
        print(line)

    break


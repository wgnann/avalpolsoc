# uso:
# python trata_cidade.py <input> <output> <field_no>

import csv
import sys
import unidecode

csvinput = open(sys.argv[1], 'r')
csvoutput = open(sys.argv[2], 'w')
field = int(sys.argv[3])
delimiter = ','
reader = csv.reader(csvinput, delimiter=delimiter)
writer = csv.writer(csvoutput, delimiter=delimiter)

all = []
row = next(reader)
all.append(row)
print(row)

for row in reader:
    tmp = row[field]
    tmp = tmp.replace(" ", "").replace("'", "")
    row[field] = unidecode.unidecode(tmp.upper())
    all.append(row)

writer.writerows(all)

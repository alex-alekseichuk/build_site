#!/usr/bin/python

import re
import sys

in_file = open(sys.argv[1])
out_file = open(sys.argv[2], 'w')

r = re.compile(r'ForeignKey\((\w+)(.*)\)')

for line in in_file:
    out_file.write(re.sub(r, r"ForeignKey('\1'\2)", line))

in_file.close()
out_file.close()


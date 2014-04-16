from random import random
import os, sys
import struct
import StringIO

sys.path.append('../../src/dev-util/')
from mongoDBWrapper import MongoDBWrapper

def prob_random(pr):
        allcount = 0
        for val in pr.values():
            allcount += val

        rnd = random() * allcount
        count = 0

        for opt in pr.keys():
            count += pr[opt]
            if count >= rnd:
                return opt

if __name__ == '__main__':
    alphabet = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z']
    prob = dict()
    for letter in alphabet:
        prob[letter] = 1

    haystackSize = 2 * 1024 * 1024

    needleSize = 5
    needle = 'a*b*c'

    output = StringIO.StringIO()

    output.write(struct.pack('ii', haystackSize, needleSize))

    dbout = True

    i = haystackSize
    while i != 0:
	if i % (1024*1024) == 0 and dbout:
		print str(i)
        output.write(prob_random(prob))
        i -= 1

    output.write(needle)

    if dbout:
    	db = MongoDBWrapper('des01')
    	id = db.allocate()
	db.put(output.getvalue(), id)
    	print id
    else:
	print output.getvalue()

import csv
import os
from os import system

sampleListFile = "samples.csv"

rawDataPath = "./"
resDir = "./res/"
r1Suffix = ".R1.fq.gz"
r2Suffix = ".R2.fq.gz"

try:
    os.mkdir(resDir)
    os.mkdir(resDir + "/01.clean/")
    os.mkdir(resDir + "/02.mergedFQ/")
except:
    pass

with open(sampleListFile, "r") as f:
    files = [i for i in csv.reader(f)]


# system = print


def fastp(inputR1, outputR1, inputR2, outputR2):

    cmd = "fastp -i {} -o {} -I {} -O {}".format(
        inputR1, outputR1, inputR2, outputR2)
    returnCode = system(cmd)
    if (returnCode != 0):
        exit(1)


def fastq_join(fastpR1, fastpR2, merge_fq):

    cmd = "join_paired_ends.py -f {} -r {} -m fastq-join -o {}".format(
        fastpR1, fastpR2, os.path.dirname(merge_fq))
    returnCode = system(cmd)
    if (returnCode != 0):
        exit(1)


merged_file = "{}{}".format(resDir, "/merged*.fa")
system("rm " + merged_file)


count = 0
for file in files:
    count_index = (count) % 10
    
    file = file[0]
    inputR1 = "{}{}{}".format(rawDataPath, file, r1Suffix)
    fastpR1 = "{}{}{}{}".format(resDir, "/01.clean/", file, ".clean.r1.fq.gz")
    inputR2 = "{}{}{}".format(rawDataPath, file, r2Suffix)
    fastpR2 = "{}{}{}{}".format(resDir, "/01.clean/", file, ".clean.r2.fq.gz")

    fastp(inputR1, fastpR1, inputR2, fastpR2)

    merge_fq = "{}{}{}{}".format(
        resDir, "/02.mergedFQ/", file, "/fastqjoin.join.fastq")
    fastq_join(fastpR1, fastpR2, merge_fq)

    toMergedFa = "awk 'NR%4==2 {{print \">{}_\"NR/4+0.5\"\\n\"$0}}' {} >> {}".format(
        file, merge_fq, merged_file.replace("*", str(count_index)))

    returnCode = system(toMergedFa)
    if (returnCode != 0):
        exit(1)
    else:
        cmd = "rm {} {} {}".format(fastpR1, fastpR2, merge_fq)
        system(cmd)
    
    count = count + 1

system("mkdir {}{}".format(resDir, "/merged_fa"))
system("mv " + merged_file + " {}{}".format(resDir, "/merged_fa/"))

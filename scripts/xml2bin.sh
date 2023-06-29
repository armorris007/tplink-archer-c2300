#!/bin/bash
[ $# -lt 1 ] && echo "Syntax: $0 filename.xml [output-filename.bin]" && exit

IN=$1
[ $# -lt 2 ] && OUT=${IN%.*}.bin || OUT=$2

OPENSSL=/usr/bin/openssl

[ ! -f $IN ] && echo File $IN does not exist && exit

# MD5 used for Archer C2300
OUR_MD5=`echo -n "Archer C2300" | md5sum | cut -d' ' -f 1`

# AES key & iv params
AES="-K 2EB38F7EC41D4B8E1422805BCD5F740BC3B95BE163E39D67579EB344427F7836 -iv 360028C9064242F81074F4C127D299F6"

TMP=$IN-tmp-dir
mkdir -p $TMP

# encrypt xml to get orig.bin file
cat $IN | python -c "import zlib,sys;sys.stdout.write(zlib.compress(sys.stdin.read()))" | $OPENSSL aes-256-cbc $AES -out $TMP/orig.bin

# create binary file (16 bytes) with content of product name md5
echo $OUR_MD5 | xxd -r -p >$TMP/md5file

# concatenate md5 file + orig.bin into mid.bin
cat $TMP/md5file $TMP/orig.bin >$TMP/mid.bin

# encrypt mid.bin to prepare final .bin acceptable by TP-Link firmware - Restore
cat $TMP/mid.bin | python -c "import zlib,sys;sys.stdout.write(zlib.compress(sys.stdin.read()))" | $OPENSSL aes-256-cbc $AES -out $OUT

echo BIN file saved in $OUT

rm -rf $TMP

#!/bin/sh

SRC="./src"
TARGET="app"
RES="results.txt"

cd $SRC
yacc -d parser.y 
lex scanner.l
gcc lex.yy.c y.tab.c -o ../$TARGET
rm y.tab.* lex.yy.c
cd ..
echo > $RES
for test in testcases/*
do
    ./$TARGET $test > /dev/null
done

cat $RES
# Go-Compiler
Этот компилятор предназначен для языка Go и предоставляет возможность определить, является ли написанный код кодом на языке Go.

Запуск программы  - run.sh. Вот его содержание:
```
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
```

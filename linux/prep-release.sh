#!/bin/bash

ENV_PATH=$1

echo Reading build environment variables from $1 into release environment ...

cat $ENV_PATH | while IFS="="; read name val || [ -n "$name" ]; do
    echo "##vso[task.setvariable variable=$name]$val"
    echo "$name = $val"
done

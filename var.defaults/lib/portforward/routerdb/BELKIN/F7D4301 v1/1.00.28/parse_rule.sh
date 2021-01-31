#!/bin/sh

rule="$1"
file="$2"

echo "$rule" >> "$file"

echo "$file"

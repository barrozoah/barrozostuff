#!/bin/bash

awk '{sum += $2; sumsq += ($2)^2} END {print sum/NR, sqrt((sumsq-sum^2/NR)/NR)}' $1

#!/bin/bash

#sed 's/\./,/g' $1 > tmp.log
#mv tmp.log $1
awk 'NR > 1  {sum += $2; sumsq += ($2)^2} END {print NR-1, sum/(NR-1), sqrt((sumsq-sum^2/(NR-1))/(NR-1))}' $1

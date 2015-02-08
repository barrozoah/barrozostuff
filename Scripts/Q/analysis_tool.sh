#!/bin/bash
#########################################
# Script to open mapping file from Q    #
# and print relevant information    #
#########################################

# float number comparison
function fcomp() {
    awk -v n1=$1 -v n2=$2 'BEGIN{ if (n1<n2) exit 0; exit 1}'
}

if [ -f "dG_dE.log" ]
then
rm dG_dE.log lambda_dE.log
fi
 
read begin1 <<< $(awk '$0 ~ str{print NR}' str="Part 3" $1)
begin1=$(($begin1+2))
 
echo -e dE '\t' dG > f1.log
awk -v firstline=$begin1 'NR>firstline {print $2, $4} ' $1 > f2.log
cat f1.log f2.log >> dG_dE.log
rm f1.log f2.log
 
read min1 min1_gap <<< $(awk 'min=="" || $2 < min {min=$2; mingap=$1}; END{ print min,mingap}'  dG_dE.log)

if fcomp $min1_gap 0;
then
   rs=$min1
   read min2 min2_gap <<< $(awk 'min=="" || $2 < min && $1 > 0 {min=$2; mingap=$1}; END{ print min,mingap}'  dG_dE.log)
   read ts ts_gap <<< $(awk -v m1="$min1_gap" -v m2="$min2_gap" 'NR>2 && max=="" || $2 > max && $1 > m1 && $1 < m2 {max=$2; maxgap=$1}; END{ print max,maxgap}'  dG_dE.log)
   ps=$min2
else
   ps=$min1
   read min2 min2_gap <<< $(awk 'min=="" || $2 < min && $1 < 0 {min=$2; mingap=$1}; END{ print min,mingap}'  dG_dE.log)
   read ts ts_gap <<< $(awk -v m1="$min1_gap" -v m2="$min2_gap" 'NR>2 && max=="" || $2 > max && $1 < m1 && $1 > m2 {max=$2; maxgap=$1}; END{ print max,maxgap}'  dG_dE.log)
   rs=$min2
fi

tsrs=$(echo $ts - $rs | bc)
tsps=$(echo $ts - $ps | bc)

if fcomp $tsrs 0 || fcomp $tsps 0;
then
   echo "Check your profile. It looks like a parabola."
   exit 1
fi

dg=$(echo $ts - $rs | bc)
dG0=$(echo $ps - $rs | bc)
 
echo "dg*: $dg"
echo "dG0: $dG0"

sed 's/.800000/.80000 /g' $1 > $1.tmp
sed 's/.600000/.60000 /g' $1.tmp > $1
sed 's/.400000/.40000 /g' $1 > $1.tmp
sed 's/.200000/.20000 /g' $1.tmp > $1
sed 's/.000000/.00000 /g' $1 > $1.tmp

sed 's/80000/8000 /g' $1.tmp > $1
sed 's/60000/6000 /g' $1 > $1.tmp
sed 's/40000/4000 /g' $1.tmp > $1
sed 's/20000/2000 /g' $1 > $1.tmp
sed 's/.000000/.00000 /g' $1.tmp > $1

sed 's/0-/0 -/g' $1 > $1.tmp
sed 's/1-/1 -/g' $1.tmp > $1
sed 's/2-/2 -/g' $1 > $1.tmp
sed 's/3-/3 -/g' $1.tmp > $1
sed 's/4-/4 -/g' $1 > $1.tmp
sed 's/5-/5 -/g' $1.tmp > $1
sed 's/6-/6 -/g' $1 > $1.tmp
sed 's/7-/7 -/g' $1.tmp > $1
sed 's/8-/8 -/g' $1 > $1.tmp
sed 's/9-/9 -/g' $1.tmp > $1

rm *.tmp

read begin1 <<< $(awk '$0 ~ str{print NR}' str="Part 2" $1)
begin1=$(($begin1+2))
 
read end1 <<< $(awk '$0 ~ str{print NR}' str="Part 3" $1)
end1=$(($end1-3))
 
echo -e lambda '\t' dG > f1.log
awk -v firstline=$begin1 -v lastline=$end1 'NR>firstline&&NR<=lastline {print $1, $3} ' $1  > f2.log
cat f1.log f2.log >> lambda_dE.log
rm f1.log f2.log

if [ -z ${3+x} ]
then
  exit 0
else 

read begin2 <<< $(awk '$0 ~ str{print NR}' str="fep_$2.en             1" $1)
read end2 <<< $(awk '$0 ~ str{print NR}' str="fep_$3.en             1" $1)

# EVB LRAs
# Total
read e1_tot e1_bnd e1_ang e1_tor e1_ee e1_vdw <<< $(awk -v line=$begin2 'NR==line {print $5, $6, $7, $8, $10, $11} ' $1)
read e2_tot e2_bnd e2_ang e2_tor e2_ee e2_vdw <<< $(awk -v line=$(($begin2+1)) 'NR==line {print $5, $6, $7, $8, $10, $11} ' $1)
 
e2e110_tot=$(echo $e2_tot - $e1_tot | bc)
e2e110_bnd=$(echo $e2_bnd - $e1_bnd | bc)
e2e110_ang=$(echo $e2_ang - $e1_ang | bc)
e2e110_tor=$(echo $e2_tor - $e1_tor | bc)
e2e110_ee=$(echo $e2_ee - $e1_ee | bc)
e2e110_vdw=$(echo $e2_vdw - $e1_vdw | bc)

read e1_tot e1_bnd e1_ang e1_tor e1_ee e1_vdw <<< $(awk -v line=$end2 'NR==line {print $5, $6, $7, $8, $10, $11} ' $1)
read e2_tot e2_bnd e2_ang e2_tor e2_ee e2_vdw <<< $(awk -v line=$(($end2+1)) 'NR==line {print $5, $6, $7, $8, $10, $11} ' $1)
 
e2e101_tot=$(echo $e2_tot - $e1_tot | bc)
e2e101_bnd=$(echo $e2_bnd - $e1_bnd | bc)
e2e101_ang=$(echo $e2_ang - $e1_ang | bc)
e2e101_tor=$(echo $e2_tor - $e1_tor | bc)
e2e101_ee=$(echo $e2_ee - $e1_ee | bc)
e2e101_vdw=$(echo $e2_vdw - $e1_vdw | bc)
 
lra_tot=$(echo $e2e101_tot*0.5 + $e2e110_tot*0.5 | bc)
lra_bnd=$(echo $e2e101_bnd*0.5 + $e2e110_bnd*0.5 | bc)
lra_ang=$(echo $e2e101_ang*0.5 + $e2e110_ang*0.5 | bc)
lra_tor=$(echo $e2e101_tor*0.5 + $e2e110_tor*0.5 | bc)
lra_ee=$(echo "scale=2; $e2e101_ee*0.5 + $e2e110_ee*0.5" | bc)
lra_vdw=$(echo $e2e101_vdw*0.5 + $e2e110_vdw*0.5 | bc)
 
reo_tot=$(echo $e2e110_tot*0.5 - $e2e101_tot*0.5 | bc)
reo_bnd=$(echo $e2e110_bnd*0.5 - $e2e101_bnd*0.5 | bc)
reo_ang=$(echo $e2e110_ang*0.5 - $e2e101_ang*0.5 | bc)
reo_tor=$(echo $e2e110_tor*0.5 - $e2e101_tor*0.5 | bc)
reo_ee=$(echo "scale=2; $e2e110_ee*0.5 - $e2e101_ee*0.5" | bc)
reo_vdw=$(echo $e2e110_vdw*0.5 - $e2e101_vdw*0.5 | bc)
 
 
# Interactions between Q atoms, Q atoms with protein and water
read e1elqq e1vdwqq e1elqp e1vdwqp e1elqw e1vdwqw <<< $(awk -v line=$begin2 'NR==line {print $12, $13, $14, $15, $16, $17} ' $1)
read e2elqq e2vdwqq e2elqp e2vdwqp e2elqw e2vdwqw <<< $(awk -v line=$(($begin2+1)) 'NR==line {print $12, $13, $14, $15, $16, $17} ' $1)
 
e2e110elqq=$(echo $e2elqq - $e1elqq | bc)
e2e110vdwqq=$(echo $e2vdwqq - $e1vdwqq | bc)
e2e110elqp=$(echo $e2elqp - $e1elqp | bc)
e2e110vdwqp=$(echo $e2vdwqp - $e1vdwqp | bc)
e2e110elqw=$(echo $e2elqw - $e1elqw | bc)
e2e110vdwqw=$(echo $e2vdwqw - $e1vdwqw | bc)
 
read e1elqq e1vdwqq e1elqp e1vdwqp e1elqw e1vdwqw <<< $(awk -v line=$end2 'NR==line {print $12, $13, $14, $15, $16, $17} ' $1)
read e2elqq e2vdwqq e2elqp e2vdwqp e2elqw e2vdwqw <<< $(awk -v line=$(($end2+1)) 'NR==line {print $12, $13, $14, $15, $16, $17} ' $1)
 
e2e101elqq=$(echo $e2elqq - $e1elqq | bc)
e2e101vdwqq=$(echo $e2vdwqq - $e1vdwqq | bc)
e2e101elqp=$(echo $e2elqp - $e1elqp | bc)
e2e101vdwqp=$(echo $e2vdwqp - $e1vdwqp | bc)
e2e101elqw=$(echo $e2elqw - $e1elqw | bc)
e2e101vdwqw=$(echo $e2vdwqw - $e1vdwqw | bc)
 
lraelqq=$(echo $e2e101elqq*0.5 + $e2e110elqq*0.5 | bc)
lravdwqq=$(echo $e2e101vdwqq*0.5 + $e2e110vdwqq*0.5 | bc)
lraelqp=$(echo $e2e101elqp*0.5 + $e2e110elqp*0.5 | bc)
lravdwqp=$(echo $e2e101vdwqp*0.5 + $e2e110vdwqp*0.5 | bc)
lraelqw=$(echo "scale=2; $e2e101elqw*0.5 + $e2e110elqw*0.5" | bc)
lravdwqw=$(echo $e2e101vdwqw*0.5 + $e2e110vdwqw*0.5 | bc)
 
reoelqq=$(echo $e2e110elqq*0.5 - $e2e101elqq*0.5 | bc)
reovdwqq=$(echo $e2e110vdwqq*0.5 - $e2e101vdwqq*0.5 | bc)
reoelqp=$(echo $e2e110elqp*0.5 - $e2e101elqp*0.5 | bc)
reovdwqp=$(echo $e2e110vdwqp*0.5 - $e2e101vdwqp*0.5 | bc)
reoelqw=$(echo "scale=2; $e2e110elqw*0.5 - $e2e101elqw*0.5" | bc)
reovdwqw=$(echo $e2e110vdwqw*0.5 - $e2e101vdwqw*0.5 | bc)
 
echo -e '\n'"-----------------------------------------------------------------------------" '\n'
echo "EVB Electrostatic + van der Waals LRA:"
echo -e '\t' '\t' "   LRA" '\t' "<E2-E1>_10" '\t' "<E2-E1>_01" '\t' "  REO"
printf "El(q/q) : %14.2f %15.2f %15.2f %14.2f \n" "$lraelqq" "$e2e110elqq" "$e2e101elqq" "$reoelqq"
printf "El(q/p) : %14.2f %15.2f %15.2f %14.2f \n" "$lraelqp" "$e2e110elqp" "$e2e101elqp" "$reoelqp"
printf "El(q/w) : %14.2f %15.2f %15.2f %14.2f \n" "$lraelqw" "$e2e110elqw" "$e2e101elqw" "$reoelqw"
printf "vdW(q/q): %14.2f %15.2f %15.2f %14.2f \n" "$lravdwqq" "$e2e110vdwqq" "$e2e101vdwqq" "$reovdwqq"
printf "vdW(q/p): %14.2f %15.2f %15.2f %14.2f \n" "$lravdwqp" "$e2e110vdwqp" "$e2e101vdwqp" "$reovdwqp"
printf "vdW(q/w): %14.2f %15.2f %15.2f %14.2f \n" "$lravdwqw" "$e2e110vdwqw" "$e2e101vdwqw" "$reovdwqw"
echo -e '\n'"-----------------------------------------------------------------------------" '\n'
#printf "Total  : %15.2f %15.2f %15.2f %14.2f \n" "$lra_tot" "$e2e110_tot" "$e2e101_tot" "$reo_tot"
 
echo "EVB Total LRA:"
echo -e '\t' '\t' "   LRA" '\t' "<E2-E1>_10" '\t' "<E2-E1>_01" '\t' "  REO"
printf "Bond   : %15.2f %15.2f %15.2f %14.2f \n" "$lra_bnd" "$e2e110_bnd" "$e2e101_bnd" "$reo_bnd"
printf "Angle  : %15.2f %15.2f %15.2f %14.2f \n" "$lra_ang" "$e2e110_ang" "$e2e101_ang" "$reo_ang"
printf "Torsion: %15.2f %15.2f %15.2f %14.2f \n" "$lra_tor" "$e2e110_tor" "$e2e101_tor" "$reo_tor"
printf "Coulomb: %15.2f %15.2f %15.2f %14.2f \n" "$lra_ee" "$e2e110_ee" "$e2e101_ee" "$reo_ee"
printf "vdW    : %15.2f %15.2f %15.2f %14.2f \n" "$lra_vdw" "$e2e110_vdw" "$e2e101_vdw" "$reo_vdw"
echo "-----------------------------------------------------------------------------"
printf "Total  : %15.2f %15.2f %15.2f %14.2f \n" "$lra_tot" "$e2e110_tot" "$e2e101_tot" "$reo_tot"
 
#gnuplot -persist <<PLOT

#   plot 'dG_dE.log' using 1:2 title 'dG profile' with lines

#   quit
#PLOT


#if [[ -z "$2" && -z "$3" ]];
#then
#Making distance plots

#   rm dist$2_$3.dat

#   for i in 100 098 096 094 092 090 088 086 084 082 080 078 076 074 072 070 068 066 064 062 060 058 056 054 052 050 048 046 044 042 040 038 036 034 032 030 028 026 024 022 020 018 016 014 012 010 008 006 004 002 000 ; do

#      awk "/dist. between Q-atoms   $2   $3/{print \$12, $i}" fep_$i.log  > distance$2_$3.log
#      tail -n 1 distance$2_$3.log >> dist$2_$3.log

#cat distance$2_$3.log >> dist$2_$3.log
#   done

#   rm distance$2_$3.log

#   gnuplot -persist <<PLOT

#   plot 'dist$2_$3.log' using 2:1 title 'distance betwee "$2" and "$3"' with lines

#   quit
#PLOT
#fi

#echo "LRA Bond: $e2e110_bnd"
 
#echo "$lra_tot"
 
#lra=$(($e2+$e1
#sed -n "$begin2 p" $1
#sed -n "$end2 p" $1
fi

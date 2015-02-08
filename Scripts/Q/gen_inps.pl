#!/usr/bin/perl 
#fep_inper.pl
use warnings;
#       _____________________________________
#      |                                     |
#      |  created by Masoud Kazemi July 2011 |
#      |_____________________________________|
#	Modified by Paul Bauer March 2013
$a=0;
$pn=1;
while ($a<1.0001){ 
             $a= sprintf ( "%4.2f",$a);
             push (@landa, $a);
             $a=$a+0.02;
             $pn++;
}
$pn=100;
for ($b=0;$b<51;$b++){
$nn= sprintf ("%03d",$pn);
open INP, ">fep_$nn.inp";
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------#
print  INP "[MD]\n";
print  INP "steps                          25000\n";
print  INP "stepsize                        1.0\n";
print  INP "temperature                    300\n" ;
print  INP "bath_coupling                     100\n";
print  INP "separate_scaling                on\n" ;
print  INP "lrf                               on\n";
print  INP "\n[cut-offs]\n";
print  INP "q_atom                        99\n";
print  INP "\n[sphere]\n";                                       
print  INP "exclude_bonded		on\n";
print  INP "\n[intervals]\n"			      ;
print  INP "non_bond                      30\n"	      ;  # time step for nonbonded decreased
print  INP "output                        100\n"	      ;
print  INP "energy                        10\n"	      ;
print  INP "trajectory                   25000\n"	      ;
print  INP "\n[files]\n"			      ;
print  INP "topology             1O03.top\n"        ;
printf INP "restart	         fep_%03d.re\n",$nn+2 ;
print  INP "final	         fep_$nn.re\n"	      ;
print  INP "energy	         fep_$nn.en\n"	      ;
print  INP "trajectory           fep_$nn.dcd\n"	      ;
print  INP "fep	                     1O03.fep\n"	      ;
print  INP "restraint		 rest_fep_102.re\n" ;
print  INP "\n[lambdas]\n"			      ;
printf INP "%4.2f   %4.2f\n", (1-$landa[$b]) ,$landa[$b]   ;
print  INP "\n[sequence_restraints]\n"			;
print  INP "131   133   0.5   1   0\n"			;
print  INP "159   164   0.5   1   0\n"			; 
print  INP "3436  3466  0.5   1   0\n"                    ;
#print  INP "\n[angle_restraints]\n"                  ;
#print  INP "32202	5062	5063	180.0	50.0	0"                    ;
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------#
$pn=$pn-2;
close INP ;
}

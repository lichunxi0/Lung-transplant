#!usr/bin/perl -w
use strict;
use Getopt::Std;

#die "perl $0 <otu.table> <meta.file> <fields> <output-prefix> [cores] [numeric_catogory_both] [features]\n" unless @ARGV==4 or @ARGV==5 or @;

my $usage="perl $0 -i <\$PWD/otu.table> -o <\$PWD/output.prefix> -m <\$PWD/meta.file> -f <fields> -t <type (should only be category, numeric)> -n [numeric_features] -c [catogory_features] -k [cores]
This is the program runs Random Forest model.
-i <otu.table or taxafix.table>    Required. 
-o <output_prefix>        Requried.
-m <metadata file>    Requried. With absolutly same sample number as -i 
-f <field> Requried. The predict target which contained in the metadata
-t <type> Required. The model type which depend on the type of the predict target.
-n [the_numeric_features] optional. add numeric features in the metadata to model.use , to separate
-c [the_catogory_features] optinal. add catogory features in the metadata to model. use , to separate.
-k [the_cpu_threads]optional. the number of the cpu threads.
-h [help]
";

use vars qw($opt_i $opt_o $opt_m $opt_f $opt_t $opt_n $opt_c $opt_k $opt_h);
getopts('i:o:m:f:t:n:c:k:h');

if ($opt_h){
        print $usage,"\n";
        exit(1);
}

unless ($opt_i and $opt_o and $opt_m and $opt_f and $opt_t){
        print "$usage\n";
        exit(1);
}

if (-e $opt_o){
        print "output_dir already exists\n";
        exit(1);
}
`mkdir $opt_o`;

#Get the location of this script, since it has used other scripts, we need to get the location of all of them.
use File::Spec;

my $path_script=File::Spec->rel2abs(__FILE__);
my @path_script=split(/\//,$path_script);
pop @path_script;
my $dir_script=join("/",@path_script);
print $dir_script;

my @k = split(/\//,$opt_o);
my $out = join("/",$opt_o,$k[-1]);

## create args file and make RF model
open OUT,">$out.args";
print OUT "\-\-input\_otu\_table $opt_i\n\-\-metadata\ $opt_m\n\-\-fields\ $opt_f\n\-\-models\ rf\n";

if ($opt_n){
	print OUT "\-\-add\_numeric $opt_n\n";
}

if ($opt_c){
	print OUT "\-\-add\_category $opt_c\n";
}

if ($opt_k){
	print OUT "\-\-core $opt_k\n";
}else{
	print OUT "\-\-core 5\n";
}

close OUT;
## args file created

## run model
if ($opt_t eq "numeric"){
	`/home/lipan/R/bin/Rscript $dir_script/regression.R --file $out.args`;
	`mv $opt_f.pdf $opt_o/$opt_f.cor.pdf`;
	`mv $out.pdf $opt_o/$opt_f.imps.pdf`;
	`/home/lipan/R/bin/Rscript $dir_script/extract.Rvalue.R -i $out.Rdata`;
}elsif ($opt_t eq "category"){
	`/home/lipan/R/bin/Rscript $dir_script/classification.R --file $out.args`;
	#`sleep 20s`;
	`mv $out.pdf $opt_o/$opt_f.imps.pdf`;
	`/home/lipan/R/bin/Rscript $dir_script/extract.auc.R -i $out.Rdata`;
}else{
	print "-t should only be numeric or category\n";
        exit(1);	
}
## run model ends









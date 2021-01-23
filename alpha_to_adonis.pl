#!/usr/bin/perl -w
use strict;
die "perl $0 <metadata.txt> <biom> <tree> <outputdir>\n" unless @ARGV==4;
print "the $ARGV[0] is not exist\n" unless (-e $ARGV[0]);
print "the $ARGV[1] is not exist\n" unless (-e $ARGV[1]);
print "the $ARGV[2] is not exist\n" unless (-e $ARGV[2]);
if (-e $ARGV[3]){
    print "the $ARGV[3] is exist!\n" ;
}else{
    `mkdir $ARGV[3]`;
}
# converting file to UNIX format in order to remove the irregularity end "^m" at the end of the line
`dos2unix $ARGV[0]`;
#----------
my $otu_table_prefix;
if ($ARGV[1]=~/(.*).biom/){
    $otu_table_prefix=$1."_sorted_L";
    #print "$otu_table_prefix\n";
}
#alpha_beta_taxa 
`alpha_diversity.py -i $ARGV[1] -o $ARGV[3]/adiv.txt -m shannon,chao1,observed_otus,PD_whole_tree -t $ARGV[2]`;
`/home/wangxian/programs/R/R-3.4.3/bin/Rscript /data/tangwenli/script/pre/Alpha_Pvalue_pip.R -t $ARGV[3]/adiv.txt -m $ARGV[0] -o $ARGV[3]/Alph`;
`beta_diversity_through_plots.py -i $ARGV[1] -o $ARGV[3]/bdiv -m $ARGV[0] -t $ARGV[2] -p /home/heyan/Data_analysis_scripts/QIIME_params/bdiv.params.txt`;
`summarize_taxa_through_plots.py -i $ARGV[1] -o $ARGV[3]/taxa -m $ARGV[0] -s`; 
#------
#creat pre_lefse.txt
`perl /home/heyan/Data_analysis_scripts/lefse/create_input/create_lefse_input.pl $ARGV[3]/taxa $ARGV[3]/lefse.txt $otu_table_prefix`;
#`perl /home/heyan/Data_analysis_scripts/lefse/create_input/lefse_add_group.pl $ARGV[3]/lefse.txt $ARGV[0] group $ARGV[3]/$ARGV[3].lefse.txt`;
`/home/lipan/R/bin/Rscript /data/tangwenli/script/beta/2D_PCoA_v1.2.3.r -p $ARGV[3]/bdiv -m $ARGV[0] -o $ARGV[3]/PCoA -d abund_jaccard,binary_jaccard,unweighted_unifrac,weighted_unifrac,euclidean,bray_curtis,pearson,kulczynski`;
#prepare the treatments for lefse.txt
open IN,$ARGV[0] or die "can't open $ARGV[0]\n";
my $line=<IN>;
chomp $line;
#print "$line\n";
my @line=split(/\t/,$line);
shift @line;
my $categories=join(",",@line);
#print "the categories for adonis:$categories\n";
my @dm_path = `ls $ARGV[3]/bdiv/*dm.txt`;
#print "dm_path:@dm_path";
#print "-----------\n";
`mkdir $ARGV[3]/adonis`;
foreach my $dm (@dm_path){
	chomp $dm;
	#print "$dm\n";
	my @dm1=split(/\//,$dm);
	my $dm_name=pop @dm1;
	$dm_name=$1 if($dm_name=~/(.*).txt/);
	#print "dm_name:$dm_name\n";
	my $adonis_name="adonis_".$dm_name;
	print "adonis name :$adonis_name\n";
	`perl /data/tangwenli/script/beta/adonis_all_metadata.pl $dm $ARGV[0] $categories $ARGV[3]/adonis/adonis_$dm_name 1`;
}
print "-----------\n";
#print "@line\n";
#print "the treatment for lefse:\n";
foreach my $treatment(@line){
    #print "$treatment\n";
    #`perl /data/tangwenli/script/lefse_add_group.pl $ARGV[3]/lefse.txt $ARGV[0] $treatment $ARGV[3]/$treatment.lefse.txt`;
}
close IN;

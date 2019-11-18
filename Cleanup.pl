#!/usr/bin/perl
#c1864687 Jodie Edge
#Task 1: Script programming

use strict;
use warnings;
use File::Find;
use HTML::LinkExtor;
use File::Basename;
use File::Spec;
use File::Copy;
use File::Path qw(make_path);

#takes in arguments and stores them as variables
die "For file: $0 \nYou need to enter in a <cleanupDirectory> and a <rubbishBinDirectory for the program to work>\n" unless @ARGV >= 2; #adapted from: https://stackoverflow.com/questions/9309488/how-to-handle-the-missing-arguments-while-executing-pl-file-in-perl
my ($cleanupDir, $rubbishBinDir) = @ARGV;

#working out the total arguments given and the number of additional arguments
my $total = $#ARGV;
print $total;

#search for files within a directory/earch within files for files listed in the directory
my (@allFiles, @baseAllFiles, @excludeFiles, @baseExclude); 
find(sub {return unless -f; push @allFiles, $File::Find::name}, $cleanupDir); #adapted from: https://www.cs.ait.ac.th/~on/O/oreilly/perl/cookbook/ch09_08.htm

#placing additional files into an array ready for processing
my ($skipFile, $i);
if ($#ARGV>1){
	for(my $i=1; $i <= $total; $i++){
		$skipFile = $ARGV[$i];
		push @excludeFiles, $skipFile;}}

#find out the base level of the file name for the excluded files
foreach my $element (@excludeFiles){
	my @baseNameFiles = File::Spec->splitdir($element); #adapted from: https://stackoverflow.com/questions/19838779/how-to-go-1-level-back-for-a-directory-path-stored-in-a-variable-in-perl
	my $actualFileName = @baseNameFiles-1;
	my $newdir = File::Spec->catdir($baseNameFiles[$actualFileName]);
	push @baseExclude, $newdir;}
print "baseExclude:@baseExclude";
#find out the base level of the file name for all files linked 
foreach my $element (@allFiles){
	my @baseNameFiles = File::Spec->splitdir($element); #adapted from: https://stackoverflow.com/questions/19838779/how-to-go-1-level-back-for-a-directory-path-stored-in-a-variable-in-perl
	my $actualFileName = @baseNameFiles-1;
	my $newdir = File::Spec->catdir($baseNameFiles[$actualFileName]);
	push @baseAllFiles, $newdir;}

# extract a tag content, href/img src tags
my ($base_url, $linkArray); # adapted from https://www.oreilly.com/library/view/perl-cookbook/1565922433/ch20s04.html
my (@links, @fileLinked); 
my $parser = HTML::LinkExtor->new(undef, $base_url);
foreach my $element (@allFiles){ 
	my $fileName = $element;
	$parser->parse_file($fileName);
	@links = $parser->links;
	foreach $linkArray (@links) {
		my @element = @$linkArray;
		my $elt_type = shift @element;
		while (@element) {
			my ($attr_name, $attr_value) = splice(@element, 0, 2);
			push @fileLinked, $attr_value;			}}}

#check whether the file exists and add on the files to ignore
my (@matchedFiles, @notLinked) ;
foreach my $element (@baseAllFiles){ #adapted from: https://stackoverflow.com/questions/7898499/grep-to-find-item-in-perl-array
	if ( grep /$element/, @fileLinked) {
		push @matchedFiles, $element;}}
foreach my $element (@baseExclude){
	push @matchedFiles, $element;}

#cross reference with files - if not listed store in new array 
my %seen; #adapted from: https://www.oreilly.com/library/view/perl-cookbook/1565922433/ch04s08.html
@seen{@matchedFiles} = (); 
foreach (@baseAllFiles) {
    push(@notLinked, $_) unless exists ($seen{$_});}

#find full path of not linked file - searching through allFiles to find a file ending in file path
my @allFullPaths;
for(my $i=0 ; $i < scalar @allFiles ; $i++){	#adapted from: https://www.perlmonks.org/?node_id=407265
	foreach my $item (@notLinked){
		if ($allFiles[$i] =~ m/$item$/){
			my $fullPath="$allFiles[$i]";
			push @allFullPaths, $fullPath ;}}}

#removal of unused files in directory and subdirectories. Maintains folder structure when cleaning up. If there is two file in different folders take both files and folder structure
foreach my $item (@allFullPaths){
	my ($filename2,$baseNameFiles2) = fileparse($item); #adapted from: https://www.linuxquestions.org/questions/programming-9/perl-removing-file-from-path-to-get-directory-only-447322/
	my $overallDirectory = "$rubbishBinDir$baseNameFiles2";
	make_path "$overallDirectory" or die "The move operation failed: $!";
	move($item, $overallDirectory) or die "The move operation failed: $!";}

#~~~~~~~~~~~~~~STAT FILE~~~~~~~

#get the number of files - find the ending 
my (@allFilesRecycle, @suffixFiles, @countFileTypes, @fileTypes); 
find(sub {return unless -f; push @allFilesRecycle, $File::Find::name}, $rubbishBinDir);

my $numberOfFiles = $#allFilesRecycle+1;

#get file ending
foreach my $item (@allFilesRecycle){
	my ($name,$path,$suffix) = fileparse($item,qr"\..[^.]*$"); #adapted from: https://stackoverflow.com/questions/2467016/is-there-a-regular-expression-in-perl-to-find-a-files-extension
  	push  @suffixFiles, $suffix;}

#get the number of files -count the number
my %count;
$count{$_}++ foreach @suffixFiles; #adapted from: https://stackoverflow.com/questions/17875256/perl-count-repeated-strings-in-array
while (my ($key, $value) = each(%count)) {
	if ($value == 0) {
		delete($count{$key});}
	push @countFileTypes,"$key:$value";
	push @fileTypes, $key;}

#overall size of files with that ending
my @indFileSize;
my $count =0;
foreach my $item (@allFilesRecycle){
	my $fileUsing = $item;
	my $fileSize = -s $fileUsing;
	my ($name,$path,$suffix) = fileparse($item,qr"\..[^.]*$");
	push @indFileSize, $suffix, $fileSize;	}

#work out totals for groups
my @overallFileTotal;
my @overallTotal;
my %sums; #adapted from: https://stackoverflow.com/questions/18684692/perl-array-sum-similar-elements#comment27523449_18684751
while (@indFileSize) {
  my ($label, $value) = splice(@indFileSize, 0, 2);
  $sums{$label} += $value;}
for my $key (sort keys %sums) {
  push @overallFileTotal, $key, $sums{$key};
push @overallTotal, $sums{$key}}

#work out overall file total
my $sumOfFileSize = 0;
foreach( @overallTotal) { $sumOfFileSize += $_ }

#output for stat report
print "Cleanup statistics for $cleanupDir:\n";
print "Overall number of files moved: $numberOfFiles \n";
print "File ending and number of files: @countFileTypes \n";
print "File ending and total size of files moved: @overallFileTotal (given in bytes) \n";
print "Total size of files moved: $sumOfFileSize (given in bytes) \n";
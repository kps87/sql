#!/usr/bin/perl
use strict;
use warnings;
use Time::HiRes qw(gettimeofday tv_interval);
require "./generateRelations.pl";
require "./printRelations.pl";


main();

sub main {
	
	
	print "-generateDatabase::main()\n";
	my %input;
	$input{'number_of_patients'} = 200;
	$input{'number_of_specialists'} = 10;
	
	my $tick = [gettimeofday];
	my %relations = %{ generate_relations(\%input) };
	write_relations(\%relations);
	my $elapsed = tv_interval ( $tick );
	print "\t-database generation took $elapsed seconds\n";
	
	
}

#!/usr/bin/perl
package genericFileParsers;
use strict;
use warnings;
use FindBin;
use vars qw($VERSION @ISA @EXPORT);
require Exporter;
@ISA    = qw(Exporter);
@EXPORT = qw(
  read_file
);

sub read_file {

	my ( $ref1, $ref2 ) = @_;
	my $file    = ${$ref1};
	my $comment = 0;

	open( my $fh, "$file" ) or die "\t-file: $file does not exist $!\n";
	my @file = <$fh>;
	close $fh;
	chomp $_ foreach (@file);

	if ( defined($ref2) ) {
		my $comment = ${$ref2};
		my @commented;
		foreach my $line (@file) {
			unless ( $line =~ /^$comment/ ) {
				push( @commented, $line );
			}
		}
		@file = @commented;
	}
	return @file;
}

1;

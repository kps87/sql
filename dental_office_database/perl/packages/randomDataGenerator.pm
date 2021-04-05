#!/usr/bin/perl
package randomDataGenerator;
use strict;
use warnings;
use Cwd;
use List::Util qw(shuffle);
use List::MoreUtils qw(uniq);
use Data::Random qw(:all);

use FindBin;
use lib "$FindBin::Bin/../packages";
use genericFileParsers;

use vars qw($VERSION @ISA @EXPORT);
require Exporter;
@ISA    = qw(Exporter);
@EXPORT = qw(
  new
);

sub new {
	my ($class) = @_;
	my $self = {};
	$self->{'name'} = 'randomgenerator';
	@{ $self->{uniqueID} } = ();
	bless $self, $class;

	return $self;
}

sub set_data {
	my ($self) = @_;

	my @fields = (
		"firstname", "surname", "address1", "address2",
		"address3",  "county",  "domain"
	);

	foreach my $field (@fields) {
		my $file = File::Spec->catfile((cwd(), 'inputs'), $field . ".txt");
		@{ $self->{$field} } = genericFileParsers::read_file( \$file );
		foreach ( @{ $self->{firstnames} } ) {
			$_ =~ s/^\s+//ig;
			$_ =~ s/\s+$//ig;
			$_ =~ s/\s+/ /ig;
			$_ = lc $_;
			$_ = ucfirst $_;
		}
		foreach ( @{ $self->{surname} } ) {
			$_ =~ s/^\s+//ig;
			$_ =~ s/\s+$//ig;
			$_ =~ s/\s+/ /ig;
			$_ = lc $_;
			$_ = ucfirst $_;
		}
		@{ $self->{$field} } = uniq( @{ $self->{$field} } );
	}
	
	# read in the treatments file
	my $file = File::Spec->catfile((cwd(), 'inputs'), "treatments.txt");
	@{ $self->{gender} } = ( "M", "F", "NB", "NULL" );
	@{ $self->{treatments_file} } =
	  genericFileParsers::read_file( \$file );
	$self->sort_treatments();

}

sub sort_treatments {

	my ($self) = @_;
	my @treatments_file = @{ $self->{treatments_file} };
	my %treatments;

	foreach my $line (@treatments_file) {

		chomp $line;
		my @line      = split( /\t+/, $line );
		my $treatment = $line[0];
		my $inhouse   = $line[1];
		my $min       = $line[2];
		my $max       = $line[3];
		
		$treatment =~ s/^\s+//ig;
		$treatment =~ s/\s+$//ig;
		$treatment =~ s/\s+/ /ig;

		if ($inhouse) {
			push( @{ $self->{'inhouse_treatment'} }, $treatment );
			$treatments{$treatment}{'min'} = $min;
			$treatments{$treatment}{'max'} = $max;

		}
		else {
			push( @{ $self->{'referral_treatment'} }, $treatment );
			$treatments{$treatment}{'min'} = "NULL";
			$treatments{$treatment}{'max'} = "NULL";
		}

	}

	%{ $self->{treatments} } = %treatments;

}

sub stringField {

	my ( $self, $ref ) = @_;
	my $type = ${$ref};
	my $result =
	  ${ $self->{$type} }[ int( rand( scalar( @{ $self->{$type} } ) ) ) ];
	return \$result;

}

sub houseNumber {

	my ($self) = @_;
	my @set = ( 'A' ... 'F' );
	push( @set, "" );
	my $houseNumber = int( rand(500) ) . $set[ int( rand( scalar(@set) ) ) ];
	return \$houseNumber;

}

sub phoneNumber {

	my ($self) = @_;
	my $prefix = "0";
	my @codes  = ( "86", "87", "88", "89" );
	my $num =
	  $prefix . $codes[ int( rand( scalar(@codes) ) ) ] . int( rand(9999999) );
	return \$num;

}

sub pps {

	my ($self) = @_;
	my @codes = ( "P", "R" );
	my $pps =
	  int( rand(9999999) ) . "/" . $codes[ int( rand( scalar(@codes) ) ) ];
	return \$pps;

}

sub email {

	my ( $self, $ref1, $ref2, $ref3, $ref4 ) = @_;

	my $fname = ${$ref1};
	my $sname = ${$ref2};

	my @firstname  = split( //, ${$ref1} );
	my @secondname = split( //, ${$ref2} );
	my $dopy_names = ${$ref3};
	my $number     = ${$ref4};

	my @domains = @{ $self->{domain} };
	my @chars   = ( "", ".", "-" );

	if ($dopy_names) {
		$fname = ${ $self->array_slice( \@firstname ) };
		$sname = ${ $self->array_slice( \@secondname ) };
	}
	if ($number) {
		$number = int( rand(100) );
	}
	else {
		$number = "";
	}

	my $email =
		$fname
	  . $chars[ int( rand( scalar(@chars) ) ) ]
	  . $sname
	  . $number . "@"
	  . $domains[ int( rand( scalar(@domains) ) ) ];

	return \$email;

}

sub random_treatments {

	my ( $self, $ref1, $ref2 ) = @_;
	my @array = shuffle @{$ref1};
	my $number_treatments = ${$ref2};
	if ( scalar @array < $number_treatments ) {
		$number_treatments = scalar @array;
	}
	my @random_sub_array = @array[ 0 ... $number_treatments-1 ];
	return \@random_sub_array;

}

sub random_sub_array {

	my ( $self, $ref ) = @_;
	my @array = shuffle @{$ref};
	my $rand1 = 0;
	while ( $rand1 == 0 ) {
		$rand1 = 2 + int( rand( scalar(@array) - 2 ) );
	}
	my @random_sub_array = @array[ 0 ... $rand1 ];
	return \@random_sub_array;

}

sub array_slice {

	my ( $self, $ref ) = @_;
	my @array = @{$ref};
	my $rand1 = 0;
	while ( $rand1 == 0 ) {
		$rand1 = int( rand( scalar(@array) ) );
	}
	my $slice = join( "", @array[ 0 ... $rand1 ] );
	return \$slice;
}

sub uniqueID {

	my ( $self, $ref1, $ref2, $ref3, $ref4 ) = @_;
	my $maxchar = ${$ref1};
	my $prefix  = ${$ref2};
	my $suffix  = ${$ref3};
	my $type    = ${$ref4};
	my $length  = $maxchar - length($prefix) - length($suffix);

	my @set = ( 'A' ... 'Z' );

	my $id;

	if ( $type eq 'numeric' ) {

		my $maxint = '';
		for my $i ( 1 ... $length ) {
			$maxint = $maxint . "9";
		}
		my $int = int( rand($maxint) );
		for my $i ( 1 ... ( $length - length($int) ) ) {
			$int = "0" . $int;
		}
		$id = $prefix . $int . $suffix;
	}
	elsif ( $type eq 'alpha' ) {

		$id = $prefix;
		for my $i ( 1 ... $length ) {
			$id = $id . $set[ int( rand( scalar(@set) ) ) ];
		}
		$id = $id . $suffix;

	}
	else {

		$id = $prefix;
		for my $i ( 1 ... $length ) {
			if ( $i % 2 != 0 ) {
				$id = $id . int( rand(9) );
			}
			else {
				$id = $id . $set[ int( rand( scalar(@set) ) ) ];
			}
		}
		$id = $id . $suffix;

	}

	return \$id;

}

sub date {

	my ( $self, $ref1, $ref2 ) = @_;
	my $min  = ${$ref1};
	my $max  = ${$ref2};
	my $date = rand_date( min => $min, max => $max );
	return \$date;

}

sub time {
	my ( $self, $ref1, $ref2 ) = @_;
	my $min  = ${$ref1};
	my $max  = ${$ref2};
	my $time = rand_time( min => '00:09:00', max => '17:00:00' );
	return \$time;

}

sub datetime_slot {

	my ( $self, $ref1, $ref2, $ref3, $ref4 ) = @_;
	my $start_date = ${$ref1};
	my $end_date   = ${$ref2};
	my %datetimes  = %{$ref3};
	my $ntreatments = ${$ref4};

	if($end_date eq "NULL"){
		$end_date = '2020-05-31';
	}
	
	my $false = 1;
	my $date;
	my $time = 9;
	while($false){
		$date = ${ $self->date( \$start_date, \$end_date ) };
		if(exists($datetimes{$date}) and $datetimes{$date}+$ntreatments <= 19){
			$time = $datetimes{$date};
			$datetimes{$date} = $datetimes{$date}+$ntreatments;
			$false = 0;
		}
		elsif(!exists($datetimes{$date})){
			$datetimes{$date} = $time+$ntreatments;
			$false = 0;
		}
	}
	
	my %return;
	$return{'date'} = $date;
	$return{'time'} = $time;
	%{$return{'datetimes'}} = %datetimes;
	return \%return;
	

}

sub dental_report{
	
	my ($self, $ref) = @_;
	my @treatments = @{$ref};
	
	# regurgitate the treamtments
	my $treatment_summary = "Patient presented for";
	foreach my $i (0...$#treatments){
		
		if($i == $#treatments){
			$treatment_summary = $treatment_summary . " " . $treatments[$i] . ".";
		}
		elsif($i < $#treatments-1){
			$treatment_summary = $treatment_summary . " " . $treatments[$i] . ",";
		}
		elsif($i == $#treatments-1){
			$treatment_summary = $treatment_summary . " " . $treatments[$i] . ", and";			
		}
		
	}
	
	# some procedure options - generate a random outcome
	my %procedure_summary;
	@{ $procedure_summary{"went according to plan"}} = ("but future treatments are required", "and future treatments are likely not required");
	@{ $procedure_summary{"had minor complications"}} = ("and future treatments are likely required");
 	my %options;
 	$options{1} = "went according to plan";
 	$options{2} = "had minor complications";
	my $option = 1 + int(rand(scalar(keys %options)));
	my $random_int = int(rand(scalar @{$procedure_summary{$options{$option}}}));
	my $procedure_summary = "Procedure " . $options{$option} . " " . ${$procedure_summary{$options{$option}}}[$random_int] . ".";
	
	# lists of possible actions and options
	my %symptom_actions;
	@{ $symptom_actions{"patient reported no pain or discomfort"}} = ("no action required", "possible nerve damage");
	@{ $symptom_actions{"patient reported mild pain"}} = ("prescribed painkiller", "medical certificate provided", "follow up required");
	@{ $symptom_actions{"patient reported severe pain"}} = ("prescribed painkiller", "medical certificate provided", "follow up required");
	@{ $symptom_actions{"patient has no infection"}} = ("should monitor and report if pain or infection develops");
	@{ $symptom_actions{"patient has infection"}} = ("prescribed antibiotic", "medical certificate provided", "follow up required");

	%options = ();
	@{ $options{1} } = ("patient reported no pain or discomfort", "patient has infection");
	@{ $options{2} } = ("patient reported no pain or discomfort", "patient has no infection");
	@{ $options{3} } = ("patient reported mild pain", "patient has infection");
	@{ $options{4} } = ("patient reported severe pain", "patient has infection");
	@{ $options{5} } = ("patient reported mild pain", "patient has no infection");
	@{ $options{6} } = ("patient reported severe pain", "patient has no infection");
	
	# generate the options for the report
	my $possible_options = scalar keys %options;
	$option = 1 + int(rand($possible_options-1));
	
	if(grep(/emergency care for pain relief/, @treatments)){
		$option = 3 + int(rand($possible_options-3));
	}
	elsif(grep(/routine tooth extractions/, @treatments)){
		$option = 3 + int(rand($possible_options-3));
	}
	
	# randomly choose whether this is consistent with their history
	my $actions_summary = "";
	my $count = 0;
	foreach my $symptom (@{$options{$option}}){
		$count++;
		
		# randomly decide which actions were taken
		my @possible_actions = @{$symptom_actions{$symptom}};
		my @actions_taken;
		foreach my $possible_action (@possible_actions){
			if(int(rand(2)) == 1){
				push(@actions_taken, $possible_action);
			}
		}
		unless(scalar(@actions_taken) > 0){
			my $nactions = scalar @possible_actions;
			my $random_action_index = int(rand($nactions-1));
			push(@actions_taken, $possible_actions[$random_action_index]);
		}
		
		if($count == 1){
			$actions_summary = $actions_summary .  ucfirst $symptom . " so";
		}
		else{
			$actions_summary = $actions_summary . " " . ucfirst $symptom . " so";			
		}
		foreach my $i (0...$#actions_taken){
			if($i == $#actions_taken){
				$actions_summary = $actions_summary . " " . $actions_taken[$i] . ".";
			}
			elsif($i < $#actions_taken-1){
				$actions_summary = $actions_summary . " " . $actions_taken[$i] . ",";
			}
			elsif($i == $#actions_taken-1){
				$actions_summary = $actions_summary . " " . $actions_taken[$i] . ", and";			
			}
		}	
	}
	
	my $dental_report_comment = $treatment_summary . " " . $procedure_summary . " " . $actions_summary;
		
	return \$dental_report_comment;
	
}

sub gaussian_rand {
	
	# adapted from
	# https://www.cs.ait.ac.th/~on/O/oreilly/perl/cookbook/ch02_11.htm
    my ($u1, $u2);  # uniformly distributed random numbers
    my $w;          # variance, then a weight
    my ($g1, $g2);  # gaussian-distributed numbers

    do {
        $u1 = 2 * rand() - 1;
        $u2 = 2 * rand() - 1;
        $w = $u1*$u1 + $u2*$u2;
    } while ( $w >= 1 );

    $w = sqrt( (-2 * log($w))  / $w );
    $g2 = $u1 * $w;
    $g1 = $u2 * $w;
    # return both if wanted, else just one
    
    return \$g1;
}








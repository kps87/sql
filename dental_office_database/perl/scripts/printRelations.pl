#!/usr/bin/perl
use strict;
use warnings;
use Cwd;

my $output_dir = File::Spec->catdir( ( cwd(), "../../sql" ) );

sub write_relations {

	# input data
	my ($ref1) = @_;
	my %input = %{$ref1};
	print "\t-printRelations::write_relations()\n";
	print "\t\t-writing data to $output_dir\n";

	# make the output directory
	unless ( -d $output_dir ) {
		mkdir("$output_dir") or die "cannot mkdir $output_dir $!\n";
	}

	# create one file that just creates tables
	my $create_file = File::Spec->catfile( $output_dir, "create.sql" );
	print "\t-creating file = $create_file\n";
	open( my $fh, ">$create_file" ) or die "cannot open $create_file $!\n";
	write_preamble( \$fh );
	create_tables( \$fh, \%input );
	write_views( \$fh );
	write_keys_and_constraints( \$fh );
	close $fh;

	# create one file that just inserts data
	my $insert_file = File::Spec->catfile( $output_dir, "insert.sql" );
	print "\t-creating file = $insert_file\n";
	open( $fh, ">$insert_file" ) or die "cannot open $insert_file $!\n";
	insert_data( \$fh, \%input );
	close $fh;

	# create one file that creates, inserts and constrains
	my $all_operations =
	  File::Spec->catfile( $output_dir, "create_insert.sql" );
	print "\t-creating file = $all_operations\n";
	open( $fh, ">$all_operations" ) or die "cannot open $all_operations $!\n";
	write_preamble( \$fh );
	create_tables( \$fh, \%input );
	write_views( \$fh );
	write_keys_and_constraints( \$fh );
	insert_data( \$fh, \%input );
	close $fh;

}

sub get_relation_write_order {

	my @tables = (
		"patients",              "accounts",
		"specialists",           "employees",
		"treatments",            "appointments",
		"appointmentTreatments", "bills",
		"payments",              "referrals",
		"dentalReports",

	);

	return @tables;

}

sub get_view_write_order {
	my @views = (
		"billCosts",                    "billPayments",
		"billSummary",                  "overdueBills",
		"accountsInArrears",            "scheduleFortnightlyDetailed",
		"scheduleWeeklyDetailed",       "scheduleSummary",
		"scheduleDetailed",             "doubleBookingDetails",
		"doubleBookingSummary",         "nextWeeksAppointmentsDetailed",
		"todaysAppointments",           "specialistTreatmentsSummary",
		"specialistTreatmentsDetailed", "referralsSummary",
		"patientDentalReportsAll",      "patientDentalReportsLast12Months"
	);
	return @views;
}

sub get_keys {

	my %pks;
	$pks{'patients'}              = 'patientID';
	$pks{'accounts'}              = 'accountNumber';
	$pks{'calendar'}              = 'date';
	$pks{'employees'}             = 'employeeID';
	$pks{'specialists'}           = 'specialistID';
	$pks{'treatments'}            = 'treatmentID';
	$pks{'appointments'}          = 'appointmentID';
	$pks{'referrals'}             = 'referralID';
	$pks{'bills'}                 = 'billNumber';
	$pks{'payments'}              = 'paymentID';
	$pks{'appointmentTreatments'} = 'appTreatID';
	$pks{'dentalReports'}         = 'reportID';

	# define foreign keys through arrays
	# which reference primary keys above
	my %fks;
	@{ $fks{'accounts'} }     = ('patients');
	@{ $fks{'appointments'} } = ( 'patients', 'employees', 'specialists' );
	@{ $fks{'referrals'} }    = ( 'patients', 'employees', 'specialists' );
	@{ $fks{'bills'} }        = ( 'accounts', 'appointments' );
	@{ $fks{'payments'} }     = ( 'accounts', 'bills' );
	@{ $fks{'treatments'} }   = ('specialists');
	@{ $fks{'appointmentTreatments'} } = ( 'appointments', 'treatments' );
	@{ $fks{'dentalReports'} } =
	  ( 'appointments', 'referrals', );    # 'patients', 'specialists'

	# return the keys
	my %keys;
	%{ $keys{'pks'} } = %pks;
	%{ $keys{'fks'} } = %fks;
	return \%keys;

}

sub get_attribute_write_options {

	my ( $ref1, $ref2 ) = @_;
	my $relation_name = ${$ref1};
	my @attributes    = @{$ref2};

	# a specific CHECK for referral ID
	my $referral_check =
"CHECK((\`appointmentID\` is NOT NULL OR \`referralID\` is NOT NULL) AND  ((\`appointmentID\` is NULL and \`referralID\` is NOT NULL) OR (\`referralID\` is NULL and \`appointmentID\` is NOT NULL)))";

	# definition of print settings for 'generic' columns
	my %default;
	$default{"accountNumber"}{'write_format'} = 'string';
	$default{"accountNumber"}{'type'} =
'char(9) NOT NULL CHECK(LENGTH(`accountNumber`) > 1 AND LENGTH(`accountNumber`) <= 9)';
	$default{"address"}{'write_format'}       = "string";
	$default{"address"}{'type'}               = "varchar(200) NOT NULL CHECK(LENGTH(`address`) > 0 AND LENGTH(`address`) <= 200)";
	$default{"amount"}{'write_format'}        = "float";
	$default{"amount"}{'type'}                = "float NOT NULL CHECK (`amount` > 0)";
	$default{"appointmentID"}{'write_format'} = "string";
	$default{"appointmentID"}{'type'}         = "char(10) NOT NULL CHECK(LENGTH(`appointmentID`) = 10)";
	$default{"appTreatID"}{'write_format'}    = "string";
	$default{"appTreatID"}{'type'}            = "char(15) NOT NULL CHECK(LENGTH(`appTreatID`) = 15)";
	$default{"billNumber"}{'write_format'}    = "string";
	$default{"billNumber"}{'type'}            = "char(7) NOT NULL CHECK(LENGTH(`billNumber`) = 7)";
	$default{"closedDate"}{'write_format'}    = "string";
	$default{"closedDate"}{'type'}            = "date DEFAULT NULL";
	$default{"comment"}{'write_format'}       = "string";
	$default{"comment"}{'type'}               = "varchar(1000) NOT NULL CHECK(LENGTH(`comment`) > 0 AND LENGTH(`comment`) <= 1000)";
	$default{"cost"}{'write_format'}          = "float";
	$default{"cost"}{'type'}                  = "float DEFAULT NULL CHECK (`cost` > 0)";
	$default{"date"}{'write_format'}          = "string";
	$default{"date"}{'type'}                  = "date NOT NULL";
	$default{"dob"}{'write_format'}           = "string";
	$default{"dob"}{'type'}                   = "date NOT NULL";
	$default{"dueDate"}{'write_format'}       = "string";
	$default{"dueDate"}{'type'}               = "date NOT NULL";
	$default{"email"}{'write_format'}         = "string";
	$default{"email"}{'type'}                 = "varchar(100) DEFAULT NULL";
	$default{"endTime"}{'write_format'}       = "time";
	$default{"endTime"}{'type'}               = "time NOT NULL";
	$default{"employeeID"}{'write_format'}    = "string";
	$default{"employeeID"}{'type'}            = "char(4) NOT NULL CHECK(LENGTH(`employeeID`) = 4)";
	$default{"firstname"}{'write_format'}     = "string";
	$default{"firstname"}{'type'}             = "varchar(50) NOT NULL CHECK(LENGTH(`firstname`) > 0 AND LENGTH(`firstname`) <= 50)";
	$default{"gender"}{'write_format'}        = "string";
	$default{"gender"}{'type'}                = "varchar(10) DEFAULT NULL";
	$default{"issueDate"}{'write_format'}     = "string";
	$default{"issueDate"}{'type'}             = "date NOT NULL";
	$default{"openedDate"}{'write_format'}    = "string";
	$default{"openedDate"}{'type'}            = "date NOT NULL";
	$default{"patientID"}{'write_format'}     = "string";
	$default{"patientID"}{'type'}             = "char(6) NOT NULL CHECK(LENGTH(`patientID`) = 6)";
	$default{"paymentDate"}{'write_format'}   = "string";
	$default{"paymentDate"}{'type'}           = "date NOT NULL";
	$default{"paymentID"}{'write_format'}     = "string";
	$default{"paymentID"}{'type'}             = "char(7) NOT NULL CHECK(LENGTH(`paymentID`) = 7)";
	$default{"paymentType"}{'write_format'}   = "string";
	$default{"paymentType"}{'type'}           = "varchar(20) NOT NULL CHECK(LENGTH(`paymentType`) > 0 AND LENGTH(`paymentType`) <= 20)";
	$default{"phoneNumber"}{'write_format'}   = "string";
	$default{"phoneNumber"}{'type'}           = "varchar(30) NOT NULL CHECK(LENGTH(`phoneNumber`) > 0 AND LENGTH(`phoneNumber`) <= 30)";
	$default{"pps"}{'write_format'}           = "string";
	$default{"pps"}{'type'}                   = "char(9) DEFAULT NULL";
	$default{"referralID"}{'write_format'}    = "string";
	$default{"referralID"}{'type'}            = "char(10) NOT NULL CHECK(LENGTH(`referralID`) = 10)";
	$default{"reportDate"}{'write_format'}    = "string";
	$default{"reportDate"}{'type'}            = "date NOT NULL";
	$default{"reportID"}{'write_format'}      = "string";
	$default{"reportID"}{'type'}              = "char(8) NOT NULL CHECK(LENGTH(`reportID`) = 8)";
	$default{"role"}{'write_format'}          = "string";
	$default{"role"}{'type'}                  = "varchar(50) NOT NULL CHECK(LENGTH(`role`) > 0 AND LENGTH(`role`) <= 50)";
	$default{"specialistID"}{'write_format'}  = "string";
	$default{"specialistID"}{'type'}          = "char(7) NOT NULL CHECK(LENGTH(`specialistID`) = 7)";
	$default{"startDate"}{'write_format'}     = "string";
	$default{"startDate"}{'type'}             = "date NOT NULL";
	$default{"status"}{'write_format'}        = "string";
	$default{"status"}{'type'}                = "varchar(20) NOT NULL CHECK(LENGTH(`status`) > 0 AND LENGTH(`status`) <= 20)";
	$default{"surname"}{'write_format'}       = "string";
	$default{"surname"}{'type'}               = "varchar(50) NOT NULL CHECK(LENGTH(`surname`) > 0 AND LENGTH(`surname`) <= 50)";
	$default{"startTime"}{'write_format'}     = "time";
	$default{"startTime"}{'type'}             = "time NOT NULL";
	$default{"treatmentID"}{'write_format'}   = "string";
	$default{"treatmentID"}{'type'}           = "char(7) NOT NULL CHECK(LENGTH(`treatmentID`) = 7)";
	$default{"treatmentType"}{'write_format'} = "string";
	$default{"treatmentType"}{'type'}         = "varchar(100) NOT NULL CHECK(LENGTH(`treatmentType`) > 0 AND LENGTH(`treatmentType`) <= 100)";

	# definition of print settings for specific columns
	my %specific;

	$specific{'dentalReports'}{"appointmentID"}{'write_format'} = 'string';
	$specific{'dentalReports'}{"appointmentID"}{'type'} =
	  'char(10) DEFAULT NULL';
	$specific{'dentalReports'}{"referralID"}{'write_format'} =
	  'string';
	$specific{'dentalReports'}{"referralID"}{'type'} =
	  "char(10) DEFAULT NULL $referral_check";

	# first populate a hash with print settings for generics,
	# then if there are specifics - override
	my %write_options;
	foreach my $attribute (@attributes) {
		if ( exists( $specific{$relation_name}{$attribute} ) ) {
			my %settings = %{ $specific{$relation_name}{$attribute} };
			%{ $write_options{$attribute} } = %settings;
		}
		else {
			%{ $write_options{$attribute} } = %{ $default{$attribute} };
		}
	}

	return \%write_options;

}

sub get_relation_attributes {

	my ($ref1) = @_;
	my $relation = ${$ref1};

	my %relation_attributes;

	@{ $relation_attributes{'accounts'} } =
	  ( 'accountNumber', 'closedDate', 'openedDate', 'patientID' );
	@{ $relation_attributes{'appointments'} } = (
		'appointmentID', 'date',   'employeeID', 'patientID',
		'specialistID',  'status', 'startTime',  'endTime'
	);
	@{ $relation_attributes{'appointmentTreatments'} } =
	  ( 'appTreatID', 'appointmentID', 'treatmentID' );
	@{ $relation_attributes{'bills'} } =
	  ( 'accountNumber', 'appointmentID', 'billNumber', 'dueDate',
		'issueDate' );
	@{ $relation_attributes{'dentalReports'} } =
	  ( 'appointmentID', 'comment', 'referralID', 'reportDate', 'reportID' )
	  ;    # 'patientID''specialistID'
	@{ $relation_attributes{'employees'} } =
	  ( 'employeeID', 'firstname', 'role', 'startDate', 'surname' );
	@{ $relation_attributes{'patients'} } = (
		'address', 'dob',       'email',       'firstname',
		'gender',  'patientID', 'phoneNumber', 'pps',
		'surname'
	);
	@{ $relation_attributes{'payments'} } = (
		'accountNumber', 'amount', 'billNumber', 'paymentDate',
		'paymentID',     'paymentType'
	);
	@{ $relation_attributes{'referrals'} } =
	  ( 'employeeID', 'patientID', 'referralID', 'specialistID', 'date' );
	@{ $relation_attributes{'specialists'} } = (
		'address',      'email', 'firstname', 'phoneNumber',
		'specialistID', 'surname'
	);
	@{ $relation_attributes{'treatments'} } =
	  ( 'cost', 'specialistID', 'treatmentID', 'treatmentType' );

	@{ $relation_attributes{'calendar'} } =
	  ('date');

	return @{ $relation_attributes{$relation} };

}

sub write_preamble {

	my ($ref1) = @_;
	my $fh = ${$ref1};

	my @relations = get_relation_write_order();
	my @views     = get_view_write_order();
	print "\t\t-write_preamble()\n";
	
	# some basic options
	print $fh "SET SQL_MODE = \"NO_AUTO_VALUE_ON_ZERO\";\n";
	print $fh "SET time_zone = \"+00:00\";\n";
	print $fh "\n\n";
	
	
	# drop the tables
	write_table_header( \$fh,
		\'Remove foreign key checks before DROP statements so that database import is fresh\n'
	);
	print $fh "SET FOREIGN_KEY_CHECKS=0;";
	print $fh "\n\n";
	
	
	

	# drop the tables
	write_table_header( \$fh,
		\'Drop all tables if they already exist - want to do a fresh import every time'
	);
	foreach my $relation (@relations) {
		print $fh "DROP TABLE IF EXISTS `$relation`;\n";
	}
	print $fh "\n\n";

	# drop the views
	write_table_header( \$fh,
		\'Drop all views if they already exist - want to do a fresh import every time'
	);
	foreach my $view (@views) {
		print $fh "DROP VIEW IF EXISTS `$view`;\n";
	}
	print $fh "\n\n";

	
	# turn foreign key checks back on
	write_table_header( \$fh,
		\'Add foreign key checks before any INSERT statements so that integrity of data preserved\n'
	);	
	print $fh "SET FOREIGN_KEY_CHECKS=1;\n";
	print $fh "\n\n";

}

sub create_tables {

	my ( $ref1, $ref2 ) = @_;
	my $fh        = ${$ref1};
	my %relations = %{$ref2};
	print "\t\t-create_tables()\n";

	# get the array of relation names to print
	my @relations = get_relation_write_order();
	foreach my $relation (@relations) {

		# print a title and get the data for this relation
		print "\t\t\t-creating $relation\n";
		my %data = %{ $relations{$relation} };

		# get the attributes to print, and their print options
		my @attributes = get_relation_attributes( \$relation );
		my %write_options =
		  %{ get_attribute_write_options( \$relation, \@attributes ) };

		# print the table structure
		my $header = "Creating table structure for $relation";
		write_table_header( \$fh, \$header );
		write_table_structure( \$fh, \$relation, \@attributes,
			\%write_options );

	}

}

sub insert_data {

	my ( $ref1, $ref2 ) = @_;
	my $fh        = ${$ref1};
	my %relations = %{$ref2};
	print "\t\t-insert_data()\n";

	# get the array of relation names to print
	my @relations = get_relation_write_order();
	foreach my $relation (@relations) {

		# print a title and get the data for this relation
		print "\t\t\t-inserting data $relation\n";
		my %data = %{ $relations{$relation} };

		# get the attributes to print, and their print options
		my @attributes = get_relation_attributes( \$relation );
		my %write_options =
		  %{ get_attribute_write_options( \$relation, \@attributes ) };

		# print the table data
		my $header = "Inserting table data for $relation";
		write_table_header( \$fh, \$header );
		write_table_data( \$fh, \$relation, \@attributes, \%write_options,
			\%data );

	}

}

sub write_keys_and_constraints {

	my ($ref1) = @_;
	my $fh = ${$ref1};

	print "\t\t-write_keys_and_constraints()\n";

	# define primary keys in each relation
	my %keys = %{ get_keys() };
	my %pks  = %{ $keys{'pks'} };
	my %fks  = %{ $keys{'fks'} };

	# an array with the order in which each relation
	# should be printed
	my @relations = get_relation_write_order();

	# add the keys
	write_table_header( \$fh, \'Indexes for dumped tables' );
	print $fh "\n\n";
	foreach my $relation (@relations) {

		next if ( $relation eq 'calendar' );

		my $title = "Indexes for table `$relation`";
		write_table_header( \$fh, \$title );
		print $fh "ALTER TABLE `$relation`\n";
		print $fh "\tADD PRIMARY KEY (`$pks{$relation}`)";
		if ( exists( $fks{$relation} ) ) {
			print $fh ",\n";
			my @fks = @{ $fks{$relation} };
			for my $i ( 0 ... $#fks ) {
				my $fk = ${ $fks{$relation} }[$i];
				print $fh "\tADD KEY `$pks{$fk}` (`$pks{$fk}`)";
				if ( $i < $#fks ) {
					print $fh ",\n";
				}
			}
		}
		print $fh ";\n\n";
	}

	# add constraints
	write_table_header( \$fh, \'Constraints for dumped tables' );
	print $fh "\n\n";
	foreach my $relation (@relations) {
		if ( exists( $fks{$relation} ) ) {
			my $title = "Constraints for table `$relation`";
			write_table_header( \$fh, \$title );
			print $fh "ALTER TABLE `$relation`\n";
			my @fks = @{ $fks{$relation} };
			for my $i ( 0 ... $#fks ) {
				my $constraint_name = $relation . "_fk_" . ( $i + 1 );
				my $fk              = ${ $fks{$relation} }[$i];
				print $fh
"\tADD CONSTRAINT `$constraint_name` FOREIGN KEY (`$pks{$fk}`) REFERENCES `$fk` (`$pks{$fk}`)";
				if ( $i < $#fks ) {
					print $fh ",\n";
				}
			}
			print $fh ";\n\n";
		}
	}
}

sub write_views {

	my ($ref1) = @_;
	my $fh = ${$ref1};

	print "\t\t-write_views()\n";

	my $views_file = File::Spec->catfile( ( cwd(), 'inputs' ), 'views.sql' );
	my @views      = genericFileParsers::read_file( \$views_file );
	print $fh $_, "\n" foreach (@views);

}

sub write_table_data {

	my ( $ref1, $ref2, $ref3, $ref4, $ref5 ) = @_;
	my $fh            = ${$ref1};
	my $table_name    = ${$ref2};
	my @attributes    = @{$ref3};
	my %write_options = %{$ref4};
	my %data          = %{$ref5};

	print $fh "INSERT INTO" . " `$table_name` " . "(";

	for my $i ( 0 ... $#attributes ) {
		printf $fh "`%-1s`", $attributes[$i];
		if ( $i < $#attributes ) {
			print $fh ", ";
		}
	}
	print $fh ") VALUES\n";

	my $number_rows = scalar keys %data;
	foreach my $irow ( sort { $a <=> $b } keys %data ) {

		print $fh "(";
		for my $i ( 0 ... $#attributes ) {

			my $write_format =
			  $write_options{ $attributes[$i] }{'write_format'};

			if (   $write_format eq 'string'
				&& $data{$irow}{ $attributes[$i] } ne 'NULL' )
			{
				printf $fh "'%-1s'",
				  ${ escape_disallowed_chars( \$data{$irow}{ $attributes[$i] } )
				  };
			}
			elsif ($write_format eq 'float'
				&& $data{$irow}{ $attributes[$i] } ne 'NULL' )
			{
				printf $fh "%-1.2f", $data{$irow}{ $attributes[$i] };
			}
			elsif ($write_format eq 'time'
				&& $data{$irow}{ $attributes[$i] } ne 'NULL' )
			{
				( my $time = $data{$irow}{ $attributes[$i] } ) =~ s/\-/\:/ig;
				printf $fh "'%-1s'", $time;
			}
			elsif ( $data{$irow}{ $attributes[$i] } eq 'NULL' ) {
				print $fh "NULL";
			}
			if ( $i < $#attributes ) {
				print $fh ",";
			}
		}

		if ( $irow < $number_rows ) {
			print $fh "),\n";
		}
		else {
			print $fh ");\n";
		}

	}
	print $fh "\n\n";

}

sub escape_disallowed_chars {

	my ($ref1) = @_;
	my $var = ${$ref1};
	$var =~ s/'/''/ig;
	return \$var;

}

sub write_table_header {

	my ( $ref1, $ref2 ) = @_;
	my $fh     = ${$ref1};
	my $header = ${$ref2};

	print $fh "--\n";
	print $fh "-- $header\n";
	print $fh "--\n";

}

sub write_table_structure {

	my ( $ref1, $ref2, $ref3, $ref4 ) = @_;
	my $fh            = ${$ref1};
	my $table_name    = ${$ref2};
	my @attributes    = @{$ref3};
	my %write_options = %{$ref4};

	print $fh "CREATE TABLE" . " `$table_name` " . "(\n";
	for my $i ( 0 ... $#attributes ) {

		if ( $i < $#attributes ) {
			printf $fh "`%-1s` %-1s,\n", $attributes[$i],
			  $write_options{ $attributes[$i] }{'type'};
		}
		else {
			printf $fh "`%-1s` %-1s\n", $attributes[$i],
			  $write_options{ $attributes[$i] }{'type'};
		}
	}
	print $fh ") ENGINE=InnoDB DEFAULT CHARSET=latin1;\n";
	print $fh "\n\n";

}

1;

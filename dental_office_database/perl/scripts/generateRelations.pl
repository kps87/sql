#!/usr/bin/perl
use strict;
use warnings;
use Cwd;
use Calendar::Simple;
use List::Util qw(shuffle);
use List::MoreUtils qw(firstidx);
use Time::HiRes qw(gettimeofday tv_interval);
use Statistics::Basic qw(:all);
use FindBin;
use lib "$FindBin::Bin/../packages";
use genericFileParsers;
use randomDataGenerator;

# generate a list of appointment slots
my %appointments_calendar;
my @work_days;
my $today;
my $min_working_year;
my $max_working_year;
my $min_dob;
my $max_dob;

sub generate_relations {

	# input data
	my ($ref1)                = @_;
	my %input                 = %{$ref1};
	my $number_of_patients    = $input{'number_of_patients'};
	my $number_of_specialists = $input{'number_of_specialists'};

	# print a header to screen
	print "\t-generateRelations::generate_relations()\n";

	# set the options and generate calendars
	set_options();

	# declare the relations hash, and a randomDataGenerator instance
	my %relations;    # return hash
	my $random = randomDataGenerator->new();
	$random->set_data();

	# generate relations 1 and 2
	my %patients = %{ generate_patients( \$random, \$number_of_patients ) };
	my %accounts = %{ generate_accounts( \$random, \%patients ) };
	%{ $relations{'patients'} } = %patients;
	%{ $relations{'accounts'} } = %accounts;

	# generate relation 7

	my %specialists =
	  %{ generate_specialists( \$random, \$number_of_specialists ) };
	%{ $relations{'specialists'} } = %specialists;

	# generate treaments = relation 8
	# and another hash of treatments for generating other relations
	my %treatment_data = %{ generate_treatments( \$random, \%specialists ) };
	my %treatments     = %{ $treatment_data{'treatments'} };
	my %specialists_treatments = %{ $treatment_data{'specialists_treatments'} };
	%{ $relations{'treatments'} }             = %treatments;
	%{ $relations{'specialists_treatments'} } = %specialists_treatments;

	# generate relation 5
	my %employees = %{ generate_employees( \$random ) };
	%{ $relations{'employees'} } = %employees;

	# generate relation 6 and 10 - appointments and appointment treatments
	my %generate_appointments_input;
	$generate_appointments_input{'random'} = $random;
	%{ $generate_appointments_input{'employees'} }   = %employees;
	%{ $generate_appointments_input{'patients'} }    = %patients;
	%{ $generate_appointments_input{'accounts'} }    = %accounts;
	%{ $generate_appointments_input{'specialists'} } = %specialists;
	%{ $generate_appointments_input{'treatments'} }  = %treatments;
	%{ $generate_appointments_input{'specialists_treatments'} } =
	  %specialists_treatments;

	my %results = %{ generate_appointments( \%generate_appointments_input ) };
	my %app_treatments = %{ $results{'appointmentTreatments'} };
	my %appointments   = %{ $results{'appointments'} };
	my %referrals      = %{ $results{'referrals'} };
	my %ref_treatments = %{ $results{'referralTreatments'} };
	%{ $relations{'appointments'} }          = %appointments;
	%{ $relations{'appointmentTreatments'} } = %app_treatments;
	%{ $relations{'referrals'} }             = %referrals;
	%{ $relations{'referralTreatments'} }    = %ref_treatments;

	# relation 4-bill
	my %bills = %{ generate_bills( \%appointments, \%patients, \%accounts ) };
	%{ $relations{'bills'} } = %bills;

	# need to generate relation 3-payment
	my %generate_payments_input;
	$generate_payments_input{'random'} = $random;
	%{ $generate_payments_input{'bills'} }          = %bills;
	%{ $generate_payments_input{'patients'} }       = %patients;
	%{ $generate_payments_input{'accounts'} }       = %accounts;
	%{ $generate_payments_input{'treatments'} }     = %treatments;
	%{ $generate_payments_input{'app_treatments'} } = %app_treatments;
	%{ $generate_payments_input{'appointments'} }   = %appointments;
	my %payments = %{ generate_payments( \%generate_payments_input ) };
	%{ $relations{'payments'} } = %payments;

	#	# need to generate relation 9-dental reports
	my %dental_report_input;
	$dental_report_input{'random'} = $random;
	%{ $dental_report_input{'referrals'} }      = %referrals;
	%{ $dental_report_input{'ref_treatments'} } = %ref_treatments;
	%{ $dental_report_input{'appointments'} }   = %appointments;
	%{ $dental_report_input{'app_treatments'} } = %app_treatments;
	%{ $dental_report_input{'treatments'} }     = %treatments;
	my %dental_reports = %{ generate_dental_reports( \%dental_report_input ) };
	%{ $relations{'dentalReports'} } = %dental_reports;

	# generate a calendar table
	%{ $relations{'calendar'} } = %{ generate_working_day_calendar() };
	return \%relations;

}

sub set_options {

	print "\t-set_options()\n";

	# set todays date
	$today = sprintf "%04d-%02d-%02d", 2020, 05, 01;

	# read in the options file
	my $options_file =
	  File::Spec->catfile( ( cwd(), 'inputs' ), 'options.txt' );
	my @options = genericFileParsers::read_file( \$options_file );

	my %options;
	for my $i ( 0 ... $#options ) {
		if ( $options[$i] =~ /\w+/ ) {
			chomp $options[$i];
			@_ = split( /\t+/, $options[$i] );
			$options{ $_[0] } = $_[1];
		}
	}

	# set some global variables from options
	$min_working_year = $options{'min_working_year'};
	$max_working_year = $options{'max_working_year'};
	$min_dob          = $options{'min_dob'};
	$max_dob          = $options{'max_dob'};

	# setup the calendars
	set_working_day_calendar( \$min_working_year, \$max_working_year );
	%appointments_calendar = %{ generate_appointments_calendar() };

}

sub generate_working_day_calendar {

	set_working_day_calendar( \2020, \2025 );
	my %calendar;

	for my $i ( 0 ... $#work_days ) {
		$calendar{ $i + 1 }{'date'} = $work_days[$i];
	}
	return \%calendar;

}

sub generate_patients {

	# input data
	my ( $ref1, $ref2 ) = @_;
	my $generate_random    = ${$ref1};
	my $number_of_patients = ${$ref2};

	# declare the hash to be returned
	my %patients;

	# print a title to screen so user can monitor progress
	print
"\t\t-generate_patients()->generating $number_of_patients random patients\n";

	# these are the fields required of a patient in relational database
	my @string_fields = (
		"firstname", "surname",  "gender", "address1",
		"address2",  "address3", "county"
	);
	my $min_date = $min_dob;    # earliest allowed birth day
	my $max_date = $max_dob;    # latest allowed birth day

	# an id assigned to patients
	for my $i ( 1 ... $number_of_patients ) {

		# generate random text fields using the randomDataGenerator.pm package

		# generate a unique id
		$patients{$i}{'patientID'} = "p" . sprintf "%05d", $i;

		foreach my $string_fields (@string_fields) {
			my $string = ${ $generate_random->stringField( \$string_fields ) };
			$patients{$i}{$string_fields} = $string;
		}

		# generate address from components
		$patients{$i}{'address'} =
			${ $generate_random->houseNumber() } . " "
		  . $patients{$i}{'address1'} . " "
		  . $patients{$i}{'address2'} . ", "
		  . $patients{$i}{'address3'} . ", "
		  . $patients{$i}{'county'};

		# generate other properties - phone, pps number, email
		$patients{$i}{'phoneNumber'} = ${ $generate_random->phoneNumber() };
		$patients{$i}{'pps'}         = ${ $generate_random->pps() };
		$patients{$i}{'email'}       = ${
			$generate_random->email(
				\$patients{$i}{firstname},
				\$patients{$i}{surname},
				\0, \1
			)
		};

		# generate a date of birth in range of min and max date
		$patients{$i}{'dob'} =
		  ${ $generate_random->date( \$min_date, \$max_date ) };

	}
	
	# make me the first patinet
	$patients{1}{'firstname'} = "Kieran";
	$patients{1}{'surname'} = "Somers";
	$patients{1}{'gender'} = "M";
	$patients{1}{'email'} = "g00221349\@gmit.ie";

	# return the hash array
	return \%patients;

}

sub generate_accounts {

	# input data
	my ( $ref1, $ref2 ) = @_;
	my $generate_random = ${$ref1};
	my %patients        = %{$ref2};

	# declare the hash to be returned
	my %accounts;

	# print a title to screen so user can monitor progress
	print "\t\t-generate_accounts()->generating accounts for ",
	  scalar keys %patients, " patients\n";

	# set the min and max date for opening and closing the account
	my $latest_account_creation_date = $today;
	my @open_dates;
	my @work_days =
	  get_working_days_before_date( \$latest_account_creation_date );
	my $number_work_days = scalar @work_days;

	# assign a random account opening date
	foreach my $ipatient ( sort { $a <=> $b } keys %patients ) {
		my $open_date = $work_days[ int( rand( $number_work_days - 1 ) ) ];
		push( @open_dates, $open_date );
	}
	@open_dates = sort @open_dates;

	# generate an account for each patient
	my $i = 0;

	foreach my $ipatient ( sort { $a <=> $b } keys %patients ) {

		# generate a unique id and associate with a patient ID
		$i++;
		$accounts{$i}{'accountNumber'} = sprintf "acc%06d", $i;
		$accounts{$i}{'patientID'}     = $patients{$ipatient}{'patientID'};

		# generate the account open date
		$accounts{$i}{'openedDate'} = $open_dates[ $i - 1 ];

		# generate the account closed date -- 1/100 chance its closed
		if ( ( 1 + int( rand(100) ) ) % 10 == 0 ) {
			@work_days = get_working_days_between_dates( \$open_dates[ $i - 1 ],
				\$latest_account_creation_date );
			$number_work_days = scalar @work_days;
			my $closed_date =
			  $work_days[ int( rand( $number_work_days - 1 ) ) ];
			$accounts{$i}{'closedDate'} = $closed_date;
		}
		else {
			$accounts{$i}{'closedDate'} = "NULL";
		}
	}

	# return the hash array
	return \%accounts;

}

sub generate_specialists {

	# input data
	my ( $ref1, $ref2 ) = @_;
	my $random                = ${$ref1};
	my $number_of_specialists = ${$ref2};

	# print a title to screen so user can monitor progress
	print
"\t\t-generate_specialists()->generating $number_of_specialists random specialists\n";

	# declare the hash to be returned
	my %specialists;

	# the string fields which need to be generated for a specialist
	my @string_fields =
	  ( "firstname", "surname", "address1", "address2", "address3", "county" );

	# Always add mary mulcahy as specialist number 1
	# These data are hard-coded in
	$specialists{1}{firstname}    = "Mary";
	$specialists{1}{surname}      = "Mulcahy";
	$specialists{1}{address}      = "42 Flood Avenue, Main Street, Cork";
	$specialists{1}{specialistID} = "sp00001";
	$specialists{1}{phoneNumber}  = "0865678945";
	$specialists{1}{email}        = "marymulcahy\@corkdental.ie";
	$specialists{1}{specialistID} = "sp00001";

	# now generate the rest of the specialists
	my $specialist_number = 1;
	for my $i ( 2 ... $number_of_specialists + 1 ) {

		# generate random text fields
		$specialist_number++;
		foreach my $string_fields (@string_fields) {
			my $string = ${ $random->stringField( \$string_fields ) };
			$specialists{$i}{$string_fields} = $string;

		}

		# generate address from components
		$specialists{$i}{'address'} =
			${ $random->houseNumber() } . " "
		  . $specialists{$i}{'address1'} . " "
		  . $specialists{$i}{'address2'} . ", "
		  . $specialists{$i}{'address3'} . ", " . "Cork";

		# generate other properties - phone number, email
		$specialists{$i}{'phoneNumber'} = ${ $random->phoneNumber() };
		$specialists{$i}{'email'}       = ${
			$random->email(
				\$specialists{$i}{firstname},
				\$specialists{$i}{surname},
				\0, \0
			)
		};

		# generate a unique id
		$specialists{$i}{'specialistID'} = sprintf "sp%05d", $i;

	}

	# return the hash array
	return \%specialists;

}

sub generate_treatments {

	# input date
	my ( $ref1, $ref2 ) = @_;
	my $random      = ${$ref1};
	my %specialists = %{$ref2};

	# print a title to screen so user can monitor progress
	print
"\t\t-generate_treatments()->generating list of treatments that each specialist can carry out\n";

	# some variables used to define whether treatments are in house or referral
	my @referral_treatments = @{ $random->{'referral_treatment'} };
	my @inhouse_treatments  = @{ $random->{'inhouse_treatment'} };
	my %treatment_info      = %{ $random->{'treatments'} };

	# a hash array of treatments
	my %treatments;

	# stored the list of treatments which each specialist can carry out
	my %specialists_treatments;

	# add data to the treatments hash
	# need to account for late cancellations
	# so that bills can be generated
	my $treatment_id = 1;
	$treatments{$treatment_id}{'treatmentID'} = "tr" . sprintf "%05d",
	  $treatment_id;
	$treatments{$treatment_id}{'specialistID'}  = 'sp00001';
	$treatments{$treatment_id}{'treatmentType'} = "late cancellation";
	$treatments{$treatment_id}{'cost'}          = 10;

	# generate treatments for known specialist mary mulcahy
	foreach my $treatment (@inhouse_treatments) {

		# increment a counter
		$treatment_id++;

		# get the minimum and maximum cost for that treatment
		my $min_cost                  = $treatment_info{$treatment}{'min'};
		my $max_cost                  = $treatment_info{$treatment}{'max'};
		my $treatment_id_print_format = "tr" . sprintf "%05d", $treatment_id;

		# add this treatment to a list of treatments
		# which that specialist can carry out
		push(
			@{ $specialists_treatments{'sp00001'} },
			$treatment_id_print_format
		);

		# add data to the treatments hash
		$treatments{$treatment_id}{'treatmentID'}  = $treatment_id_print_format;
		$treatments{$treatment_id}{'specialistID'} = 'sp00001';
		$treatments{$treatment_id}{'treatmentType'} = $treatment;
		$treatments{$treatment_id}{'cost'} =
		  $min_cost + int( rand( $max_cost - $min_cost ) );
	}

	# generate treatments for random specialists
	foreach my $specialist ( sort { $a <=> $b } keys %specialists ) {

		if ( $specialists{$specialist}{'specialistID'} eq 'sp00001' ) {

			# specialist one has hard-coded treatments
		}
		else {

			# generate some random treatments
			my @random_treatments =
			  @{ $random->random_sub_array( \@referral_treatments ) };

			# now foreach treatment add it to the treatments list
			foreach my $treatment (@random_treatments) {

				# increase the counters
				$treatment_id++;

				# assign the treatment id
				my $treatment_id_print = sprintf "tr%05d", $treatment_id;
				$treatments{$treatment_id}{'treatmentID'} = $treatment_id_print;
				$treatments{$treatment_id}{'specialistID'} =
				  $specialists{$specialist}{'specialistID'};
				$treatments{$treatment_id}{'treatmentType'} = $treatment;

				# do not assign a cost for referred treatments
				$treatments{$treatment_id}{'cost'} = "NULL";

			   # add the treatment to the list of treatments for this specialist
				my $specialist_id = $specialists{$specialist}{'specialistID'};
				push(
					@{ $specialists_treatments{$specialist_id} },
					$treatment_id_print
				);
			}
		}
	}

	# return the hash arrays
	my %return_data;
	%{ $return_data{'treatments'} }             = %treatments;
	%{ $return_data{'specialists_treatments'} } = %specialists_treatments;
	return \%return_data;

}

sub generate_employees {

	# input date
	my ($ref1) = @_;
	my $generate_random = ${$ref1};
	my %employees;

	# print a title to screen so user can monitor progress
	print "\t\t-generate_employees()\n";

	# assign a minimum and maximum contract start date
	my $min_date = $min_working_year . "-01-01";
	my $max_date = $today;

	# generate Helen
	$employees{1}{'employeeID'} = "e" . sprintf "%03d", 1;
	$employees{1}{'firstname'}  = "Helen";
	$employees{1}{'surname'} =
	  ${ $generate_random->stringField( \'surname' ) };
	$employees{1}{'startDate'} = $min_date;
	$employees{1}{'endDate'}   = "NULL";
	$employees{1}{'role'}      = "secretary";

	# generate a random temp employee
	$employees{2}{'employeeID'} = "e" . sprintf "%03d", 2;
	$employees{2}{'firstname'} =
	  ${ $generate_random->stringField( \'firstname' ) };
	$employees{2}{'surname'} =
	  ${ $generate_random->stringField( \'surname' ) };
	$employees{2}{'startDate'} =
	  ${ $generate_random->date( \$min_date, \$max_date ) };
	$employees{2}{'endDate'} = "NULL";
	$employees{2}{'role'}    = "temporary secretary";

	# generate a random temp employee
	$employees{3}{'employeeID'} = "e" . sprintf "%03d", 3;
	$employees{3}{'firstname'} =
	  ${ $generate_random->stringField( \'firstname' ) };
	$employees{3}{'surname'} =
	  ${ $generate_random->stringField( \'surname' ) };
	$employees{3}{'startDate'} =
	  ${ $generate_random->date( \$min_date, \$max_date ) };
	$employees{3}{'endDate'} = "NULL";
	$employees{3}{'role'}    = "temporary secretary";

	# return the employees hash
	return \%employees;

}

sub generate_appointments {

	my ($ref1)                      = @_;
	my %generate_appointments_input = %{$ref1};
	my $random                      = $generate_appointments_input{'random'};
	my %employees   = %{ $generate_appointments_input{'employees'} };
	my %patients    = %{ $generate_appointments_input{'patients'} };
	my %accounts    = %{ $generate_appointments_input{'accounts'} };
	my %specialists = %{ $generate_appointments_input{'specialists'} };
	my %treatments  = %{ $generate_appointments_input{'treatments'} };
	my %specialists_treatments =
	  %{ $generate_appointments_input{'specialists_treatments'} };
	print "\t\t-generate_appointments()\n";

	# the hash to return
	my %apps;
	my %apps_treats;

	# generate a dictionary of the number of years
	# a patient has been with the clinic
	# this will determine the number of appointments
	my %patient_years;
	my %patient_account;
	foreach my $ipatient ( sort { $a <=> $b } keys %patients ) {
		foreach my $iaccount ( sort { $a <=> $b } keys %accounts ) {
			if ( $patients{$ipatient}{'patientID'} eq
				$accounts{$iaccount}{'patientID'} )
			{
				# assign open and closed date to variables
				my $start_date  = $accounts{$iaccount}{'openedDate'};
				my $closed_date = $accounts{$iaccount}{'closedDate'};
				$patient_account{ $patients{$ipatient}{'patientID'} }
				  {'start_date'} = $start_date;
				$patient_account{ $patients{$ipatient}{'patientID'} }
				  {'closed_date'} = $closed_date;

				# split to get year
				@_ = split( /\-/, $start_date );
				my $start_year = $_[0];
				my $end_year   = $max_working_year;

				if ( $closed_date ne "NULL" ) {
					@_        = split( /\-/, $closed_date );
					$end_year = $_[0];
				}

				my $nyears = 1 + ( $end_year - $start_year );
				$patient_years{ $patients{$ipatient}{'patientID'} } = $nyears;
				last;
			}
		}
	}

	# foreach patient, generate their first appointments
	my $iapp;
	my $iapp_treat;
	print "\t\t\t-gen. ordered appointments\n";
	foreach my $ipatient ( sort { $a <=> $b } keys %patients ) {

		# generate between 1 and 3 treatments
		# and the patient id
		my $number_treatments = 1 + int( rand(3) );
		my $patient_id        = $patients{$ipatient}{'patientID'};

		# get the next free appointment slots
		my $min_date = $patient_account{$patient_id}{'start_date'};
		my $max_date = $patient_account{$patient_id}{'closed_date'};

		my %slot = %{
			get_next_free_appointment_slot( \$min_date, \$max_date,
				\$number_treatments )
		};

		# assign app and patient ID
		$iapp++;

		# assign the app id, patient id, treatment list id
		$apps{$iapp}{'appointmentID'} = sprintf "app%07d", $iapp;
		$apps{$iapp}{'patientID'}     = $patient_id;
		$apps{$iapp}{'date'}          = $slot{'date'};
		$apps{$iapp}{'startTime'}     = $slot{'start'};
		$apps{$iapp}{'endTime'}       = $slot{'end'};
		$apps{$iapp}{'status'}        = 'completed';

		# assign mary mulcahy for first visit
		my $specialist_id = "sp00001";
		$apps{$iapp}{'specialistID'} = $specialist_id;
		$apps{$iapp}{'type'}         = "In-house";

		# assign a random employee who created the appointment
		# 5% of the time it should be one of the two temporary employees
		if ( int( rand(100) ) > 95 ) {
			my $n_employees = scalar keys %employees;
			my $emp_number  = 2 + int( rand( $n_employees - 2 ) );
			$apps{$iapp}{'employeeID'} = $employees{$emp_number}{'employeeID'};
		}
		else {
			$apps{$iapp}{'employeeID'} = "e001";
		}

		# assign a treatment
		my @specialist_treatments =
		  @{ $specialists_treatments{$specialist_id} };
		my @random_treatments = @{
			$random->random_treatments( \@specialist_treatments,
				\$number_treatments )
		};

		for my $i ( 0 ... $#random_treatments ) {
			$iapp_treat++;
			$apps_treats{$iapp_treat}{'appTreatID'} = sprintf "appTreat%07d",
			  $iapp_treat;
			$apps_treats{$iapp_treat}{'appointmentID'} = $iapp;
			$apps_treats{$iapp_treat}{'treatmentID'}   = $random_treatments[$i];

		}

	}

	# generate random patient visits
	my @patient_visits =
	  generate_random_patient_visits( \$random, \%patients, \%patient_years );
	print "\t\t\t-generated ", scalar @patient_visits,
	  " random patient visits\n";

	# foreach patient in the randomized visits array
	# generate appointments
	my $today = "2020-04-23";
	print "\t\t\t-gen. random appointments\n";
	my $tick;
	my @gen_times;
	foreach my $ipatient (@patient_visits) {

		# set the number of treatments
		# and the patient id
		$tick = [gettimeofday];
		$iapp++;
		my $number_treatments =
		  1 + int( rand(3) );    # generate between 1 and 3 treatments
		my $patient_id = $patients{$ipatient}{'patientID'};

		# get the next free appointment slots
		my $min_date = $patient_account{$patient_id}{'start_date'};
		my $max_date = $patient_account{$patient_id}{'closed_date'};
		$min_date =
		  ${ get_random_working_day_between( \$min_date, \$max_date ) };

		# generate a day in the future 5% of the time
		# for people whose accounts are not closed
		if ( $max_date eq "NULL" ) {
			if ( int( rand(100) ) > 95 ) {
				$min_date = $today;
			}
		}

		# generate the time slot
		my %slot = %{
			get_next_free_appointment_slot( \$min_date, \$max_date,
				\$number_treatments )
		};

		# assign the app id, patient id, treatment list id
		$apps{$iapp}{'appointmentID'} = sprintf "app%07d", $iapp;
		$apps{$iapp}{'patientID'}     = $patient_id;
		$apps{$iapp}{'date'}          = $slot{'date'};
		$apps{$iapp}{'startTime'}     = $slot{'start'};
		$apps{$iapp}{'endTime'}       = $slot{'end'};

		# is date in future, if so decide if is scheduled or
		# or cancelled
		if ( date_in_future( \$apps{$iapp}{'date'} ) ) {
			$apps{$iapp}{'status'} = 'scheduled';
		}
		else {
			my $randint = int( rand(100) );
			if ( $randint >= 95 ) {
				$apps{$iapp}{'status'} = 'late cancellation';
			}
			else {
				$apps{$iapp}{'status'} = 'completed';
			}
		}

		# assign a random employee who created the appointment
		# 5% of the time it should be one of the two temporary employees
		if ( int( rand(100) ) > 95 ) {
			my $n_employees = scalar keys %employees;
			my $emp_number  = 2 + int( rand( $n_employees - 2 ) );
			$apps{$iapp}{'employeeID'} = $employees{$emp_number}{'employeeID'};
		}
		else {
			$apps{$iapp}{'employeeID'} = "e001";
		}

		# assign a random specialist 20% of the time,
		my $specialist_id;
		if ( int( rand(10) ) > 8 ) {
			my $n_specialists     = scalar keys %specialists;
			my $specialist_number = 2 + int( rand( $n_specialists - 2 ) );
			$specialist_id = $specialists{$specialist_number}{'specialistID'};
			$apps{$iapp}{'specialistID'} = $specialist_id;
			$apps{$iapp}{'type'}         = "Referral";
		}

		# otherwise assign mary mulcahy
		else {
			$specialist_id               = "sp00001";
			$apps{$iapp}{'specialistID'} = $specialist_id;
			$apps{$iapp}{'type'}         = "In-house";
		}

		# assign a treatment for apps. not cancelled
		if ( $apps{$iapp}{'status'} !~ /cancel/ ) {
			my @specialist_treatments =
			  @{ $specialists_treatments{$specialist_id} };
			my @random_treatments = @{
				$random->random_treatments( \@specialist_treatments,
					\$number_treatments )
			};
			for my $i ( 0 ... $#random_treatments ) {
				$iapp_treat++;
				$apps_treats{$iapp_treat}{'appTreatID'} =
				  sprintf "appTreat%07d",
				  $iapp_treat;
				$apps_treats{$iapp_treat}{'appointmentID'} = $iapp;
				$apps_treats{$iapp_treat}{'treatmentID'} =
				  $random_treatments[$i];
			}
		}
		elsif ( $apps{$iapp}{'status'} eq 'late cancellation' ) {
			$iapp_treat++;
			$apps_treats{$iapp_treat}{'appTreatID'} = sprintf "appTreat%07d",
			  $iapp_treat;
			$apps_treats{$iapp_treat}{'appointmentID'} = $iapp;
			$apps_treats{$iapp_treat}{'treatmentID'}   = sprintf "tr%05d", 1;
		}
		push( @gen_times, tv_interval($tick) );
	}

	my $mean_time = sprintf "%1.5f", mean(@gen_times);
	my $stddev    = sprintf "%1.5f", stddev(@gen_times);
	print "\t\t\t-generated ", scalar keys %apps, " appointments\n";
	print "\t\t\t-average appointment time = ", $mean_time, "+-", $stddev, "\n";

	# create a list of dates and appointments
	my %treatment_dates;
	foreach my $iapp ( sort { $a <=> $b } keys %apps ) {
		my $date      = $apps{$iapp}{'date'};
		my $time      = $apps{$iapp}{'startTime'};
		my $date_time = $date . "-" . $time;
		if ( exists( $treatment_dates{$date_time} ) ) {
			print "\t-[warning] $iapp $date_time already scheduled \n";
			$treatment_dates{$date_time} = $iapp;
		}
		else {
			$treatment_dates{$date_time} = $iapp;
		}
	}

	# now sort the appointments into referrals and local appointments
	my $new_app_id = 0;
	my $new_ref_id = 0;
	my %sorted_apps;
	my %sorted_referrals;
	my %old_new_app_id;
	my %old_new_ref_id;
	foreach my $datetime ( sort { $a cmp $b } keys %treatment_dates ) {
		my $old_id = $treatment_dates{$datetime};
		if ( $apps{$old_id}{'type'} eq "In-house" ) {
			$new_app_id++;
			$old_new_app_id{$old_id} = $new_app_id;
			%{ $sorted_apps{$new_app_id} } = %{ $apps{$old_id} };
			$sorted_apps{$new_app_id}{'appointmentID'} = sprintf "app%07d",
			  $new_app_id;
			delete $sorted_apps{$new_app_id}{'type'};
		}
		else {
			$new_ref_id++;
			$old_new_ref_id{$old_id} = $new_ref_id;
			%{ $sorted_referrals{$new_ref_id} } = %{ $apps{$old_id} };
			$sorted_referrals{$new_ref_id}{'referralID'} = sprintf "ref%07d",
			  $new_ref_id;
			$sorted_referrals{$new_ref_id}{'patientID'} =
			  $apps{$old_id}{'patientID'};
			$sorted_referrals{$new_ref_id}{'specialistID'} =
			  $apps{$old_id}{'specialistID'};
			$sorted_referrals{$new_ref_id}{'date'} = $apps{$old_id}{'date'};
			delete $sorted_referrals{$new_ref_id}{'type'};
			delete $sorted_referrals{$new_ref_id}{'appointmentID'};
		}
	}

	# now re-index the appointment-treatments and referral-treatments relation
	my %sorted_apps_treats;
	my %sorted_ref_treats;
	my $new_app_index = 0;
	my $new_ref_index = 0;
	my $count         = 0;
	foreach my $index ( sort { $a <=> $b } keys %apps_treats ) {

		# get the old application id
		my $old_app_id = $apps_treats{$index}{'appointmentID'};

		# sort the appointments
		if ( exists( $old_new_app_id{$old_app_id} ) ) {
			$new_app_index++;
			%{ $sorted_apps_treats{$new_app_index} } =
			  %{ $apps_treats{$index} };
			$sorted_apps_treats{$new_app_index}{'appointmentID'} =
			  sprintf "app%07d", $old_new_app_id{$old_app_id};
		}

		# sort the referrals
		elsif ( exists( $old_new_ref_id{$old_app_id} ) ) {
			$new_ref_index++;
			%{ $sorted_ref_treats{$new_ref_index} } = %{ $apps_treats{$index} };
			$sorted_ref_treats{$new_ref_index}{'referralID'} =
			  sprintf "ref%07d", $old_new_ref_id{$old_app_id};
			$sorted_ref_treats{$new_ref_index}{'refTreatID'} =
			  $sorted_ref_treats{$new_ref_index}{'appTreatID'};
			$sorted_ref_treats{$new_ref_index}{'refTreatID'} =~ s/app/ref/ig;
			delete $sorted_ref_treats{$new_ref_index}{'appointmentID'};
			delete $sorted_ref_treats{$new_ref_index}{'appTreatID'};
		}
	}

	# now re index the appTreatIDs
	# by sorting based on appointement IDs
	my %reindex_app_treats;
	$count = 0;
	foreach my $i (
		sort {
			$sorted_apps_treats{$a}->{appointmentID}
			  cmp $sorted_apps_treats{$b}->{appointmentID}
			  or $sorted_apps_treats{$a}->{treatmentID}
			  cmp $sorted_apps_treats{$b}->{treatmentID}
		} keys %sorted_apps_treats
	  )
	{
		$count++;
		$sorted_apps_treats{$i}{'appTreatID'} = sprintf "appTreat%07d", $count;
		%{ $reindex_app_treats{$count} } = %{ $sorted_apps_treats{$i} };
	}

	# now re index the refTreatIDs
	# by sorting based on appointement IDs
	$count = 0;
	foreach my $i (
		sort {
			$sorted_ref_treats{$a}->{referralID}
			  cmp $sorted_ref_treats{$b}->{referralID}
		} keys %sorted_ref_treats
	  )
	{
		$count++;
		$sorted_ref_treats{$i}{'refTreatID'} = sprintf "refTreat%07d", $count;
	}

	# create a small number of double booked appointmnets
	my $double_bookings = 0;
	my @apps            = keys %sorted_apps;
	my $next_j = 0;
	for ( my $i = $#apps ; $i >= 0 ; $i-- ) {

		# get app1 details
		my $t1                 = $sorted_apps{ $apps[$i] }{'startTime'};
		my $t2                 = $sorted_apps{ $apps[$i] }{'endTime'};
		my $date               = $sorted_apps{ $apps[$i] }{'date'};
		my $status             = $sorted_apps{ $apps[$i] }{'status'};
		my $has_double_booking = 0;

		# if the status is scheduled
		if ( $status eq 'scheduled' ) {

			# loop over array again
			for ( my $j = $next_j ; $j <= $#apps ; $j++ ) {
				
				# if status is scheduled
				if (   $sorted_apps{ $apps[$j] }{'status'} eq 'scheduled'
					&& $i != $j )
				{
					$sorted_apps{ $apps[$j] }{'startTime'} = $t1;
					$sorted_apps{ $apps[$j] }{'endTime'}   = $t2;
					$sorted_apps{ $apps[$j] }{'date'}      = $date;
					$double_bookings++;
					$next_j = $j+1;
					$has_double_booking = 1;
					last;
				}
				
			}
		}
		last if $double_bookings >= 10;
	}
	

	my %return;
	%{ $return{'appointmentTreatments'} } = %reindex_app_treats;
	%{ $return{'appointments'} }          = %sorted_apps;
	%{ $return{'referralTreatments'} }    = %sorted_ref_treats;
	%{ $return{'referrals'} }             = %sorted_referrals;

	return \%return;

}

sub generate_random_patient_visits {

	my ( $ref1, $ref2, $ref3 ) = @_;
	my $random        = ${$ref1};
	my %patients      = %{$ref2};
	my %patient_years = %{$ref3};

	# generate a list of randomized patients so
	# that their visits are not sequential other than the first set of visits
	print "\t\t\t-generating randomized patient appointments\n";
	my $mean                = 2;
	my $stddev              = 1;
	my @randomized_patients = keys %patients;
	@randomized_patients = shuffle(@randomized_patients);
	my @random_patient_visits;

	for my $i ( 0 ... $#randomized_patients ) {

		# assign a random number of total visits
		# based on the number of years they have been a patient
		# and a random number generating from a gaussian random distribution
		my $patient_id = $patients{ $randomized_patients[$i] }{'patientID'};
		my $nyears     = $patient_years{$patient_id};
		for my $j ( 1 ... $nyears ) {
			my $random_float = ${ $random->gaussian_rand() } * $stddev + $mean;
			my $random_int   = int( abs($random_float) );
			my $nvisits      = 1 + $random_int;
			for my $k ( 1 ... $nvisits ) {
				push( @random_patient_visits, $randomized_patients[$i] );
			}
		}
	}

	@random_patient_visits = shuffle(@random_patient_visits);
	return @random_patient_visits;

}

sub generate_bills {

	my ( $ref1, $ref2, $ref3 ) = @_;
	my %appointments = %{$ref1};
	my %patients     = %{$ref2};
	my %accounts     = %{$ref3};
	print "\t\t-generate_bills()\n";

	# declare variables
	my %bills;
	my $billID = 0;

	# generate a lookup table of patient-accounts
	my %patient_account;
	foreach my $ipatient ( sort { $a <=> $b } keys %patients ) {
		foreach my $iaccount ( sort { $a <=> $b } keys %accounts ) {
			if ( $patients{$ipatient}{'patientID'} eq
				$accounts{$iaccount}{'patientID'} )
			{
				$patient_account{ $patients{$ipatient}{'patientID'} } =
				  $accounts{$iaccount}{'accountNumber'};
				last;
			}
		}
	}

	# foreach appointment create a bill
	foreach my $iapp ( sort { $a <=> $b } keys %appointments ) {

		# only generate bills for appointments that were not cancelled
		if (   $appointments{$iapp}{'status'} ne "cancelled"
			&& $appointments{$iapp}{'status'} ne "scheduled" )
		{
			$billID++;

			$bills{$billID}{'billNumber'} = sprintf "b%06d", $billID;

			$bills{$billID}{'appointmentID'} =
			  $appointments{$iapp}{'appointmentID'};
			my $patient_id = $appointments{$iapp}{'patientID'};
			$bills{$billID}{'accountNumber'} = $patient_account{$patient_id};
			$bills{$billID}{'issueDate'}     = $appointments{$iapp}{'date'};
			$bills{$billID}{'dueDate'} =
			  ${ set_due_date( \$bills{$billID}{'issueDate'} ) };
		}

	}

	print "\t\t\t-generated ", scalar keys %bills, " bills\n";

	# return the bills table
	return \%bills;

}

sub generate_payments {

	# input data
	my ($ref1)                  = @_;
	my %generate_payments_input = %{$ref1};
	my $random                  = $generate_payments_input{'random'};
	my %bills                   = %{ $generate_payments_input{'bills'} };
	my %patients                = %{ $generate_payments_input{'patients'} };
	my %accounts                = %{ $generate_payments_input{'accounts'} };
	my %treatments              = %{ $generate_payments_input{'treatments'} };
	my %app_treatments = %{ $generate_payments_input{'app_treatments'} };
	my %appointments   = %{ $generate_payments_input{'appointments'} };

	# print to screen so user can monitor progress
	print "\t\t-generate_payments()\n";

	# get the treatment costs
	my %treatment_costs;
	foreach my $itreatment ( keys %treatments ) {
		my $id = $treatments{$itreatment}{'treatmentID'};
		$treatment_costs{$id} = $treatments{$itreatment}{'cost'};
	}

	# create a lookup table of patient ids and account numbers
	my %patient_accounts;
	foreach my $ipatient ( keys %patients ) {
		foreach my $iaccount ( sort { $a <=> $b } keys %accounts ) {
			if ( $patients{$ipatient}{'patientID'} eq
				$accounts{$iaccount}{'patientID'} )
			{
				$patient_accounts{ $patients{$ipatient}{'patientID'} } =
				  $accounts{$iaccount}{'accountNumber'};
				last;
			}
		}
	}

	# create a lookup table of appointments and patient ids
	my %app_patients;
	foreach my $ipatient ( keys %patients ) {
		foreach my $iapp ( keys %appointments ) {
			if ( $patients{$ipatient}{'patientID'} eq
				$appointments{$iapp}{'patientID'} )
			{
				my $app_id = $appointments{$iapp}{'appointmentID'};
				$app_patients{$app_id} = $patients{$ipatient}{'patientID'};
				next;
			}
		}
	}

	# create a table of appointment status
	my %app_status;
	foreach my $iapp ( keys %appointments ) {
		my $app_id = $appointments{$iapp}{'appointmentID'};
		$app_status{$app_id} = $appointments{$iapp}{'status'};
	}

	# create a table to store the number of, and sum of bills
	# that are unpaid
	my %patient_arrears;
	foreach my $ipatient ( keys %patients ) {
		my $id = $patients{$ipatient}{'patientID'};
		$patient_arrears{$id}{'total'}  = 0.0;
		$patient_arrears{$id}{'number'} = 1;
	}

	# create an array of payment types
	my @payment_types =
	  ( "cash", "cheque", "cash-post", "cheque-post", "credit card" );

	# create some timers to see where these routines are slow
	my @bill_times;
	my @payment_times;

	# foreach bill get a list of treatments associated with it
	my %bill_data;
	my %payments;
	my $payment_id = 0;

	# get a list of treatments for the bills
	foreach my $ibill ( sort { $b <=> $a } keys %bills ) {
		my $app_id     = $bills{$ibill}{'appointmentID'};
		my $patient_id = $app_patients{$app_id};
		foreach my $iapp_treat ( keys %app_treatments ) {
			my $app_id_2 = $app_treatments{$iapp_treat}{'appointmentID'};
			if ( $app_id eq $app_id_2 ) {
				push(
					@{ $bill_data{$ibill}{'treatments'} },
					$app_treatments{$iapp_treat}{'treatmentID'}
				);
			}
		}

		# calculate the cost of the bill
		foreach my $treatment ( @{ $bill_data{$ibill}{'treatments'} } ) {
			$bill_data{$ibill}{'cost'} += $treatment_costs{$treatment};
		}

	}

	# now generate the payments from bill costs etc.
	foreach my $ibill ( sort { $b <=> $a } keys %bills ) {

		# get the treatments and costs
		my $bill_tick  = [gettimeofday];
		my $app_id     = $bills{$ibill}{'appointmentID'};
		my $patient_id = $app_patients{$app_id};

		# set the patient id and account
		$bill_data{$ibill}{'patientID'} = $app_patients{$app_id};
		$bill_data{$ibill}{'account'} =
		  $patient_accounts{ $app_patients{$app_id} };

		# these are bounds for payments
		my $issue_date = $bills{$ibill}{'issueDate'};
		my $due_date   = $bills{$ibill}{'dueDate'};

		# create a 'random' number of payments
		my $balance = $bill_data{$ibill}{'cost'};

		# if the due date was more than 100 days ago
		# make sure it gets paid of most of the time
		my @work_days_before = get_working_days_before_date( \$due_date );
		my @days_between =
		  get_working_days_between_dates( \$issue_date, \$due_date );
		my $ndays_between    = scalar @days_between;
		my $complete_payment = 1;
		if ( scalar @work_days_before > 2500 ) {
			$complete_payment = 0;
		}

		if ( $patient_arrears{$patient_id}{'total'} > 500 ) {
			$complete_payment = 1;
		}
		if ( $patient_arrears{$patient_id}{'number'} >= 4 ) {
			$complete_payment = 1;
		}

		# generate the payments
		my $n_payments;

		if ( $balance < 500 ) {
			$n_payments = 1 + int( rand(2) );
		}
		elsif ( $balance >= 500 && $balance <= 1000 ) {
			$n_payments = 1 + int( rand(5) );
		}
		elsif ( $balance > 1000 ) {
			$n_payments = 1 + int( rand(8) );
		}

		my $payment_date_counter = 0;
		my $stop_payments;

		for my $i ( 1 ... $n_payments ) {

			$payment_id++;
			my $payment_tick            = [gettimeofday];
			my $payment_id_print_format = "p" . sprintf "%06d", $payment_id;

			# generate a random payment date
			# between the issue and due date
			$payment_date_counter = $payment_date_counter +
			  int( rand( $ndays_between - $payment_date_counter ) );
			my $payment_date = $days_between[$payment_date_counter];

			# generate the payment amount
			my $payment_amount = 0.0;
			if ( $i == $n_payments && $complete_payment ) {
				$payment_amount = $balance;
			}
			else {
				my $f1 = 0.5 + ( 1 + int( rand(5) ) ) / 10;
				$payment_amount = $f1 * $balance;
				$payment_amount = int($payment_amount);
			}

			if ( $payment_amount >= $balance ) {
				$payment_amount = $balance;
			}
			elsif ( $balance - $payment_amount <= 10 ) {
				$payment_amount = $balance;
			}

			my $payment_type = "cash";
			if ( $balance > 1000 ) {
				if ( int( rand(5) ) % 2 == 0 ) {
					$payment_type = "cheque";
				}
				else {
					$payment_type = "credit card";
				}
			}
			else {
				$payment_type =
				  $payment_types[ int( rand( scalar @payment_types ) ) ];
			}

			# populate the payments
			$payments{$payment_id}{'paymentID'} = $payment_id_print_format;
			$payments{$payment_id}{'billNumber'} =
			  $bills{$ibill}{'billNumber'};
			$payments{$payment_id}{'accountNumber'} =
			  $bill_data{$ibill}{'account'};
			$payments{$payment_id}{'amount'}      = $payment_amount;
			$payments{$payment_id}{'paymentType'} = $payment_type;
			$payments{$payment_id}{'paymentDate'} = $payment_date;

			# correct the balance
			$balance = $balance - $payment_amount;

			if ( !$complete_payment ) {
				$patient_arrears{$patient_id}{'total'} += $balance;
				$patient_arrears{$patient_id}{'number'}++;
				$balance = 0;
			}

			push( @payment_times, tv_interval($payment_tick) );
			last if ( $balance == 0 );
		}
		push( @bill_times, tv_interval($bill_tick) );
	}

	# print some summary statistics to screen
	print "\t\t\t-generated ", scalar keys %payments, " payments\n";
	my $mean_payment_time   = sprintf "%1.5f", mean(@payment_times);
	my $stddev_payment_time = sprintf "%1.5f", stddev(@payment_times);
	print "\t\t\t-average payment time = ", $mean_payment_time, "+-",
	  $stddev_payment_time, "\n";

	my $mean_bill_time   = sprintf "%1.5f", mean(@bill_times);
	my $stddev_bill_time = sprintf "%1.5f", stddev(@bill_times);
	print "\t\t\t-average bill time = ", $mean_bill_time, "+-",
	  $stddev_bill_time, "\n";

	# sort the payments by date
	my %sorted_payments;
	my $count = 0;
	foreach my $ipay (
		sort { $payments{$a}->{paymentDate} cmp $payments{$b}->{paymentDate} }
		keys %payments
	  )
	{
		$count++;
		%{ $sorted_payments{$count} } = %{ $payments{$ipay} };
		$sorted_payments{$count}{'paymentID'} = sprintf "p%06d", $count;
	}

	return \%sorted_payments;

}

sub generate_dental_reports {

	my ( $ref1, $ref2, $ref3, $ref4 ) = @_;
	my %dental_report_input = %{$ref1};
	my $random              = $dental_report_input{'random'};
	my %referrals           = %{ $dental_report_input{'referrals'} };
	my %ref_treatments      = %{ $dental_report_input{'ref_treatments'} };
	my %appointments        = %{ $dental_report_input{'appointments'} };
	my %app_treatments      = %{ $dental_report_input{'app_treatments'} };
	my %treatments          = %{ $dental_report_input{'treatments'} };
	print "\t\t-generate_dental_reports()\n";

	# generate a table of appointment - treatments
	my %appointment_treatments;
	foreach my $iapp ( keys %appointments ) {
		my $appID = $appointments{$iapp}{'appointmentID'};
		foreach my $itreatment ( sort { $a <=> $b } keys %app_treatments ) {
			if ( $app_treatments{$itreatment}{'appointmentID'} eq $appID ) {
				my $treatmentid = $app_treatments{$itreatment}{'treatmentID'};
				push( @{ $appointment_treatments{$appID} }, $treatmentid );
			}
		}
	}

	# generate a table of referral - tratments
	foreach my $iapp ( keys %referrals ) {
		my $refID = $referrals{$iapp}{'referralID'};
		foreach my $itreatment ( keys %ref_treatments ) {
			if ( $ref_treatments{$itreatment}{'referralID'} eq $refID ) {
				my $treatmentid = $ref_treatments{$itreatment}{'treatmentID'};
				push( @{ $appointment_treatments{$refID} }, $treatmentid );
			}
		}
	}

	# generate a table of treatmentID-treatment Type
	my %treatment_id_type;
	foreach my $itreatment ( keys %treatments ) {
		$treatment_id_type{ $treatments{$itreatment}{'treatmentID'} } =
		  $treatments{$itreatment}{'treatmentType'};
	}

	# generate the list of dental reports for in house treatments
	my %dental_reports;
	my $ireport = 0;
	my @times;
	foreach my $iapp ( keys %appointments ) {

		my $tick = [gettimeofday];

		# only generate a report for
		if ( $appointments{$iapp}{'status'} eq "completed" ) {

			# populate with forigen key info
			my $report_number = sprintf "dr%06d", $ireport++;
			$dental_reports{$report_number}{'reportID'} = $report_number;
			$dental_reports{$report_number}{'patientID'} =
			  $appointments{$iapp}{'patientID'};
			$dental_reports{$report_number}{'specialistID'} =
			  $appointments{$iapp}{'specialistID'};
			$dental_reports{$report_number}{'appointmentID'} =
			  $appointments{$iapp}{'appointmentID'};
			$dental_reports{$report_number}{'referralID'} = "NULL";

			$dental_reports{$report_number}{'reportDate'} =
			  $appointments{$iapp}{'date'};

			# generate a report based on the treatments
			my @treatments =
			  @{ $appointment_treatments{ $appointments{$iapp}{'appointmentID'}
			  } };

			my @treatment_types;
			foreach my $treatment_id (@treatments) {
				my $treatment_type = $treatment_id_type{$treatment_id};
				push( @treatment_types, $treatment_type );
			}
			$dental_reports{$report_number}{'comment'} =
			  ${ $random->dental_report( \@treatment_types ) };
		}

		push( @times, tv_interval($tick) );

	}

	foreach my $iapp ( keys %referrals ) {

		my $tick = [gettimeofday];
		
		# dental report date for a referral should be well after
		# the referral data
		my $min_date = $referrals{$iapp}{'date'};
		$min_date = ${ increment_date_one_month( \$min_date ) };
		my $max_date = ${ increment_date_one_month( \$min_date ) };
		my $report_date =
		  ${ get_random_working_day_between( \$min_date, \$max_date ) };


		if(!defined($report_date)){
			$report_date = $max_date;
		}

		(my $report_date_as_int = $report_date) =~ s/\-//ig;
		(my $today_as_int = $today) =~ s/\-//ig;
		

		# only generate a report for
		if ( $report_date_as_int =~ /\d+/ && $report_date_as_int < $today_as_int ) {

			# populate with forigen key info
			my $report_number = sprintf "dr%06d", $ireport++;
			$dental_reports{$report_number}{'reportID'} = $report_number;
			$dental_reports{$report_number}{'patientID'} =
			  $referrals{$iapp}{'patientID'};
			$dental_reports{$report_number}{'specialistID'} =
			  $referrals{$iapp}{'specialistID'};
			$dental_reports{$report_number}{'referralID'} =
			  $referrals{$iapp}{'referralID'};
			$dental_reports{$report_number}{'appointmentID'} = "NULL";


			$dental_reports{$report_number}{'reportDate'} = $report_date;

			# generate a report based on the treatments
			my @treatments =
			  @{ $appointment_treatments{ $referrals{$iapp}{'referralID'} } };

			my @treatment_types;
			foreach my $treatment_id (@treatments) {
				my $treatment_type = $treatment_id_type{$treatment_id};
				push( @treatment_types, $treatment_type );
			}
			$dental_reports{$report_number}{'comment'} =
			  ${ $random->dental_report( \@treatment_types ) };
		}

		push( @times, tv_interval($tick) );

	}

	print "\t\t\t-generated ", scalar keys %dental_reports, " dental reports\n";
	my $mean_time = sprintf "%1.5f", mean(@times);
	my $stddev    = sprintf "%1.5f", stddev(@times);
	print "\t\t\t-average report generation time = ", $mean_time, "+-",
	  $stddev, "\n";

	# now sort by date
	my %sorted_reports;
	my $count = 0;
	foreach my $dr (
		sort {
			$dental_reports{$a}->{reportDate}
			  cmp $dental_reports{$b}->{reportDate}
		}
		keys %dental_reports
	  )
	{
		$count++;
		%{ $sorted_reports{$count} } = %{ $dental_reports{$dr} };
		$sorted_reports{$count}{'reportID'} = sprintf "dr%06d", $count;
	}

	return \%sorted_reports;

}

sub set_working_day_calendar {

	# generate a calendar of valid working days
	# between the min and max year
	my ( $ref1, $ref2 ) = @_;
	my $min_year = ${$ref1};
	my $max_year = ${$ref2};
	@work_days = ();
	for my $year ( $min_year ... $max_year ) {
		foreach my $mon ( 1 .. 12 ) {
			my @weeks_month = calendar( $mon, $year );
			foreach my $week (@weeks_month) {
				my @days = @{$week};
				my $iday = 0;
				foreach my $day (@days) {
					if ( $iday >= 1 && $iday <= 5 && defined($day) ) {
						my $work_day = sprintf "%04d-%02d-%02d", $year, $mon,
						  $day;
						push( @work_days, $work_day );
					}
					$iday++;
				}
			}
		}
	}
}

sub get_working_day_calendar {
	return @work_days;
}

sub get_random_working_day_between {

	my ( $ref1, $ref2 ) = @_;
	my $min_date = ${$ref1};
	my $max_date = ${$ref2};

	my @working_days = get_working_day_calendar();
	my $last_date    = $max_date;
	if ( $max_date eq "NULL" ) {
		$last_date = $working_days[-1];
	}

	my @days_between =
	  get_working_days_between_dates( \$min_date, \$last_date );
	my $total_days        = scalar(@days_between)-1;
	my $random_start_date = int( rand($total_days-1) );
	my $random_date       = $days_between[$random_start_date];
	return \$random_date;

}

sub get_working_days_before_date {

	my ($ref)     = @_;
	my $max_date  = ${$ref};
	my @work_days = get_working_day_calendar();
	my $idx       = firstidx { $_ eq $max_date } @work_days;
	return @work_days[ 0 ... $idx - 1 ];
}

sub get_working_days_between_dates {
	my ( $ref1, $ref2 ) = @_;
	my $min_date = ${$ref1};
	my $max_date = ${$ref2};

	unless ( defined($max_date) && defined($min_date) ) {
		die "\t-[oops] something went wrong, just re-run\n";
	}

	my @work_days = get_working_day_calendar();
	my @work_days_between;
	my $idx1 = firstidx { $_ eq $min_date } @work_days;
	my $idx2 = firstidx { $_ eq $max_date } @work_days;

	# if first and last date defined
	if ( $idx1 != -1 && $idx2 != -1 ) {
		return @work_days[ $idx1 ... $idx2 ];
	}
	else {
		my $start_index = 0;
		my $end_index   = $#work_days;
		if ( $idx1 != -1 ) {
			$start_index = $idx1;
		}
		$min_date =~ s/-//ig;
		$max_date =~ s/-//ig;
		for my $i ( $start_index ... $end_index ) {
			( my $day_as_int = $work_days[$i] ) =~ s/-//ig;
			if ( $day_as_int >= $min_date && $day_as_int <= $max_date ) {
				push( @work_days_between, $work_days[$i] );
			}
			last if ( $day_as_int >= $max_date );
		}
		return @work_days_between;
	}
}

sub generate_appointments_calendar {

	my @work_days = get_working_day_calendar();
	my %appointment_slots;
	my $nslots = 0;
	foreach my $work_day (@work_days) {
		for my $i ( 9 ... 17 ) {
			for my $j ( 1 ... 2 ) {
				$nslots++;
				my $x    = ( 60 - ( 60 / $j ) );
				my $time = sprintf "%02d-%02d-%02d", $i, $x, 0;
				push( @{ $appointment_slots{$work_day} }, $time );
			}
		}
	}
	print "\t-total of $nslots appointment slots available\n";
	return \%appointment_slots;
}

sub get_next_free_appointment_slot {

	my ( $ref1, $ref2, $ref3 ) = @_;
	my $min_date       = ${$ref1};
	my $max_date       = ${$ref2};
	my $slots_required = ${$ref3};

	# get a list of valid dates for this customer
	my @working_dates = get_working_day_calendar();

	unless ( defined($max_date) ) {
		die "\t-[oops] something went wrong, just re-run\n";
	}

	if ( $max_date eq "NULL" ) {
		$max_date = $working_dates[-1];
	}

	my @valid_dates = get_working_days_between_dates( \$min_date, \$max_date );
	my %slot;
	foreach my $valid_date (@valid_dates) {
		if ( exists( $appointments_calendar{$valid_date} ) ) {
			my @slots        = @{ $appointments_calendar{$valid_date} };
			my $number_slots = scalar @slots;
			if ( @slots && $number_slots >= $slots_required ) {
				$slot{'date'}  = $valid_date;
				$slot{'start'} = $slots[0];

				if ( defined( $slots[$slots_required] ) ) {
					$slot{'end'} = $slots[$slots_required];
				}
				else {
					$slot{'end'} = "18-00-00";
				}

				for my $i ( 1 ... $slots_required ) {
					shift @slots;
				}
				@{ $appointments_calendar{$valid_date} } = @slots;
				last;
			}
		}
	}

	return \%slot;
}

sub calculate_remaining_calendar_slots {
	my $count = 0;
	foreach my $i ( keys %appointments_calendar ) {
		$count += scalar @{ $appointments_calendar{$i} };
	}
	return \$count;
}

sub increment_date {

	my ($ref1) = @_;
	my $date = ${$ref1};

	my %decrease_day_months;
	$decrease_day_months{2}  = 28;
	$decrease_day_months{4}  = 30;
	$decrease_day_months{6}  = 30;
	$decrease_day_months{9}  = 30;
	$decrease_day_months{11} = 30;

	my @split = split( /\-/, $date );
	my $year  = $split[0];
	my $mon   = $split[1];
	my $day   = $split[2] + 1;

	if ( exists( $decrease_day_months{$mon} ) ) {
		if ( $day > $decrease_day_months{$mon} ) {
			$day = 1;
			$mon += 1;
		}
	}
	else {
		if ( $day > 31 ) {
			$day = 1;
			$mon += 1;
		}
	}
	if ( $mon == 13 ) {
		$year += 1;
		$mon = 1;
	}

	my $return_date = sprintf "%04d-%02d-%02d", $year, $mon, $day;
	return \$return_date;

}

sub decrement_date {

	my ($ref1) = @_;
	my $date = ${$ref1};

	my %decrease_day_months;
	$decrease_day_months{2}  = 28;
	$decrease_day_months{4}  = 30;
	$decrease_day_months{6}  = 30;
	$decrease_day_months{9}  = 30;
	$decrease_day_months{11} = 30;

	my @split = split( /\-/, $date );
	my $year  = $split[0];
	my $mon   = $split[1];
	my $day   = $split[2] - 1;

	if ( $day <= 0 ) {
		$day = 1;
		$mon = $mon - 1;
	}
	if ( $mon < 1 ) {
		$year -= 1;
		$mon = 12;
	}
	if ( exists( $decrease_day_months{$mon} ) ) {
		if ( $day > $decrease_day_months{$mon} ) {
			$day = 1;
			$mon += 1;
		}
	}

	my $return_date = sprintf "%04d-%02d-%02d", $year, $mon, $day;
	return \$return_date;

}

sub increment_date_one_month {

	my ($ref1) = @_;
	my $date = ${$ref1};

	my %decrease_day_months;
	$decrease_day_months{2}  = 28;
	$decrease_day_months{4}  = 30;
	$decrease_day_months{6}  = 30;
	$decrease_day_months{9}  = 30;
	$decrease_day_months{11} = 30;

	my @split = split( /\-/, $date );
	my $year  = $split[0];
	my $mon   = $split[1] + 1;
	my $day   = $split[2];
	if ( $mon > 12 ) {
		$year += 1;
		$mon = $mon - 12;
	}
	if ( exists( $decrease_day_months{$mon} ) ) {
		if ( $day > $decrease_day_months{$mon} ) {
			$day = $decrease_day_months{$mon};
		}
	}

	my $return_date = sprintf "%04d-%02d-%02d", $year, $mon, $day;
	return \$return_date;

}

sub set_due_date {

	my ($ref1) = @_;
	my $date = ${$ref1};
	$date = ${ increment_date_one_month( \$date ) };
	$date = ${ increment_date_one_month( \$date ) };
	return \$date;

}

sub get_payment_end_date {

	my ($ref)      = @_;
	my $start_date = ${$ref};
	my @split      = split( /\-/, $start_date );
	my $year       = $split[0];
	my $mon        = $split[1] + 6;
	my $day        = $split[2] - 1;

	if ( $day == 0 ) {
		$day = 1;
	}

	if ( $mon > 12 ) {
		$year += 1;
		$mon = $mon - 12;
	}
	my $return_date = sprintf "%04d-%02d-%02d", $year, $mon, $day;
	return \$return_date;

}

sub date_in_future {

	my ($ref) = @_;
	my $date = ${$ref};
	( my $date_as_int  = $date )  =~ s/-//ig;
	( my $today_as_int = $today ) =~ s/\-//ig;
	if ( $date_as_int > $today_as_int ) {
		return 1;
	}
	return 0;

}

1;

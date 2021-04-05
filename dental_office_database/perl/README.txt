Code is to be distributed and used on an as-is basis.

The following packages can be installed via CPAN if not installed on your system:
	Time::HiRes
	Statistics::Basic
	Calendar::Simple
	Data::Random

via the commands:

	$>cpan install Time::HiRes
	$>cpan install Statistics::Basic
	$>cpan install Calendar::Simple
	$>cpan install Data::Random


To run, go to the /scripts/ folder open a command prompt and type:
	
	$> perl generateDatabase.pl

Occasionally you will see an error on screen related to a random date generation bug,
just re-run if this occurs it.

To change basic options:

open the /generateDatabase.pl file in a text editor
change the following lines to reflect the number of patients and specialists you want in your DB:
	
	$input{'number_of_patients'} = 200;
	$input{'number_of_specialists'} = 10;

open the /inputs/options.txt file in a text editor
and set the following fields to reflect the minimum and maximum years
for which the dental practice was open for business
and the minimum and maximum dates of birth which patients should have
	
	min_working_year	2010
	max_working_year	2020
	min_dob	1930-01-01
	max_dob	2008-01-01

open the /generateRelations.pl file and go to line 126 to change the definition of 
'today' which is hard-wired as the first of may but could equally be set to any date:

	$today = sprintf "%04d-%02d-%02d", 2020, 05, 01;

This does influence whether a date is "in the future" or not in both perl and SQL database.

Output files will be written to a folder called "sql" in the /g00221349_Somers base folder.


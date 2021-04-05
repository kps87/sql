--	---------------------------------------------------------------------------------
--	Kieran Somers, g00221349@gmit.ie
--	The following file is best viewed in a modern text editor:
--		notepad++ or sublime text or recommended.
--	---------------------------------------------------------------------------------

--	This document provides an overview of SQL DDL and DML operations
--	used to illustrate the suitability of the designed relational DB
--	for business use in Mary Mulcahys surgery.
--	This document has the following structure:
--		-Firstly a series of basic SQL queries of the database are provided with comments
--			these serve to illustrate basic functionality and understanding of SQL
--			as a DML. These include various examples of the following keywords, amongst others:
--			-SELECT
--			-INSERT
--			-UPDATE
--			-DELETE
--			-CREATE
--		-Then 6 sets of business use cases are described
--			-these require use a combination of the above keywords as well as others commands (GROUP BY etc.)
--				and illustrate more complex SQL DDL and DML queries.
--			-Each business use case corresponds to a paragraph in the project narrative
--				excluding the first paragraph as referrals and specialists are specifically
--				dealt with later in the project narrative
--			-Important text from the narrative is extracted, split into important statements, and re-iterated
--			-each piece of text is then interpreted, in terms of what would occur
--				in real-life (a practical approach) before demonstrating how the current database
--				satisfies the business need, or can be used in a business scenario
--			-for each piece of text from the business narrative, example SQL 
--				queries are provided which allow the important data to be:
--					a) viewed
--					b) queried
--					c) edited
--				using various DDL and DML strategies

--	---------------------------------------------------------------------------------

--	---------------------------------------------------------------------------------
--	Simple SQL queries
--	---------------------------------------------------------------------------------

--	---------------------------------------
--	SELECT 
--	These have the general format
--	SELECT		-- get something from one or more relations
--	FROM 		-- the list of relations to be queried
--	WHERE 		-- conditional clauses to filter data
--	GROUP BY 	-- group the data attributes in specific relations, important for aggregate queries
--	ORDER BY 	-- choose fields to sort the resulting fields (ascending, descending)
--	---------------------------------------

--	Getting all patients and all details in the `patients` table
--	The * wildcard requests that all columns be returned and the lack
--	of any clauses such as WHERE, mean that all rows will be returned:

	SELECT 
		* 
	FROM 
		patients;

--	Getting all data from the patients table for a specific patient
--	based on their name - an example of the WHERE clause for filtering data:

	SELECT 
		patients.*
	FROM
		patients
	WHERE
		patients.firstname = 'Kieran' 
	AND 
		patients.surname = 'Somers';

--	Getting all data from the patients table for a specific patient
--	based on their `patientID` - use of a primary key to obtain data:

	SELECT 
		patients.*
	FROM
		patients
	WHERE
		patients.patientID = 'p00001';

--	Getting specific columns from the patients table for a specific patient
--	based on their `patientID` - use of a primary key to obtain data and column
--	names to access only specific fields:

	SELECT 
		patients.firstname, patients.surname
	FROM
		patients
	WHERE
		patients.patientID = 'p00001';

--	Based on the above, here are SELECT statements illustrating Codds second rule, 
--	Accessing a single datum based on a combination of table name, primary key and attribute name:

	SELECT accounts.openedDate FROM accounts WHERE accounts.accountNumber = 'acc000001';
	SELECT appointments.date FROM appointments WHERE appointments.appointmentID = 'app0000001';
	SELECT appointmentTreatments.appointmentID FROM appointmentTreatments WHERE appointmentTreatments.appTreatID = 'appTreat0000001';
	SELECT bills.dueDate FROM bills WHERE bills.billNumber = 'b000001';
	SELECT dentalReports.reportDate FROM dentalReports WHERE dentalReports.reportID = 'dr000001';
	SELECT employees.firstname FROM employees WHERE employees.employeeID = 'e001';
	SELECT payments.amount FROM payments WHERE payments.paymentID = 'p000001';
	SELECT patients.firstname FROM patients WHERE patients.patientID = 'p00001';
	SELECT referrals.date FROM referrals WHERE referrals.referralID = 'ref0000001';
	SELECT specialists.firstname FROM specialists WHERE specialists.specialistID = 'sp00001';
	SELECT treatments.treatmentType FROM treatments WHERE treatments.treatmentID = 'tr00002';

--	A SELECT statment which illustrates filtering information stored in two tables
--	based on the use of the primary key in one table (`patients.patientID`) as the foreign key
--	in another table (`accounts.patientID`):

	SELECT 
		patients.*, accounts.accountNumber, accounts.openedDate
	FROM
		patients, accounts
	WHERE
		patients.patientID = accounts.patientID;

--	The above statement requests all data from the `patients` table
--	and only the `accountNumber` and `openedDate` from the `accounts`
--	table.

--	A SELECT statement which sorts the information from the above query
--	based on descending order of the account opening date - that is in
--	reverse chronological order:

	SELECT 
		patients.*, accounts.accountNumber, accounts.openedDate
	FROM
		patients, accounts
	WHERE
		patients.patientID = accounts.patientID
	ORDER BY
		accounts.openedDate DESC;

--	A SELECT statement which uses the keywords above,
--	in combination with the GROUP BY statement
--	and aggregate queries to get the total number of appointments
--	on a given date, and then sorting them based on reverse chronological order,
--	first based on the number of appointments on that date, then based on the date

	SELECT 
		appointments.date,
		COUNT(appointments.date) AS appointmentsOnThisDate
	FROM
		appointments
	GROUP BY
		appointments.date
	ORDER BY
		appointmentsOnThisDate DESC, appointments.date DESC;

--	in the above statement the AS keyword is used to define an alias
--	for the COUNT statement so that the attribute name is sensible to the
--	user.

--	A similar approach can be used to get the total costs of a given
--	bill. This is a slightly more complex query. Each appointment in the 
--	`appointments` relation has at least one treatment associated with
--	it, and these treatments are stored in a junction table,
--	`appointmentTreatments` which allows a one to many mapping of appointments
--	and treatments, based on the `treatmentID` from the `treatments` relation. 
--	Each appointment also has a bill associated with it. 
--	The primary key in the `appointments` table
--	is used as as a foreign key in the `appointmentTreatments` table
--	and as a foreign key in the `bills` relation. We therefore want to 
--	get data where the appointmentID in the `bills` and `appointmentTreatments`
--	relations are the same, and to cross reference each treatmentID in the `appointmentTreatments`
--	table associated with a given appointmentID, to sum the treatment costs in order
--	to compute a total cost associated with each bill. This can be achieved by the following
--	query, which syntactically is not too complex, thus illustrating the power of
--	a well defined relation DB, and corresponding DML


	SELECT 
		bills.billNumber, 
		bills.appointmentID,
		count(treatments.treatmentID) AS numberTreatments, 
		sum(treatments.cost) AS totalCost
	FROM 
		bills, treatments, appointmentTreatments
	WHERE 
		appointmentTreatments.appointmentID = bills.appointmentID 
	AND 
		appointmentTreatments.treatmentID = treatments.treatmentID 
	GROUP BY 
		bills.appointmentID;

--	Nested select statements are also useful, supposed we wanted to get
--	a list of all treatements performed by a given specialist
--	but we did not know there specialistID, just their firstname and surname
--	The following nested SELECT statement has an inner (the second SELECT)
--	and outer statement:

	SELECT
		treatments.*
	FROM
		treatments
	WHERE
		treatments.specialistID = 
			(SELECT 
				specialists.specialistID 
			FROM
		 		specialists 
		 	WHERE 
		 		specialists.firstname = "Mary"
	 		AND 
	 			specialists.surname = "Mulcahy"
		 	);

--	The second SELECT statemet returns a single
--	result, the specialistID for the specialist with firstname of Mary
--	and surname of Mulcahy. The result of this query is then used
--	as input in for the outer query, which aims to get a list of treatments
--	associated with a specific specialistID.

--	---------------------------------------
--	INSERT 
--	adding a patient and their account
--	to the database
--	---------------------------------------

--	The following is an example of inserting a single patient into the patients table, where
--	the column names are specifically declared. The first line below declares the INSERT statment and the table, `patients`,
--	INTO which the data is being inserted. The second line corresponds to the attribute names in the `patients` relation these do no have to be declared, but if not declared,
--	then it is assumed that the subsequent VALUES are being inserted in the "ORDINAL_POSITION" declared in the relational schema.
--	The third line below, VALUES, is a keyword that a datum, or series of data are to be inserted, and the fourth line is declares each 
--	attribute value using comma separated fields.

	INSERT INTO `patients` 
	(`address`, `dob`, `email`, `firstname`, `gender`, `patientID`, `phoneNumber`, `pps`, `surname`) 
	VALUES
	('315D Fen Mews, Garden, Limerick','2004-08-10','Diane-Marie.Viridis79@neuf.fr','Diane-Marie','M','p99990','0874822448','8265236/R','Viridis');

--	the open and closing brackets on the firth line demarc the start and end of a single
--	row of data. The fourth line can be repeated n times, with commas used to demarc rows, in order
--	 to INSERT multiple rows of data into a relation:

	INSERT INTO `patients` 
	(`address`, `dob`, `email`, `firstname`, `gender`, `patientID`, `phoneNumber`, `pps`, `surname`) 
	VALUES
	('42B Hobbit Drive','2004-08-10','bilbo.baggins79@neuf.fr','Bilbo','M','p99991','0874822448','8265236/R','Baggins'),
	('163A Wesley Yard, Close, Limerick','2005-05-08','Walliw-Jelle59@hotmail.it','Walliw','NB','p99992','0893952433','6870340/P','Jelle');

--	The SQL scripts provided to create the database provide further examples of
--	INSERT statements for every relation in the database.

--	---------------------------------------
--	UPDATE 
--		SET 	-- a keyword used to declare the fields to update	
--		WHERE 	-- a clause to filter fields to be updated
--	---------------------------------------

--	The UDPATE kewyord can be used to update fields
--	in a relation via the SET keyword. The general syntax
--	is:

--	UPDATE "TABLE_NAME"
-- 		SET "COLUMN_NAME" = "VALUE";
--	with the following given an example of how to changes
--	all patients names in the `patients` table -

	UPDATE patients 
		SET 
			patients.firstname = 'Kieran',
			patients.surname = 'Somers';

--	The above statement is rather unlikely and it is more likely
--	that we wish to add some clauses to the data, as follows:
	UPDATE patients 
		SET 
			patients.firstname = 'Kieran',
			patients.surname = 'Somers'
		WHERE 
			patients.patientID = 'p00005';

--	in this case, only one specific patients name is updated as the 
--	patientID is a unique primary key.

--	Another example might be to give all bill payments an extension
--	on their dueDate if they were created after some date:

	UPDATE bills
		SET 
			bills.dueDate = bills.dueDate + INTERVAL 7 DAY
		WHERE 
			bills.issueDate > '2020-01-01';

--	Multiple conditions can of course be included
--	and here we show an example of increasing the bill
--	dueDate for dates in a specific range

	UPDATE bills
		SET 
			bills.dueDate = bills.dueDate + INTERVAL 7 DAY
		WHERE 
			bills.issueDate >= '2020-01-01'
		AND
			bills.issueDate <= '2020-01-10';

-- The above query can similarly be written as:

	UPDATE bills
		SET 
			bills.dueDate = bills.dueDate + INTERVAL 7 DAY
		WHERE 
			bills.issueDate 
		BETWEEN '2020-01-01' AND '2020-01-10';

--	---------------------------------------
--	DELETE
--		FROM 		-- the list of relations to be queried
--		WHERE 		-- conditional clauses to filter data
--	---------------------------------------

--	The DELETE command has the following generic syntax
-- 	DELETE
--	FROM 	"TABLE_NAME"
--	WHERE 	[SOME CLAUSES]

--	To delete all records from a table, one simply omits
--	the WHERE clause, with the following command deleting
--	all records from the `payments` relation:

	DELETE FROM payments;

--	Such an operation is likely to unuseful unless conditions
--	are applied. We can refine the approach by adding conditions
--	via the WHERE clause. Below we have an example of deleting
--	an appointment from the `appointments` relation. However, all
--	treatments associated with a given appointment are stored
--	in the `appointmentTreatments` junction table, and before
--	deleting the appointment, we must first delete the corresponding
--	treatments from the `appointmentTreatments` relation, as the appointmentID
--	in the `appointmentTreatments` relation is a foreign key from the 
--	`appointments` relation. This can be achieved as follows:

	DELETE FROM appointmentTreatments WHERE appointmentID = 'app0002567';

--	and we can now proceed to deleting the appointment and its corresponding bill 
--	from the `bills` and `appointments` relation ()

	DELETE FROM appointments WHERE appointmentID = 'app0002567';

--	Note that attempting to delete both simultaneously requires more sophisticated
--	syntax via JOIN operations, and may be problematic in cases where there are
--	foriegn key dependencies, as the order of deletion is difficult to control, 
--	and in cases where there are dependencies between relations the order of 
--	deletion is important (the parent cannot be deleted before the child).
--	The following query, which may be valid in the case where there
--	were no foreign key dependencies, may fail:

--	DELETE appointments, appointmentTreatments 
--	FROM appointmentTreatments 
--	INNER JOIN appointments 
--	ON 
--		appointmentTreatments.appointmentID = appointments.appointmentID
--	WHERE 
--		appointments.appointmentID = 'app0001361' 

--	Note that the WHERE clause in the previous examples can be elaborated
--	upon to add more conditions via the usual commands (AND, OR, BETWEEN, IS NULL).

--	---------------------------------------
--	CREATE
--	---------------------------------------
--	Below we have an example for the creation of a new relation.
--	The syntax is as follows:

--	CREATE TABLE "TABLE_NAME" (
--		"COLUMN_NAME_1" "TYPE1" "CONDITIONS1",
--		"COLUMN_NAME_2" "TYPE2" "CONDITIONS2"
--	);

--	The CREATE TABLE command is used to define the creation
--	of a new table and the "TABLE_NAME" in parenthesis
--	is a unique name for the relation. The comma separated
--	fields between the open and closing brackets are included
--	for each column in the relation where "COLUMN_NAME_1" is
--	a unique name for the first attribute, "TYPE1" referes
--	the the value type (date, char, varchar, int, number, tinytext etc.)
--	and "CONDITIONS" refers to any constraints or default
--	values which we wish to include for that particular
--	field. A more specific example is below:

	CREATE TABLE `patients_test1` (
		`address` varchar(200) NOT NULL,
		`dob` date NOT NULL,
		`email` varchar(100) DEFAULT NULL,
		`firstname` varchar(50) NOT NULL,
		`gender` varchar(10) DEFAULT NULL,
		`patientID` char(6) NOT NULL,
		`phoneNumber` varchar(30) NOT NULL,
		`pps` char(9) DEFAULT NULL,
		`surname` varchar(50) NOT NULL
	) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--	Here we are creating a table entitled `patients_test` with attributes
--	`address`, `dob`, `email`, `firstname`, `gender`, `patientID`
--	`phoneNumber`, `pps` and `surname`. Certain fields which can be expected
--	to have variable length are assigned varchar() types, others which must strictly
--	be a fixed length are assigned a char() type, with in brackets after each of these
--	types refer to the character length. The `address`, `dob`, `firstname`, `patientID`,`phoneNumber`
--	and `surname` are all constrained such that they cannot be NULL via the NOT NULL commands.
--	Conversely, some fields which are optional are assigned a default value of NULL via 
--	the DEFAULT command, which allows a DEFAULT value to be assigned -- it does not have to be 
--	NULL, it could be a default cost or payment amount of 0 etc.

--	During table creation one can enforce other constraints, as shown below:

	CREATE TABLE `payments_test2` (
		`accountNumber` varchar(9) NOT NULL CHECK(LENGTH(`accountNumber`) > 1 AND LENGTH(`accountNumber`) <= 9),
		`amount` float NOT NULL CHECK (`amount` > 0),
		`billNumber` varchar(7) NOT NULL CHECK(LENGTH(`billNumber`) = 7),
		`paymentDate` date NOT NULL,
		`paymentID` varchar(7) NOT NULL CHECK(LENGTH(`paymentID`) = 7),
		`paymentType` varchar(20) NOT NULL CHECK(LENGTH(`paymentType`) > 1 AND LENGTH(`paymentType`) <= 20)
	) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--	for example, the payment amount, denoted by the `amount` column is not allowed to have a value equal
--	to or less than 0 via the CHECK (`amount` > 0) command. Similar commands are included to ensure
--	that character lengths are  within appropraite bounds via the CHECK(LENGTH()) constraints.

--	Key constraints can be explicitly included in the CREATE TABLE block, using a shortened
--	version of the `patients` table we illustrate via:
	CREATE TABLE `patients_test3` (
		`patientID` char(6) NOT NULL PRIMARY KEY,
		`pps` char(9) DEFAULT NULL,
		`surname` varchar(50) NOT NULL
	) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--	where the `patientID` is assigned as the primary key. Similar statements can be used
--	to define columns as foreign keys (FOREIGN KEY), and to enforce uniqueness (UNIQUE).
--	An alternative approach is to include such constraints after table creation via
--	the ALTER TABLE command with the following examples taken
--	directly from the project database used to illustrate the syntax:

-- Setting the patientID as the primary key in the `patients` relation 
	ALTER TABLE `patients`
		ADD PRIMARY KEY (`patientID`);

-- Setting the accountNumber number as the primary key and the
-- patientID as a key in the `accounts` relation 
	ALTER TABLE `accounts`
		ADD PRIMARY KEY (`accountNumber`),
		ADD KEY `patientID` (`patientID`);

--	Further constraints can subsequently be added to the `accounts` relation. In this
--	case we specifically specify the `patientID` in the `accounts` relation as being
--	a foreign key which references the `patients` relation `patientID` attribute.

ALTER TABLE `accounts`
		ADD CONSTRAINT `accounts_fk_1` FOREIGN KEY (`patientID`) REFERENCES `patients` (`patientID`);

--	In this case `accoutns_fk_1` is a generic name assigned to the constraint.


--	Views can be created similary to tables using the following generic
--	syntax:

--	CREATE VIEW "VIEW_NAME" AS ();

--	where the CREATE VIEW commands define that a new VIEW is being created
--	and with a name of VIEW_NAME. The AS command defines that the view is
--	created based on the results of the command between the brackets.
--	Below we show an example for the creation of a simple view
--	based on an aggregate query. This view cross references the `billNumber`,
--	which is a primary key in the `bills` relation and a foreign key in the
--	`payments` relation in order compute the sum of all payments against that bill.
--	The SELECT statement syntax has been described previously.

	-- if you deleted the payments relation above, this will return nothing
	CREATE VIEW billPayments AS (
		SELECT 
			bills.billNumber, 
			bills.appointmentID,
			count(payments.paymentID) AS numberPayments, 
			sum(payments.amount) AS totalPaid 
		FROM 
			bills, payments
		WHERE 
			bills.billNumber = payments.billNumber  
		GROUP BY bills.billNumber 
	);

--	Views of other views can also be created. For instance, the `billSummary` view
--	presented in the main project uses data from two other views, the `billCosts`
--	and `billPayments` to produce a summary of all relevant bill related
--	data which can be inspected at a glance and queried to extract useful information:

	CREATE VIEW billSummary AS (
		SELECT 
			patients.firstname,
			patients.surname,
			bills.billNumber, bills.accountNumber, bills.appointmentID,
			bills.issueDate, bills.dueDate, 
			billCosts.numberTreatments, 
			billCosts.allTreatmentIDs,
			billCosts.totalCost, 
			billPayments.numberPayments, 
			billPayments.totalPaid, 
			(billCosts.totalCost-billPayments.totalPaid) AS balance 
		FROM 
			bills, billCosts, billPayments, patients, appointments
		WHERE 
			bills.billNumber = billCosts.billNumber 
		AND 
			bills.billNumber = billPayments.billNumber
		AND
			appointments.appointmentID = bills.appointmentID
		AND
			appointments.patientID = patients.patientID
	); 


--	---------------------------------------------------------------------------------
--	Business use case 1.
--	---------------------------------------------------------------------------------
--	---------------------------------------
--	Text from project narrative
--	---------------------------------------
--	a) 	Patients ask Helen, the office secretary, for appointments, either by post, 
--		phoning or dropping in.	
--	b)	She [sic Helen] arranges a suitable appointment by referring to the appointments 
--		diary unless they owe over a certain amount, or for too long, as seen 
--		from the patient's chart. 
--	c)	She writes the new appointment into the diary and, if it is the patient's first visit, 
--		she makes a new chart for the patient and puts it into the charts filing cabinet. 
--	d)	Appointment details are also written into the patient's chart.
--	---------------------------------------
--	Interpretation of the business use case
--	---------------------------------------
--	It does not matter if a patient phones, posts, or drops in
--	Helen would approach this problem in several stages:
--		a)	First, she would ask the patient whether they are recurring customers
--			or if it is their first visit. If they are new patients Helen
--			will not have to assess whether they are in arrears. 
--			From a DB perspective, I associate the creation of a `chart` with
--			the creation of a new `patient` instance and a new `account` instance. 
--			With all patient medical information retrievable via their `patient`
--			details, and all financial information associated with their `account` details.
--			Note that there is no formal `patientChart` entitry in the current
--			database - charts are generated as VIEWS from the underlying base relations
--			and will be described later in this document.
--			Ultimately, the `patient` and `account` must be created before the patient can be 
--			registered for an appointment.
--		b)	If the patient already has an account, Helen would query 
--			the patient's 'chart' to get an estimate of whether the patient owes money, 
--			the quantity of money owed, and how long those payments are overdue. 
--			If and only if this query is satisfied, will she proceed to organising 
--			an appointment. 
--		c)	If a) and b) are satisfied, Helen needs to be able to find a suitable time for 
--			the appointment. This will be done by scrutinising the details of the 
--			`appointments` relation and associated VIEWS. When a suitable date and time 
--			have been found, Helen then needs to insert the new appointment 
--			into the the database. The appointment does not have to be added to a specific
--			`chart`, any appointments for a given patient can be retrieved from the database
--			as illustrated below.
--		d)	Helen then needs to create a treatment list associated with the appointment.
--
--	---------------------------------------
--	Database structures and SQL queries which satisfy part a)
--		does patient have an account, or
--		does a new one have to be created?
--	---------------------------------------
--	The following query of the `patients` table will allow Helen to assess whether
--	the patient exists in the database:
	SELECT 
		patients.*
	FROM
		patients
	WHERE
		patients.firstname = 'Kieran' and patients.surname = 'Somers';

--	if no patient with that name exists, Helen can be somewhat sure
--	that the patient is not a recurring visitor, and other fields such as
--	the patients.address, patients.dob, and patients.pps can be used to confirm
--	this. To create a new patient in the DB Helen would use the follow SQL command:

	INSERT INTO `patients` 
	(`address`, `dob`, `email`, `firstname`, `gender`, 
		`patientID`, `phoneNumber`, `pps`, `surname`) VALUES
	('123 Fake Street','1979-05-21','g00221349@gmit.ie',
		'Kieran','M','p99999','0861234567','1112223/R','Somers');

--	where the `patientID` is a unique primary key/patient identifier used
--	throughout the database to store information associated with the patients
--	`chart` which includes medical and financial details. 
--	Once the patient details have been added, an `accounts` instance
--	should be created, with the following SQL statement doing so:

	INSERT INTO `accounts` 
	(`accountNumber`, `closedDate`, `openedDate`, `patientID`) VALUES
	('acc999999',NULL,CURDATE(),'p99999');

--	In this case, the `accountNumber` is the unique identifer/primary key
--	for storing account information. The `patientID` is a foreign key
--	from the `patients` table used to associate a patient instance with
--	an account instance. Once a patient and account have been created,
--	Helen can proceed with part c) below for new patients, or part b)
--	below to assess whether the patient has arrears, before proceeding
--	to creating an appointment.

--	---------------------------------------
--	Database structures and SQL queries which satisfy part b)
--		are patients in arrears?
--		this does not have to be done if
--		it is a new patient
--	---------------------------------------
--
--	Firstly we need the patients account number or patientID in order to assess
--	whether they owe too much money, or for too long. If the patient cannot remember either
--	their patientID or accountNumber, it can be obtained quite readily with the following query
--	along with other information which can confirm the patients identity

	SELECT 
		patients.*, accounts.accountNumber
	FROM
		patients, accounts
	WHERE
		patients.patientID = accounts.patientID
	AND 
		patients.firstname = 'Kieran' and patients.surname = 'Somers';

--	Once the pertinent patient information is found, Helen must assess whether
--	that account is in arrears. A number of VIEWS have been created in order
--	to simplify this task for Helen, as it is assumed she may not be capable
--	of performing complex SQL queries. These VIEWS are:
--		`accountsInArrears'
--		`overdueBills`	
--	
--	with both VIEWS being derived from other VIEWS which simplify
--	the visualisation of data from the underlying relations. These other
--	VIEWS include:
--		`billCosts'
--		`billPayments`
--		`billSummary`
--		`overdueBills`

--	The `accountsInArrears` VIEW was derived based on the following SQL query:

	CREATE VIEW accountsInArrears AS (
		SELECT 
			patients.firstname, 
			patients.surname, 
			patients.dob, 
			patients.address, 
			patients.patientID,
			accounts.accountNumber, 
			SUM(overdueBills.balance) AS amountOwed,
			COUNT(overdueBills.billNumber) AS billsOverdue,
			MAX(overdueBills.daysOverdue) AS maxDaysOverdue
		FROM 
			patients, accounts, overdueBills 
		WHERE 
			patients.patientID = accounts.patientID 
		AND 
			accounts.accountNumber = overdueBills.accountNumber 
		GROUP BY 
			accounts.accountNumber 
		ORDER BY 
			amountOwed DESC, billsOverdue DESC
	);


--
--	Assuming that Helen has the `patientID` or `accountNumber` to hand, we can readily 
--	find out if they owe too much money, or, have bills that have been unpaid for 
--	too long with any of the following queries of the `accountsInArrears` VIEW

	SELECT
		*
	FROM
		accountsInArrears
	WHERE
		patientID = 'p00001';

--	with the following query being equally valid

	SELECT
		*
	FROM
		accountsInArrears
	WHERE
		accountNumber = 'acc000001';

--	Therefore, identifying whether a patient is simply a matter of whether 
--	the patientID or accountID are to hand.
	
--	---------------------------------------
--	Database structures and SQL queries which satisfy part c)
--		creating an appointment.
--	---------------------------------------
--	Now that we are satisfied a patient has an account, and is not in arrears,
--	we must find a suitable appointment time.
--	A number of VIEWS are provided to give an overview of upcoming
--	appointments:
--		`scheduleDetailed`
--		`scheduleWeeklyDetailed`
--		`scheduleForthnightlyDetailed`
--		`scheduleSummary`
--	These VIEWS were created as follows:

	--
	-- Create a summary of the schedule for the coming week
	--
	CREATE VIEW scheduleWeeklyDetailed AS (
		SELECT 
			appointments.appointmentID, appointments.date, 
			DAYNAME(appointments.date) AS day, 
			DAY(appointments.date) as dayNumber, 
			MONTHNAME(appointments.date) as month, 
			YEAR(appointments.date) AS yr, 
			appointments.startTime, appointments.endTime
		FROM 
			appointments
		WHERE 
			appointments.status = 'scheduled' 
		AND 
			DATEDIFF(appointments.date, CURDATE()) < 7 
		ORDER BY 
			appointments.date, appointments.startTime ASC
	);

	--
	-- Create a summary of the schedule for the coming two weeks
	--
	CREATE VIEW scheduleFortnightlyDetailed AS (
		SELECT 
			appointments.appointmentID, 
			appointments.date, 
			DAYNAME(appointments.date) AS day, 
			DAY(appointments.date) as dayNumber, 
			MONTHNAME(appointments.date) as month, 
			YEAR(appointments.date) AS yr, 
			appointments.startTime, appointments.endTime
		FROM 
			appointments
		WHERE 
			appointments.status = 'scheduled' 
		AND 
			DATEDIFF(appointments.date, CURDATE()) < 14 
		ORDER BY 
			appointments.date, appointments.startTime ASC
	);

	--
	-- Create a summary of all schedule appointments
	--
	CREATE VIEW scheduleDetailed AS (
		SELECT 
			appointments.appointmentID, 
			appointments.patientID,
			appointments.date, 
			DAYNAME(appointments.date) AS day, 
			DAY(appointments.date) as dayNumber, 
			MONTHNAME(appointments.date) as month, 
			YEAR(appointments.date) AS yr, 
			appointments.startTime, appointments.endTime
		FROM 
			appointments
		WHERE 
			appointments.status = 'scheduled' 
		ORDER BY 
			appointments.date, appointments.startTime ASC
	);

	--
	-- Create a summary of all upcoming appointments
	--
	CREATE VIEW scheduleSummary AS (

		SELECT 
			appointments.date, 
			appointments.patientID,
			DAYNAME(appointments.date) AS day, 
			DAY(appointments.date) as dayNumber, 
			MONTHNAME(appointments.date) as month, 
			YEAR(appointments.date) AS yr, 
			COUNT(appointmentID) AS numberAppointments, 
			MIN(appointments.startTime) AS earliestAppStart, 
			MAX(appointments.endTime) AS latestAppEnd 
		FROM 
			appointments 
		WHERE 
			appointments.status = 'scheduled' 
		GROUP BY 
			appointments.date 
		ORDER BY appointments.date ASC

	);


--	The first three views provide a detailed tabulation of upcoming appointment dates,
--	and their times, so Helen can readily find upcoming dates that are more or less suitable
--	from these views, before pencilling in a specific appointment date and time.
--	If no suitable appointment slots can be found based on
--	these two views, the `scheduleSummary` provides a complete perspective of dates,
--	and the number of treatments currently scheduled for each day. 
--	If a date or time does not appear in these tables, then Helen knows that 
--	an appointment can be scheduled on that date/time.
--	To insert an appointment into the database, the following SQL statement
--	can be executed:

	INSERT INTO `appointments` 
		(`appointmentID`, `date`, `employeeID`, `patientID`, `specialistID`, 
			`status`, `startTime`, `endTime`)
	VALUES
		('app9999998','2020-05-15','e001','p00001','sp00001',
			'scheduled','09:00:00','10:30:00');

--	alternatively, the column headers can be ignored so long as subsequent VALUES are
-- 	correctly ordered

	INSERT INTO `appointments` 
		VALUES
		('app9999999','2020-05-15','e001','p00001','sp00001',
			'scheduled','09:00:00','10:30:00');

--	whilst the primary key (appointmentID) ensures uniqueness in appointments rows/tuples,
--	no such restrictions are placed on appointment dates and times
--	and organising appointments is still a semi-manual process that 
--	relies on Helen to ensure there are no clashes.
--	To assist her in this, two views have been created which
--	test the appointment schedule for possible clashes, these are:
--		`doubleBookingDetails`
--		`doubleBookingSummary`
--	and these were created as follows:

	--
	-- Create a summary of any double bookings
	--
	CREATE VIEW doubleBookingDetails AS (
	    SELECT 
	        appointments.date, 
	        DAYNAME(appointments.date) AS day, 
	        DAY(appointments.date) AS dayNumber, 
	        MONTHNAME(appointments.date) AS month, 
	        YEAR(appointments.date) AS yr,      
	        appointments.appointmentID AS app1ID, 
	        appointments.patientID AS app1PatientID,
	        appointments.startTime AS app1StartTime, 
	        appointments.endTime AS app1EndTime,
	        a1.appointmentID AS app2ID, 
	        a1.patientID AS app2PatientID,
	        a1.startTime AS app2StartTime, 
	        a1.endTime AS app2EndTime
	    FROM 
	        appointments
	    INNER JOIN 
	        appointments a1
	    ON 
	        a1.status = 'scheduled'
	    AND
	        appointments.status = 'scheduled'
	    AND
	        a1.date = appointments.date
	    AND
	        appointments.appointmentID != a1.appointmentID
	    AND
	        (
	            (a1.startTime > appointments.startTime AND a1.startTime < appointments.endTime)
	            OR
	            (a1.endTime > appointments.startTime AND a1.startTime < appointments.endTime)
	            OR
	            (a1.endTime = appointments.startTime AND a1.startTime = appointments.endTime)
	        )
	);
	 
	--
	-- Create a summary of any double bookings
	--
	CREATE VIEW doubleBookingSummary AS (
		SELECT 
	        DISTINCT(doubleBookingDetails.app1ID) AS appointmentID,
	        appointments.date, 
	        appointments.patientID,
	        DAYNAME(appointments.date) AS day, 
	        DAY(appointments.date) AS dayNumber, 
	        MONTHNAME(appointments.date) AS month, 
	        YEAR(appointments.date) AS yr,      
	        appointments.startTime,
	        appointments.endTime
	    FROM 
	        doubleBookingDetails, appointments
	    WHERE
	        doubleBookingDetails.app1ID = appointments.appointmentID
	);

--
--	The `doubleBookingDetail` VIEW gives a detailed overview of any
--	appointments which have the same date (but which also have different appointmentIDs), 
--	and where startTimes and endTimes overlap (that is one appointments start or end time)
--	is between another appointments start or end time
--	
--	The `doubleBookingSummary` VIEW
--	is based on the `doubleBookingDetails` VIEW, with the former providing an overview
--	of any unique appointments which are clashing. Double bookings have been intentionally
--	introduced to the database to illustrate these features. 
--	Once an appointment has been made, rescheduling it is as simple as:

	UPDATE appointments 
		SET 
			appointments.date = '2021-06-02',
			appointments.startTime = '09:00:00',
			appointments.endTime = '10:00:00' 
		WHERE 
			appointments.status = 'scheduled'
		AND
			appointments.appointmentID = "app9999999";

-- 	this change to the appointment will not influence the associated with treatments list
-- 	if it has been created, as the treatments are associated with a given appointment
--	based on the appointmentID. The creation of a list of treatments is describe below.
--	It is noted in the business narrative, that Helen typically adds appointment details
--	to the patients chart. In this case, appointment details for a given patient
--	can be readily access via the following query:

	SELECT
		patients.firstname, patients.surname, patients.patientID,
		appointments.appointmentID, appointments.date
	FROM
		patients, appointments
	WHERE
		patients.patientID = "p00001" 
	AND 
		appointments.patientID = "p00001"
	ORDER BY 
		appointments.date  DESC;

--	assuming one was searching for appointments involving the patient with
--	a patientID = "p00001"

--	---------------------------------------
--	Database structures and SQL queries which satisfy part d)
--		creating a list of treatments
--	---------------------------------------
--	All treatments are stored in the `treatments` table with each treatment
--	assigned a unique primary key (`treatmentID`), along with other information
--	including the cost, a description of the treatment (`treatmentType`) and
--	a foreign key (`specialistID`) which specialists can perform the treatment.
--	To obtain a list of treatments which are performed in-house by Mary Mulcahy
--	The following SQL statement is executed:
	
	SELECT
		treatments.*
	FROM
		treatments
	WHERE
		treatments.specialistID = 
			(SELECT 
				specialists.specialistID 
			FROM
		 		specialists 
		 	WHERE 
		 		specialists.firstname = "Mary"
	 		AND 
	 			specialists.surname = "Mulcahy"
		 	);

--	given that Helen likely knows Mary Mulcahy's specialistID is "sp00001",
--	the following SQL statement simplifies the procedure:

	SELECT
		treatments.*
	FROM
		treatments
	WHERE
		treatments.specialistID = "sp00001";

--	to create a list of treatments associated with the appointment, each treatment
--	and the associated appointmentID are inserted into the appointmentTreatments
--	relation, which is a junction table designed to simplify many-to-many relationships.
--	The following syntax would be used to insert the list of treatments:

	INSERT INTO `appointmentTreatments` 
		(`appTreatID`, `appointmentID`, `treatmentID`) 
		VALUES
		('appTreat9999997','app9999999','tr00015'),
		('appTreat9999998','app9999999','tr00016'),
		('appTreat9999999','app9999999','tr00018');

--	in this case the `appTreatID` is a unique primary key which allows one to associate
--	each unique appointemtID with one or more treatmentIDs. 

--	---------------------------------------------------------------------------------
--	Business use case 2.
--	---------------------------------------------------------------------------------
--	---------------------------------------
--	Text from project narrative
--	---------------------------------------
--	a)	Sometimes patients contact Helen to rearrange or even cancel appointments. 
--		Rearrangements are made by referring to the appointments diary to find a free time, and
--		tippexing out the old time. 
--	b)	Cancellations are done by simply tippexing out the appointment in the diary. 
--	c)	The details in the patient's chart are also updated with 
--		rearrangements and cancellations 
--		(late cancellations are charged a €10 late cancellation fee).
--	---------------------------------------
--	Interpretation of the business use case
--	---------------------------------------
--	"Tippex" essentialy refers to an UPDATE or DELETE statement, depending
--	on the situation. The following business use cases are assumed
--		a)	Helen needs to be able to re-arrange a pre-existing appointment
--		b)	Helen needs to be able to cancel an appointment
--		c)	Helen needs to be able to differentiate between a 'late' cancellation
--			and a timely one, and the patient should be billed for the former.

--	---------------------------------------
--	Database structures and SQL queries which satisfy part a)
--		re-arranging an appointment
--	---------------------------------------
--	The `scheduleDetailed` VIEW provides
--	an overview of upcoming appointments, assuming the date and time of the appointment
--	are known, one can retrieve the appointmentID and patientID (as a confirmatory check) as follows:
	
	SELECT
		*
	FROM
		scheduleDetailed
	WHERE
		scheduleDetailed.date = '2021-06-02'
	AND
		scheduleDetailed.startTime = '09:00:00';

--	This query will return a table of information (appointmentIDs, patientIDs, appointment times and date) 
--	that are occurring at that time. A a single appointmentID ,
-- 	should usually be the result of this query (see notes on double bookings above).
--	With the appointmentID known, rescheduling is trivial, and can be carried out as follows:
	
	UPDATE appointments 
		SET 
			appointments.date = '2021-07-02',
			appointments.startTime = '09:00:00',
			appointments.endTime = '10:00:00' 
		WHERE 
			appointments.status = 'scheduled'
		AND
			appointments.appointmentID = "app9999999";

--	---------------------------------------
--	Database structures and SQL queries which satisfy part b)
--		cancelling an appointment
--	---------------------------------------
--	Cancelling an appointment is slightly more involved than rescheduling one, as it requires
--	removing the appointment and any associated treatments which were scheduled
--	for that appointment. Treatments related to an appointment are stored in the `appointmentTreatments`
--	relation, with each row in `appointmentTreatments` having an `appointmentID`
--	by inclusion of the `appointments.appointmentID` primary key as the foreign key,
--	(`appointmentTreatments.appointmentID`) in the `appointmentTreatments` relation. Because
--	of the foreign key constraint, the entry in `appointmentTreatments` must first be removed.
--	Removing an appointment from the database can be done using the following SQL statements,
--	the first of which removes any treatments associated with the appointment, with the second
--	statement removing the appointment permanently from the DB:

	DELETE 
	FROM 
		appointmentTreatments 
	WHERE 
		appointmentTreatments.appointmentID = 'app9999999';

	DELETE 
	FROM 
		appointments 
	WHERE 
		appointments.appointmentID = 'app9999999';

--	The deletion operation can be confirmed as follow,
--	which should return no results

	SELECT
		appointments.*, appointmentTreatments.* 
	FROM
		appointments, appointmentTreatments
	WHERE
		appointments.appointmentID = 'app9999999'
	AND
		appointments.appointmentID = appointmentTreatments.appointmentID;

--	---------------------------------------
--	Database structures and SQL queries which satisfy part b)
--		managing late cancellations
--	---------------------------------------
--	Late cancellations differ from others, in that there is a cost
--	i.e. a bill (`bills` relation) associated with it, and a permanent,
--	record of the cancellation must be stored for proper auditing and
--	day-to-day business operation.
--	In order to account for this the following strategy has been implemented
--	for simplicity. `appointments` are assigned a `status`, which can be assigned
--	any value, although `completed`, `scheduled` and `late cancellation` appear
--	to be the only relevant options. All `appointments` have associated `treatments`
--	stored in the `appointmentTreatments` relation. When a `scheduled` appointment,
--	becomes a `cancelled` appointment, as described above, one simply deletes the associated
--	`appointment` and `appointmentTreatments` based on the unique `appointmentID`.
--	In the event that an appointment reverts from being `scheduled` to a `late cancellation`
--	Helen would take the following actions.
--
--	Change the appointment status from `scheduled` to `late cancellation`
--

	UPDATE appointments 
		SET 
			appointments.status = 'late cancellation'
		WHERE 
			appointments.appointmentID = 'app0002579';	

--	Note that the appointments.date, appointments.startTime and appointments.endTime
--	Do not have to be edited, and in some sense, shouldn't be -- altering the date
--	and time removes important information related to the nature of the appointment,
--	and any subsequent billing. Note that the VIEWS which have been created to manage
--	scheduling, and double bookings, which include the `scheduleDetailed` 
--	`scheduleWeeklyDetailed`,`scheduleForthnightlyDetailed`,`scheduleSummary`
--	`doubleBookingDetails`, and `doubleBookingSummary` VIEWS only act on `appointments`
--	where the `appointment.status` = 'schedule' and changing the `appointment.status`
--	from `scheduled` to `late cancellation` therefore avoids complications with managing
--	scheduling.

--	Once the appointment status has been changed, the treatments which were going to be
--	administered are modified, with a specific `treatment` with `treatmentID` = 'tr00001',
--	`treatmentType` = `late cancellation`, and `cost` = 10 used to identify late cancellations.
--	The `appointmentTreatments` can be updated as follows, by first removing any pre-existing
--	treatments:

	DELETE 
	FROM 
		appointmentTreatments 
	WHERE 
		appointmentTreatments.appointmentID = 'app0002579';

--	and then inserting the new treatment corresponding to a late cancellation:

	INSERT INTO `appointmentTreatments` 
		(`appTreatID`, `appointmentID`, `treatmentID`) 
		VALUES
		('appTreat9999999','app0002579','tr00001');

--	these transactions can be verified via:

	SELECT 
        appointments.appointmentID,
        appointments.status,
        appointments.date,
        appointments.startTime,
        appointments.endTime,
        appointmentTreatments.treatmentID 
    FROM 
        appointments, appointmentTreatments 
    WHERE 
        appointments.appointmentID = 'app0002579'
    AND
        appointments.appointmentID = appointmentTreatments.appointmentID;

--	In terms of billing, for the late cancellation, or any other appointment
--	bills are created as follows, where the only information required
--	to generate the bill are the:
--		`billNumber`	-a unique primary key used to distinguish between bills
--		`accountNumber` -a foreign key which refers to the `accounts.accountNumber`
--						-which can be associated with a patient with a given patientID 
--		`appointmentID` -a foreign key which is associated with a `treatment` via 
--						-the appointmentID and the junction table, `appointmentTreatments`
--		`issueDate`		-a date which specifies when the bill was created
--		`dueDate`		-a date which specifies when the bill is due so that overdue bills
--						-can be categorised
--	
--	To get the account number associated with a given appointment, the following
--	query is sufficient:

	SELECT 
		accounts.accountNumber 
	FROM 
		accounts 
	WHERE 
		accounts.patientID = 
		(SELECT 
			patientID 
		FROM 
			appointments 
		WHERE 
			appointments.appointmentID = 'app0002579'
		);


--	The bill can be created as follows, assuming the issueDate is today,
--	and the payment is due in two months time, else it will be deemed overdue:

	INSERT INTO `bills` 
		(`accountNumber`, `appointmentID`, `billNumber`, `dueDate`, `issueDate`) 
		VALUES
		('acc000129','app0002579','b999999',CURDATE() + INTERVAL 60 DAY, CURDATE());

--	---------------------------------------------------------------------------------
--	Business use case 3.
--	---------------------------------------------------------------------------------
--	---------------------------------------
--	Text from project narrative
--	---------------------------------------
--	a)	Every Tuesday morning, Helen checks the appointment diary and makes a list of all next
--		week's appointments. 
--		She sends a reminder to all the patients (finding their addresses in their
--		charts), enclosing an appointment card containing the appointment and treatment details with
--		the reminders. 
--	b)	Next, at about 2.30 p.m. she prepares bills by searching the patient charts to
--		find details of any unpaid treatments. 
--	c)	Then she looks up the Treatment Fees guidelines book, which 
--	d)	Dr Mulcahy updates from time to time. 
--	e)	The bills, itemising all unpaid treatments and late cancellations, 
--		are sent to patients in the afternoon post.
--	---------------------------------------
--	Interpretation of the business use case
--	---------------------------------------
--		a)	Helen needs to be able to get a list of all appointments in the following week
--			and to cross-reference these appointments with patients addresses
--			and treatment details to generate postal reminders.
--		b)	Helen needs to be able to generate a list of all unpaid bills
--		c)	Helen needs to be able to access fees associated with treatments in the database
--		d)	Dr Mulcahy occassionaly updates the treatment fees and needs a mechanism
--			to do so within the database
--		e)	Helen requires a mechanism to get a list of all unpaid treatments, 
--			and late cancellations for a given patient so that she can send them 
--			postal reminders
--
--	---------------------------------------
--	Database structures and SQL queries which satisfy part a)
--		getting a list of the following
--		weeks appointments, associating
--		that with patient information,
--		and treatment information so that
--		a reminder can be sent to the patient
--	---------------------------------------
--	Some VIEWS which were generated previously to simplify the process of
--	scheduling appointments for Helen are as follows:
--		`scheduleDetailed`
--		`scheduleWeeklyDetailed`
--		`scheduleForthnightlyDetailed`
--		`scheduleSummary`
--	and a similar approach can be taken here to simplify the process of
--	getting a list of upcoming appointments via the `nextWeeksAppointmentsDetailed` VIEW
--	which was created as follows:

	--
	-- 	Create a summary of next weeks appointments including the appointment
	--	details, patient details (postal), and treatment details
	--
	CREATE VIEW nextWeeksAppointmentsDetailed AS (
		SELECT 
			appointments.appointmentID, 
			patients.firstname,
			patients.surname,
			patients.address,
			patients.patientID,
			appointments.date, 
			DAYNAME(appointments.date) AS day, 
			YEAR(appointments.date) AS yr, 
			appointments.startTime, 
			appointments.endTime,
			COUNT(treatments.treatmentType) AS numberTreatments,
			GROUP_CONCAT(treatments.treatmentID SEPARATOR ' + ') AS allTreatmentIDs
		FROM 
			appointments, patients, treatments, appointmentTreatments
		WHERE 
			appointments.status = 'scheduled'
		AND
			appointmentTreatments.appointmentID = appointments.appointmentID 
		AND 
			treatments.treatmentID = appointmentTreatments.treatmentID 
		AND 
			appointments.patientID = patients.patientID
		AND
			WEEK(appointments.date) = WEEK(CURDATE())+1
		GROUP BY
			appointments.appointmentID
		ORDER BY 
			appointments.date, appointments.startTime ASC
	);


--	---------------------------------------
--	Database structures and SQL queries which satisfy part b)
--		Helen needs to be able to 
--		generate a list of all unpaid bills
--	---------------------------------------
--	In business use case 1, where Helen had to check whether a patient was in arrears,
--	a number of VIEWS were outlined which allowed Helen to quickly access the important
--	information. These included:
--		`billCosts'
--		`billPayments`
--		`billSummary`
--		`overdueBills`
--	The `overdueBills` VIEW provides a complete tabulation of overdue bills
--	and was created as follows from the billSummary VIEW:

	--
	-- get a summary of all overdue bills
	--
	CREATE VIEW overdueBills AS (
		SELECT 
	        billSummary.*, DATEDIFF(CURDATE(), billSummary.dueDate) AS daysOverdue
	    FROM 
	        billSummary 
	    WHERE 
	        balance > 0 AND dueDate < CURDATE()
	    ORDER BY
	        balance DESC, daysOverdue DESC
	);


--	---------------------------------------
--	Database structures and SQL queries which satisfy part c)
--		Helen needs to be able to access 
--		fees associated with treatments 
--		in the database 
--	---------------------------------------
--	The `treatments` relation contains a list of all unique treatments, as defined by
--	the `treatmentID` primary key, with the fee for any treatement given by the 
--	`cost` attribute. To get the `cost` of all treatments, the following query can
--	be used:

	SELECT
		*
	FROM
		treatments;

--	to get the cost associated with a given treatment, the following query suffices:

	SELECT
		*
	FROM
		treatments
	WHERE
		treatments.treatmentID = "tr00011"


--	---------------------------------------
--	Database structures and SQL queries which satisfy part d)
--	Dr Mulcahy occassionaly updates the 
--	treatment fees and needs a mechanism
--	to do so within the database
--	---------------------------------------
--	Updating treatment costs is a delicate matter, and perhaps could
--	have been handled better in the current schema, as directly 
--	changing a treatment cost for an existing treatment
--	will influence historical data, including fees, bill balances and therefore patient
--	arrears. As Dr. Mulcahy only changes her costs from time to time, the simple solution
--	is to introduce a new treatment when costs are updated.
--	The new treatment can have the same treatmentType, i.e. the description of what the treatment
--	is, as this is not a primary key, but using a unique treatmentID (primary key), 
--	the integrity of the data can be ensured. An example is as follows:

	INSERT INTO `treatments` 
	(`cost`, `specialistID`, `treatmentID`, `treatmentType`) 
	VALUES
	('50','sp00001','tr99999','bitewing x-rays');

--	---------------------------------------
--	Database structures and SQL queries which satisfy part e)
--	Helen requires a mechanism to get a 
--	list of all unpaid treatments, 
--	and late cancellations for a given patient 
--	so that she can send them postal reminders
--	---------------------------------------
--	The `overdueBills` VIEW, as described previously,
--	provides Helen with the information required so that she can generate
--	postal reminders for each patient and this can be leveraged again
--	to create a billPostalReminders view:

--	---------------------------------------------------------------------------------
--	Business use case 4.
--	---------------------------------------------------------------------------------
--	a)	Patients pay by cheque, credit card or cash, either by post or by dropping in. 
--	b)	The bill or the bill number is enclosed with the payment. 
--	c)	Treatments which have been paid for are marked as such in the patient's file so that 
--		they will not be billed again. 
--	d)	Patients often arrange to make several small payments for a large bill.
--	---------------------------------------
--	Interpretation of the business use case
--	---------------------------------------
--		a)	Patients pay by a variety of means, but this does not influence the underlying
--			database very much, the `payments` relation should have a field for the
--			payment type
--		b)	Payments should cross-reference the bill to which the refer
--		c)	There needs to be a mechanism to distinguish between treatments/appointments
--			requiring payments, and those where the balance is 0
--		d)	Different payments can refer to the same bill/treatment/appointment
--			and the database should have a mechanism to compute balances by comparing
--			the total costs/fees for various treatments, with the total amount paid
--			against that treatment/bill
--
--	---------------------------------------
--	Database structures and SQL queries which satisfy part a)
--		people pay by different means
--	---------------------------------------
-- 	The `payments` relation stores all data related to payments.
--	An attribute has been included in the `payments` relation to account
--	for this -- `payments.paymentType`. It is a varchar() field which can
--	take arbitrary values, including cash, card, cash-post etc.
--	The KISS principle applies.
--	To get an overview of the types of payments used, the following
--	query is useful:

	SELECT DISTINCT(payments.paymentType) FROM payments;

--	---------------------------------------
--	Database structures and SQL queries which satisfy part b)
--		Payments should cross-reference the 
--		bill to which the refer
--	---------------------------------------
--	The primary key/unique key in the `payments` relation is the `paymentID`
--	To associate a unique payment with a given bill, therefore the primary key in
--	the `bills` relation is used as a foreign key in the `payments` relation.
--	At the simplest level, the payments associated with a all bill can be
--	obtained as follows

	SELECT 
		bills.billNumber, payments.paymentID 
	FROM 
		bills, payments 
	WHERE 
		bills.billNumber = payments.billNumber;

--	being more specific, one can query the payments associated with a given bill
	
	SELECT 
		bills.billNumber, payments.paymentID 
	FROM 
		bills, payments 
	WHERE 
		bills.billNumber = payments.billNumber
	AND
		bills.billNumber = 'b000005';

-- 	further, one can associate the `bills`, `payments` and `accounts`
--	data via:

	SELECT 
		bills.billNumber, accounts.accountNumber, payments.paymentID 
	FROM 
		bills, accounts, payments 
	WHERE 
		bills.billNumber = payments.billNumber
	AND
		bills.accountNumber = accounts.accountNumber
	AND
		bills.billNumber = 'b000005';

--	as the `accountNumber`, the primary key in the `accounts` relation
--	is used as a foreign key in the `bills` relation

--	---------------------------------------
--	Database structures and SQL queries which satisfy part c)
--		There needs to be a mechanism to 
--		distinguish between treatments or
--		appointments requiring payment, 
--		and those where the balance is 0
--	---------------------------------------
--	The project narrative states that, treatments which have been paid for are 
--	marked as such in the patient's file so that 
--	they will not be billed again. This does not necessarily mean that
--	treatments require a 'paid in full' field. Rather, it means
--	that Helen needs to identify those bills that have arrears.
--	The `accountsInArrears` and `overdueBills` VIEWS described previously
--	provide a summary of those bills that have a balance so that she can prompt patients
--	when their `bills` are past their `dueDate`.	

--	---------------------------------------
--	Database structures and SQL queries which satisfy part d)
--		Patients often arrange to make 
--		several small payments for a large bill.
--	---------------------------------------
--	Again, this is accounted for again by including the `billNumber` as a foreign
--	key in `payments` relation. Multiple payments, each with a different
--	payment amount, can refer to the same bill, and the balance must be derived
--	from the underlying relations through VIEWS or other encapsulated approaches.
--	To get a broad overview of those bills which have multiple payments associated
--	with them, the following SQL statement is useful:

	SELECT 
		bills.billNumber, 
		COUNT(payments.paymentID) AS numberBillPayments
	FROM 
		bills, payments 
	WHERE 
		bills.billNumber = payments.billNumber
	GROUP BY
		bills.billNumber
	ORDER BY
		numberBillPayments DESC;

--	one can build upon this by getting the number of payments associated
--	with a give account, the patient details and when they last paid any
--	bill via:

	SELECT 
		bills.accountNumber, 
		patients.firstname,
		patients.surname,
		patients.patientID,
		COUNT(payments.paymentID) AS numberBillPayments,
		MAX(payments.paymentDate) AS lastPaymentDate
	FROM 
		bills, patients, payments, accounts
	WHERE 
		bills.billNumber = payments.billNumber
	AND
		bills.accountNumber = accounts.accountNumber
	AND
		patients.patientID = accounts.patientID
	GROUP BY
		accounts.accountNumber
	ORDER BY
		patients.patientID ASC;

--	The `billPayments` and `billSummary` VIEW provide a complete overview of
--	the payments made on each bill so that individual `payments` do not have
--	to be manually retreived, and summed, and balances computed.

--	---------------------------------------------------------------------------------
--	Business use case 5.
--	---------------------------------------------------------------------------------
--	a)	When a patient arrives for an appointment, he/she presents the appointment card to Helen.
--		The patient sits in the waiting room until the dentist is ready to see him/ her, whereupon
--		Helen passes the appointment card to Dr Mulcahy so that she can see what treatments are to
--		be carried out. 
--	b)	After each visit, Dr Mulcahy completes the appointment card with details of
--		work done and puts the filled card into her "Visit cards out tray". 
--	c)	Helen takes the card and arranges appointments with the patient for any required 
--		follow-up treatments written on the card, and enters them into the appointments diary. 
--	d)	The visit card is then filed in the patient's chart.
--	e)	Sometimes patients make payments "on the spot" before leaving the clinic.
--	---------------------------------------
--	Interpretation of the business use case
--	---------------------------------------
--		a)	The patient presents an appointment card, which details the time/date
--			of the appointment+the treatments to be carried out, and this data
--			should be retrievable from the database.
--		b)	Dr Mulcahy writes something akin to a dental report, which must
--			be stored in the patients chart
--		c)	If follow up visits are required, Helen must be able to schedule appointments
--			and detail associated follow up treatments
--		d)	Refer to point b) -- there needs to be a means to store dental reports in
--			the database
--		e)	Patients sometimes pay there and then - this does not mean that
--			a bill is not created. For auditing and financial reasons, there is
--			is no difference between paying on the spot, or by other means
--			other than Helen needs to carry out the database operations there and then
--	---------------------------------------
--	Database structures and SQL queries which satisfy part a)
--		Appointment card + treatments
--	---------------------------------------
--	The appointment card was posted out by Helen. If Helen is using the new
--	database system, the appointment card will likely have the `appointmentID`,
--	or otherwise, the time/date. The main information required is the list
--	of treatments to be carried out. These can be retrieved, readily, with any of the
--	following statements:

--	Querying based on a known `appointmentID`, which is presumable readily available
--	based on the appointment card the patient presented:

	SELECT 
		treatments.*, appointments.startTime 
	FROM 
		treatments, appointments, appointmentTreatments 
	WHERE 
		appointments.appointmentID = 'app0000001'
	AND 
		appointmentTreatments.appointmentID = appointments.appointmentID
	AND 
		treatments.treatmentID = appointmentTreatments.treatmentID;

--	Querying based on the patientID, and knowing that the appointment is schedule
--	for "today" (note that this exact query will not necessarily work as it was generated on
--	a specific date corresponding to CURDATE()):

	SELECT 
		treatments.*, 
		appointments.startTime,
		patients.patientID,
		patients.firstname,
		patients.surname
	FROM 
		treatments, patients, appointments, appointmentTreatments 
	WHERE 
		patients.patientID = appointments.patientID
	AND
		patients.patientID = 'p00112'
	AND
		appointments.date = CURDATE()
	AND 
		appointmentTreatments.appointmentID = appointments.appointmentID
	AND 
		treatments.treatmentID = appointmentTreatments.treatmentID;

-- 	one can take this notion further, and generate a useful VIEW of the data
--	for both Helen and Mary Mulcahy, which gives a list of all of the 
--	appointments+treatments for the current day. This VIEW is presented in the 
--	`todaysAppointments` VIEW as follows:

	--
	-- 	Create a summary of todays appointments
	--
	CREATE VIEW todaysAppointments AS (

		SELECT 
			patients.patientID,
			patients.firstname,
			patients.surname,
			accounts.accountNumber,
			appointments.appointmentID,
			appointments.startTime,
			appointments.endTime,
			COUNT(treatments.treatmentType) AS numberTreatments,
			GROUP_CONCAT(treatments.treatmentID SEPARATOR ' + ') AS allTreatmentIDs,
			SUM(treatments.cost) AS totalTreatmentCost
		FROM 
			treatments, patients, accounts, appointments, appointmentTreatments 
		WHERE 
			patients.patientID = appointments.patientID
		AND
			patients.patientID = accounts.patientID
		AND
			appointments.date = CURDATE()
		AND 
			appointmentTreatments.appointmentID = appointments.appointmentID
		AND 
			treatments.treatmentID = appointmentTreatments.treatmentID
		GROUP BY
			appointments.appointmentID
	);

--	---------------------------------------
--	Database structures and SQL queries which satisfy part b)
--		Mary Mulcahy fills out visit
--		cards which can be viewed as dental reports
--	---------------------------------------
--	See part d) below and business case 6 referring to dentalReports
--	provided from referrals. A full description of
--	the `dentalReports` relation is provided later.


--	---------------------------------------
--	Database structures and SQL queries which satisfy part c)
--		Helen must be able to schedule
--		follow up visits
--	---------------------------------------
--	The creation of appointments has been described previously

--	---------------------------------------
--	Database structures and SQL queries which satisfy part d)
--		Visit cards are filed in the patient
--		char
--	---------------------------------------
--	see business case 6, referring to dentalReports
--	provided from referrals. A full description of
--	the `dentalReports` relation is provided later.

--	---------------------------------------
--	Database structures and SQL queries which satisfy part e)
--		Some patients pay there and then
--	---------------------------------------
--	The creation of bills, and payments has been described before.
--	The ensure consistency of the database, Helen still has to carry out
--	a number of procedures when patients pay on the spot. 
--	First of which is creating a bill, which was illustratated
--	previously via the command:

	INSERT INTO `bills` 
		(`accountNumber`, `appointmentID`, `billNumber`, `dueDate`, `issueDate`) 
		VALUES
		('acc000129','app0002579','b999999',CURDATE() + INTERVAL 60 DAY, CURDATE());

--	Once the bill is created, Helen will need to create a payment on the spot.
--	To do so, Helen will first require the total cost of the treatments. This can
--	be achieved via the `billCosts` VIEW, which will have been updated when
--	the above bill was created

	SELECT 
		totalCost
	FROM
		billCosts
	WHERE 
		billNumber = 'b999999';

--	To enter a payment, Helen needs to know the patients account number, which is
--	handily provided to her in the `todaysAppointments` VIEW. Aside from this
--	she needs to know the `billNumber`, which she just created, the payment `amount`,
--	and she will need to assign a unique `paymentID` along with the `paymentType`.

	INSERT INTO `payments` 
	(`accountNumber`, `amount`, `billNumber`, `paymentDate`, `paymentID`, `paymentType`) 
	VALUES
	('acc000129',10,'b999999',CURDATE(),'p999999','cash');

--	---------------------------------------------------------------------------------
--	Business use case 6.
--	---------------------------------------------------------------------------------
--	If the patient needs specialist treatment which Dr Mulcahy cannot provide, she 
--	writes the name of an appropriate specialist on the filled visit card 
--	and the secretary sends a patient referral to the specialist. 
--	After specialist treatment, the specialist posts a dental report to Dr
--	Mulcahy, who reads it and files it in the patient's chart.
--	---------------------------------------
--	Interpretation of the business use case
--	---------------------------------------
--		a) 	the database needs to be able to store details of an arbitrary
--			number of specialists, and the treatments they perform.
--			Mary Mulcahy can be assumed to be one of these specialists,
--			and there is no obvious reason to distinguish Mary Mulcahy
--			from others when designing relations - a universal and minimal 
--			DBMS can and should be developed.
--		b)	Helen needs to be able to create referrals, and enter them in
--			the database.
--		c) 	Helen needs to be able to store the dental report arising from
--			referrals to ensure that the patients medical history is complete
--			and the system needs to be able to associate referrals and their reports
--	---------------------------------------
--	Database structures and SQL queries which satisfy part a)
--		The DB needs to be able to store,
--		and retrieve information with multiple
--		specialists and their treatments
--	---------------------------------------
--	For the present project it is assumed that all specialist details can be stored
--	in one relation, and a single relation entitled `specialists` has been created. 
--	Each specialist is assigned a unique `specialistID`, which acts as the primary key 
--	in the `specialists` relation. Along with this unique primary key, the 
--	specialists details, including their name (`firstname`, `lastname`), 
--	`address`, `phoneNumber` and `email` address are stored. Each `specialist` likely
--	has a unique set of speciality treatments which the can perform. In order to 
--	be able to cross reference a specialist, with their treatments, each 
--	unique treatment, as defined by the `treatmentID`, is assigned a `specialistID` 
--	as a foreign key. This allows one to retrieve a list of treatments associated 
--	with a specialist, or conversely, to get a list of specialists based on a query of the
--	`treatmentType`, which is a description of the treatment being performed.
--	The following SQL queries prove useful. To retreive a list of specialists:

	SELECT
		specialists.firstname, specialists.surname, 
		specialists.address, specialists.phoneNumber, specialists.email
	FROM
		specialists
	ORDER BY
		specialists.firstname, specialists.surname;

--	To get a broad overview of specialists and their treatments
--	the following SQL query is useful:

	SELECT
		specialists.specialistID, specialists.firstname, specialists.surname, 
		specialists.address, specialists.phoneNumber, specialists.email, 
		COUNT(treatments.treatmentID) AS numberTreatments
	FROM
		specialists, treatments
	WHERE
		specialists.specialistID = treatments.specialistID
	GROUP BY
		specialists.specialistID
	ORDER BY
		specialists.firstname, specialists.surname;

--	and this query has been made available to Helen via the `specialistTreatmentsSummary`
--	VIEW which was created via:

	-- 	Create a summary of each specialist and the number of treatments they can perform
	CREATE VIEW specialistTreatmentsSummary AS(
		SELECT
			specialists.specialistID, specialists.firstname, specialists.surname, 
			specialists.address, specialists.phoneNumber, specialists.email, 
			COUNT(treatments.treatmentID) AS numberTreatments
		FROM
			specialists, treatments
		WHERE
			specialists.specialistID = treatments.specialistID
		GROUP BY
			specialists.specialistID
		ORDER BY
			specialists.firstname, specialists.surname
	);

--	Similary, the `specialistTreatmentsDetailed` VIEW has been created to 
--	provide a complete breakdown of each specialist, and the treatments they perform:

	-- 	Create a detailed view of each specialist and the treatments they can perform
	CREATE VIEW specialistTreatmentsDetailed AS(
		SELECT
			specialists.specialistID, specialists.firstname, specialists.surname, 
			specialists.address, specialists.phoneNumber, specialists.email, 
			treatments.treatmentID, treatments.treatmentType
		FROM
			specialists, treatments
		WHERE
			specialists.specialistID = treatments.specialistID
		ORDER BY
			specialists.firstname, specialists.surname
	);


--	To get a list of specialists who can perform a given treatment, based on some keyword
--	the following type of SQL query on the `specialistTreatmentsDetailed` VIEW
--	is useful to Helen and Mary Mulcahy, to find for example, specialist who perform
--	x-rays, or wisdom teeth related procedures:

	SELECT 
		*
	FROM
		specialistTreatmentsDetailed
	WHERE
		treatmentType LIKE '%x-ray%';

	SELECT 
		*
	FROM
		specialistTreatmentsDetailed
	WHERE
		treatmentType LIKE '%wisdom%';

--	---------------------------------------
--	Database structures and SQL queries which satisfy part b)
--		Helen needs to be able to create referrals, 
--		and enter them in the database.
--	---------------------------------------
--	Once a suitable specialist has been identified, most likely using the above
--	queries and VIEWS, Helen needs to create a referral.
--	Referrals are stored in a single relation, entitled `referrals`.
--	Each referral has a unique primary key, entitled `referralID`, with foreign
--	keys including the `patientID` and `specialistID`, which reference the 
--	`patients` and `specialists` relations respectively. The `employeeID` is included
--	to ensure that one can assign responsibility to Helen, or a temporary employee
--	should Helen require sick leave/holidays, in terms of who created the referral.
--	To create a referral, the following query is useful:

	INSERT INTO 
		`referrals` (`employeeID`, `patientID`, `referralID`, `specialistID`, `date`) 
			VALUES
		('e001','p00001','ref9999999','sp00002', CURDATE());

--	To get broad overview of referrals, including the patient details, specialist
--	details, and the employee who made the referral the following query is useful
--	and it has been included as a permanent VIEW (`referralsSummary`) in the database:

	SELECT
		referrals.referralID, 
		referrals.date, 
		CONCAT(patients.firstname, " ", patients.surname) AS patient, 
		CONCAT(specialists.firstname, " ", specialists.surname) AS specialist, 
		specialists.address AS specialistAddress,
		CONCAT(employees.firstname, " ", employees.surname) AS madeBy
	FROM 
		patients, specialists, referrals, employees
	WHERE
		referrals.patientID = patients.patientID
	AND
		referrals.employeeID = employees.employeeID
	AND
		referrals.specialistID = specialists.specialistID;

--	To retreive a list of all referrals associated with one patient, one can query
--	the databse as follows:

	SELECT
		*
	FROM 
		referralsSummary
	WHERE
		referralsSummary.patient = "Kieran Somers";

--	It may sometimes be useful to get an overview of how frequently
--	a patient is visiting a given specialist, and the following query
--	is useful in that sense:

	SELECT 
		*
	FROM
		referralsSummary
	WHERE
		referralsSummary.patient = "Kieran Somers"
	AND
		referralsSummary.specialist = "Sibley Andie";


--	---------------------------------------
--	Database structures and SQL queries which satisfy part c)
--		Dental reports provided by
--		external specialists after referrals
--		should be storeable, and retrievable
--		to ensure the patients medical
--		history is complete
--	---------------------------------------
--	A concept which is mentioned regularly in the project narrative
--	is the concept of the patients `chart` - strictly speaking,
--	that does not imply a `chart` relation must exist. Rather,
--	the `chart` is a collection of information stored in different
--	relations, and meaningful groupings of data in these base relations
--	form the basis of an ongoing chart. To accommodate the storing of
--	all patient medical records, a `dentalReports` relation is provided.
--	Each dentalReport contains a unique primary key, the `reportID` 
--	and  EITHER an appointmentID (if the report is related to an 
--	internal appointment in Mary Mulcahys practice) or a referralID (if the report)
--	was provided by an external specialist. For auditing, the `reportDate` is also stored.
--	Note that a constraint should be placed so that the with respect to
--	the `appointmentID` and `referralID`, only one of these two foreign keys should be NULL
--	and only should be NOT NULL, and so these constraints are placed in the `dentalReports`
--	TABLE when it is created as follows:

	CREATE TABLE `dentalReports` (
	`appointmentID` char(10) DEFAULT NULL,
	`comment` varchar(1000) NOT NULL CHECK(LENGTH(`comment`) > 0 AND LENGTH(`comment`) <= 1000),
	`referralID` char(10) DEFAULT NULL 
		CHECK(
			(`appointmentID` is NOT NULL OR `referralID` is NOT NULL) 
			AND  
			(
				(`appointmentID` is NULL and `referralID` is NOT NULL) 
				OR 
				(`referralID` is NULL and `appointmentID` is NOT NULL)
			)
			),
	`reportDate` date NOT NULL,
	`reportID` char(8) NOT NULL CHECK(LENGTH(`reportID`) = 8)
	) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--	If Helen receives a `dentalReport` from either Mary Mulcahy (in the form of a
--	visit card), or an external specialist the following SQL queries 
--	can be used to enter a unique record in the database:

	INSERT INTO 
		`dentalReports` 
		(`appointmentID`, `comment`, `referralID`, `reportDate`, `reportID`) 
	VALUES
		(NULL,'Some medically relevant information.','ref9999999',CURDATE(),'dr999999');

--	In order to produce VIEWS of the data which are representative of a patients
--	medical "chart", one requires patient information, and information from dental
--	reports. To this end, two VIEWS of the base relations are provided.
--	The `patientDentalReportsAll` and `patientDentalReportsLast12Months` VIEWS.
--	Both VIEWS have the same attributes, they are the appointmentID or
--	referralID, the specialistID, the patientID, the specialist and patient
--	names, the date the report was generated and a string describing
--	the treatments carried out and their outcomes. The only distinction is that the latter
--	only presents an overview of dental reports from the previous 12 months.
--	These VIEWS were effectively created via a simple combination of two SELECT
--	statements, and a UNION statement which reference the `dentalReports`, 
--	`patients`, `specialists`, `referrals`, and `appointments` relations as follows:

	-- 	Create a detailed summary of all of the patient dental
	--	reports from both appointments and referrals
	CREATE VIEW patientDentalReportsAll AS (

		SELECT
			dentalReports.reportID,
			dentalReports.appointmentID,
			dentalReports.referralID,
			dentalReports.reportDate,
			patients.patientID,
			CONCAT(patients.firstname, " ", patients.surname) AS patientName,
			specialists.specialistID,
			CONCAT(specialists.firstname, " ", specialists.surname) AS specialistName,
			dentalReports.comment
		FROM
			dentalReports, patients, specialists, referrals
		WHERE
			dentalReports.referralID = referrals.referralID 
				AND
			patients.patientID = referrals.patientID
				AND
			specialists.specialistID = referrals.specialistID 
		UNION ALL
		SELECT
			dentalReports.reportID,
			dentalReports.appointmentID,
			dentalReports.referralID,
			dentalReports.reportDate,
			patients.patientID,
			CONCAT(patients.firstname, " ", patients.surname) AS patientName,
			specialists.specialistID,
			CONCAT(specialists.firstname, " ", specialists.surname) AS specialistName,
			dentalReports.comment
		FROM
			dentalReports, patients, specialists, appointments
		WHERE
			dentalReports.appointmentID = appointments.appointmentID 
				AND
			patients.patientID = appointments.patientID
				AND
			specialists.specialistID = appointments.specialistID 
	);

	-- 	Create a detailed summary of all of the patient dental
	--	reports from the past 12 months
	CREATE VIEW patientDentalReportsLast12Months AS (
		SELECT
			*
		FROM 
			patientDentalReportsAll
		WHERE
			patientDentalReportsAll.reportDate > DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
	);

-- 	patient information can be filtered from these views using relatively straight forward
--	queries such as the following, which retrieves all information for a patient
--	with the name "Kieran Somers":

	-- get all dental reports for "Kieran Somers"
	SELECT
		*
	FROM
		patientDentalReportsAll
	WHERE
		patientDentalReportsAll.patientName = "Kieran Somers";

	-- get all dental reports for "Kieran Somers" from the last 12 months
	SELECT
		*
	FROM
		patientDentalReportsLast12Months
	WHERE
		patientDentalReportsLast12Months.patientName = "Kieran Somers";


	-- get all dental reports for "Kieran Somers" from the last 12 months
	-- where the specialist was NOT Mary Mulcahy
	SELECT
		*
	FROM
		patientDentalReportsLast12Months
	WHERE
		patientDentalReportsLast12Months.patientName = "Kieran Somers"
	AND
		patientDentalReportsLast12Months.specialistName != "Mary Mulcahy";

--	This concludes the description of the database and queries relative to business
--	use cases.
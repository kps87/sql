SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";


--
-- Remove foreign key checks before DROP statements so that database import is fresh\n
--
SET FOREIGN_KEY_CHECKS=0;

--
-- Drop all tables if they already exist - want to do a fresh import every time
--
DROP TABLE IF EXISTS `patients`;
DROP TABLE IF EXISTS `accounts`;
DROP TABLE IF EXISTS `specialists`;
DROP TABLE IF EXISTS `employees`;
DROP TABLE IF EXISTS `treatments`;
DROP TABLE IF EXISTS `appointments`;
DROP TABLE IF EXISTS `appointmentTreatments`;
DROP TABLE IF EXISTS `bills`;
DROP TABLE IF EXISTS `payments`;
DROP TABLE IF EXISTS `referrals`;
DROP TABLE IF EXISTS `dentalReports`;


--
-- Drop all views if they already exist - want to do a fresh import every time
--
DROP VIEW IF EXISTS `billCosts`;
DROP VIEW IF EXISTS `billPayments`;
DROP VIEW IF EXISTS `billSummary`;
DROP VIEW IF EXISTS `overdueBills`;
DROP VIEW IF EXISTS `accountsInArrears`;
DROP VIEW IF EXISTS `scheduleFortnightlyDetailed`;
DROP VIEW IF EXISTS `scheduleWeeklyDetailed`;
DROP VIEW IF EXISTS `scheduleSummary`;
DROP VIEW IF EXISTS `scheduleDetailed`;
DROP VIEW IF EXISTS `doubleBookingDetails`;
DROP VIEW IF EXISTS `doubleBookingSummary`;
DROP VIEW IF EXISTS `nextWeeksAppointmentsDetailed`;
DROP VIEW IF EXISTS `todaysAppointments`;
DROP VIEW IF EXISTS `specialistTreatmentsSummary`;
DROP VIEW IF EXISTS `specialistTreatmentsDetailed`;
DROP VIEW IF EXISTS `referralsSummary`;
DROP VIEW IF EXISTS `patientDentalReportsAll`;
DROP VIEW IF EXISTS `patientDentalReportsLast12Months`;


--
-- Add foreign key checks before any INSERT statements so that integrity of data preserved\n
--
SET FOREIGN_KEY_CHECKS=1;


--
-- Creating table structure for patients
--
CREATE TABLE `patients` (
`address` varchar(200) NOT NULL CHECK(LENGTH(`address`) > 0 AND LENGTH(`address`) <= 200),
`dob` date NOT NULL,
`email` varchar(100) DEFAULT NULL,
`firstname` varchar(50) NOT NULL CHECK(LENGTH(`firstname`) > 0 AND LENGTH(`firstname`) <= 50),
`gender` varchar(10) DEFAULT NULL,
`patientID` char(6) NOT NULL CHECK(LENGTH(`patientID`) = 6),
`phoneNumber` varchar(30) NOT NULL CHECK(LENGTH(`phoneNumber`) > 0 AND LENGTH(`phoneNumber`) <= 30),
`pps` char(9) DEFAULT NULL,
`surname` varchar(50) NOT NULL CHECK(LENGTH(`surname`) > 0 AND LENGTH(`surname`) <= 50)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


--
-- Creating table structure for accounts
--
CREATE TABLE `accounts` (
`accountNumber` char(9) NOT NULL CHECK(LENGTH(`accountNumber`) > 1 AND LENGTH(`accountNumber`) <= 9),
`closedDate` date DEFAULT NULL,
`openedDate` date NOT NULL,
`patientID` char(6) NOT NULL CHECK(LENGTH(`patientID`) = 6)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


--
-- Creating table structure for specialists
--
CREATE TABLE `specialists` (
`address` varchar(200) NOT NULL CHECK(LENGTH(`address`) > 0 AND LENGTH(`address`) <= 200),
`email` varchar(100) DEFAULT NULL,
`firstname` varchar(50) NOT NULL CHECK(LENGTH(`firstname`) > 0 AND LENGTH(`firstname`) <= 50),
`phoneNumber` varchar(30) NOT NULL CHECK(LENGTH(`phoneNumber`) > 0 AND LENGTH(`phoneNumber`) <= 30),
`specialistID` char(7) NOT NULL CHECK(LENGTH(`specialistID`) = 7),
`surname` varchar(50) NOT NULL CHECK(LENGTH(`surname`) > 0 AND LENGTH(`surname`) <= 50)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


--
-- Creating table structure for employees
--
CREATE TABLE `employees` (
`employeeID` char(4) NOT NULL CHECK(LENGTH(`employeeID`) = 4),
`firstname` varchar(50) NOT NULL CHECK(LENGTH(`firstname`) > 0 AND LENGTH(`firstname`) <= 50),
`role` varchar(50) NOT NULL CHECK(LENGTH(`role`) > 0 AND LENGTH(`role`) <= 50),
`startDate` date NOT NULL,
`surname` varchar(50) NOT NULL CHECK(LENGTH(`surname`) > 0 AND LENGTH(`surname`) <= 50)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


--
-- Creating table structure for treatments
--
CREATE TABLE `treatments` (
`cost` float DEFAULT NULL CHECK (`cost` > 0),
`specialistID` char(7) NOT NULL CHECK(LENGTH(`specialistID`) = 7),
`treatmentID` char(7) NOT NULL CHECK(LENGTH(`treatmentID`) = 7),
`treatmentType` varchar(100) NOT NULL CHECK(LENGTH(`treatmentType`) > 0 AND LENGTH(`treatmentType`) <= 100)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


--
-- Creating table structure for appointments
--
CREATE TABLE `appointments` (
`appointmentID` char(10) NOT NULL CHECK(LENGTH(`appointmentID`) = 10),
`date` date NOT NULL,
`employeeID` char(4) NOT NULL CHECK(LENGTH(`employeeID`) = 4),
`patientID` char(6) NOT NULL CHECK(LENGTH(`patientID`) = 6),
`specialistID` char(7) NOT NULL CHECK(LENGTH(`specialistID`) = 7),
`status` varchar(20) NOT NULL CHECK(LENGTH(`status`) > 0 AND LENGTH(`status`) <= 20),
`startTime` time NOT NULL,
`endTime` time NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


--
-- Creating table structure for appointmentTreatments
--
CREATE TABLE `appointmentTreatments` (
`appTreatID` char(15) NOT NULL CHECK(LENGTH(`appTreatID`) = 15),
`appointmentID` char(10) NOT NULL CHECK(LENGTH(`appointmentID`) = 10),
`treatmentID` char(7) NOT NULL CHECK(LENGTH(`treatmentID`) = 7)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


--
-- Creating table structure for bills
--
CREATE TABLE `bills` (
`accountNumber` char(9) NOT NULL CHECK(LENGTH(`accountNumber`) > 1 AND LENGTH(`accountNumber`) <= 9),
`appointmentID` char(10) NOT NULL CHECK(LENGTH(`appointmentID`) = 10),
`billNumber` char(7) NOT NULL CHECK(LENGTH(`billNumber`) = 7),
`dueDate` date NOT NULL,
`issueDate` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


--
-- Creating table structure for payments
--
CREATE TABLE `payments` (
`accountNumber` char(9) NOT NULL CHECK(LENGTH(`accountNumber`) > 1 AND LENGTH(`accountNumber`) <= 9),
`amount` float NOT NULL CHECK (`amount` > 0),
`billNumber` char(7) NOT NULL CHECK(LENGTH(`billNumber`) = 7),
`paymentDate` date NOT NULL,
`paymentID` char(7) NOT NULL CHECK(LENGTH(`paymentID`) = 7),
`paymentType` varchar(20) NOT NULL CHECK(LENGTH(`paymentType`) > 0 AND LENGTH(`paymentType`) <= 20)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


--
-- Creating table structure for referrals
--
CREATE TABLE `referrals` (
`employeeID` char(4) NOT NULL CHECK(LENGTH(`employeeID`) = 4),
`patientID` char(6) NOT NULL CHECK(LENGTH(`patientID`) = 6),
`referralID` char(10) NOT NULL CHECK(LENGTH(`referralID`) = 10),
`specialistID` char(7) NOT NULL CHECK(LENGTH(`specialistID`) = 7),
`date` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


--
-- Creating table structure for dentalReports
--
CREATE TABLE `dentalReports` (
`appointmentID` char(10) DEFAULT NULL,
`comment` varchar(1000) NOT NULL CHECK(LENGTH(`comment`) > 0 AND LENGTH(`comment`) <= 1000),
`referralID` char(10) DEFAULT NULL CHECK((`appointmentID` is NOT NULL OR `referralID` is NOT NULL) AND  ((`appointmentID` is NULL and `referralID` is NOT NULL) OR (`referralID` is NULL and `appointmentID` is NOT NULL))),
`reportDate` date NOT NULL,
`reportID` char(8) NOT NULL CHECK(LENGTH(`reportID`) = 8)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


--
-- get a summary of all bill costs
--
CREATE VIEW billCosts AS (
	SELECT 
		bills.billNumber, 
		bills.appointmentID,
		count(treatments.treatmentID) AS numberTreatments, 
		GROUP_CONCAT(treatments.treatmentID SEPARATOR ' + ') AS allTreatmentIDs,
		sum(treatments.cost) AS totalCost
	FROM 
		bills,treatments, appointmentTreatments
	WHERE 
		appointmentTreatments.appointmentID = bills.appointmentID 
	AND 
		appointmentTreatments.treatmentID = treatments.treatmentID 
	GROUP BY 
		bills.billNumber  
);

--
-- get a summary of all bill payments
--
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

--
-- get a summary of all bills where costs-payments are reported
--
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

--
-- create a summary of all accounts that are in arrears
--
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

--
-- 	Create a summary of each specialist and the number of treatments they
--	can perform
--
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

--
-- 	Create a detailed view of each specialist and the treatments they
--	can perform
--
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

--
-- 	Create a detailed summary of all of the referrals
--
CREATE VIEW referralsSummary AS(
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
		referrals.specialistID = specialists.specialistID
);


--
-- 	Create a detailed summary of all of the patient dental
--	reports from both appointments and referrals
--
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

--
-- 	Create a detailed summary of all of the patient dental
--	reports from both appointments and referrals
--
CREATE VIEW patientDentalReportsLast12Months AS (

	SELECT
		*
	FROM 
		patientDentalReportsAll
	WHERE
		patientDentalReportsAll.reportDate > DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
);

--
-- Indexes for dumped tables
--


--
-- Indexes for table `patients`
--
ALTER TABLE `patients`
	ADD PRIMARY KEY (`patientID`);

--
-- Indexes for table `accounts`
--
ALTER TABLE `accounts`
	ADD PRIMARY KEY (`accountNumber`),
	ADD KEY `patientID` (`patientID`);

--
-- Indexes for table `specialists`
--
ALTER TABLE `specialists`
	ADD PRIMARY KEY (`specialistID`);

--
-- Indexes for table `employees`
--
ALTER TABLE `employees`
	ADD PRIMARY KEY (`employeeID`);

--
-- Indexes for table `treatments`
--
ALTER TABLE `treatments`
	ADD PRIMARY KEY (`treatmentID`),
	ADD KEY `specialistID` (`specialistID`);

--
-- Indexes for table `appointments`
--
ALTER TABLE `appointments`
	ADD PRIMARY KEY (`appointmentID`),
	ADD KEY `patientID` (`patientID`),
	ADD KEY `employeeID` (`employeeID`),
	ADD KEY `specialistID` (`specialistID`);

--
-- Indexes for table `appointmentTreatments`
--
ALTER TABLE `appointmentTreatments`
	ADD PRIMARY KEY (`appTreatID`),
	ADD KEY `appointmentID` (`appointmentID`),
	ADD KEY `treatmentID` (`treatmentID`);

--
-- Indexes for table `bills`
--
ALTER TABLE `bills`
	ADD PRIMARY KEY (`billNumber`),
	ADD KEY `accountNumber` (`accountNumber`),
	ADD KEY `appointmentID` (`appointmentID`);

--
-- Indexes for table `payments`
--
ALTER TABLE `payments`
	ADD PRIMARY KEY (`paymentID`),
	ADD KEY `accountNumber` (`accountNumber`),
	ADD KEY `billNumber` (`billNumber`);

--
-- Indexes for table `referrals`
--
ALTER TABLE `referrals`
	ADD PRIMARY KEY (`referralID`),
	ADD KEY `patientID` (`patientID`),
	ADD KEY `employeeID` (`employeeID`),
	ADD KEY `specialistID` (`specialistID`);

--
-- Indexes for table `dentalReports`
--
ALTER TABLE `dentalReports`
	ADD PRIMARY KEY (`reportID`),
	ADD KEY `appointmentID` (`appointmentID`),
	ADD KEY `referralID` (`referralID`);

--
-- Constraints for dumped tables
--


--
-- Constraints for table `accounts`
--
ALTER TABLE `accounts`
	ADD CONSTRAINT `accounts_fk_1` FOREIGN KEY (`patientID`) REFERENCES `patients` (`patientID`);

--
-- Constraints for table `treatments`
--
ALTER TABLE `treatments`
	ADD CONSTRAINT `treatments_fk_1` FOREIGN KEY (`specialistID`) REFERENCES `specialists` (`specialistID`);

--
-- Constraints for table `appointments`
--
ALTER TABLE `appointments`
	ADD CONSTRAINT `appointments_fk_1` FOREIGN KEY (`patientID`) REFERENCES `patients` (`patientID`),
	ADD CONSTRAINT `appointments_fk_2` FOREIGN KEY (`employeeID`) REFERENCES `employees` (`employeeID`),
	ADD CONSTRAINT `appointments_fk_3` FOREIGN KEY (`specialistID`) REFERENCES `specialists` (`specialistID`);

--
-- Constraints for table `appointmentTreatments`
--
ALTER TABLE `appointmentTreatments`
	ADD CONSTRAINT `appointmentTreatments_fk_1` FOREIGN KEY (`appointmentID`) REFERENCES `appointments` (`appointmentID`),
	ADD CONSTRAINT `appointmentTreatments_fk_2` FOREIGN KEY (`treatmentID`) REFERENCES `treatments` (`treatmentID`);

--
-- Constraints for table `bills`
--
ALTER TABLE `bills`
	ADD CONSTRAINT `bills_fk_1` FOREIGN KEY (`accountNumber`) REFERENCES `accounts` (`accountNumber`),
	ADD CONSTRAINT `bills_fk_2` FOREIGN KEY (`appointmentID`) REFERENCES `appointments` (`appointmentID`);

--
-- Constraints for table `payments`
--
ALTER TABLE `payments`
	ADD CONSTRAINT `payments_fk_1` FOREIGN KEY (`accountNumber`) REFERENCES `accounts` (`accountNumber`),
	ADD CONSTRAINT `payments_fk_2` FOREIGN KEY (`billNumber`) REFERENCES `bills` (`billNumber`);

--
-- Constraints for table `referrals`
--
ALTER TABLE `referrals`
	ADD CONSTRAINT `referrals_fk_1` FOREIGN KEY (`patientID`) REFERENCES `patients` (`patientID`),
	ADD CONSTRAINT `referrals_fk_2` FOREIGN KEY (`employeeID`) REFERENCES `employees` (`employeeID`),
	ADD CONSTRAINT `referrals_fk_3` FOREIGN KEY (`specialistID`) REFERENCES `specialists` (`specialistID`);

--
-- Constraints for table `dentalReports`
--
ALTER TABLE `dentalReports`
	ADD CONSTRAINT `dentalReports_fk_1` FOREIGN KEY (`appointmentID`) REFERENCES `appointments` (`appointmentID`),
	ADD CONSTRAINT `dentalReports_fk_2` FOREIGN KEY (`referralID`) REFERENCES `referrals` (`referralID`);


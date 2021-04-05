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


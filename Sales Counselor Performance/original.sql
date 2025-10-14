USE DataWarehouse;

-- DECLARE @StartDate DATE = '5/17/2025'; -- Replace with your start date
-- DECLARE @EndDate DATE = '6/16/2025'; -- Replace with your end date
WITH BaseData
AS (
	SELECT a.CommunityId
		,a.ActivitySubject
		,a.ActivityType
		,a.ActivityTypeDetail
		,a.CompletedDate
		,a.Result
		,a.activityid
		,a.isSalesMail
		,a.activityCreatedBy
		,s.fullname
		,s.systemuserid BookerOwnerid
		,c.GroupedShortName
		,'CommpletedAppt' AS Source
		,acc.ksl_donotcontactreason
		,-- Include the do not contact reason
		acc.accountid -- Add accountid for NRR lookup
	FROM (
		SELECT CASE 
				WHEN a.activityid IN (
						'9ad6f0ea-bb4d-ef11-a316-000d3a37eb33'
						,'99c01aba-3b53-ef11-a316-000d3a369a19'
						,'6df0bead-ec4d-ef11-a316-000d3a37eb33'
						,'f9bcb466-d849-ef11-a317-0022480295c5'
						,'1b785436-7e39-ef11-8409-000d3a3bcc75'
						,'943abf7a-4544-ef11-8409-000d3a37eb33'
						,'7bea5c38-963f-ef11-8409-002248095061'
						,'1e6a9cc7-103e-ef11-8409-0022480295c5'
						,'a6d588c7-133e-ef11-8409-000d3a37eb33'
						,'dc20af4b-083b-ef11-8409-6045bd09b20c'
						,'51e815ba-e33a-ef11-8409-6045bd01a259'
						,'a7347da4-593d-ef11-8409-6045bd01a259'
						,'b1be0989-7d38-ef11-8409-002248095061'
						)
					THEN 'a9ee54fb-70b0-ec11-9840-000d3a5c03ed'
				ELSE [activityCreatedBy]
				END AS [activityCreatedBy]
			,-- to account for an issue with appt being marked as created by scribe1
			a.CommunityId
			,a.ActivitySubject
			,a.ActivityType
			,a.ActivityTypeDetail
			,a.CompletedDate
			,a.Result
			,a.activityid
			,a.isSalesMail
			,a.accountid
			,IsBD
		FROM [DataWarehouse].[dbo].[Fact_Activity] a
		) a
	JOIN [KSLCLOUD_MSCRM]..systemuser s ON s.systemuserid = a.[activityCreatedBy]
	JOIN (
		SELECT DISTINCT Groupedksl_communityId
			,GroupedShortName
		FROM [DataWarehouse].[dbo].[dim_community]
		) c ON c.Groupedksl_communityId = a.CommunityId
	JOIN [KSLCLOUD_MSCRM].[dbo].[account] acc WITH (NOLOCK) ON a.accountid = acc.accountid -- Join with account table
	WHERE (
			IsBD = 'no'
			--   AND a.CompletedDate BETWEEN @StartDate AND @EndDate
			AND s.title LIKE '%sales counselor%'
			)
	
	UNION ALL
	
	SELECT a.ksl_CommunityId AS CommunityId
		,ap.Subject AS ActivitySubject
		,ap.ActivityTypeCode AS ActivityType
		,ap.ksl_appointmenttype AS ActivityTypeDetail
		,CONVERT(DATE, ap.scheduledend) AS CompletedDate
		,ksl_resultoptions_displayname AS Result
		,ap.activityid
		,CASE 
			WHEN ap.activityid IN (
					SELECT activityid
					FROM kslcloud_mscrm.dbo.ksl_sms
					WHERE description LIKE '%sm.chat%'
					)
				OR ap.activityid IN (
					SELECT activityid
					FROM kslcloud_mscrm.dbo.email
					WHERE description LIKE '%See your personal message here!%'
						AND subject NOT LIKE 'Re: %'
					)
				THEN 'Yes'
			ELSE 'No'
			END AS isSalesMail
		,ap.createdby
		,s.fullname
		,s.systemuserid BookerOwnerid
		,c.GroupedShortName
		,'BookedAppt' AS Source
		,a.ksl_donotcontactreason
		,-- Include the do not contact reason
		a.accountid -- Add accountid for NRR lookup
	FROM (
		SELECT Subject
			,ActivityTypeCode
			,ksl_appointmenttype
			,RegardingObjectId
			,ksl_appointmenttype_displayname
			,statecode_displayname
			,ksl_resultoptions_displayname
			,scheduledend
			,scheduledstart
			,actualend
			,activityid
			,CASE 
				WHEN activityid IN (
						'9ad6f0ea-bb4d-ef11-a316-000d3a37eb33'
						,'99c01aba-3b53-ef11-a316-000d3a369a19'
						,'6df0bead-ec4d-ef11-a316-000d3a37eb33'
						,'f9bcb466-d849-ef11-a317-0022480295c5'
						,'1b785436-7e39-ef11-8409-000d3a3bcc75'
						,'943abf7a-4544-ef11-8409-000d3a37eb33'
						,'7bea5c38-963f-ef11-8409-002248095061'
						,'1e6a9cc7-103e-ef11-8409-0022480295c5'
						,'a6d588c7-133e-ef11-8409-000d3a37eb33'
						,'dc20af4b-083b-ef11-8409-6045bd09b20c'
						,'51e815ba-e33a-ef11-8409-6045bd01a259'
						,'a7347da4-593d-ef11-8409-6045bd01a259'
						,'b1be0989-7d38-ef11-8409-002248095061'
						)
					THEN 'a9ee54fb-70b0-ec11-9840-000d3a5c03ed'
				ELSE createdby
				END createdby -- to account for an issue with appt being marked as created by scribe1
		FROM [KSLCLOUD_MSCRM].[dbo].[appointment]
		) ap
	JOIN kslcloud_mscrm.dbo.Account a WITH (NOLOCK) ON ap.RegardingObjectId = a.accountid -- Correct join
	JOIN [KSLCLOUD_MSCRM]..systemuser s ON s.systemuserid = ap.createdby
	JOIN (
		SELECT DISTINCT Groupedksl_communityId
			,GroupedShortName
		FROM [DataWarehouse].[dbo].[dim_community]
		) c ON c.Groupedksl_communityId = a.ksl_CommunityId
	WHERE (
			ksl_appointmenttype_displayname = 'In-Person Appointment'
			-- AND ap.statecode_displayname IN ('Completed')
			AND ap.activityid NOT IN (
				SELECT activityid
				FROM [DataWarehouse].[dbo].[Fact_Activity]
				)
			--   AND ap.actualend BETWEEN @StartDate AND @EndDate
			AND s.title LIKE '%sales counselor%'
			)
	)
	,AccountCreated
AS (
	SELECT L.ksl_CommunityId AS CommunityId
		,acc.createdon AS AccountCreatedDate
		,s.fullname
		,c.GroupedShortName
	FROM [DataWarehouse].[dbo].[Fact_Lead] L
	JOIN [KSLCLOUD_MSCRM].[dbo].[account] acc ON L.Lead_AccountID = acc.accountid
	JOIN [KSLCLOUD_MSCRM]..systemuser s ON s.systemuserid = acc.createdby
	JOIN (
		SELECT DISTINCT Groupedksl_communityId
			,GroupedShortName
		FROM [DataWarehouse].[dbo].[dim_community]
		) c ON c.Groupedksl_communityId = L.ksl_CommunityId
	WHERE acc.createdon BETWEEN @StartDate
			AND @EndDate
		AND s.title LIKE '%sales counselor%'
	)
	,CommunityNRR
AS (
	-- Modified to capture ALL counselors with NRR in the time period, not just those in BaseData
	SELECT c.GroupedShortName
		,b.fullname
		,b.BookerOwnerid
		,SUM((l.TransferFee + l.AptRate) - l.CommTransFeeSpecial) + SUM(l.NrrAdjustment) AS NRR
	FROM (
		SELECT DISTINCT fullname
			,BookerOwnerid
			,GroupedShortName
			,accountid
		FROM BaseData
		WHERE ActivityType = 'appointment'
		) b
	JOIN Fact_Lease l ON b.accountid = l.accountid
	JOIN [KSLCLOUD_MSCRM]..ksl_apartment a ON a.ksl_apartmentid = l.ksl_ApartmentId
	JOIN [DataWarehouse].[dbo].[Dim_Date] d ON d.DATE = l.StartDate
	JOIN [DataWarehouse].[dbo].[dim_community] c ON c.ksl_communityId = l.ksl_CommunityId
	WHERE d.DATE BETWEEN @StartDate
			AND @EndDate
		AND (
			l.ksl_CareLevelIdName != 'Skilled Nursing'
			OR l.ksl_CareLevelIdName IS NULL
			)
		AND l.ksl_communityId NOT IN (
			'C74BD355-B5DA-4C9A-AE08-C6655B245C38'
			,'FB8AF664-D9C2-4B2C-80C5-1774EA31EDAE'
			)
		AND l.MoveinTransactionType IN (
			'Actual Move In'
			,'Scheduled Move In'
			)
		AND (
			NOT (
				l.MoveOutTransactionType = 'Actual Move Out'
				AND l.MonthsAsResident = 0
				)
			OR MoveOutTransactionType IS NULL
			OR (
				l.MoveOutTransactionType = 'Actual Move Out'
				AND l.MonthsAsResident > 0
				)
			)
	GROUP BY c.GroupedShortName
		,b.fullname
		,b.BookerOwnerid
	)
	,AggregatedBaseData
AS (
	SELECT fullname
		,BookerOwnerid
		,GroupedShortName
		,SUM(CASE 
				WHEN ActivityType = 'appointment'
					AND (
						Result = 'COMP - Completed'
						OR Result = 'CEXP - Community Experience Given'
						)
					AND ActivityTypeDetail <> 864960000 --Exclude phone appointments
					AND Source IN (
						'CommpletedAppt'
						,'BookedAppt'
						)
					THEN 1
				ELSE 0
				END) AS Appointments_CommpletedAppt
		,SUM(CASE 
				WHEN ActivityType = 'appointment'
					AND ActivityTypeDetail <> 864960000 --Exclude phone appointments
					AND Source IN (
						'CommpletedAppt'
						,'BookedAppt'
						)
					THEN 1
				ELSE 0
				END) AS Appointments_BookedAppt
		,SUM(CASE 
				WHEN (
						ActivityType = 'phonecall'
						OR (
							ActivityType = 'appointment'
							AND ActivityTypeDetail = 864960000
							)
						)
					AND Result = 'COMP - Completed'
					THEN 1
				ELSE 0
				END) AS CompletedPhoneCalls
		,SUM(CASE 
				WHEN ActivityType = 'phonecall'
					AND Result NOT IN (
						'BDCI - Bad Contact Information'
						,'CANC - Cancelled'
						,'COMP - Completed'
						)
					AND ActivityTypeDetail <> 864960000
					THEN 1
				ELSE 0
				END) AS AttemptedCalls
		,SUM(CASE 
				WHEN ActivityType = 'phonecall'
					AND Result = 'COMP - Completed'
					AND (
						ActivitySubject = 'INCC - Incoming Call - COMP'
						OR ActivitySubject = 'Incoming Call - COMP'
						)
					THEN 1
				ELSE 0
				END) AS IncomingCompletedCalls
		,SUM(CASE 
				WHEN isSalesMail = 'Yes'
					THEN 1
				ELSE 0
				END) AS SalesMailSent
		,SUM(CASE 
				WHEN (
						ActivityType = 'email'
						AND ActivityTypeDetail = 864960002
						)
					OR (
						ActivityType = 'letter'
						AND ActivityTypeDetail = 864960000
						)
					THEN 1
				ELSE 0
				END) AS SentMessages
		,SUM(CASE 
				WHEN ActivityType = 'ksl_sms'
					AND ActivityTypeDetail = 1002
					THEN 1
				ELSE 0
				END) AS TextsSent
		,SUM(CASE 
				WHEN ActivityType = 'task'
					AND ActivityTypeDetail = 864960003
					THEN 1
				ELSE 0
				END) AS LiveChats
		,SUM(CASE 
				WHEN ActivityType = 'task'
					AND ActivityTypeDetail = 864960003
					THEN 1
				ELSE 0
				END) + SUM(CASE 
				WHEN ActivityType = 'appointment'
					AND ActivityTypeDetail <> 864960000
					AND Source IN (
						'CommpletedAppt'
						,'BookedAppt'
						)
					THEN 1
				ELSE 0
				END) + SUM(CASE 
				WHEN (
						ActivityType = 'phonecall'
						OR (
							ActivityType = 'appointment'
							AND ActivityTypeDetail = 864960000
							)
						)
					AND Result = 'COMP - Completed'
					THEN 1
				ELSE 0
				END) + SUM(CASE 
				WHEN ActivityType = 'phonecall'
					AND Result NOT IN (
						'BDCI - Bad Contact Information'
						,'CANC - Cancelled'
						,'COMP - Completed'
						)
					AND ActivityTypeDetail <> 864960000
					THEN 1
				ELSE 0
				END) + SUM(CASE 
				WHEN isSalesMail = 'Yes'
					THEN 1
				ELSE 0
				END) + SUM(CASE 
				WHEN (
						ActivityType = 'email'
						AND ActivityTypeDetail = 864960002
						)
					OR (
						ActivityType = 'letter'
						AND ActivityTypeDetail = 864960000
						)
					THEN 1
				ELSE 0
				END) + SUM(CASE 
				WHEN ActivityType = 'ksl_sms'
					AND ActivityTypeDetail = 1002
					THEN 1
				ELSE 0
				END) AS TotalActivities
		,SUM(CASE 
				WHEN ksl_donotcontactreason IS NOT NULL
					AND ActivityType IN (
						'appointment'
						,'phonecall'
						,'email'
						,'letter'
						,'ksl_sms'
						)
					OR (
						ActivityType = 'task'
						AND ActivityTypeDetail = 864960003
						)
					THEN 1
				ELSE 0
				END) AS TotalActivities_DoNotContact
	FROM BaseData bd
	WHERE bd.CompletedDate BETWEEN @StartDate
			AND @EndDate
	-- and fullname = 'Allison Nani'
	GROUP BY fullname
		,GroupedShortName
		,BookerOwnerid
	)
	,AggregatedAccounts
AS (
	SELECT fullname
		,GroupedShortName
		,COUNT(AccountCreatedDate) AS AccountsCreated
	FROM AccountCreated
	GROUP BY fullname
		,GroupedShortName
	)
-- Use FULL OUTER JOIN to capture all counselors who have either activities OR NRR
SELECT COALESCE(bd.fullname, nrr.fullname) AS fullname
	,COALESCE(bd.BookerOwnerid, nrr.BookerOwnerid) AS BookerOwnerid
	,COALESCE(bd.GroupedShortName, nrr.GroupedShortName) AS GroupedShortName
	,COALESCE(bd.Appointments_CommpletedAppt, 0) AS Appointments_CommpletedAppt
	,COALESCE(bd.Appointments_BookedAppt, 0) AS Appointments_BookedAppt
	,COALESCE(bd.CompletedPhoneCalls, 0) AS CompletedPhoneCalls
	,COALESCE(bd.AttemptedCalls, 0) AS AttemptedCalls
	,COALESCE(bd.IncomingCompletedCalls, 0) AS IncomingCompletedCalls
	,COALESCE(bd.SalesMailSent, 0) AS SalesMailSent
	,COALESCE(bd.SentMessages, 0) AS SentMessages
	,COALESCE(bd.TextsSent, 0) AS TextsSent
	,COALESCE(bd.LiveChats, 0) AS LiveChats
	,COALESCE(bd.TotalActivities, 0) AS TotalActivities
	,COALESCE(bd.TotalActivities_DoNotContact, 0) AS TotalActivities_DoNotContact
	,COALESCE(ac.AccountsCreated, 0) AS AccountsCreated
	,COALESCE(nrr.NRR, 0) AS CommunityNRR
FROM AggregatedBaseData bd
FULL OUTER JOIN CommunityNRR nrr ON bd.GroupedShortName = nrr.GroupedShortName
	AND bd.BookerOwnerid = nrr.BookerOwnerid
LEFT JOIN AggregatedAccounts ac ON COALESCE(bd.fullname, nrr.fullname) = ac.fullname
	AND COALESCE(bd.GroupedShortName, nrr.GroupedShortName) = ac.GroupedShortName
ORDER BY COALESCE(bd.fullname, nrr.fullname);
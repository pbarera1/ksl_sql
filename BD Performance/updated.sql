use KSLCLOUD_MSCRM_RESTORE_TEST;
declare @Year int = 2025;

WITH activity
AS (
	SELECT b.ownerid AccountOwnerID
		,b.owneridname AccountOwnerName
		,a.ksl_CommunityId AS CommunityId
		,a.ksl_CommunityIdName AS CommunityIdName
		,
		--Get Last Attempt Information
		b.Subject AS ActivitySubject
		,b.ActivityTypeCode + ' BD' AS ActivityType
		,b.ActivityTypeDetail AS ActivityTypeDetail
		,convert(DATE, b.CompletedDate) CompletedDate
	FROM (
		SELECT activityid
			,ksl_resultoptions_displayname AS Rslt
			,ownerid
			,Assoc.USR_First + ' ' + Assoc.USR_Last AS owneridname
			,PC.Subject
			,PC.ActivityTypeCode
			,PC.activitytypecode AS ActivityTypeDetail
			,PC.regardingobjectid
			,PC.scheduledend AS CompletedDate
			,left(PC.description, 300) AS notes
		FROM KSLCLOUD_MSCRM_RESTORE_TEST.dbo.activities PC WITH (NOLOCK)
		LEFT JOIN KiscoCustom.dbo.Associate Assoc ON PC.ownerid = Assoc.SalesAppID
		-- all activities except sms, task
		WHERE PC.activitytypecode NOT LIKE '%text%'
		AND PC.activitytypecode <> 'Task'
		AND PC.statuscode_displayname = 'Completed'
		AND PC.ksl_resultoptions_displayname <> 'Cancelled'
		) AS b
	INNER JOIN kslcloud_mscrm.dbo.contact a WITH (NOLOCK) ON b.RegardingObjectId = a.contactid
	WHERE YEAR(CompletedDate) = @Year -- Filter by the selected year
		AND CompletedDate BETWEEN DATEFROMPARTS(@Year, 1, 1) -- Start from January 1st of the selected year
			AND CASE 
					WHEN @Year = YEAR(GETDATE())
						THEN GETDATE() -- If it's the current year, go up to today
					ELSE DATEFROMPARTS(@Year, 12, 31) -- If it's a past year, go up to December 31st of that year
					END
	
	UNION ALL
	
	-- Appointments with active residents - appointments for generating Resident referrals
	SELECT e.ownerid AccountOwnerID
		,e.owneridname AccountOwnerName
		,e.ksl_CommunityId AS CommunityId
		,e.ksl_CommunityIdName AS CommunityIdName
		,
		--Get Last Attempt Information
		e.Subject AS ActivitySubject
		,'RR ' + e.ActivityTypeCode + ' BD' AS ActivityType
		,e.ActivityTypeDetail AS ActivityTypeDetail
		,convert(DATE, e.CompletedDate) CompletedDate
	FROM (
		SELECT TOP 1000 activityid
			,ksl_resultoptions_displayname AS Rslt
			,pc.ownerid
			,Assoc.USR_First + ' ' + Assoc.USR_Last AS owneridname
			,PC.Subject
			,PC.ActivityTypeCode
			,PC.activitytypecode AS ActivityTypeDetail
			,PC.regardingobjectid
			,PC.scheduledstart AS CompletedDate
			,c.MoveInDate
			,left(PC.description, 300) AS notes
			,c.ksl_CommunityId
			,c.ksl_CommunityIdName
		FROM KSLCLOUD_MSCRM_RESTORE_TEST.dbo.activities PC WITH (NOLOCK)
		LEFT JOIN KiscoCustom.dbo.Associate Assoc ON PC.ownerid = Assoc.SalesAppID
		JOIN [DataWarehouse].[dbo].[Fact_Lead] c ON c.Lead_AccountID = pc.regardingobjectid
		WHERE PC.activitytypecode IN ('Committed Face Appointment','Unscheduled Walk-In')
		AND PC.statuscode_displayname = 'Completed'
			--AND PC.ksl_resultoptions <> '100000000' --Result: 100000000:Cancelled 
			--AND pc.ksl_appointmenttype = '864960003' -- Bus Development Drop In
			--and pc.compl
			AND scheduledstart > c.MoveInDate
			AND YEAR(scheduledstart) = @Year -- Filter by the selected year
			AND scheduledstart BETWEEN DATEFROMPARTS(@Year, 1, 1) -- Start from January 1st of the selected year
				AND CASE 
						WHEN @Year = YEAR(GETDATE())
							THEN GETDATE() -- If it's the current year, go up to today
						ELSE DATEFROMPARTS(@Year, 12, 31) -- If it's a past year, go up to December 31st of that year
						END
		) e
	)
	,actSUM
AS (
	SELECT accountownerid
		,Sum(CASE 
				WHEN [activitytype] IN ('Committed Face Appointment BD', 'Unscheduled Walk-In BD')
				--WHEN [activitytype] LIKE '%appointment BD%'
					THEN 1
				ELSE 0
				END) AS appointment_BD
		,Sum(CASE 
				WHEN [activitytype] IN ('RR Committed Face Appointment BD', 'RR Unscheduled Walk-In BD') --TODO correct?
				--WHEN [activitytype] LIKE '%RRappointment BD%'
					THEN 1
				ELSE 0
				END) * 1.0 AS RR_appointment_BD
		,Sum(CASE 
				WHEN [activitytype] LIKE '%email%'
					THEN 1
				ELSE 0
				END) AS email_BD
		,Sum(CASE 
				WHEN [activitytype] LIKE '%letter%'
					THEN 1
				ELSE 0
				END) AS letter_BD
		,Sum(CASE 
				WHEN [activitytype] LIKE '%phone%'
				AND [activitytype] <> 'Committed Phone Appointment BD'
					THEN 1
				ELSE 0
				END) AS phonecall_BD
	FROM activity
	GROUP BY accountownerid
	)
	,NRR
AS (
	SELECT sum(RentRev) RentRev
		,ksl_securityregionteamid
	FROM (
		SELECT isnull(sum(ksl_ACT_CommTransFee + new_ApartmentRate - ISNULL(est.ksl_ACT_CommTransFeeSpecial, 0)), 0) AS RentRev
			,a.ksl_CommunityId
		FROM (
			SELECT afh.ksl_BeginDate
				,afh.ksl_ApartmentId
				,afh.ksl_ApartmentIdName
				,afh.ksl_CommunityId
				--,afh.AccountId
				,afh.ksl_communityIdName
				,afh.ksl_accountLeadId
				,MAX(afh.ksl_endDate) AS EndDt
				,afh.ksl_estimateId
				,afh.ksl_BeginTransactionType
				,MAX(afh.ksl_EndTransactionType) ksl_EndTransactionType
				,MAX(afh.ksl_ReasonDetailIDName) AS ksl_ReasonDetailIDName
				,MAX(afh.ksl_MoveOutDestinationIdName) AS ksl_MoveOutDestinationIdName
				,MAX(afh.OwnerId) AS afh_OwnerID
				--,LEA.ksl_ReasonDetailIdName AS ReasonDetail
				,MAX(ksl_MoveOutReasonDetailIdName) AS MoveOutReasonDetail
			FROM ksl_apartmentfinancialhistory afh WITH (NOLOCK) --history of what happened 
			LEFT JOIN account A WITH (NOLOCK) ON a.AccountID = ksl_accountleadid
			LEFT JOIN Quote q WITH (NOLOCK) ON q.QuoteID = ksl_estimateid
			WHERE (
					afh.ksl_BeginTransactionType IN (
						864960001
						,864960003
						,864960007
						,864960008
						) -- 01=Actual Move In, 03=Actual Transfer In, Scheduled Transfer, Scheduled Move In
					AND a.[ksl_initialsourcecategory] = '25AC1CB4-C27F-E311-986A-0050568B37AC'
					AND afh.statecode = 0
					AND (
						afh.ksl_EndTransactionType IN (
							864960004
							,864960006
							,864960002
							,864960005
							)
						OR afh.ksl_EndTransactionType IS NULL
						)
					) -- Actual Transfer Out, Actual move out, Scheduled Transfer,Scheduled move out
				OR (
					afh.ksl_BeginTransactionType = 864960000
					AND afh.statecode = 0
					AND afh.ksl_EndTransactionType IS NULL
					AND CAST(afh.ksl_BeginDate AS DATE) >= CAST(GETDATE() - 15 AS DATE)
					)
			--" . $WhereSDSQL . "
			GROUP BY afh.ksl_BeginDate
				,afh.ksl_ApartmentId
				,afh.ksl_accountLeadId
				,afh.ksl_estimateId
				,afh.ksl_BeginTransactionType
				,afh.ksl_ApartmentIdName
				,afh.ksl_CommunityId
				--,afh.AccountId
				,afh.ksl_communityIdName
			) AS y
		FULL OUTER JOIN [Quote] est ON QuoteID = ksl_estimateId
		LEFT JOIN account A WITH (NOLOCK) ON a.accountid = est.customerid
		WHERE coalesce(CASE 
					WHEN y.ksl_BeginTransactionType = 864960001
						THEN 'Actual Move in'
					WHEN y.ksl_BeginTransactionType = 864960003
						THEN 'Actual Transfer In'
					WHEN y.ksl_BeginTransactionType = 864960007
						THEN 'Short Term Stay Begin'
					WHEN y.ksl_BeginTransactionType = 864960008
						THEN 'Seasonal Stay Begin'
					WHEN y.ksl_BeginTransactionType = 864960000
						THEN 'Scheduled Move in'
							--ELSE 'Other'
					END, est.ksl_estimatetype_displayname) IN (
				'Actual Move in'
				,'Moved In'
				)
			AND a.[ksl_initialsourcecategory] = '25AC1CB4-C27F-E311-986A-0050568B37AC'
			--and isnull(y.ksl_CommunityId,est.ksl_CommunityId) = '0DC35920-B2DE-E211-9163-0050568B37AC'
			AND isnull(ksl_BeginDate, est.ksl_schfinanmovein) BETWEEN DATEFROMPARTS(@Year, 1, 1) -- Start from January 1st of the selected year
				AND CASE 
						WHEN @Year = YEAR(GETDATE())
							THEN GETDATE() -- If the selected year is the current year, use today's date
						ELSE DATEFROMPARTS(@Year, 12, 31) -- Otherwise, use December 31st of the selected year
						END
		GROUP BY a.ksl_CommunityId
		) d
	INNER JOIN [KSLCLOUD_MSCRM].[dbo].ksl_community c WITH (NOLOCK) ON d.ksl_CommunityId = c.ksl_communityid
	--where 	ksl_securityregionteamid = '0933038A-375D-E811-A94F-000D3A3ACDE0'
	GROUP BY ksl_securityregionteamid
	)
	,leads
AS (
	SELECT count(accountid) AS newLeadsavg
		,ksl_securityregionteamid
	FROM [KSLCLOUD_MSCRM].[dbo].[account] a
	INNER JOIN [KSLCLOUD_MSCRM].[dbo].ksl_community c ON a.ksl_communityid = c.ksl_communityid
	WHERE [ksl_initialsourcecategory] = '25AC1CB4-C27F-E311-986A-0050568B37AC'
		AND YEAR(ksl_initialinquirydate) = @Year -- Filter by the selected year
		AND ksl_initialinquirydate BETWEEN DATEFROMPARTS(@Year, 1, 1) -- Start from January 1st of the selected year
			AND CASE 
					WHEN @Year = YEAR(GETDATE())
						THEN GETDATE() -- If it's the current year, go up to today
					ELSE DATEFROMPARTS(@Year, 12, 31) -- If it's a past year, go up to December 31st of that year
					END
	GROUP BY ksl_securityregionteamid
	)
	,MoveIns
AS (
	SELECT count(est.quoteid) AS MoveInavg
		,c.ksl_securityregionteamid
	FROM (
		SELECT afh.ksl_BeginDate
			,afh.ksl_ApartmentId
			,afh.ksl_ApartmentIdName
			,afh.ksl_CommunityId
			--,afh.AccountId
			,afh.ksl_communityIdName
			,afh.ksl_accountLeadId
			,MAX(afh.ksl_endDate) AS EndDt
			,afh.ksl_estimateId
			,afh.ksl_BeginTransactionType
			,MAX(afh.ksl_EndTransactionType) ksl_EndTransactionType
			,MAX(afh.ksl_ReasonDetailIDName) AS ksl_ReasonDetailIDName
			,MAX(afh.ksl_MoveOutDestinationIdName) AS ksl_MoveOutDestinationIdName
			,MAX(afh.OwnerId) AS afh_OwnerID
			--,LEA.ksl_ReasonDetailIdName AS ReasonDetail
			,MAX(ksl_MoveOutReasonDetailIdName) AS MoveOutReasonDetail
		FROM ksl_apartmentfinancialhistory afh WITH (NOLOCK) --history of what happened 
		LEFT JOIN account A WITH (NOLOCK) ON a.AccountID = ksl_accountleadid
		LEFT JOIN Quote q WITH (NOLOCK) ON q.QuoteID = ksl_estimateid
		WHERE (
				afh.ksl_BeginTransactionType IN (
					864960001
					,864960003
					,864960007
					,864960008
					) -- 01=Actual Move In, 03=Actual Transfer In, Scheduled Transfer, Scheduled Move In
				AND afh.statecode = 0
				AND [ksl_initialsourcecategory] = '25AC1CB4-C27F-E311-986A-0050568B37AC'
				AND (
					afh.ksl_EndTransactionType IN (
						864960004
						,864960006
						,864960002
						,864960005
						)
					OR afh.ksl_EndTransactionType IS NULL
					)
				) -- Actual Transfer Out, Actual move out, Scheduled Transfer,Scheduled move out
			OR (
				afh.ksl_BeginTransactionType = 864960000
				AND afh.statecode = 0
				AND afh.ksl_EndTransactionType IS NULL
				AND CAST(afh.ksl_BeginDate AS DATE) >= CAST(GETDATE() - 15 AS DATE)
				)
		GROUP BY afh.ksl_BeginDate
			,afh.ksl_ApartmentId
			,afh.ksl_accountLeadId
			,afh.ksl_estimateId
			,afh.ksl_BeginTransactionType
			,afh.ksl_ApartmentIdName
			,afh.ksl_CommunityId
			--,afh.AccountId
			,afh.ksl_communityIdName
		) AS y
	FULL OUTER JOIN [Quote] est ON QuoteID = ksl_estimateId
	LEFT JOIN account A WITH (NOLOCK) ON a.accountid = est.customerid
	LEFT JOIN contact c1 ON est.ksl_primaryresident1id = c1.contactid
	LEFT JOIN contact c2 ON est.ksl_potentialsecondaryresidentid = c2.contactid
	LEFT JOIN ksl_apartment apt ON est.ksl_ApartmentId = apt.ksl_ApartmentID
	LEFT JOIN ksl_apartment tra ON est.ksl_act_transferfromapartmentid = tra.ksl_ApartmentID
	INNER JOIN [KSLCLOUD_MSCRM].[dbo].ksl_community c ON a.ksl_communityid = c.ksl_communityid
	WHERE coalesce(CASE 
				WHEN y.ksl_BeginTransactionType = 864960001
					THEN 'Actual Move in'
				WHEN y.ksl_BeginTransactionType = 864960003
					THEN 'Actual Transfer In'
				WHEN y.ksl_BeginTransactionType = 864960007
					THEN 'Short Term Stay Begin'
				WHEN y.ksl_BeginTransactionType = 864960008
					THEN 'Seasonal Stay Begin'
				WHEN y.ksl_BeginTransactionType = 864960000
					THEN 'Scheduled Move in'
						--ELSE 'Other'
				END, est.ksl_estimatetype_displayname) IN ('Actual Move in')
		AND YEAR(isnull(ksl_BeginDate, est.ksl_schfinanmovein)) = @Year -- Filter by the selected year
		AND isnull(ksl_BeginDate, est.ksl_schfinanmovein) BETWEEN DATEFROMPARTS(@Year, 1, 1) -- Start from January 1st of the selected year
			AND CASE 
					WHEN @Year = YEAR(GETDATE())
						THEN GETDATE() -- If it's the current year, go up to today
					ELSE DATEFROMPARTS(@Year, 12, 31) -- If it's a past year, go up to December 31st of that year
					END
	--and isnull(y.ksl_CommunityId,est.ksl_CommunityId) = '0DC35920-B2DE-E211-9163-0050568B37AC'
	GROUP BY c.ksl_securityregionteamid
	)
	,newRS
AS (
	SELECT count(contactid) RSourceAvg
		,c.createdby ownerid
	FROM [KSLCLOUD_MSCRM].[dbo].[contact] c
	WHERE [ksl_contacttype] = '864960002'
		AND YEAR(c.createdon) = @Year -- Filter by the selected year
		AND c.createdon BETWEEN DATEFROMPARTS(@Year, 1, 1) -- Start from January 1st of the selected year
			AND CASE 
					WHEN @Year = YEAR(GETDATE())
						THEN GETDATE() -- If it's the current year, go up to today
					ELSE DATEFROMPARTS(@Year, 12, 31) -- If it's a past year, go up to December 31st of that year
					END
	GROUP BY c.createdby
	)
	,ResRef
AS (
	SELECT count(accountid) * 1.0 RRAvg
		,[ksl_associtateduser]
		,[ksl_associtatedusername]
	FROM [KSLCLOUD_MSCRM].[dbo].account c
	INNER JOIN [KSLCLOUD_MSCRM].[dbo].[ksl_referralorgs] r ON r.ksl_referralorgsid = c.ksl_referralorganization
	WHERE YEAR(c.createdon) = @Year -- Filter by the selected year
		AND c.createdon BETWEEN DATEFROMPARTS(@Year, 1, 1) -- Start from January 1st of the selected year
			AND CASE 
					WHEN @Year = YEAR(GETDATE())
						THEN GETDATE() -- If it's the current year, go up to today
					ELSE DATEFROMPARTS(@Year, 12, 31) -- If it's a past year, go up to December 31st of that year
					END
		AND ksl_initialsource = '07E31289-00A3-E311-B839-0050568B7D16' --Resident Referral
	GROUP BY [ksl_associtateduser]
		,[ksl_associtatedusername]
	)

SELECT u.USR_First + ' ' + u.USR_Last AS fullname
	,CASE 
		WHEN r.Name LIKE 'Business Development Director'
			OR r.Name LIKE 'Buisness Developement Director'
			OR r.Name LIKE 'Director, Business Development'
			OR r.Name LIKE 'Director of Strategic Partnership%'
			THEN 'Business Development'
		WHEN r.Name LIKE 'Executive%'
			OR r.Name LIKE 'General Manager'
			THEN 'Executive Director'
		ELSE 'Sales'
		END Title
	,commCrm.ksl_regionidname AS ksl_regionalteamidname
	,a.*
	,newLeadsavg
	,nrr.RentRev RentRevYTD
	,mi.MoveInavg
	,nr.RSourceAvg
	,RRAvg
	,commCrm.ksl_regionid
FROM actsum a
INNER JOIN [KiscoCustom].[dbo].[Associate] u ON u.SalesAppID = a.accountownerid
JOIN KiscoCustom.dbo.KSL_Roles r ON r.roleid = u.RoleID
JOIN KiscoCustom.dbo.Community AS c ON c.CommunityIDY = u.USR_CommunityIDY
JOIN KSLCLOUD_MSCRM_RESTORE_TEST.dbo.ksl_community AS commCrm ON commCrm.ksl_communityid = c.CRM_CommunityID
LEFT JOIN leads l ON commCrm.ksl_securityregionteamid = l.ksl_securityregionteamid
LEFT JOIN nrr ON nrr.ksl_securityregionteamid = commCrm.ksl_securityregionteamid
LEFT JOIN moveins mi ON mi.ksl_securityregionteamid = commCrm.ksl_securityregionteamid
LEFT JOIN newrs nr ON nr.ownerid = u.SalesAppID
LEFT JOIN resref rr ON rr.[ksl_associtateduser] = u.SalesAppID
WHERE appointment_bd + email_bd + phonecall_bd > 5
ORDER BY 2
	,1
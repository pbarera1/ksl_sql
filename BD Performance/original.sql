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
			,owneridname
			,PC.Subject
			,PC.ActivityTypeCode
			,PC.ksl_phonecalltype AS ActivityTypeDetail
			,PC.regardingobjectid
			,PC.ksl_datecompleted AS CompletedDate
			,left(PC.description, 300) AS notes
		FROM kslcloud_mscrm.dbo.PhoneCall PC WITH (NOLOCK)
		WHERE PC.statecode_displayname = 'Completed' --Workflow changed call to completed
			AND PC.ksl_resultoptions <> '864960008' --Result: Anything but cancelled
		
		UNION ALL
		
		SELECT activityid
			,ksl_resultoptions_displayname AS Rslt
			,ownerid
			,owneridname
			,PC.Subject
			,PC.ActivityTypeCode
			,PC.ksl_appointmenttype AS ActivityTypeDetail
			,PC.regardingobjectid
			,PC.scheduledstart AS CompletedDate
			,left(PC.description, 300) AS notes
		FROM kslcloud_mscrm.dbo.appointment PC WITH (NOLOCK)
		WHERE PC.statecode_displayname = 'Completed'
			AND PC.ksl_resultoptions <> '100000000' --Result: 100000000:Cancelled 
		
		UNION ALL
		
		SELECT activityid
			,ksl_emailtype_displayname AS Rslt
			,ownerid
			,owneridname
			,PC.Subject
			,PC.ActivityTypeCode
			,PC.ksl_emailtype AS ActivityTypeDetail
			,PC.regardingobjectid
			,PC.actualend AS CompletedDate
			,left(PC.description, 300) AS notes
		FROM kslcloud_mscrm.dbo.email PC WITH (NOLOCK)
		WHERE PC.statecode_displayname = 'Completed'
			AND PC.ksl_emailtype <> 864960000
		
		UNION ALL
		
		SELECT activityid
			,ksl_lettertype_displayname AS Rslt
			,ownerid
			,owneridname
			,PC.Subject
			,PC.ActivityTypeCode
			,PC.ksl_lettertype AS ActivityTypeDetail
			,PC.regardingobjectid
			,PC.actualend AS CompletedDate
			,left(PC.description, 300) AS notes
		FROM kslcloud_mscrm.dbo.letter PC WITH (NOLOCK)
		WHERE PC.statecode_displayname = 'Completed'
			AND PC.ksl_lettertype <> 864960004
			--Union All
			--SELECT L.accountid, RIGHT(PC.Subject, LEN(PC.Subject) - 13) as [Subject], 'sms' as ActivityTypeCode, NULL as ActivityTypeDetail, PC.regardingobjectid, PC.actualend as CompletedDate, left(PC.description,300) as notes
			--FROM Account L WITH (NOLOCK)
			--INNER JOIN txtsync_sms PC ON PC.RegardingObjectId = L.accountid
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
			,pc.owneridname
			,PC.Subject
			,PC.ActivityTypeCode
			,PC.ksl_appointmenttype AS ActivityTypeDetail
			,PC.regardingobjectid
			,PC.scheduledstart AS CompletedDate
			,c.MoveInDate
			,left(PC.description, 300) AS notes
			,c.ksl_CommunityId
			,c.ksl_CommunityIdName
		FROM kslcloud_mscrm.dbo.appointment PC WITH (NOLOCK)
		JOIN [DataWarehouse].[dbo].[Fact_Lead] c ON c.Lead_AccountID = pc.regardingobjectid
		WHERE PC.statecode_displayname = 'Completed'
			AND PC.ksl_resultoptions <> '100000000' --Result: 100000000:Cancelled 
			AND pc.ksl_appointmenttype = '864960003' -- Bus Development Drop In
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
	SELECT AccountOwnerID
		,sum(CASE 
				WHEN [ActivityType] = 'appointment BD'
					THEN 1
				ELSE 0
				END) AS appointment_BD
		,sum(CASE 
				WHEN [ActivityType] = 'RR appointment BD'
					THEN 1
				ELSE 0
				END) * 1.0 AS RR_appointment_BD
		,sum(CASE 
				WHEN [ActivityType] = 'email BD'
					THEN 1
				ELSE 0
				END) AS email_BD
		,sum(CASE 
				WHEN [ActivityType] = 'letter BD'
					THEN 1
				ELSE 0
				END) AS letter_BD
		,sum(CASE 
				WHEN [ActivityType] = 'phonecall BD'
					THEN 1
				ELSE 0
				END) AS phonecall_BD
	FROM Activity
	GROUP BY AccountOwnerID
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
	--inner join [KSLCLOUD_MSCRM].[dbo].[systemuser] u on u.ksl_regionalteamid = c.ksl_securityregionteamid
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
--SELECT *
--FROM  actSUM
--where systemuserid ='FE6E9B1A-ABAB-E811-A95E-000D3A360847'
SELECT u.fullname
	,CASE 
		WHEN u.Title LIKE 'Business Development Director'
			OR u.Title LIKE 'Buisness Developement Director'
			OR u.Title LIKE 'Director, Business Development'
			OR u.Title LIKE 'Director of Strategic Partnership%'
			THEN 'Business Development'
		WHEN u.Title LIKE 'Executive%'
			OR u.title LIKE 'General Manager'
			THEN 'Executive Director'
		ELSE 'Sales'
		END Title
	,u.ksl_regionalteamidname
	,a.*
	,newLeadsavg
	,nrr.RentRev RentRevYTD
	,mi.MoveInavg
	,nr.RSourceAvg
	,RRAvg
	,u.ksl_regionalteamid
FROM actSUM a
INNER JOIN [KSLCLOUD_MSCRM].[dbo].[systemuser] u ON u.systemuserid = a.AccountOwnerID
LEFT JOIN leads l ON u.ksl_regionalteamid = l.ksl_securityregionteamid
LEFT JOIN nrr ON nrr.ksl_securityregionteamid = u.ksl_regionalteamid
LEFT JOIN MoveIns mi ON mi.ksl_securityregionteamid = u.ksl_regionalteamid
LEFT JOIN newRS nr ON nr.ownerid = u.systemuserid
LEFT JOIN ResRef rr ON rr.[ksl_associtateduser] = u.systemuserid
WHERE appointment_BD + email_BD + phonecall_BD > 5
ORDER BY 2
	,1
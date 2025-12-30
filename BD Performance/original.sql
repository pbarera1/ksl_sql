USE kslcloud_mscrm_restore_test;

DECLARE @Year INT = 2025;

WITH activity
AS (
	SELECT b.ownerid AccountOwnerID
		,b.[from] AccountOwnerName
		,a.ksl_communityid AS CommunityId
		,a.ksl_communityidname AS CommunityIdName
		,
		--Get Last Attempt Information
		b.subject AS ActivitySubject
		,b.activitytypecode AS ActivityType
		,b.activitytypedetail AS ActivityTypeDetail
		,CONVERT(DATE, b.completeddate) CompletedDate
	FROM (
		SELECT activityid
			,ksl_resultoptions_displayname AS Rslt
			,ownerid
			,[from]
			,PC.subject
			,PC.activitytypecode
			,PC.activitytypecode AS ActivityTypeDetail
			,PC.regardingobjectid
			,PC.scheduledstart AS CompletedDate
			,LEFT(PC.description, 300) AS notes
		FROM KSLCLOUD_MSCRM_RESTORE_TEST.dbo.activities PC WITH (NOLOCK)
		WHERE PC.statuscode_displayname = 'Completed'
			AND (
				PC.activitytypecode LIKE '%walk-in%'
				OR PC.activitytypecode LIKE '%face appointment%'
				)
			OR PC.activitytypecode LIKE '%phone%'
			OR PC.activitytypecode LIKE '%email%'
			OR PC.activitytypecode LIKE '%letter%'
		) AS b
	INNER JOIN kslcloud_mscrm.dbo.contact a WITH (NOLOCK) ON b.regardingobjectid = a.contactid
	WHERE Year(completeddate) = @Year -- Filter by the selected year
		AND completeddate BETWEEN Datefromparts(@Year, 1, 1)
				-- Start from January 1st of the selected year
			AND CASE 
					WHEN @Year = Year(Getdate())
						THEN Getdate()
							-- If it's the current year, go up to today
					ELSE Datefromparts(@Year, 12, 31)
						-- If it's a past year, go up to December 31st of that year
					END
	
	UNION ALL
	
	-- Appointments with active residents - appointments for generating Resident referrals
	SELECT e.ownerid AccountOwnerID
		,e.[from] AccountOwnerName
		,e.ksl_communityid AS CommunityId
		,e.ksl_communityidname AS CommunityIdName
		,
		--Get Last Attempt Information
		e.subject AS ActivitySubject
		,'RR ' + e.activitytypecode + ' BD' AS ActivityType
		,e.activitytypedetail AS ActivityTypeDetail
		,CONVERT(DATE, e.completeddate) CompletedDate
	FROM (
		SELECT TOP 1000 activityid
			,ksl_resultoptions_displayname AS Rslt
			,pc.ownerid
			,pc.[from]
			,PC.subject
			,PC.activitytypecode
			,PC.activitytypecode AS ActivityTypeDetail
			,PC.regardingobjectid
			,PC.scheduledstart AS CompletedDate
			,c.moveindate
			,LEFT(PC.description, 300) AS notes
			,c.ksl_communityid
			,c.ksl_communityidname
		FROM KSLCLOUD_MSCRM_RESTORE_TEST.dbo.activities PC WITH (NOLOCK)
		JOIN [DataWarehouse].[dbo].[fact_lead] c ON c.lead_accountid = pc.regardingobjectid
		WHERE PC.statuscode_displayname = 'Completed'
			--AND PC.ksl_resultoptions <> '100000000'
			--Result: 100000000:Cancelled 
			AND pc.activitytypecode = 'Bus Development Drop In'
			-- Bus Development Drop In
			--and pc.compl
			AND scheduledstart > c.moveindate
			AND Year(scheduledstart) = 2025
			-- Filter by the selected year
			AND scheduledstart BETWEEN Datefromparts(2025, 1, 1)
					-- Start from January 1st of the selected year
				AND CASE 
						WHEN 2025 = Year(Getdate())
							THEN Getdate()
								-- If it's the current year, go up to today
						ELSE Datefromparts(2025, 12, 31)
							-- If it's a past year, go up to December 31st of that year
						END
		) e
	)
	,actsum
AS (
	SELECT accountownerid
		,Sum(CASE 
				WHEN (
						[activitytype] LIKE '%Face Appointment%'
						OR [activitytype] LIKE '%Walk-in%'
						)
					THEN 1
				ELSE 0
				END) AS appointment_BD
		,Sum(CASE 
				WHEN [activitytype] = 'RR Bus Development Drop In BD'
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
					THEN 1
				ELSE 0
				END) AS phonecall_BD
	FROM activity
	GROUP BY accountownerid
	)
	,nrr
AS (
	SELECT Sum(rentrev) RentRev
		,ksl_securityregionteamid
	FROM (
		SELECT Isnull(Sum(ksl_act_commtransfee + new_apartmentrate - Isnull(est.ksl_act_commtransfeespecial, 0)), 0) AS RentRev
			,a.ksl_communityid
		FROM (
			SELECT afh.ksl_begindate
				,afh.ksl_apartmentid
				,afh.ksl_apartmentidname
				,afh.ksl_communityid
				--,afh.AccountId
				,afh.ksl_communityidname
				,afh.ksl_accountleadid
				,Max(afh.ksl_enddate) AS EndDt
				,afh.ksl_estimateid
				,afh.ksl_begintransactiontype
				,Max(afh.ksl_endtransactiontype) ksl_EndTransactionType
				,Max(afh.ksl_reasondetailidname) AS ksl_ReasonDetailIDName
				,Max(afh.ksl_moveoutdestinationidname) AS ksl_MoveOutDestinationIdName
				,Max(afh.ownerid) AS afh_OwnerID
				--,LEA.ksl_ReasonDetailIdName AS ReasonDetail
				,Max(ksl_moveoutreasondetailidname) AS MoveOutReasonDetail
			FROM ksl_apartmentfinancialhistory afh WITH (NOLOCK)
			--history of what happened 
			LEFT JOIN account A WITH (NOLOCK) ON a.accountid = ksl_accountleadid
			LEFT JOIN quote q WITH (NOLOCK) ON q.quoteid = ksl_estimateid
			WHERE (
					afh.ksl_begintransactiontype IN (
						864960001
						,864960003
						,864960007
						,864960008
						)
					-- 01=Actual Move In, 03=Actual Transfer In, Scheduled Transfer, Scheduled Move In
					AND a.[ksl_initialsourcecategory] = '25AC1CB4-C27F-E311-986A-0050568B37AC'
					AND afh.statecode = 0
					AND (
						afh.ksl_endtransactiontype IN (
							864960004
							,864960006
							,864960002
							,864960005
							)
						OR afh.ksl_endtransactiontype IS NULL
						)
					)
				-- Actual Transfer Out, Actual move out, Scheduled Transfer,Scheduled move out
				OR (
					afh.ksl_begintransactiontype = 864960000
					AND afh.statecode = 0
					AND afh.ksl_endtransactiontype IS NULL
					AND Cast(afh.ksl_begindate AS DATE) >= Cast(Getdate() - 15 AS DATE)
					)
			--" . $WhereSDSQL . "
			GROUP BY afh.ksl_begindate
				,afh.ksl_apartmentid
				,afh.ksl_accountleadid
				,afh.ksl_estimateid
				,afh.ksl_begintransactiontype
				,afh.ksl_apartmentidname
				,afh.ksl_communityid
				--,afh.AccountId
				,afh.ksl_communityidname
			) AS y
		FULL OUTER JOIN [quote] est ON quoteid = ksl_estimateid
		LEFT JOIN account A WITH (NOLOCK) ON a.accountid = est.customerid
		WHERE COALESCE(CASE 
					WHEN y.ksl_begintransactiontype = 864960001
						THEN 'Actual Move in'
					WHEN y.ksl_begintransactiontype = 864960003
						THEN 'Actual Transfer In'
					WHEN y.ksl_begintransactiontype = 864960007
						THEN 'Short Term Stay Begin'
					WHEN y.ksl_begintransactiontype = 864960008
						THEN 'Seasonal Stay Begin'
					WHEN y.ksl_begintransactiontype = 864960000
						THEN 'Scheduled Move in'
							--ELSE 'Other'
					END, est.ksl_estimatetype_displayname) IN (
				'Actual Move in'
				,'Moved In'
				)
			AND a.[ksl_initialsourcecategory] = '25AC1CB4-C27F-E311-986A-0050568B37AC'
			--and isnull(y.ksl_CommunityId,est.ksl_CommunityId) = '0DC35920-B2DE-E211-9163-0050568B37AC'
			AND Isnull(ksl_begindate, est.ksl_schfinanmovein) BETWEEN Datefromparts(@Year, 1, 1)
					-- Start from January 1st of the selected year
				AND CASE 
						WHEN @Year = Year(Getdate())
							THEN Getdate()
								-- If the selected year is the current year, use today's date
						ELSE Datefromparts(@Year, 12, 31)
							-- Otherwise, use December 31st of the selected year
						END
		GROUP BY a.ksl_communityid
		) d
	INNER JOIN [KSLCLOUD_MSCRM].[dbo].ksl_community c WITH (NOLOCK) ON d.ksl_communityid = c.ksl_communityid
	--where   ksl_securityregionteamid = '0933038A-375D-E811-A94F-000D3A3ACDE0'
	GROUP BY ksl_securityregionteamid
	)
	,leads
AS (
	SELECT Count(accountid) AS newLeadsavg
		,ksl_securityregionteamid
	FROM [KSLCLOUD_MSCRM].[dbo].[account] a
	INNER JOIN [KSLCLOUD_MSCRM].[dbo].ksl_community c ON a.ksl_communityid = c.ksl_communityid
	--inner join [KSLCLOUD_MSCRM].[dbo].[systemuser] u on u.ksl_regionalteamid = c.ksl_securityregionteamid
	WHERE [ksl_initialsourcecategory] = '25AC1CB4-C27F-E311-986A-0050568B37AC'
		AND Year(ksl_initialinquirydate) = @Year
		-- Filter by the selected year
		AND ksl_initialinquirydate BETWEEN Datefromparts(@Year, 1, 1)
				-- Start from January 1st of the selected year
			AND CASE 
					WHEN @Year = Year(Getdate())
						THEN Getdate()
							-- If it's the current year, go up to today
					ELSE Datefromparts(@Year, 12, 31)
						-- If it's a past year, go up to December 31st of that year
					END
	GROUP BY ksl_securityregionteamid
	)
	,moveins
AS (
	SELECT Count(est.quoteid) AS MoveInavg
		,c.ksl_securityregionteamid
	FROM (
		SELECT afh.ksl_begindate
			,afh.ksl_apartmentid
			,afh.ksl_apartmentidname
			,afh.ksl_communityid
			--,afh.AccountId
			,afh.ksl_communityidname
			,afh.ksl_accountleadid
			,Max(afh.ksl_enddate) AS EndDt
			,afh.ksl_estimateid
			,afh.ksl_begintransactiontype
			,Max(afh.ksl_endtransactiontype) ksl_EndTransactionType
			,Max(afh.ksl_reasondetailidname) AS ksl_ReasonDetailIDName
			,Max(afh.ksl_moveoutdestinationidname) AS ksl_MoveOutDestinationIdName
			,Max(afh.ownerid) AS afh_OwnerID
			--,LEA.ksl_ReasonDetailIdName AS ReasonDetail
			,Max(ksl_moveoutreasondetailidname) AS MoveOutReasonDetail
		FROM ksl_apartmentfinancialhistory afh WITH (NOLOCK)
		--history of what happened 
		LEFT JOIN account A WITH (NOLOCK) ON a.accountid = ksl_accountleadid
		LEFT JOIN quote q WITH (NOLOCK) ON q.quoteid = ksl_estimateid
		WHERE (
				afh.ksl_begintransactiontype IN (
					864960001
					,864960003
					,864960007
					,864960008
					)
				-- 01=Actual Move In, 03=Actual Transfer In, Scheduled Transfer, Scheduled Move In
				AND afh.statecode = 0
				AND [ksl_initialsourcecategory] = '25AC1CB4-C27F-E311-986A-0050568B37AC'
				AND (
					afh.ksl_endtransactiontype IN (
						864960004
						,864960006
						,864960002
						,864960005
						)
					OR afh.ksl_endtransactiontype IS NULL
					)
				)
			-- Actual Transfer Out, Actual move out, Scheduled Transfer,Scheduled move out
			OR (
				afh.ksl_begintransactiontype = 864960000
				AND afh.statecode = 0
				AND afh.ksl_endtransactiontype IS NULL
				AND Cast(afh.ksl_begindate AS DATE) >= Cast(Getdate() - 15 AS DATE)
				)
		GROUP BY afh.ksl_begindate
			,afh.ksl_apartmentid
			,afh.ksl_accountleadid
			,afh.ksl_estimateid
			,afh.ksl_begintransactiontype
			,afh.ksl_apartmentidname
			,afh.ksl_communityid
			--,afh.AccountId
			,afh.ksl_communityidname
		) AS y
	FULL OUTER JOIN [quote] est ON quoteid = ksl_estimateid
	LEFT JOIN account A WITH (NOLOCK) ON a.accountid = est.customerid
	LEFT JOIN contact c1 ON est.ksl_primaryresident1id = c1.contactid
	LEFT JOIN contact c2 ON est.ksl_potentialsecondaryresidentid = c2.contactid
	LEFT JOIN ksl_apartment apt ON est.ksl_apartmentid = apt.ksl_apartmentid
	LEFT JOIN ksl_apartment tra ON est.ksl_act_transferfromapartmentid = tra.ksl_apartmentid
	INNER JOIN [KSLCLOUD_MSCRM].[dbo].ksl_community c ON a.ksl_communityid = c.ksl_communityid
	WHERE COALESCE(CASE 
				WHEN y.ksl_begintransactiontype = 864960001
					THEN 'Actual Move in'
				WHEN y.ksl_begintransactiontype = 864960003
					THEN 'Actual Transfer In'
				WHEN y.ksl_begintransactiontype = 864960007
					THEN 'Short Term Stay Begin'
				WHEN y.ksl_begintransactiontype = 864960008
					THEN 'Seasonal Stay Begin'
				WHEN y.ksl_begintransactiontype = 864960000
					THEN 'Scheduled Move in'
						--ELSE 'Other'
				END, est.ksl_estimatetype_displayname) IN ('Actual Move in')
		AND Year(Isnull(ksl_begindate, est.ksl_schfinanmovein)) = @Year
		-- Filter by the selected year
		AND Isnull(ksl_begindate, est.ksl_schfinanmovein) BETWEEN Datefromparts(@Year, 1, 1)
				-- Start from January 1st of the selected year
			AND CASE 
					WHEN @Year = Year(Getdate())
						THEN Getdate()
							-- If it's the current year, go up to today
					ELSE Datefromparts(@Year, 12, 31)
						-- If it's a past year, go up to December 31st of that year
					END
	--and isnull(y.ksl_CommunityId,est.ksl_CommunityId) = '0DC35920-B2DE-E211-9163-0050568B37AC'
	GROUP BY c.ksl_securityregionteamid
	)
	,newrs
AS (
	SELECT Count(contactid) RSourceAvg
		,c.createdby ownerid
	FROM [KSLCLOUD_MSCRM].[dbo].[contact] c
	WHERE [ksl_contacttype] = '864960002'
		AND Year(c.createdon) = @Year -- Filter by the selected year
		AND c.createdon BETWEEN Datefromparts(@Year, 1, 1)
				-- Start from January 1st of the selected year
			AND CASE 
					WHEN @Year = Year(Getdate())
						THEN Getdate()
							-- If it's the current year, go up to today
					ELSE Datefromparts(@Year, 12, 31)
						-- If it's a past year, go up to December 31st of that year
					END
	GROUP BY c.createdby
	)
	,resref
AS (
	SELECT Count(accountid) * 1.0 RRAvg
		,[ksl_associtateduser]
		,[ksl_associtatedusername]
	FROM [KSLCLOUD_MSCRM].[dbo].account c
	INNER JOIN [KSLCLOUD_MSCRM].[dbo].[ksl_referralorgs] r ON r.ksl_referralorgsid = c.ksl_referralorganization
	WHERE Year(c.createdon) = @Year -- Filter by the selected year
		AND c.createdon BETWEEN Datefromparts(@Year, 1, 1)
				-- Start from January 1st of the selected year
			AND CASE 
					WHEN @Year = Year(Getdate())
						THEN Getdate()
							-- If it's the current year, go up to today
					ELSE Datefromparts(@Year, 12, 31)
						-- If it's a past year, go up to December 31st of that year
					END
		AND ksl_initialsource = '07E31289-00A3-E311-B839-0050568B7D16'
	--Resident Referral
	GROUP BY [ksl_associtateduser]
		,[ksl_associtatedusername]
	)
--SELECT *
--FROM  actSUM
--where systemuserid ='FE6E9B1A-ABAB-E811-A95E-000D3A360847'
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
	,commCrm.ksl_regionidname
	,a.*
	,newleadsavg
	,nrr.rentrev RentRevYTD
	,mi.moveinavg
	,nr.rsourceavg
	,rravg
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
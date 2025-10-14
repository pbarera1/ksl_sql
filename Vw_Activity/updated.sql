WITH lastce
AS (
	SELECT --Get Last Contact Activity Information
		b.subject AS ActivitySubject
		,b.activitytypecode AS LCEType
		,--b.activitytypedetail AS LCETypeDetail,
		b.regardingobjectid
		,b.createdon AS LastCEDate
		,b.notes AS LCENotes
		,b.activityid
	FROM (
		SELECT pc.activityid
			,PC.subject
			,PC.activitytypecode
			--PC.ksl_appointmenttype    AS ActivityTypeDetail,
			,PC.createdon
			,PC.regardingobjectid
			,PC.scheduledstart AS CompletedDate
			,LEFT(PC.description, 300) AS notes
		FROM KSLCLOUD_MSCRM_RESTORE_TEST.dbo.activities PC WITH (NOLOCK)
		WHERE PC.statuscode_displayname = 'Completed'
			AND (
				PC.activitytypecode LIKE '%face appointment%'
				OR PC.activitytypecode LIKE '%walk-in%'
				)
		) AS b
	)
SELECT X.* --,case when ROW_NUMBER() over (partition by accountid order by completeddate) = 1 then 1 else 0 end as lead  -- js 5/18
	--,ROW_NUMBER() over (partition by accountid order by completeddate) row
	,CASE 
		WHEN activitytype LIKE '%phone%'
		AND activitytype <> 'Committed Phone Appointment'
			AND rslt = 'Completed'
			THEN 1
		ELSE 0
		END AS Completed_Phone_Calls
	,CASE 
		WHEN activitytype IN ('Incoming Phone Call')
			AND rslt = 'Completed'
			THEN 1
		ELSE 0
		END AS Completed_Incoming_Phone_Calls
	,CASE 
		WHEN activitytype IN ('Outbound Email', 'Letter')
			THEN 1
		ELSE 0
		END AS Sent_Messages
	,CASE 
		WHEN (
				activitytype LIKE '%face appointment%'
				OR activitytype LIKE '%walk-in%'
			) AND activitytype NOT LIKE '%phone%'
			THEN 1
		ELSE 0
		END AS Appointment
	,CASE 
		WHEN ActivityType = 'Inbound Email'
			AND AccountStatus = 'Referral Org'
			THEN 1
		ELSE 0
		END AS Sent_Messages_Biz_Dev
	,CASE 
		WHEN activitytype = 'Outbound Text Message'
			AND AccountStatus = 'Referral Org'
			AND ksl_textssent > 0
			THEN ksl_textssent
		ELSE 0
		END AS TextSent_Biz_Dev
	,CASE 
		WHEN activitytype = 'Inbound Text Message'
			AND AccountStatus = 'Referral Org'
			AND ksl_textsreceived > 0
			THEN ksl_textsreceived
		ELSE 0
		END AS TextReceived_Biz_Dev
	,CASE 
		WHEN ActivityType LIKE '%phone%'
			AND activitytype <> 'Committed Phone Appointment'
			AND Rslt = 'Completed'
			AND AccountStatus = 'Referral Org'
			THEN 1
		ELSE 0
		END AS Completed_Phone_Calls_Biz_Dev
	,CASE 
		WHEN ActivityType IN ('In-Person Appointment', 'Committed Face Appointment', 'Unscheduled Walk-In')
			AND Rslt = 'Completed'
			AND AccountStatus = 'Referral Org'
			THEN 1
		ELSE 0
		END AS Appointment_Biz_Dev
	,CASE 
		WHEN ActivityType IN ('In-Person Appointment', 'Committed Face Appointment', 'Unscheduled Walk-In')
			AND Rslt = 'Completed'
			AND CAST(CompletedDate AS DATE) = CAST(LastCEDate AS DATE)
			THEN 1
		ELSE 0
		END AS Community_Experience
	,0 AS Virtual_Community_Experience --non existant field
	,CASE 
		WHEN activitytype LIKE '%phone%'
		AND activitytype <> 'Committed Phone Appointment'
			AND ActivityTypeDetail <> 'Incoming Phone Call'
			AND Rslt <> 'CANC - Cancelled'
			AND Rslt <> 'COMP - Completed'
			AND AccountStatus = 'Referral Org'
			THEN 1
		ELSE 0
		END AS Phone_Call_Attempted_Biz_Dev
	,CASE 
		WHEN activitytype LIKE '%phone%'
		AND activitytype <> 'Committed Phone Appointment'
			AND ActivityTypeDetail <> 'Incoming Phone Call'
			AND Rslt <> 'Cancelled'
			AND Rslt <> 'Completed'
			THEN 1
		ELSE 0
		END AS Phone_Call_Attempted
	,CASE 
		WHEN ActivityType LIKE '%text%'
			AND ksl_textssent > 0
			THEN ksl_textssent
		ELSE 0
		END AS TextSent
	,CASE 
		WHEN ActivityType LIKE '%text%'
			AND ksl_textsreceived > 0
			THEN ksl_textsreceived
		ELSE 0
		END AS TextReceived
FROM (
	SELECT a.accountid
		,a.ownerid AccountOwnerID
		,a.owneridname AccountOwnerName
		,b.ownerid ActivityOwnerID
		,b.[from] ActivityOwnerName
		,a.ksl_communityid AS CommunityId
		,a.ksl_communityidname AS CommunityIdName
		,b.subject AS ActivitySubject
		,b.activitytypecode AS ActivityType
		,b.statuscode_displayname AS ActivityTypeDetail
		,rslt
		,activityid
		,notes
		,ksl_textssent
		,ksl_textsreceived
		,b.AccountStatus as AccountStatus
		,b.CompletedDate AS CompletedDate
	FROM (
		SELECT activityid
			,ksl_resultoptions_displayname AS Rslt
			,L.accountid
			,PC.subject
			,PC.activitytypecode
			,PC.regardingobjectid
			,PC.createdon          AS CompletedDate,
			pc.description AS notes
			,pc.[from]
			,pc.ownerid
			/* Derive text counts */
			,CASE WHEN PC.activitytypecode IN ('Outbound Text Message','Text Message Conversation') THEN 1 ELSE 0 END AS ksl_textssent
			,CASE WHEN PC.activitytypecode IN ('Inbound Text Message','Text Message Conversation') THEN 1 ELSE 0 END AS ksl_textsreceived
			,pc.statuscode_displayname
			,L.statuscode_displayname as AccountStatus
		FROM kslcloud_mscrm.dbo.account L WITH (NOLOCK)
		INNER JOIN KSLCLOUD_MSCRM_RESTORE_TEST.dbo.activities PC WITH (NOLOCK) ON PC.regardingobjectid = L.accountid
		WHERE PC.statuscode_displayname = 'Completed'
		) AS b
	INNER JOIN kslcloud_mscrm.dbo.account a ON b.regardingobjectid = a.accountid
	
	UNION ALL
	
	SELECT a.contactid
		,b.ownerid AccountOwnerID
		,b.[from] AccountOwnerName
		,b.ownerid ActivityOwnerID
		,b.[from] ActivityOwnerName
		,a.ksl_communityid AS CommunityId
		,a.ksl_communityidname AS CommunityIdName
		,b.subject AS ActivitySubject
		,b.activitytypecode + ' BD' AS ActivityType
		,NULL AS ActivityTypeDetail
		,rslt
		,activityid
		,notes
		,ksl_textssent
		,ksl_textsreceived
		,NULL AS AccountStatus
		,b.CompletedDate AS CompletedDate
	FROM (
		SELECT activityid
			,ksl_resultoptions_displayname AS Rslt
			,ownerid
			,[from]
			,PC.subject
			,PC.activitytypecode
			,PC.regardingobjectid
			,PC.createdon          AS CompletedDate,
			pc.description AS notes,
			/* Derive text counts */
			CASE WHEN PC.activitytypecode IN ('Outbound Text Message','Text Message Conversation') THEN 1 ELSE 0 END AS ksl_textssent
			,CASE WHEN PC.activitytypecode IN ('Inbound Text Message','Text Message Conversation') THEN 1 ELSE 0 END AS ksl_textsreceived
		FROM KSLCLOUD_MSCRM_RESTORE_TEST.dbo.activities PC WITH (NOLOCK)
		WHERE PC.statuscode_displayname = 'Completed'
		AND PC.ksl_resultoptions_displayname <> 'Cancelled'
		) AS b
	INNER JOIN kslcloud_mscrm.dbo.contact a ON b.regardingobjectid = a.contactid
	) AS x
OUTER APPLY (
	SELECT TOP 1 *
	FROM lastce
	WHERE X.accountid = lastce.regardingobjectid
	ORDER BY lastce.lastcedate ASC
	) FCE
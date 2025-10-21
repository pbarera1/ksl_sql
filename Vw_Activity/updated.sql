-- TAKE 1
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
	
	--activitytype = activities.activitytypecode
	--rslt = activities.ksl_resultoptions_displayname
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
		WHEN activitytype IN ('Committed Face Appointment', 'Unscheduled Walk-In')
			THEN 1
		ELSE 0
		END AS Appointment
	,CASE 
		WHEN ActivityType = 'Inbound Email'
			AND AccountStatus LIKE 'referral org%'
			THEN 1
		ELSE 0
		END AS Sent_Messages_Biz_Dev
	,CASE 
		WHEN activitytype = 'Outbound Text Message' -- TODO
			AND AccountStatus LIKE 'referral org%'
			THEN 1
		ELSE 0
		END AS TextSent_Biz_Dev
	,CASE 
		WHEN activitytype = 'Inbound Text Message'
			AND AccountStatus LIKE 'referral org%'
			THEN 1
		ELSE 0
		END AS TextReceived_Biz_Dev
	,CASE 
		WHEN ActivityType LIKE '%phone%'
			AND activitytype <> 'Committed Phone Appointment'
			AND Rslt = 'Completed'
			AND AccountStatus LIKE 'referral org%'
			THEN 1
		ELSE 0
		END AS Completed_Phone_Calls_Biz_Dev
	,CASE 
		WHEN ActivityType IN ('Committed Face Appointment', 'Unscheduled Walk-In')
			AND Rslt = 'Completed'
			AND AccountStatus LIKE 'referral org%'
			THEN 1
		ELSE 0
		END AS Appointment_Biz_Dev
	,CASE 
		WHEN ActivityType IN ('Committed Face Appointment', 'Unscheduled Walk-In')
			AND Rslt = 'Completed'
			AND CAST(CompletedDate AS DATE) = CAST(LastCEDate AS DATE)
			THEN 1
		ELSE 0
		END AS Community_Experience --TODO remove or set as 0
	,0 AS Virtual_Community_Experience -- TODO remove or set as 0
	,CASE 
		WHEN activitytype = 'Outgoing Phone Call'
			AND Rslt <> 'Cancelled'
			AND Rslt <> 'Completed'
			AND AccountStatus LIKE 'referral org%'
			THEN 1
		ELSE 0
		END AS Phone_Call_Attempted_Biz_Dev
	,CASE 
		WHEN activitytype = 'Outgoing Phone Call'
			AND Rslt <> 'Cancelled'
			AND Rslt <> 'Completed'
			THEN 1
		ELSE 0
		END AS Phone_Call_Attempted
	,CASE 
		WHEN activitytype = 'Outbound Text Message'
			THEN 1
		ELSE 0
		END AS TextSent
	,CASE 
		WHEN activitytype = 'Inbound Text Message'
			THEN 1
		ELSE 0
		END AS TextReceived
FROM (
	SELECT 
		a.accountid, -- Get the account ID that the contact belongs to
        a.OwnerID as AccountOwnerID,
        a.OwnerIDname as AccountOwnerName,
		b.ownerid ActivityOwnerID,
		b.ActivityOwnerName ActivityOwnerName,
        a.ksl_CommunityId as CommunityId,
        a.ksl_CommunityIdName as CommunityIdName,
        b.subject as ActivitySubject,
        b.activitytypecode as ActivityType,
        b.activitytypecode as ActivityTypeDetail, -- This was a number like 864960000 but now phonecall etc.
		isnull(dateadd(hour, (
			SELECT com.[ksl_utctimeadjust]
			FROM [KSLCLOUD_MSCRM].[dbo].[ksl_community] com
			WHERE ksl_communityid = a.ksl_communityid
			), b.CompletedDate), b.CompletedDate) CompletedDate,
        Rslt,
        activityid
		,notes
		,ksl_textssent
		,ksl_textsreceived
		,b.AccountStatus as AccountStatus
	FROM (
		SELECT activityid
			,ksl_resultoptions_displayname AS Rslt
			,L.accountid
			,PC.subject
			,PC.activitytypecode
			,PC.regardingobjectid
			,PC.scheduledend          AS CompletedDate,
			pc.description AS notes
			,Assoc.USR_First + ' ' + Assoc.USR_Last AS ActivityOwnerName
			,pc.ownerid
			/* Derive text counts */
			,CASE WHEN PC.activitytypecode IN ('Outbound Text Message','Text Message Conversation') THEN 1 ELSE 0 END AS ksl_textssent
			,CASE WHEN PC.activitytypecode IN ('Inbound Text Message','Text Message Conversation') THEN 1 ELSE 0 END AS ksl_textsreceived
			,pc.statuscode_displayname
			,L.statuscode_displayname as AccountStatus
		FROM kslcloud_mscrm.dbo.account L WITH (NOLOCK)
		INNER JOIN KSLCLOUD_MSCRM_RESTORE_TEST.dbo.activities PC WITH (NOLOCK) ON PC.regardingobjectid = L.accountid
		LEFT JOIN KiscoCustom.dbo.Associate Assoc ON PC.ownerid = Assoc.SalesAppID
		WHERE PC.statuscode_displayname = 'Completed'
		) AS b
	INNER JOIN kslcloud_mscrm.dbo.account a ON b.regardingobjectid = a.accountid
	
	UNION ALL
	
	SELECT 
		a.contactid
		,b.ownerid AccountOwnerID
		,a.OwnerIDname as AccountOwnerName
		,b.ownerid ActivityOwnerID
		,b.ActivityOwnerName ActivityOwnerName
		,a.ksl_communityid AS CommunityId
		,a.ksl_communityidname AS CommunityIdName
		,b.subject AS ActivitySubject
		,b.activitytypecode + ' BD' AS ActivityType
		,NULL AS ActivityTypeDetail
		,isnull(dateadd(hour, (
			SELECT com.[ksl_utctimeadjust]
			FROM [KSLCLOUD_MSCRM].[dbo].[ksl_community] com
			WHERE ksl_communityid = a.ksl_communityid
			), b.CompletedDate), b.CompletedDate) CompletedDate
		,Rslt
		,activityid
		,notes
		,ksl_textssent
		,ksl_textsreceived
		,NULL AS AccountStatus
	FROM (
		SELECT activityid
			,ksl_resultoptions_displayname AS Rslt
			,ownerid
			,PC.subject
			,PC.activitytypecode
			,PC.regardingobjectid
			,PC.scheduledend          AS CompletedDate,
			pc.description AS notes,
			Assoc.USR_First + ' ' + Assoc.USR_Last AS ActivityOwnerName,
			/* Derive text counts */
			CASE WHEN PC.activitytypecode IN ('Outbound Text Message','Text Message Conversation') THEN 1 ELSE 0 END AS ksl_textssent
			,CASE WHEN PC.activitytypecode IN ('Inbound Text Message','Text Message Conversation') THEN 1 ELSE 0 END AS ksl_textsreceived
		FROM KSLCLOUD_MSCRM_RESTORE_TEST.dbo.activities PC WITH (NOLOCK)
		LEFT JOIN KiscoCustom.dbo.Associate Assoc ON PC.ownerid = Assoc.SalesAppID
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
WHERE x.CommunityId = '3BC35920-B2DE-E211-9163-0050568B37AC'   -- Byron Park
  AND x.CompletedDate >= DATEADD(MONTH, -1, GETDATE())
ORDER BY x.CompletedDate DESC;


--TAKE 2 Same query as fact_activity
WITH lastce AS (
  SELECT
      b.subject            AS ActivitySubject
    , b.activitytypecode   AS LCEType
    -- , b.activitytypedetail AS LCETypeDetail
    , b.regardingobjectid
    , b.createdon          AS LastCEDate
    , b.notes              AS LCENotes
    , b.activityid
  FROM (
    SELECT
        pc.activityid
      , pc.subject
      , pc.activitytypecode
      -- , pc.ksl_appointmenttype AS ActivityTypeDetail
      , pc.createdon
      , pc.regardingobjectid
      , pc.scheduledstart   AS CompletedDate
      , LEFT(pc.description, 300) AS notes
    FROM KSLCLOUD_MSCRM_RESTORE_TEST.dbo.activities pc WITH (NOLOCK)
    WHERE pc.statuscode_displayname = 'Completed'
      AND ( pc.activitytypecode LIKE '%face appointment%'
            OR pc.activitytypecode LIKE '%walk-in%' )
  ) AS b
),
AllActivities AS (
WITH AllActivities
AS (
	SELECT CASE 
			WHEN a.ActivityType IN ('Outgoing Text Message')
				THEN 1
			WHEN a.ActivityType = 'Inbound Text Message'
				THEN 0
			WHEN a.ActivityType = 'Text Message Conversation'
				THEN (LEN(COALESCE(a.EmailBody, '')) - LEN(REPLACE(COALESCE(a.EmailBody, ''), 'SENT', ''))) / 4
			ELSE 0
			END AS TextsSent,
		CASE 
			WHEN a.ActivityType IN ('Outgoing Text Message')
				THEN 0
			WHEN a.ActivityType = 'Inbound Text Message'
				THEN 1
			WHEN a.ActivityType = 'Text Message Conversation'
				THEN (LEN(COALESCE(a.EmailBody, '')) - LEN(REPLACE(COALESCE(a.EmailBody, ''), 'RCVD', ''))) / 4
			ELSE 0
			END AS TextsReceived,
		a.*
	FROM (
		SELECT A.accountid,
			PC.EmailBody,
			A.OwnerID AS AccountOwnerID,
			A.OwnerIDname AS AccountOwnerName,
			PC.ownerid AS ActivityOwnerID,
			Assoc.USR_First + ' ' + Assoc.USR_Last AS ActivityOwnerName,
			A.ksl_CommunityId AS CommunityId,
			A.ksl_CommunityIdName AS CommunityIdName,
			PC.Subject AS ActivitySubject,
			PC.ActivityTypeCode AS ActivityType,
			NULL AS ActivityTypeDetail,
			PC.scheduledstart AS CompletedDate,
			PC.ksl_resultoptions_displayname AS Rslt,
			PC.activityid,
			PC.description AS notes
		FROM KSLCLOUD_MSCRM_RESTORE_TEST.dbo.Account AS A WITH (NOLOCK)
		JOIN KSLCLOUD_MSCRM_RESTORE_TEST.dbo.activities AS PC WITH (NOLOCK) ON PC.RegardingObjectId = A.accountid
		JOIN KiscoCustom.dbo.Associate AS Assoc WITH (NOLOCK) ON PC.ownerid = Assoc.SalesAppID
		) a
	)
-- SELECT *
-- FROM AllActivities
-- WHERE CommunityId = '3BC35920-B2DE-E211-9163-0050568B37AC' -- Byron Park
-- 	AND CONVERT(DATE, CompletedDate) >= '2025-09-16'
-- 	AND ActivityType LIKE '%Text Message%'
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
		WHEN ActivityType IN ('Committed Face Appointment', 'Unscheduled Walk-In')
			THEN 1
		ELSE 0
		END AS Appointment
	,CASE 
		WHEN ActivityType = 'Inbound Email'
			AND AccountStatus LIKE 'referral org%'
			THEN 1
		ELSE 0
		END AS Sent_Messages_Biz_Dev
	,CASE 
		WHEN activitytype = 'Outbound Text Message' -- TODO do all non biz dev need AccountStatus = 'Lead'
			AND AccountStatus LIKE 'referral org%'
			AND ksl_textssent > 0
			THEN ksl_textssent
		ELSE 0
		END AS TextSent_Biz_Dev
	,CASE 
		WHEN activitytype = 'Inbound Text Message'
			AND AccountStatus LIKE 'referral org%'
			AND ksl_textsreceived > 0
			THEN ksl_textsreceived
		ELSE 0
		END AS TextReceived_Biz_Dev
	,CASE 
		WHEN ActivityType LIKE '%phone%'
			AND activitytype <> 'Committed Phone Appointment'
			AND Rslt = 'Completed'
			AND AccountStatus LIKE 'referral org%'
			THEN 1
		ELSE 0
		END AS Completed_Phone_Calls_Biz_Dev
	,CASE 
		WHEN ActivityType IN ('Committed Face Appointment', 'Unscheduled Walk-In')
			AND Rslt = 'Completed'
			AND AccountStatus LIKE 'referral org%'
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
			AND AccountStatus LIKE 'referral org%'
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
FROM AllActivities AS x
OUTER APPLY (
	SELECT TOP 1 *
	FROM lastce
	WHERE X.accountid = lastce.regardingobjectid
	ORDER BY lastce.lastcedate ASC
	) FCE
WHERE x.CommunityId = '3BC35920-B2DE-E211-9163-0050568B37AC'   -- Byron Park
  AND x.CompletedDate >= DATEADD(MONTH, -1, GETDATE())
ORDER BY x.CompletedDate DESC;


-- TODO AllActivities with Text Counts
  SELECT
  CASE 
    WHEN a.ActivityType IN ('Outgoing Text Message') THEN 1
    WHEN a.ActivityType = 'Inbound Text Message'                              THEN 0
    WHEN a.ActivityType = 'Text Message Conversation' THEN
         (LEN(COALESCE(a.EmailBody,'')) - LEN(REPLACE(COALESCE(a.EmailBody,''), 'SENT', ''))) / 4
    ELSE 0
  END AS TextsSent,
  CASE 
    WHEN a.ActivityType IN ('Outgoing Text Message') THEN 0
    WHEN a.ActivityType = 'Inbound Text Message'                              THEN 1
    WHEN a.ActivityType = 'Text Message Conversation' THEN
         (LEN(COALESCE(a.EmailBody,'')) - LEN(REPLACE(COALESCE(a.EmailBody,''), 'RCVD', ''))) / 4
    ELSE 0
  END AS TextsReceived,
  a.EmailBody,
  a.*
FROM (
  SELECT 
      A.accountid,
      A.OwnerID               AS AccountOwnerID,
      A.OwnerIDname           AS AccountOwnerName,
      A.ksl_CommunityId       AS CommunityId,
      A.ksl_CommunityIdName   AS CommunityIdName,
      PC.Subject              AS ActivitySubject,
      PC.ActivityTypeCode     AS ActivityType,
      NULL                    AS ActivityTypeDetail,
      PC.scheduledstart       AS CompletedDate,
      PC.ksl_resultoptions_displayname AS Rslt,
      PC.activityid,
      PC.description          AS notes,
      CASE WHEN A.statuscode_displayname = 'Referral Org' THEN 'Yes' ELSE 'No' END AS isBD,
      CASE WHEN PC.description LIKE '%sm.chat%' THEN 'Yes' ELSE 'No' END AS isSalesMail,
      NULL                    AS google_campaignID,
      PC.ownerid              AS CreatedBy,
      PC.ownerid              AS activityCreatedBy,
      PC.EmailBody
  FROM KSLCLOUD_MSCRM_RESTORE_TEST.dbo.Account    AS A WITH (NOLOCK)
  JOIN KSLCLOUD_MSCRM_RESTORE_TEST.dbo.activities AS PC WITH (NOLOCK)
    ON PC.RegardingObjectId = A.accountid
) a
WHERE a.CommunityId = '3BC35920-B2DE-E211-9163-0050568B37AC'  -- Byron Park
  AND CONVERT(date, a.CompletedDate) >= '2025-09-16'
  AND a.ActivityType LIKE '%Text Message%';   -- include Outbound/Inbound/Conversation

-- TAKE 4
WITH lastce AS (
  SELECT
      b.subject            AS ActivitySubject
    , b.activitytypecode   AS LCEType
    -- , b.activitytypedetail AS LCETypeDetail
    , b.regardingobjectid
    , b.createdon          AS LastCEDate
    , b.notes              AS LCENotes
    , b.activityid
  FROM (
    SELECT
        pc.activityid
      , pc.subject
      , pc.activitytypecode
      -- , pc.ksl_appointmenttype AS ActivityTypeDetail
      , pc.createdon
      , pc.regardingobjectid
      , pc.scheduledstart   AS CompletedDate
      , LEFT(pc.description, 300) AS notes
    FROM KSLCLOUD_MSCRM_RESTORE_TEST.dbo.activities pc WITH (NOLOCK)
    WHERE pc.statuscode_displayname = 'Completed'
      AND ( pc.activitytypecode LIKE '%face appointment%'
            OR pc.activitytypecode LIKE '%walk-in%' )
  ) AS b
),
AllActivities AS (
	-- In activitypecode = 'Text Message Conversation' let's tally the number of times the word SENT or RCVD appears in the text body
	SELECT CASE 
			WHEN a.ActivityType IN ('Outgoing Text Message')
				THEN 1
			WHEN a.ActivityType = 'Inbound Text Message'
				THEN 0
			WHEN a.ActivityType = 'Text Message Conversation'
				THEN (LEN(COALESCE(a.EmailBody, '')) - LEN(REPLACE(COALESCE(a.EmailBody, ''), 'SENT  [', ''))) / 7
			ELSE 0
			END AS TextSent,
		CASE 
			WHEN a.ActivityType IN ('Outgoing Text Message')
				THEN 0
			WHEN a.ActivityType = 'Inbound Text Message'
				THEN 1
			WHEN a.ActivityType = 'Text Message Conversation'
				THEN (LEN(COALESCE(a.EmailBody, '')) - LEN(REPLACE(COALESCE(a.EmailBody, ''), 'RCVD  [', ''))) / 7
			ELSE 0
			END AS TextReceived,
		a.*
	FROM (
		SELECT A.accountid,
			PC.EmailBody,
			A.OwnerID AS AccountOwnerID,
			A.OwnerIDname AS AccountOwnerName,
			PC.ownerid AS ActivityOwnerID,
			Assoc.USR_First + ' ' + Assoc.USR_Last AS ActivityOwnerName,
			A.ksl_CommunityId AS CommunityId,
			A.ksl_CommunityIdName AS CommunityIdName,
			PC.Subject AS ActivitySubject,
			PC.ActivityTypeCode AS ActivityType,
			NULL AS ActivityTypeDetail,
			PC.scheduledstart AS CompletedDate,
			PC.ksl_resultoptions_displayname AS Rslt,
			PC.activityid,
			PC.description AS notes,
			A.statuscode_displayname AS AccountStatus,
			NULL AS ksl_textssent, -- TODO make sure can remove
			NULL AS ksl_textsreceived -- TODO make sure can remove
		FROM KSLCLOUD_MSCRM_RESTORE_TEST.dbo.Account AS A WITH (NOLOCK)
		JOIN KSLCLOUD_MSCRM_RESTORE_TEST.dbo.activities AS PC WITH (NOLOCK) ON PC.RegardingObjectId = A.accountid
		JOIN KiscoCustom.dbo.Associate AS Assoc WITH (NOLOCK) ON PC.ownerid = Assoc.SalesAppID
		) a
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
		WHEN ActivityType IN ('Committed Face Appointment', 'Unscheduled Walk-In')
			THEN 1
		ELSE 0
		END AS Appointment
	,CASE 
		WHEN ActivityType = 'Inbound Email'
			AND AccountStatus LIKE 'referral org%'
			THEN 1
		ELSE 0
		END AS Sent_Messages_Biz_Dev
	,CASE 
		WHEN activitytype = 'Outbound Text Message'
			AND AccountStatus LIKE 'referral org%'
			THEN TextSent
		ELSE 0
		END AS TextSent_Biz_Dev
	,CASE 
		WHEN activitytype = 'Inbound Text Message'
			AND AccountStatus LIKE 'referral org%'
			THEN TextReceived
		ELSE 0
		END AS TextReceived_Biz_Dev
	,CASE 
		WHEN ActivityType LIKE '%phone%'
			AND activitytype <> 'Committed Phone Appointment'
			AND Rslt = 'Completed'
			AND AccountStatus LIKE 'referral org%'
			THEN 1
		ELSE 0
		END AS Completed_Phone_Calls_Biz_Dev
	,CASE 
		WHEN ActivityType IN ('Committed Face Appointment', 'Unscheduled Walk-In')
			AND Rslt = 'Completed'
			AND AccountStatus LIKE 'referral org%'
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
			AND AccountStatus LIKE 'referral org%'
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
	,TextSent
	,TextReceived
FROM AllActivities AS x
OUTER APPLY (
	SELECT TOP 1 *
	FROM lastce
	WHERE X.accountid = lastce.regardingobjectid
	ORDER BY lastce.lastcedate ASC
	) FCE
WHERE x.CommunityId = '3BC35920-B2DE-E211-9163-0050568B37AC'   -- Byron Park
  AND x.CompletedDate >= DATEADD(MONTH, -1, GETDATE())
ORDER BY x.CompletedDate DESC;
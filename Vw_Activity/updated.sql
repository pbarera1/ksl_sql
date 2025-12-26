-- TAKE 4
-- Used to Identifying the "Community Experience" column
-- Later in the view we check if the activity you are currently looking at happened on the same day as that Community Experience
-- If so then we set the Community_Experience column to 1 and Appointment will be 0
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
    FROM KSLCLOUD_MSCRM.dbo.activities pc WITH (NOLOCK)
    WHERE pc.ksl_resultoptions_displayname = 'Completed'
      AND ( pc.activitytypecode LIKE '%face appointment%'
            OR pc.activitytypecode LIKE '%walk-in%' )
  ) AS b
),
AllActivities AS (
	-- In activitypecode = 'Text Message Conversation' let's tally the number of times the word SENT or RCVD appears in the text body
	SELECT CASE 
			WHEN a.ActivityType IN ('Outgoing Text Message')
				THEN 1
			WHEN a.ActivityType = 'Incoming Text Message'
				THEN 0
			WHEN a.ActivityType = 'Text Message Conversation'
				THEN (LEN(COALESCE(a.EmailBody, '')) - LEN(REPLACE(COALESCE(a.EmailBody, ''), 'SENT', ''))) / 4
			ELSE 0
			END AS TextSent,
		CASE 
			WHEN a.ActivityType IN ('Outgoing Text Message')
				THEN 0
			WHEN a.ActivityType = 'Incoming Text Message'
				THEN 1
			WHEN a.ActivityType = 'Text Message Conversation'
				THEN (LEN(COALESCE(a.EmailBody, '')) - LEN(REPLACE(COALESCE(a.EmailBody, ''), 'RCVD', ''))) / 4
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
			PC.ksl_resultoptions_displayname AS Result,
			PC.activityid,
			PC.description AS notes,
			A.statuscode_displayname AS AccountStatus
			--NULL AS ksl_textssent, -- TODO make sure can remove
			--NULL AS ksl_textsreceived -- TODO make sure can remove
		FROM KSLCLOUD_MSCRM.dbo.Account AS A WITH (NOLOCK)
		JOIN KSLCLOUD_MSCRM.dbo.activities AS PC WITH (NOLOCK) ON PC.RegardingObjectId = A.accountid
		JOIN KiscoCustom.dbo.Associate AS Assoc WITH (NOLOCK) ON PC.ownerid = Assoc.SalesAppID
		) a
)

SELECT X.* --,case when ROW_NUMBER() over (partition by accountid order by completeddate) = 1 then 1 else 0 end as lead  -- js 5/18
	--,ROW_NUMBER() over (partition by accountid order by completeddate) row
	    -- Put these first, mapped to the computed values
    ,ksl_textssent     = x.TextSent
    ,ksl_textsreceived = x.TextReceived
	,CASE 
		WHEN activitytype LIKE '%phone%'
			AND COALESCE(Result, '') = 'Completed'
			THEN 1
		ELSE 0
		END AS Completed_Phone_Calls
	,CASE 
		WHEN activitytype IN ('Incoming Phone Call')
			AND COALESCE(Result, '') = 'Completed'
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
		WHEN activitytype = 'Outgoing Text Message'
			AND AccountStatus LIKE 'referral org%'
			THEN TextSent
		ELSE 0
		END AS TextSent_Biz_Dev
	,CASE 
		WHEN activitytype = 'Incoming Text Message'
			AND AccountStatus LIKE 'referral org%'
			THEN TextReceived
		ELSE 0
		END AS TextReceived_Biz_Dev
	,CASE 
		WHEN ActivityType LIKE '%phone%'
			AND activitytype <> 'Committed Phone Appointment'
			AND COALESCE(Result, '') = 'Completed'
			AND AccountStatus LIKE 'referral org%'
			THEN 1
		ELSE 0
		END AS Completed_Phone_Calls_Biz_Dev
	,CASE 
		WHEN ActivityType IN ('Committed Face Appointment', 'Unscheduled Walk-In')
			AND COALESCE(Result, '') = 'Completed'
			AND AccountStatus LIKE 'referral org%'
			THEN 1
		ELSE 0
		END AS Appointment_Biz_Dev
	,CASE 
		WHEN ActivityType IN ('In-Person Appointment', 'Committed Face Appointment', 'Unscheduled Walk-In')
			AND COALESCE(Result, '') = 'Completed'
			AND CAST(CompletedDate AS DATE) = CAST(LastCEDate AS DATE)
			THEN 1
		ELSE 0
		END AS Community_Experience
	,0 AS Virtual_Community_Experience --non existant field
	,CASE 
		WHEN activitytype LIKE '%phone%'
		AND activitytype <> 'Committed Phone Appointment'
			AND COALESCE(ActivityTypeDetail, '') <> 'Incoming Phone Call'
			AND COALESCE(Result, '') <> 'Cancelled'
			AND COALESCE(Result, '') <> 'Completed'
			AND AccountStatus LIKE 'referral org%'
			THEN 1
		ELSE 0
		END AS Phone_Call_Attempted_Biz_Dev
	,CASE 
		WHEN activitytype LIKE '%phone%'
		AND activitytype <> 'Committed Phone Appointment'
			AND COALESCE(ActivityTypeDetail, '') <> 'Incoming Phone Call'
			AND COALESCE(Result, '') <> 'Cancelled'
			AND COALESCE(Result, '') <> 'Completed'
			THEN 1
		ELSE 0
		END AS Phone_Call_Attempted
FROM AllActivities AS x
OUTER APPLY (
	SELECT TOP 1 *
	FROM lastce
	WHERE X.accountid = lastce.regardingobjectid
	ORDER BY lastce.lastcedate ASC
	) FCE
-- TESTING
-- WHERE x.CommunityId = '3BC35920-B2DE-E211-9163-0050568B37AC'   -- Byron Park
-- WHERE x.CompletedDate >= DATEADD(DAY, -1, GETDATE())
ORDER BY x.CompletedDate DESC;

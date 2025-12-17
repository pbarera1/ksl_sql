--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% INSERT INTO Fact_Activity %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--BEGIN TRY;THROW 50000,'',1;END TRY BEGIN CATCH;insert into Staging.dbo.log_DW_Time (LineNumber,MinSinceLast) values (ERROR_LINE(),DATEDIFF(mi,@DtLast,getdate()));END CATCH
--set @DtLast = getdate()
--exec [dbo].[Fill_Fact_Activity]
-- Insert statements for procedure here
--TRUNCATE TABLE Fact_Activity
--INSERT INTO Fact_Activity

WITH AllActivities AS (
    -- Account-based activities (both BD and Sales)
    SELECT 
        A.accountid,
        A.OwnerID as AccountOwnerID,
        A.OwnerIDname as AccountOwnerName,
        A.ksl_CommunityId as CommunityId,
        A.ksl_CommunityIdName as CommunityIdName,
        PC.Subject as ActivitySubject,
        PC.ActivityTypeCode as ActivityType,
        CAST(NULL AS int) as ActivityTypeDetail,
        PC.scheduledstart as CompletedDate,
        PC.ksl_resultoptions_displayname as Rslt,
        PC.activityid,
        PC.description as notes,
        -- BD logic: BD activities are tied to accounts with status 'Referral Org'
        CASE WHEN A.statuscode_displayname = 'Referral Org' THEN 'Yes' ELSE 'No' END as isBD,
        -- SalesMail logic
        CASE WHEN PC.description LIKE '%sm.chat%' THEN 'Yes' ELSE 'No' END as isSalesMail,
        NULL as google_campaignID,
        PC.ownerid AS CreatedBy,
        PC.ownerid AS activityCreatedBy
        --Assoc.USR_First + ' ' + Assoc.USR_Last AS CreatedBy,
    FROM KSLCLOUD_MSCRM.dbo.Account A WITH (NOLOCK)
    INNER JOIN KSLCLOUD_MSCRM.dbo.activities PC WITH (NOLOCK) 
        ON PC.RegardingObjectId = A.accountid
    --LEFT JOIN KiscoCustom.dbo.Associate Assoc ON A.ownerid = Assoc.SalesAppID
)

SELECT 
    accountid,
    AccountOwnerID,
    AccountOwnerName,
    CommunityId,
    CommunityIdName,
    ActivitySubject,
    ActivityType,
    ActivityTypeDetail,
    CompletedDate,
    Rslt,
    activityid,
    notes,
    isBD,
    isSalesMail,
    google_campaignID,
    activityCreatedBy
FROM AllActivities
--WHERE CommunityId = '3BC35920-B2DE-E211-9163-0050568B37AC' --Byron Park
--AND CompletedDate >= DATEADD(month, -3, GETDATE()) -- Last Month
--AND CompletedDate <= DATEADD(month, -2, GETDATE()) -- Last Month
--ORDER BY CompletedDate DESC
ORDER BY accountid, activityid

-- Take 2
-- NEED to split text comversation into different rows
DECLARE @CommunityId uniqueidentifier = '3BC35920-B2DE-E211-9163-0050568B37AC';
DECLARE @FromDate    date            = '2025-09-17' --DATEADD(MONTH,-1, CAST(GETDATE() as date));
DECLARE @SampleN     int             = 500;

WITH Filtered AS (
  SELECT TOP (@SampleN)
      A.accountid,
      A.OwnerID               AS AccountOwnerID,
      A.OwnerIDname           AS AccountOwnerName,
      A.ksl_CommunityId       AS CommunityId,
      A.ksl_CommunityIdName   AS CommunityIdName,
      PC.Subject              AS ActivitySubject,
      PC.ActivityTypeCode     AS ActivityType,
      CAST(NULL AS int)       AS ActivityTypeDetail,
      PC.scheduledstart       AS CompletedDate,
      PC.ksl_resultoptions_displayname AS Rslt,
      PC.activityid,
      PC.description          AS notes,
      CASE WHEN A.statuscode_displayname = 'Referral Org' THEN 'Yes' ELSE 'No' END AS isBD,
      CASE WHEN PC.description LIKE '%sm.chat%' THEN 'Yes' ELSE 'No' END AS isSalesMail,
      CAST(NULL AS varchar(50)) AS google_campaignID,
      PC.ownerid              AS activityCreatedBy,
      PC.EmailBody
  FROM KSLCLOUD_MSCRM.dbo.Account    AS A WITH (NOLOCK)
  JOIN KSLCLOUD_MSCRM.dbo.activities AS PC WITH (NOLOCK)
    ON PC.RegardingObjectId = A.accountid
  --WHERE A.ksl_CommunityId = @CommunityId
    WHERE CONVERT(date, PC.scheduledstart) = @FromDate
    --AND PC.statuscode_displayname = 'Completed'
  ORDER BY PC.scheduledstart DESC
),
NonConversation AS (
  SELECT
      accountid, AccountOwnerID, AccountOwnerName,
      CommunityId, CommunityIdName, ActivitySubject,
      ActivityType, ActivityTypeDetail, CompletedDate, Rslt,
      activityid, notes, isBD, isSalesMail, google_campaignID,
      activityCreatedBy,
      CAST(NULL AS datetime2)      AS MessageTime,
      CAST(NULL AS nvarchar(4000)) AS MessageText,
      NULL                         AS MsgIndex
  FROM Filtered
  WHERE ActivityType <> 'Text Message Conversation'
),
TextConversationEvents AS (
  SELECT
      a.accountid,
      a.AccountOwnerID,
      a.AccountOwnerName,
      a.CommunityId,
      a.CommunityIdName,
      a.ActivitySubject,
      a.ActivityType,
      CASE WHEN LEFT(seg.tok,4) = 'SENT' THEN 1002 ELSE 1001 END AS ActivityTypeDetail,
      a.CompletedDate,
      CASE WHEN LEFT(seg.tok,4) = 'SENT' THEN 'Text Sent' ELSE 'Text Received' END AS Rslt,
      a.activityid,
      a.notes,
      a.isBD,
      a.isSalesMail,
      a.google_campaignID,
      a.activityCreatedBy,
      TRY_CONVERT(datetime2,
          NULLIF(SUBSTRING(seg.tok,
                 CHARINDEX('[',seg.tok)+1,
                 NULLIF(CHARINDEX(']',seg.tok),0) - CHARINDEX('[',seg.tok) - 1), '')
      ) AS MessageTime,
      LTRIM(SUBSTRING(seg.tok, NULLIF(CHARINDEX(']',seg.tok),0) + 1, 4000)) AS MessageText,
      ROW_NUMBER() OVER (PARTITION BY a.activityid ORDER BY pos.start_pos) AS MsgIndex
  FROM Filtered a
  CROSS APPLY (
      SELECT marked =
         REPLACE(
           REPLACE(
             REPLACE(COALESCE(a.EmailBody, a.notes, ''), CHAR(13)+CHAR(10), ' ')
           ,'RCVD','|RCVD')
         ,'SENT','|SENT')
  ) n
  CROSS APPLY (
      SELECT s.start_pos,
             LEAD(s.start_pos,1, LEN(n.marked)+1) OVER (ORDER BY s.start_pos) AS next_pos
      FROM (
        SELECT t.n AS start_pos
        FROM (
          SELECT TOP (LEN(n.marked))
                 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
          FROM sys.all_objects
        ) t
        WHERE SUBSTRING(n.marked, t.n, 5) IN ('|SENT','|RCVD')
      ) s
  ) pos
  CROSS APPLY (
      SELECT tok = SUBSTRING(n.marked, pos.start_pos + 1, pos.next_pos - pos.start_pos - 1)
  ) seg
  WHERE a.ActivityType = 'Text Message Conversation'
    AND (a.EmailBody LIKE '%SENT%' OR a.EmailBody LIKE '%RCVD%')
)

SELECT *
FROM NonConversation
UNION ALL
SELECT *
FROM TextConversationEvents
--ORDER BY CompletedDate DESC
ORDER BY accountid, activityid


-- TAKE 3? with text count, one per row for conversations
WITH AllActivities AS (
    SELECT 
        A.accountid,
        A.OwnerID                     AS AccountOwnerID,
        A.OwnerIDname                 AS AccountOwnerName,
        A.ksl_CommunityId             AS CommunityId,
        A.ksl_CommunityIdName         AS CommunityIdName,
        PC.Subject                    AS ActivitySubject,
        PC.ActivityTypeCode           AS ActivityType,
        CAST(NULL AS int)             AS ActivityTypeDetail,
        PC.scheduledstart             AS CompletedDate,
        CASE 
            WHEN PC.ActivityTypeCode = 'Outgoing Text Message' THEN 'Text Sent'
            WHEN PC.ActivityTypeCode = 'Incoming Text Message' THEN 'Text Recieved'
            ELSE PC.ksl_resultoptions_displayname
        END AS Rslt,
        PC.activityid,
        PC.description                AS notes,
        CASE WHEN A.statuscode_displayname = 'Referral Org' THEN 'Yes' ELSE 'No' END AS isBD,
        CASE WHEN PC.description LIKE '%sm.chat%' THEN 'Yes' ELSE 'No' END AS isSalesMail,
        CAST(NULL AS varchar(50))     AS google_campaignID,
        PC.ownerid                    AS activityCreatedBy,
        PC.EmailBody
    FROM KSLCLOUD_MSCRM.dbo.Account    AS A WITH (NOLOCK)
    JOIN KSLCLOUD_MSCRM.dbo.activities AS PC WITH (NOLOCK)
      ON PC.RegardingObjectId = A.accountid
),
-- Add Sent/Recieved notes for text conversations
TextConversationEvents AS (
    SELECT
        a.accountid,
        a.AccountOwnerID,
        a.AccountOwnerName,
        a.CommunityId,
        a.CommunityIdName,
        a.ActivitySubject,
        a.ActivityType,
        -- Check if EmailBody starts with SENT or RCVD pattern
        CASE 
            WHEN LEFT(COALESCE(a.EmailBody, a.notes, ''), 4) = 'SENT' THEN 1002 
            WHEN LEFT(COALESCE(a.EmailBody, a.notes, ''), 4) = 'RCVD' THEN 1001 
            ELSE NULL 
        END AS ActivityTypeDetail,
        a.CompletedDate,
        CASE 
            WHEN LEFT(COALESCE(a.EmailBody, a.notes, ''), 4) = 'SENT' THEN 'Text Sent' 
            WHEN LEFT(COALESCE(a.EmailBody, a.notes, ''), 4) = 'RCVD' THEN 'Text Received' 
            ELSE NULL 
        END AS Rslt,
        a.activityid,
        a.notes,
        a.isBD,
        a.isSalesMail,
        a.google_campaignID,
        a.activityCreatedBy,
    FROM AllActivities a
    WHERE a.ActivityType = 'Text Message Conversation'
      AND (LEFT(COALESCE(a.EmailBody, a.notes, ''), 4) = 'SENT' 
           OR LEFT(COALESCE(a.EmailBody, a.notes, ''), 4) = 'RCVD')
),
-- Non-conversation activities (pass through unchanged)
NonConversation AS (
    SELECT
        accountid,
        AccountOwnerID,
        AccountOwnerName,
        CommunityId,
        CommunityIdName,
        ActivitySubject,
        ActivityType,
        ActivityTypeDetail,   -- stays NULL for non-text, old value was number like 864960001, maybe we can remove
        CompletedDate,
        Rslt,
        activityid,
        notes,
        isBD,
        isSalesMail,
        google_campaignID,
        activityCreatedBy
    FROM AllActivities
    WHERE ActivityType <> 'Text Message Conversation'
)
-- Final unified set
SELECT *
FROM NonConversation

UNION ALL

SELECT
    accountid,
    AccountOwnerID,
    AccountOwnerName,
    CommunityId,
    CommunityIdName,
    ActivitySubject,
    ActivityType,
    ActivityTypeDetail,
    CompletedDate,
    Rslt,
    activityid,
    notes,
    isBD,
    isSalesMail,
    google_campaignID,
    activityCreatedBy
FROM TextConversationEvents

--TESTING filters
-- WHERE CommunityId = '3BC35920-B2DE-E211-9163-0050568B37AC'
--   AND CompletedDate >= DATEADD(MONTH, -1, GETDATE())
ORDER BY activityid, CompletedDate;

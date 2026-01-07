--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% INSERT INTO Fact_Activity %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--BEGIN TRY;THROW 50000,'',1;END TRY BEGIN CATCH;insert into Staging.dbo.log_DW_Time (LineNumber,MinSinceLast) values (ERROR_LINE(),DATEDIFF(mi,@DtLast,getdate()));END CATCH
--set @DtLast = getdate()
--exec [dbo].[Fill_Fact_Activity]
-- Insert statements for procedure here
--TRUNCATE TABLE Fact_Activity
--INSERT INTO Fact_Activity

-- Query should take ~30 seconds to run
-- TRUNCATE TABLE Fact_Activity;
WITH AllActivities AS (
    SELECT 
        A.accountid,
        PC.ownerid                    AS AccountOwnerID, -- this was A.OwnerID, but the SSAS model uses this as the relationship between Fact_Activity and Dim_User, and we didn't want to update the model
        A.OwnerIDname                 AS AccountOwnerName,
        A.ksl_CommunityId             AS CommunityId,
        A.ksl_CommunityIdName         AS CommunityIdName,
        PC.Subject                    AS ActivitySubject,
        PC.ActivityTypeCode           AS ActivityType,
        CAST(NULL AS int)             AS ActivityTypeDetail,
        PC.scheduledstart             AS CompletedDate,
        CASE 
            WHEN PC.ActivityTypeCode = 'Outgoing Text Message' THEN 'Text Sent'
            WHEN PC.ActivityTypeCode = 'Incoming Text Message' THEN 'Text Received'
            ELSE PC.ksl_resultoptions_displayname
        END AS Result,
        PC.activityid,
        -- some email templates are too long for the notes column, stopping tabular model from processing
        left(PC.description,250)                AS notes,
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
        END AS Result,
        a.activityid,
        a.notes,
        a.isBD,
        a.isSalesMail,
        a.google_campaignID,
        a.activityCreatedBy
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
        Result,
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
-- INSERT INTO Fact_Activity WITH (TABLOCK) -- TABLOCK speeds up bulk inserts
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
    Result,
    activityid,
    notes,
    isBD,
    isSalesMail,
    google_campaignID,
    activityCreatedBy
FROM TextConversationEvents;

--TESTING filters
-- WHERE CommunityId = '3BC35920-B2DE-E211-9163-0050568B37AC'
--   AND CompletedDate >= DATEADD(MONTH, -1, GETDATE())
-- ORDER BY activityid, CompletedDate;
-- TESTING END

-- This is SLOOOW
-- 	  update a
-- set google_campaignID = g.gCampaignID
--   FROM [DataWarehouse].[dbo].[Fact_Activity] a
--   join staging.[dbo].[GAds_CampaignIDs] g on g.accountid = a.[accountid]
--   where google_campaignID is null 
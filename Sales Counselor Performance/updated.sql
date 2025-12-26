--use DataWarehouse;

--DECLARE @StartDate DATE = '11/23/2025'; -- Replace with your start date
--DECLARE @EndDate DATE = '12/23/2025'; -- Replace with your end date

WITH BaseData AS (
    SELECT 
        a.CommunityId,
        a.ActivitySubject,
        a.ActivityType,
        a.ActivityTypeDetail,
        a.CompletedDate,
        a.Result,
        a.activityid,
        a.isSalesMail,
        a.activityCreatedBy,
        s.fullname,
        s.systemuserid BookerOwnerid,
        c.GroupedShortName,
        'CompletedAppt' AS Source,
        acc.ksl_donotcontactreason, -- Include the do not contact reason
        acc.accountid -- Add accountid for NRR lookup
    FROM  [DataWarehouse].[dbo].[Fact_Activity] a
    JOIN DataWarehouse.dbo.Dim_User s ON s.systemuserid = a.[activityCreatedBy]
    JOIN (SELECT DISTINCT Groupedksl_communityId, GroupedShortName FROM [DataWarehouse].[dbo].[dim_community]) c ON c.Groupedksl_communityId = a.CommunityId
    JOIN [KSLCLOUD_MSCRM].[dbo].[account] acc WITH (NOLOCK) ON a.accountid = acc.accountid -- Join with account table
    WHERE a.CompletedDate BETWEEN @StartDate AND @EndDate
		AND (IsBD = 'no' AND s.title LIKE '%sales counselor%' )
),
AccountCreated AS (
    SELECT 
        L.ksl_CommunityId AS CommunityId,
        acc.createdon AS AccountCreatedDate,
        s.fullname,
        c.GroupedShortName
    FROM [DataWarehouse].[dbo].[Fact_Lead] L
    JOIN [KSLCLOUD_MSCRM].[dbo].[account] acc ON L.Lead_AccountID = acc.accountid
    JOIN DataWarehouse.dbo.Dim_User s ON s.systemuserid = acc.createdby
    JOIN (SELECT DISTINCT Groupedksl_communityId, GroupedShortName FROM [DataWarehouse].[dbo].[dim_community]) c ON c.Groupedksl_communityId = L.ksl_CommunityId
    WHERE acc.createdon BETWEEN @StartDate AND @EndDate
      AND s.title LIKE '%sales counselor%'
),
CommunityNRR AS (
    -- Modified to capture ALL counselors with NRR in the time period, not just those in BaseData
    SELECT  
        c.GroupedShortName,
        b.fullname,
        b.BookerOwnerid,
        SUM((l.TransferFee + l.AptRate) - l.CommTransFeeSpecial) + SUM(l.NrrAdjustment) as NRR
    FROM (
        SELECT DISTINCT fullname, BookerOwnerid, GroupedShortName, accountid
        FROM BaseData
        WHERE ActivityType IN ('Committed Face Appointment', 'Unscheduled Walk-In')
    ) b
    JOIN Fact_Lease l ON b.accountid = l.accountid 
    JOIN [KSLCLOUD_MSCRM]..ksl_apartment a ON a.ksl_apartmentid = l.ksl_ApartmentId
    JOIN [DataWarehouse].[dbo].[Dim_Date] d ON d.Date = l.StartDate
    JOIN [DataWarehouse].[dbo].[dim_community] c ON c.ksl_communityId = l.ksl_CommunityId
    WHERE d.Date BETWEEN @StartDate AND @EndDate
    AND (l.ksl_CareLevelIdName != 'Skilled Nursing' OR l.ksl_CareLevelIdName IS NULL)
    AND l.ksl_communityId NOT IN ('C74BD355-B5DA-4C9A-AE08-C6655B245C38','FB8AF664-D9C2-4B2C-80C5-1774EA31EDAE')
    AND l.MoveinTransactionType IN ('Actual Move In', 'Scheduled Move In')
    AND (NOT(l.MoveOutTransactionType = 'Actual Move Out' AND l.MonthsAsResident = 0)
        OR MoveOutTransactionType IS NULL
        OR (l.MoveOutTransactionType = 'Actual Move Out' AND l.MonthsAsResident > 0))
    GROUP BY c.GroupedShortName, b.fullname, b.BookerOwnerid
),
AggregatedBaseData AS (
    SELECT
        fullname,
        BookerOwnerid,
        GroupedShortName,
        SUM(CASE 
            WHEN ActivityType IN ('Committed Face Appointment', 'Unscheduled Walk-In')
             AND (Result = 'Completed') 
             AND Source in ( 'CompletedAppt', 'BookedAppt')
            THEN 1 ELSE 0 
        END) AS Appointments_CompletedAppt,
        SUM(CASE 
            WHEN ActivityType IN ('Committed Face Appointment', 'Unscheduled Walk-In')
             AND Source in ( 'CompletedAppt', 'BookedAppt')
            THEN 1 ELSE 0 
        END) AS Appointments_BookedAppt,
        SUM(CASE 
            WHEN (ActivityType IN ('Outgoing Phone Call', 'Incoming Phone Call', 'Committed Phone Appointment'))
                AND Result = 'Completed' 
            THEN 1 ELSE 0 
        END) AS CompletedPhoneCalls,
        SUM(CASE 
            WHEN ActivityType IN ('Outgoing Phone Call', 'Incoming Phone Call')
             AND Result NOT IN ('Bad Contact Information', 'Cancelled', 'Completed') 
            THEN 1 ELSE 0 
        END) AS AttemptedCalls,
        SUM(CASE 
            WHEN ActivityType = 'Incoming Phone Call' 
             AND Result = 'Completed'
            THEN 1 ELSE 0 
        END) AS IncomingCompletedCalls,
        SUM(CASE 
            WHEN isSalesMail = 'Yes' 
            THEN 1 ELSE 0 
        END) AS SalesMailSent,
        SUM(CASE 
            WHEN (ActivityType IN ('Outbound Email','Letter')) 
            THEN 1 ELSE 0 
        END) AS SentMessages,
        SUM(CASE 
            WHEN ActivityType = 'Outbound Text Message' 
             OR (ActivityType = 'Text Message Conversation' AND Result = 'Text Sent')
            THEN 1 ELSE 0 
        END) AS TextsSent,
        SUM(CASE 
            WHEN ActivityType = 'Task'
            THEN 1 ELSE 0 
        END) AS LiveChats,

      
        SUM(CASE 
            WHEN ActivityType = 'Task'  
            THEN 1 ELSE 0 
        END) +
        SUM(CASE 
            WHEN ActivityType IN ('Committed Face Appointment', 'Unscheduled Walk-In')
             AND Source in ( 'CompletedAppt', 'BookedAppt')

            THEN 1 ELSE 0 
        END) + 
        SUM(CASE 
            WHEN (ActivityType IN ('Outgoing Phone Call', 'Incoming Phone Call', 'Committed Phone Appointment'))
                AND Result = 'Completed' 
            THEN 1 ELSE 0 
        END) + 
        SUM(CASE 
            WHEN ActivityType IN ('Outgoing Phone Call', 'Incoming Phone Call') 
             AND Result NOT IN ('Bad Contact Information', 'Cancelled', 'Completed') 
            THEN 1 ELSE 0 
        END) + 
        SUM(CASE 
            WHEN isSalesMail = 'Yes' 
            THEN 1 ELSE 0 
        END) + 
        SUM(CASE 
            WHEN (ActivityType = 'Outgoing Email') 
                OR (ActivityType = 'Letter') 
            THEN 1 ELSE 0 
        END) + 
        SUM(CASE 
            WHEN ActivityType = 'Outgoing Text'
             OR (ActivityType = 'Text Message Conversation' AND Result = 'Text Sent')
            THEN 1 ELSE 0 
        END) AS TotalActivities,

        SUM(CASE 
            WHEN ksl_donotcontactreason IS NOT NULL 
            THEN 1 ELSE 0 
        END) AS TotalActivities_DoNotContact
    FROM BaseData bd
    where bd.CompletedDate BETWEEN @StartDate AND @EndDate
-- and fullname = 'Allison Nani'

    GROUP BY fullname, GroupedShortName, BookerOwnerid
),
AggregatedAccounts AS (
    SELECT
        fullname,
        GroupedShortName,
        COUNT(AccountCreatedDate) AS AccountsCreated
    FROM AccountCreated
    GROUP BY fullname, GroupedShortName
)
-- Use FULL OUTER JOIN to capture all counselors who have either activities OR NRR
SELECT 
    COALESCE(bd.fullname, nrr.fullname) as fullname,
    COALESCE(bd.BookerOwnerid, nrr.BookerOwnerid) as BookerOwnerid,
    COALESCE(bd.GroupedShortName, nrr.GroupedShortName) as GroupedShortName,
    COALESCE(bd.Appointments_CompletedAppt, 0) as Appointments_CompletedAppt,
    COALESCE(bd.Appointments_BookedAppt, 0) as Appointments_BookedAppt,
    COALESCE(bd.CompletedPhoneCalls, 0) as CompletedPhoneCalls,
    COALESCE(bd.AttemptedCalls, 0) as AttemptedCalls,
    COALESCE(bd.IncomingCompletedCalls, 0) as IncomingCompletedCalls,
    COALESCE(bd.SalesMailSent, 0) as SalesMailSent,
    COALESCE(bd.SentMessages, 0) as SentMessages,
    COALESCE(bd.TextsSent, 0) as TextsSent,
    COALESCE(bd.LiveChats, 0) as LiveChats,
    COALESCE(bd.TotalActivities, 0) as TotalActivities,
    COALESCE(bd.TotalActivities_DoNotContact, 0) as TotalActivities_DoNotContact,
    COALESCE(ac.AccountsCreated, 0) AS AccountsCreated,
    COALESCE(nrr.NRR, 0) as CommunityNRR
FROM AggregatedBaseData bd
FULL OUTER JOIN CommunityNRR nrr ON bd.GroupedShortName = nrr.GroupedShortName AND bd.BookerOwnerid = nrr.BookerOwnerid
LEFT JOIN AggregatedAccounts ac ON COALESCE(bd.fullname, nrr.fullname) = ac.fullname 
    AND COALESCE(bd.GroupedShortName, nrr.GroupedShortName) = ac.GroupedShortName
ORDER BY COALESCE(bd.fullname, nrr.fullname);
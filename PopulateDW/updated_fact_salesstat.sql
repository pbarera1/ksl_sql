-- 5-10 seconds to run
DECLARE @today       date = CONVERT(date, GETDATE());
DECLARE @now         datetime = GETDATE();
DECLARE @ceStartDate date = '2022-03-09';  -- original CE/Appt cutoff

-- Delete existing data for today before inserting new data. Safeguard against duplicate inserts if ran mutiple times in a day.
-- DELETE FROM [DataWarehouse].[dbo].[Fact_SalesStats]
-- WHERE dt = @today;

;WITH
/* 1) Active sales users once */
ActiveSalesUsers AS (
    SELECT
        @today AS dt,
        du.FullName,
        du.SystemUserId,
        du.ksl_CommunityIdName,
        du.ksl_CommunityId,
        du.Title
    FROM DataWarehouse.dbo.Dim_User du
    WHERE du.isUserActive = 'yes'
      AND du.Title LIKE '%sales%'
      AND du.Title NOT LIKE '%VP%'
      AND du.Title <> 'Sales Coordinator'
      AND du.FullName NOT IN ('# Dynamic.Test', 'Cedarwood Sales')
      AND du.ksl_CommunityId IS NOT NULL
),

/* 2) Leads once (include fields needed by RAD + Compliance) */
LeadAccounts AS (
    SELECT
        a.accountid,
        a.ownerid,
        a.statuscode_displayname,
        a.ksl_CommunityId,
        a.ksl_initialinquirydate,
        a.ksl_mostrecentcommunityexperience,
        a.ksl_reservationfeetransactiondate,
        a.ksl_waitlisttransactiondate,
        a.ksl_waitlistenddate,
        a.ksl_losttocompetitoron,
        a.ksl_moveintiming_displayname,

        -- Compliance fields
        a.ksl_initialsourcecategoryname            AS SourceCategory,
        a.ksl_leveloflivingpreference_displayname  AS CarePref
    FROM KSLCLOUD_MSCRM.dbo.Account a WITH (NOLOCK)
    WHERE a.statuscode_displayname = 'Lead'
),

/* 3) Community timezone info once */
Community AS (
    SELECT ksl_communityId, ksl_UTCTimeAdjust
    FROM KSLCLOUD_MSCRM.dbo.ksl_community WITH (NOLOCK)
),

/* 4) Filter activities once (only the columns needed) */
ActivitiesBase AS (
    SELECT
        act.activityid,
        act.RegardingObjectId AS accountid,
        act.ownerid,
        act.Subject,
        act.ActivityTypeCode,
        act.ksl_resultoptions_displayname,
        act.statuscode_displayname,
        act.scheduledstart,
        act.scheduledend,
        act.description,
        act.createdon
    FROM KSLCLOUD_MSCRM.dbo.activities act WITH (NOLOCK)
    WHERE act.RegardingObjectId IS NOT NULL
),

/* 5) “Bucket” ranks (top 1 per account per bucket) */
RankedActivities AS (
    SELECT
        ab.*,

        ROW_NUMBER() OVER (
            PARTITION BY ab.accountid
            ORDER BY ab.scheduledstart DESC
        ) AS rn_last_contact,

        ROW_NUMBER() OVER (
            PARTITION BY ab.accountid
            ORDER BY ab.scheduledstart DESC
        ) AS rn_last_ce,

        ROW_NUMBER() OVER (
            PARTITION BY ab.accountid
            ORDER BY ab.scheduledend ASC
        ) AS rn_next_activity,

        ROW_NUMBER() OVER (
            PARTITION BY ab.accountid
            ORDER BY COALESCE(ab.scheduledend, ab.scheduledstart) DESC
        ) AS rn_last_attempt
    FROM ActivitiesBase ab
),

LastContact AS (
    SELECT
        ra.accountid,
        ra.Subject AS ActivitySubject,
        ra.ActivityTypeCode AS LCType,
        CAST(NULL AS nvarchar(100)) AS LCTypeDetail,
        ra.scheduledstart AS LastContactDate,
        ra.description AS LCNotes
    FROM RankedActivities ra
    WHERE ra.rn_last_contact = 1
      AND ra.ActivityTypeCode IN (
            'Outbound Phone Call','Incoming Phone Call',
            'Committed Face Appointment','Unscheduled Walk-In','Inbound Email'
      )
      AND ra.ksl_resultoptions_displayname = 'Completed'
),

NextActivity AS (
    SELECT
        ra.accountid,
        ra.Subject AS ActivitySubject,
        ra.ActivityTypeCode AS NAType,
        ra.ActivityTypeCode AS NATypeDetail,
        ra.scheduledend AS NextActivityDate,
        ra.description AS NANotes,
        ra.activityid AS NAActivityId,
        ra.ownerid
    FROM RankedActivities ra
    WHERE ra.rn_next_activity = 1
      AND ra.ActivityTypeCode NOT LIKE '%text%'
      AND ISNULL(ra.ksl_resultoptions_displayname,'') <> 'Completed'
),

LastAttempt AS (
    SELECT
        ra.accountid,
        ra.Subject AS ActivitySubject,
        ra.ActivityTypeCode AS LAType,
        ra.ActivityTypeCode AS LATypeDetail,
        COALESCE(ra.scheduledend, ra.scheduledstart) AS LastAttemptDate,
        LEFT(ra.description, 300) AS LANotes
    FROM RankedActivities ra
    WHERE ra.rn_last_attempt = 1
      AND (
            ra.ksl_resultoptions_displayname = 'Completed'
         OR ra.statuscode_displayname = 'Completed'
      )
),

/* 6) RADcount */
RADcountByOwner AS (
    SELECT
        la.ownerid,
        COUNT_BIG(*) AS RADcount
    FROM LeadAccounts la
    LEFT JOIN Community c
        ON c.ksl_communityId = la.ksl_CommunityId
    LEFT JOIN NextActivity na
        ON na.accountid = la.accountid
    LEFT JOIN LastContact lc
        ON lc.accountid = la.accountid
    LEFT JOIN LastAttempt lat
        ON lat.accountid = la.accountid
    WHERE
        (la.ksl_mostrecentcommunityexperience < DATEADD(day, -30, @now)
         OR la.ksl_mostrecentcommunityexperience IS NULL)
        AND la.ksl_initialinquirydate < DATEADD(day, -30, @now)
        AND la.ksl_reservationfeetransactiondate IS NULL
        AND (
            0 <= CASE
                    WHEN la.ksl_moveintiming_displayname = '> 2 Years'
                        THEN DATEDIFF(day, DATEADD(day, 90, COALESCE(lat.LastAttemptDate, DATEADD(day, -90, @now))), @now)

                    WHEN la.ksl_mostrecentcommunityexperience >= DATEADD(day, -120, @now)
                         AND lc.LastContactDate > DATEADD(day, -60, @now)
                         AND (la.ksl_waitlisttransactiondate IS NULL AND la.ksl_waitlistenddate IS NOT NULL)
                        THEN DATEDIFF(day, DATEADD(day, 14, lat.LastAttemptDate), @now)

                    WHEN la.ksl_mostrecentcommunityexperience >= DATEADD(day, -270, @now)
                         AND lc.LastContactDate > DATEADD(day, -180, @now)
                         AND (la.ksl_waitlisttransactiondate IS NULL AND la.ksl_waitlistenddate IS NOT NULL)
                        THEN DATEDIFF(day, DATEADD(day, 45, lat.LastAttemptDate), @now)

                    WHEN la.ksl_losttocompetitoron IS NOT NULL
                        THEN DATEDIFF(day, DATEADD(day, 180, lat.LastAttemptDate), @now)

                    ELSE DATEDIFF(day, DATEADD(day, 90, COALESCE(lat.LastAttemptDate, DATEADD(day, -90, @now))), @now)
                 END
            OR CONVERT(date, DATEADD(hour, c.ksl_UTCTimeAdjust, na.NextActivityDate)) < @today
        )
    GROUP BY la.ownerid
),

/* 7) Active lead counts */
ActiveLeadsByOwner AS (
    SELECT ownerid, COUNT_BIG(*) AS activeLeads
    FROM LeadAccounts
    GROUP BY ownerid
),

/* 8) Past due activities */
PastDueByOwner AS (
    SELECT
        ab.ownerid,
        COUNT_BIG(*) AS PastDueActivityCount
    FROM ActivitiesBase ab
    INNER JOIN LeadAccounts a
        ON a.accountid = ab.accountid
    LEFT JOIN Community c
        ON c.ksl_communityId = a.ksl_CommunityId
    WHERE ab.ActivityTypeCode NOT IN ('Outgoing Text Message','Incoming Text Message','Text Message Conversation')
      -- Activity wouldn't be past due if it has <> Completed status
      -- For example: Cancelled, Left Message, No Show, No Answer, Rescheduled
      AND (ab.ksl_resultoptions_displayname IS NULL OR ab.ksl_resultoptions_displayname = '')
      AND CONVERT(date, DATEADD(hour, c.ksl_UTCTimeAdjust, ab.scheduledend)) < @today
    AND ab.createdon > '2025-12-10'
    GROUP BY ab.ownerid
),

/* 9) DataCompliance inputs */
FloorPlanFilled AS (
    SELECT DISTINCT accountid
    FROM KSLCLOUD_MSCRM.dbo.ksl_account_ksl_unitfloorplan WITH (NOLOCK)
),

LastCompletedApptCE AS (
    SELECT
        act.RegardingObjectId AS accountid,
        MAX(act.scheduledstart) AS LastCompletedApptCEDate
    FROM KSLCLOUD_MSCRM.dbo.activities act WITH (NOLOCK)
    WHERE act.ActivityTypeCode IN ('Committed Face Appointment', 'Unscheduled Walk-In')
      AND (act.statuscode_displayname = 'Completed' OR act.ksl_resultoptions_displayname = 'Completed')
      AND act.ksl_resultoptions_displayname <> 'Cancelled'
      AND act.scheduledstart >= @ceStartDate
    GROUP BY act.RegardingObjectId
),

DataComplianceByOwner AS (
    SELECT
        l.ownerid,
        COUNT_BIG(*) AS DataCompliance
    FROM LeadAccounts l
    LEFT JOIN FloorPlanFilled fp
        ON fp.accountid = l.accountid
    LEFT JOIN LastCompletedApptCE ce
        ON ce.accountid = l.accountid
    WHERE
        -- Old lead
        l.ksl_initialinquirydate < DATEADD(day, -30, @now)
        AND
        (
            -- Missing any core field
            l.SourceCategory IS NULL
            OR l.ksl_moveintiming_displayname IS NULL
            OR l.CarePref IS NULL

            -- Missing floor plan, but only if completed Appt/CE > 7 days ago
            OR (
                fp.accountid IS NULL
                AND ce.LastCompletedApptCEDate IS NOT NULL
                AND ce.LastCompletedApptCEDate < DATEADD(day, -7, @now)
            )
        )
    GROUP BY l.ownerid
)

 --%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

-- Insert into [DataWarehouse].[dbo].[Fact_SalesStats] ( [dt],[Owner],[OwnerID],[Community],[CommunityID], RADcount  ,DataComplianceCount ,PastDueActivityCount, activeLeads )

 --%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

/* FINAL */
SELECT
    u.dt,
    u.FullName,
    u.SystemUserId,
    u.ksl_CommunityIdName,
    u.ksl_CommunityId,
    COALESCE(rad.RADcount, 0)             AS RADcount,
    COALESCE(dc.DataCompliance, 0)        AS DataComplianceCount,
    COALESCE(pd.PastDueActivityCount, 0)  AS PastDueActivityCount,
    COALESCE(al.activeLeads, 0)           AS activeLeads
FROM ActiveSalesUsers u
LEFT JOIN RADcountByOwner        rad ON rad.ownerid = u.SystemUserId
LEFT JOIN DataComplianceByOwner  dc  ON dc.ownerid  = u.SystemUserId
LEFT JOIN ActiveLeadsByOwner     al  ON al.ownerid  = u.SystemUserId
LEFT JOIN PastDueByOwner         pd  ON pd.ownerid  = u.SystemUserId
;
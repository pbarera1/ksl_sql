/****** Script for SelectTopNRows command from SSMS ******/
USE KSLCLOUD_MSCRM_RESTORE_TEST;

DECLARE @Year INT = 2025;

WITH activity AS (
    /* =========================
       Primary activity rows
       ========================= */
    SELECT
        b.ownerid                                    AS AccountOwnerID,
        b.[from]                                     AS AccountOwnerName,
        a.ksl_communityid                            AS CommunityId,
        a.ksl_communityidname                        AS CommunityIdName,

        b.subject                                    AS ActivitySubject,

        /* Canonical bucket so actSUM can match exactly */
        CASE
            WHEN b.activitytypecode IN ('Committed Face Appointment','Committed Phone Appointment','Unscheduled Walk-In')
                 OR b.activitytypecode LIKE '%appointment%'  THEN 'appointment BD'
            WHEN b.activitytypecode IN ('Inbound Email','Outbound Email') THEN 'email BD'
            WHEN b.activitytypecode = 'Letter'               THEN 'letter BD'
            WHEN b.activitytypecode IN ('Outgoing Phone Call','Incoming Phone Call','Phone Call')
                 OR b.activitytypecode LIKE '%phone%'        THEN 'phonecall BD'
            ELSE b.activitytypecode + ' BD'
        END                                           AS ActivityType,

        b.activitytypecode                            AS ActivityTypeDetail,
        b.CompletedDate                               AS CompletedDate
    FROM (
        SELECT
            PC.activityid,
            PC.ksl_resultoptions_displayname          AS Rslt,
            PC.ownerid,
            PC.[from],
            PC.subject,
            PC.activitytypecode,
            PC.regardingobjectid,

            /* No actualend on activities: normalize with fallback */
            CONVERT(date, COALESCE(PC.scheduledend, PC.scheduledstart, PC.modifiedon, PC.createdon)) AS CompletedDate,

            LEFT(PC.[description], 300)               AS notes
        FROM KSLCLOUD_MSCRM_RESTORE_TEST.dbo.activities AS PC WITH (NOLOCK)
        WHERE PC.statuscode_displayname = 'Completed'
          AND (
                 PC.activitytypecode LIKE '%walk-in%'
              OR PC.activitytypecode LIKE '%face appointment%'
              OR PC.activitytypecode LIKE '%appointment%'
              OR PC.activitytypecode LIKE '%phone%'
              OR PC.activitytypecode LIKE '%email%'
              OR PC.activitytypecode LIKE '%letter%'
          )
    ) AS b
    /* Many rows now regard the ACCOUNT; keep contact-regarded, but don't drop account-regarded rows */
    LEFT JOIN kslcloud_mscrm.dbo.contact AS a WITH (NOLOCK)
      ON b.regardingobjectid = a.contactid
    WHERE
        b.CompletedDate BETWEEN DATEFROMPARTS(@Year, 1, 1)
                           AND CASE WHEN @Year = YEAR(GETDATE())
                                    THEN GETDATE()
                                    ELSE DATEFROMPARTS(@Year, 12, 31) END

    UNION ALL

    /* =========================
       RR appointment branch
       ========================= */
    SELECT
        e.ownerid                                     AS AccountOwnerID,
        e.[from]                                      AS AccountOwnerName,
        e.ksl_communityid                             AS CommunityId,
        e.ksl_communityidname                         AS CommunityIdName,
        e.subject                                     AS ActivitySubject,
        'RR appointment BD'                           AS ActivityType,       -- normalized for actSUM
        e.activitytypecode                            AS ActivityTypeDetail,
        e.CompletedDate                               AS CompletedDate
    FROM (
        SELECT TOP (1000)
            PC.activityid,
            PC.ksl_resultoptions_displayname          AS Rslt,
            PC.ownerid,
            PC.[from],
            PC.subject,
            PC.activitytypecode,
            PC.regardingobjectid,

            CONVERT(date, COALESCE(PC.scheduledend, PC.scheduledstart, PC.modifiedon, PC.createdon)) AS CompletedDate,

            c.MoveInDate,
            LEFT(PC.[description], 300)               AS notes,
            c.ksl_communityid,
            c.ksl_communityidname
        FROM KSLCLOUD_MSCRM_RESTORE_TEST.dbo.activities AS PC WITH (NOLOCK)
        JOIN DataWarehouse.dbo.Fact_Lead AS c
          ON c.Lead_AccountID = PC.regardingobjectid
        WHERE PC.statuscode_displayname = 'Completed'
          AND (
                 PC.activitytypecode LIKE '%Appointment%'
              OR PC.activitytypecode IN ('Committed Face Appointment','Committed Phone Appointment','Unscheduled Walk-In')
          )
          /* If “Bus Development Drop In” is encoded differently, refine this predicate */
          AND (PC.subject LIKE '%Drop In%' OR PC.subject LIKE '%Business Development%')

          /* When scheduledstart is NULL (e.g., calls), use scheduledend/modifiedon/createdon */
          AND COALESCE(PC.scheduledstart, PC.scheduledend, PC.modifiedon, PC.createdon) > c.MoveInDate

          AND CONVERT(date, COALESCE(PC.scheduledend, PC.scheduledstart, PC.modifiedon, PC.createdon))
              BETWEEN DATEFROMPARTS(@Year, 1, 1)
                  AND CASE WHEN @Year = YEAR(GETDATE())
                           THEN GETDATE()
                           ELSE DATEFROMPARTS(@Year, 12, 31) END
    ) AS e
),

/* =========================
   Summarize by owner
   ========================= */
actSUM AS (
    SELECT
        AccountOwnerID,
        SUM(CASE WHEN ActivityType = 'appointment BD'     THEN 1 ELSE 0 END)        AS appointment_BD,
        SUM(CASE WHEN ActivityType = 'RR appointment BD'  THEN 1 ELSE 0 END) * 1.0  AS RR_appointment_BD,
        SUM(CASE WHEN ActivityType = 'email BD'           THEN 1 ELSE 0 END)        AS email_BD,
        SUM(CASE WHEN ActivityType = 'letter BD'          THEN 1 ELSE 0 END)        AS letter_BD,
        SUM(CASE WHEN ActivityType = 'phonecall BD'       THEN 1 ELSE 0 END)        AS phonecall_BD
    FROM activity
    GROUP BY AccountOwnerID
),

/* =========================
   NRR / Leads / MoveIns / NewRS / ResRef
   (left as-is)
   ========================= */
NRR AS (
    SELECT SUM(RentRev) AS RentRev, ksl_securityregionteamid
    FROM (
        SELECT
            ISNULL(SUM(ksl_ACT_CommTransFee + new_ApartmentRate - ISNULL(est.ksl_ACT_CommTransFeeSpecial,0)),0) AS RentRev,
            a.ksl_CommunityId
        FROM (
            SELECT
                afh.ksl_BeginDate, afh.ksl_ApartmentId, afh.ksl_ApartmentIdName, afh.ksl_CommunityId,
                afh.ksl_communityIdName, afh.ksl_accountLeadId, MAX(afh.ksl_endDate) AS EndDt,
                afh.ksl_estimateId, afh.ksl_BeginTransactionType, MAX(afh.ksl_EndTransactionType) ksl_EndTransactionType,
                MAX(afh.ksl_ReasonDetailIDName) AS ksl_ReasonDetailIDName,
                MAX(afh.ksl_MoveOutDestinationIdName) AS ksl_MoveOutDestinationIdName,
                MAX(afh.OwnerId) AS afh_OwnerID
            FROM ksl_apartmentfinancialhistory afh WITH (NOLOCK)
            LEFT JOIN account A WITH (NOLOCK) ON a.AccountID = ksl_accountleadid
            LEFT JOIN Quote q WITH (NOLOCK)   ON q.QuoteID = ksl_estimateid
            WHERE (afh.ksl_BeginTransactionType IN (864960001,864960003,864960007,864960008)
                     AND a.[ksl_initialsourcecategory] = '25AC1CB4-C27F-E311-986A-0050568B37AC'
                     AND afh.statecode = 0
                     AND (afh.ksl_EndTransactionType IN (864960004,864960006,864960002,864960005) OR afh.ksl_EndTransactionType IS NULL))
               OR (afh.ksl_BeginTransactionType = 864960000 AND afh.statecode = 0 AND afh.ksl_EndTransactionType IS NULL
                   AND CAST(afh.ksl_BeginDate AS DATE) >= CAST(GETDATE()-15 AS DATE))
            GROUP BY afh.ksl_BeginDate, afh.ksl_ApartmentId, afh.ksl_accountLeadId, afh.ksl_estimateId,
                     afh.ksl_BeginTransactionType, afh.ksl_ApartmentIdName, afh.ksl_CommunityId, afh.ksl_communityIdName
        ) AS y
        FULL OUTER JOIN [Quote] est ON QuoteID = ksl_estimateId
        LEFT JOIN account A WITH (NOLOCK) ON a.accountid = est.customerid
        WHERE COALESCE(
                CASE
                    WHEN y.ksl_BeginTransactionType = 864960001 THEN 'Actual Move in'
                    WHEN y.ksl_BeginTransactionType = 864960003 THEN 'Actual Transfer In'
                    WHEN y.ksl_BeginTransactionType = 864960007 THEN 'Short Term Stay Begin'
                    WHEN y.ksl_BeginTransactionType = 864960008 THEN 'Seasonal Stay Begin'
                    WHEN y.ksl_BeginTransactionType = 864960000 THEN 'Scheduled Move in'
                END, est.ksl_estimatetype_displayname
              ) IN ('Actual Move in','Moved In')
          AND a.[ksl_initialsourcecategory] = '25AC1CB4-C27F-E311-986A-0050568B37AC'
          AND ISNULL(ksl_BeginDate, est.ksl_schfinanmovein) BETWEEN DATEFROMPARTS(@Year,1,1)
              AND CASE WHEN @Year = YEAR(GETDATE()) THEN GETDATE() ELSE DATEFROMPARTS(@Year,12,31) END
        GROUP BY a.ksl_CommunityId
    ) d
    INNER JOIN [KSLCLOUD_MSCRM].[dbo].ksl_community c WITH (NOLOCK)
      ON d.ksl_CommunityId = c.ksl_communityid
    GROUP BY ksl_securityregionteamid
),

leads AS (
    SELECT COUNT(accountid) AS newLeadsavg, ksl_securityregionteamid
    FROM [KSLCLOUD_MSCRM].[dbo].[account] a
    INNER JOIN [KSLCLOUD_MSCRM].[dbo].ksl_community c ON a.ksl_communityid = c.ksl_communityid
    WHERE [ksl_initialsourcecategory] = '25AC1CB4-C27F-E311-986A-0050568B37AC'
      AND ksl_initialinquirydate BETWEEN DATEFROMPARTS(@Year,1,1)
          AND CASE WHEN @Year = YEAR(GETDATE()) THEN GETDATE() ELSE DATEFROMPARTS(@Year,12,31) END
    GROUP BY ksl_securityregionteamid
),

MoveIns AS (
    SELECT COUNT(est.quoteid) AS MoveInavg, c.ksl_securityregionteamid
    FROM (
        SELECT
            afh.ksl_BeginDate, afh.ksl_ApartmentId, afh.ksl_accountLeadId, afh.ksl_estimateId,
            afh.ksl_BeginTransactionType, afh.ksl_ApartmentIdName, afh.ksl_CommunityId, afh.ksl_communityIdName
        FROM ksl_apartmentfinancialhistory afh WITH (NOLOCK)
        LEFT JOIN account A WITH (NOLOCK) ON a.AccountID = ksl_accountleadid
        LEFT JOIN Quote q WITH (NOLOCK)   ON q.QuoteID = ksl_estimateid
        WHERE (afh.ksl_BeginTransactionType IN (864960001,864960003,864960007,864960008)
                 AND afh.statecode = 0
                 AND [ksl_initialsourcecategory] = '25AC1CB4-C27F-E311-986A-0050568B37AC'
                 AND (afh.ksl_EndTransactionType IN (864960004,864960006,864960002,864960005) OR afh.ksl_EndTransactionType IS NULL))
           OR (afh.ksl_BeginTransactionType = 864960000 AND afh.statecode = 0 AND afh.ksl_EndTransactionType IS NULL
               AND CAST(afh.ksl_BeginDate AS DATE) >= CAST(GETDATE()-15 AS DATE))
        GROUP BY afh.ksl_BeginDate, afh.ksl_ApartmentId, afh.ksl_accountLeadId, afh.ksl_estimateId,
                 afh.ksl_BeginTransactionType, afh.ksl_ApartmentIdName, afh.ksl_CommunityId, afh.ksl_communityIdName
    ) y
    FULL OUTER JOIN [Quote] est ON QuoteID = ksl_estimateId
    LEFT JOIN account A WITH (NOLOCK) ON a.accountid = est.customerid
    LEFT JOIN contact c1 ON est.ksl_primaryresident1id = c1.contactid
    LEFT JOIN contact c2 ON est.ksl_potentialsecondaryresidentid = c2.contactid
    LEFT JOIN ksl_apartment apt ON est.ksl_ApartmentId = apt.ksl_ApartmentID
    LEFT JOIN ksl_apartment tra ON est.ksl_act_transferfromapartmentid = tra.ksl_ApartmentID
    INNER JOIN [KSLCLOUD_MSCRM].[dbo].ksl_community c ON a.ksl_communityid = c.ksl_communityid
    WHERE COALESCE(
            CASE
                WHEN y.ksl_BeginTransactionType = 864960001 THEN 'Actual Move in'
                WHEN y.ksl_BeginTransactionType = 864960003 THEN 'Actual Transfer In'
                WHEN y.ksl_BeginTransactionType = 864960007 THEN 'Short Term Stay Begin'
                WHEN y.ksl_BeginTransactionType = 864960008 THEN 'Seasonal Stay Begin'
                WHEN y.ksl_BeginTransactionType = 864960000 THEN 'Scheduled Move in'
            END, est.ksl_estimatetype_displayname
          ) = 'Actual Move in'
      AND ISNULL(ksl_BeginDate, est.ksl_schfinanmovein) BETWEEN DATEFROMPARTS(@Year,1,1)
          AND CASE WHEN @Year = YEAR(GETDATE()) THEN GETDATE() ELSE DATEFROMPARTS(@Year,12,31) END
    GROUP BY c.ksl_securityregionteamid
),

newRS AS (
    SELECT COUNT(contactid) AS RSourceAvg, c.createdby AS ownerid
    FROM [KSLCLOUD_MSCRM].[dbo].[contact] c
    WHERE [ksl_contacttype] = '864960002'
      AND c.createdon BETWEEN DATEFROMPARTS(@Year,1,1)
          AND CASE WHEN @Year = YEAR(GETDATE()) THEN GETDATE() ELSE DATEFROMPARTS(@Year,12,31) END
    GROUP BY c.createdby
),

ResRef AS (
    SELECT COUNT(accountid)*1.0 AS RRAvg, [ksl_associtateduser], [ksl_associtatedusername]
    FROM [KSLCLOUD_MSCRM].[dbo].account c
    INNER JOIN [KSLCLOUD_MSCRM].[dbo].[ksl_referralorgs] r
      ON r.ksl_referralorgsid = c.ksl_referralorganization
    WHERE c.createdon BETWEEN DATEFROMPARTS(@Year,1,1)
          AND CASE WHEN @Year = YEAR(GETDATE()) THEN GETDATE() ELSE DATEFROMPARTS(@Year,12,31) END
      AND ksl_initialsource = '07E31289-00A3-E311-B839-0050568B7D16'  -- Resident Referral
    GROUP BY [ksl_associtateduser], [ksl_associtatedusername]
)

/* =========================
   Final selection
   ========================= */
SELECT
    u.USR_First + ' ' + u.USR_Last AS fullname,
    CASE
        WHEN r.Name LIKE 'Business Development Director'
          OR r.Name LIKE 'Buisness Developement Director'
          OR r.Name LIKE 'Director, Business Development'
          OR r.Name LIKE 'Director of Strategic Partnership%' THEN 'Business Development'
        WHEN r.Name LIKE 'Executive%' OR r.Name LIKE 'General Manager' THEN 'Executive Director'
        ELSE 'Sales'
    END AS Title,
    commCrm.ksl_regionidname,
    a.*,
    newLeadsavg,
    nrr.RentRev AS RentRevYTD,
    mi.MoveInavg,
    nr.RSourceAvg,
    RRAvg,
    commCrm.ksl_regionid
FROM actSUM a
INNER JOIN [KiscoCustom].[dbo].[Associate] u
  ON u.SalesAppID = a.AccountOwnerID
JOIN KiscoCustom.dbo.KSL_Roles r
  ON r.roleid = u.RoleID
JOIN KiscoCustom.dbo.Community AS c
  ON c.CommunityIDY = u.USR_CommunityIDY
JOIN KSLCLOUD_MSCRM_RESTORE_TEST.dbo.ksl_community AS commCrm
  ON commCrm.ksl_communityid = c.CRM_CommunityID
LEFT JOIN leads   l  ON commCrm.ksl_securityregionteamid = l.ksl_securityregionteamid
LEFT JOIN NRR     nrr ON nrr.ksl_securityregionteamid    = commCrm.ksl_securityregionteamid
LEFT JOIN MoveIns mi  ON mi.ksl_securityregionteamid     = commCrm.ksl_securityregionteamid
LEFT JOIN newRS   nr  ON nr.ownerid                      = u.SalesAppID
LEFT JOIN ResRef  rr  ON rr.[ksl_associtateduser]        = u.SalesAppID
WHERE appointment_BD + email_BD + phonecall_BD > 5
ORDER BY 2, 1;

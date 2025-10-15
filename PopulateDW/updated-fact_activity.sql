--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% INSERT INTO Fact_Activity %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--BEGIN TRY;THROW 50000,'',1;END TRY BEGIN CATCH;insert into Staging.dbo.log_DW_Time (LineNumber,MinSinceLast) values (ERROR_LINE(),DATEDIFF(mi,@DtLast,getdate()));END CATCH
--set @DtLast = getdate()
--exec [dbo].[Fill_Fact_Activity]
-- Insert statements for procedure here
--TRUNCATE TABLE Fact_Activity
--INSERT INTO Fact_Activity

-- TAKE 1 --
WITH A AS (  -- Completed activities + computed fields once
  SELECT
    PC.ownerid,
    PC.activityid,
    PC.subject,
    PC.activitytypecode,
    PC.regardingobjectid,
    PC.ksl_resultoptions_displayname AS rslt,
    LEFT(PC.description, 300)        AS notes,
    PC.[from],
    PC.scheduledend,
    CASE
      WHEN PC.description LIKE '%sm.chat%'
        OR (PC.description LIKE '%See your personal message here!%' AND PC.subject NOT LIKE 'Re: %')
      THEN 'Yes' ELSE 'No'
    END AS isSalesMail
  FROM KSLCLOUD_MSCRM_RESTORE_TEST.dbo.activities AS PC WITH (NOLOCK)
  WHERE PC.statuscode_displayname = 'Completed'
  AND PC.scheduledend >= DATEADD(DAY, -7, GETDATE())  -- last 7�24 hours
),
Acct AS (  -- Accounts
  SELECT
    a.accountid,
    a.ownerid,
    a.owneridname,
    a.ksl_communityid,
    a.ksl_communityidname
  FROM kslcloud_mscrm.dbo.account AS a WITH (NOLOCK)
),
Cnt AS (   -- Referral-source contacts only
  SELECT
    c.contactid,
    c.ownerid,
    c.ksl_communityid,
    c.ksl_communityidname
  FROM kslcloud_mscrm.dbo.contact AS c WITH (NOLOCK)
  WHERE c.ksl_contacttype = 864960002  -- referral source
)
SELECT
  ac.accountid                        AS accountid,
  CASE WHEN ct.contactid IS NOT NULL THEN ct.ownerid ELSE ac.ownerid END AS AccountOwnerID,
  CASE WHEN ct.contactid IS NOT NULL THEN A.[from]  ELSE ac.owneridname END AS AccountOwnerName,
  COALESCE(ac.ksl_communityid,      ct.ksl_communityid)        AS CommunityId,
  COALESCE(ac.ksl_communityidname,  ct.ksl_communityidname)    AS CommunityIdName,

  /* Activity details */
  A.subject                                                    AS ActivitySubject,
  CASE WHEN ct.contactid IS NOT NULL
       THEN A.activitytypecode + ' BD'
       ELSE A.activitytypecode
  END                                                          AS ActivityType,
  A.activitytypecode                                           AS ActivityTypeDetail,
  A.rslt,
  A.activityid,
  A.notes,
  CASE WHEN ct.contactid IS NOT NULL THEN 'Yes' ELSE 'No' END  AS isbd,
  A.isSalesMail,
  CAST(NULL AS varchar(50))                                    AS google_campaignID,  -- placeholder
  A.scheduledend                                               AS CompletedAt,
  Assoc.USR_First + ' ' + Assoc.USR_Last                       AS CreatedBy
FROM A
LEFT JOIN Acct AS ac ON A.regardingobjectid = ac.accountid
LEFT JOIN Cnt  AS ct ON A.regardingobjectid = ct.contactid
LEFT JOIN KiscoCustom.dbo.Associate Assoc ON A.ownerid = Assoc.SalesAppID
-- keep only rows that matched either Account or the referral Contact
WHERE (ac.accountid IS NOT NULL OR ct.contactid IS NOT NULL)
--AND COALESCE(ac.ksl_communityidname,ct.ksl_communityidname) = 'La Posada';



-- TAKE 2 --
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
        PC.ActivityTypeCode as ActivityTypeDetail,
        PC.scheduledstart as CompletedDate,
        PC.ksl_resultoptions_displayname as Rslt,
        PC.activityid,
        PC.description as notes,
        -- BD logic: BD activities are tied to accounts with status 'Referral Org'
        CASE WHEN A.statuscode_displayname = 'Referral Org' THEN 'Yes' ELSE 'No' END as isbd,
        -- SalesMail logic
        CASE WHEN PC.description LIKE '%sm.chat%' THEN 'Yes' ELSE 'No' END as isSalesMail,
        NULL as google_campaignID,
        PC.ownerid AS CreatedBy, 
        --Assoc.USR_First + ' ' + Assoc.USR_Last AS CreatedBy,
        'Account' as ActivitySource
    FROM KSLCLOUD_MSCRM_RESTORE_TEST.dbo.Account A WITH (NOLOCK)
    INNER JOIN KSLCLOUD_MSCRM_RESTORE_TEST.dbo.activities PC WITH (NOLOCK) 
        ON PC.RegardingObjectId = A.accountid
    LEFT JOIN KiscoCustom.dbo.Associate Assoc ON A.ownerid = Assoc.SalesAppID
    
    UNION ALL
    
    -- Contact-based activities - contacts roll up to accounts via primarycontactid
    SELECT
        A.accountid, -- Get the account ID that the contact belongs to
        A.OwnerID as AccountOwnerID,
        A.OwnerIDname as AccountOwnerName,
        A.ksl_CommunityId as CommunityId,
        A.ksl_CommunityIdName as CommunityIdName,
        PC.Subject as ActivitySubject,
        PC.ActivityTypeCode as ActivityType,
        PC.ActivityTypeCode as ActivityTypeDetail, -- This was a number like 864960000 but now phonecall etc.
        PC.scheduledstart as CompletedDate,
        PC.ksl_resultoptions_displayname as Rslt,
        PC.activityid,
        PC.description as notes,
        -- BD logic: Contact activities are BD if they belong to a Referral Org account
        CASE WHEN A.statuscode_displayname = 'Referral Org' THEN 'Yes' ELSE 'No' END as isbd, -- TODO or should this be C.ksl_contacttype_displayname = Referral Source	& ksl_contacttype = 864960002
        -- SalesMail logic
        CASE WHEN PC.description LIKE '%sm.chat%' THEN 'Yes' ELSE 'No' END as isSalesMail,
        NULL as google_campaignID,
        PC.ownerid AS CreatedBy, 
        --Assoc.USR_First + ' ' + Assoc.USR_Last
        'Contact' as ActivitySource
    FROM KSLCLOUD_MSCRM_RESTORE_TEST.dbo.Contact C WITH (NOLOCK)
    INNER JOIN KSLCLOUD_MSCRM_RESTORE_TEST.dbo.activities PC WITH (NOLOCK) 
        ON PC.RegardingObjectId = C.contactid
    LEFT JOIN KSLCLOUD_MSCRM_RESTORE_TEST.dbo.Account A 
        ON A.primarycontactid = C.contactid  -- Contacts roll up to accounts
    LEFT JOIN KiscoCustom.dbo.Associate Assoc ON A.ownerid = Assoc.SalesAppID
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
    isbd,
    isSalesMail,
    google_campaignID,
    createdby,
    ActivitySource
FROM AllActivities
--TEST: WHERE CommunityId = '3BC35920-B2DE-E211-9163-0050568B37AC' --Byron Park
-- TEST: AND CompletedDate >= DATEADD(month, -1, GETDATE())
ORDER BY CompletedDate DESC
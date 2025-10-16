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
USE [DataWarehouse] 
--go
 /****** Object:  View [dbo].[Vw_Activities]    Script Date: 10/9/2025 5:11:40 PM ******/ 
 --SET ansi_nulls ON
 --go
 --SET quoted_identifier ON
 --go
 --CREATE VIEW [dbo].[Vw_Activities]
--AS
WITH lastce AS
  (SELECT --Get Last Contact Activity Information
 b.subject AS ActivitySubject,
 b.activitytypecode AS LCEType, --b.activitytypedetail AS LCETypeDetail,
 b.regardingobjectid,
 b.completeddate AS LastCEDate,
 b.notes AS LCENotes,
 b.activityid
   FROM
     (SELECT pc.activityid,
             PC.subject,
             PC.activitytypecode, --PC.ksl_appointmenttype    AS ActivityTypeDetail,
 PC.regardingobjectid,
 PC.scheduledstart AS CompletedDate,
 LEFT(PC.description, 300) AS notes
      FROM KSLCLOUD_MSCRM_RESTORE_TEST.dbo.activities PC WITH (nolock)
      WHERE PC.statuscode_displayname = 'Completed'
        AND (PC.activitytypecode LIKE '%face appointment%'
             OR PC.activitytypecode LIKE '%walk-in%') --AND PC.ksl_appointmenttype IN ( 864960001, 864960002 )
 --AND PC.ksl_resultoptions IN ( '864960005', '864960004',
 --'864960006' )
--Result: 864960005:Completed  864960004:Community Experience  864960006: Virtual Experience
) AS b)
SELECT X.* --,case when ROW_NUMBER() over (partition by accountid order by completeddate) = 1 then 1 else 0 end as lead  -- js 5/18
 --,ROW_NUMBER() over (partition by accountid order by completeddate) row
 ,
       CASE
           WHEN activitytype LIKE '%phone%'
                AND rslt = 'Completed' THEN 1
           ELSE 0
       END AS Completed_Phone_Calls,
       CASE
           WHEN activitytype IN ('phonecall',
                                 'Incoming Phone Call')
                AND rslt = 'Completed' THEN 1
           ELSE 0
       END AS Completed_Incoming_Phone_Calls,
       CASE
           WHEN (activitytype LIKE '%email%'
                 OR activitytype LIKE '%letter%') THEN 1
           ELSE 0
       END AS Sent_Messages,
       CASE
           WHEN (activitytype LIKE '%face appointment%'
                 OR activitytype LIKE '%walk-in%') THEN 1
           ELSE 0
       END AS Appointment,
       CASE
           WHEN activitytype = 'Outbound Text Message'
                AND ksl_textssent > 0 THEN ksl_textssent
           ELSE 0
       END AS TextSent_Biz_Dev,
       CASE
           WHEN activitytype = 'Inbound Text Message'
                AND ksl_textsreceived > 0 THEN ksl_textsreceived
           ELSE 0
       END AS TextReceived_Biz_Dev,
       CASE
           WHEN activitytype LIKE '%phone%'
                AND rslt <> 'BDCI - Bad Contact Information'
                AND rslt <> 'CANC - Cancelled'
                AND rslt <> 'COMP - Completed' THEN 1
           ELSE 0
       END AS Phone_Call_Attempted,
       CASE
           WHEN activitytype = 'ksl_sms'
                AND ksl_textssent > 0 THEN ksl_textssent
           ELSE 0
       END AS TextSent,
       CASE
           WHEN activitytype = 'ksl_sms'
                AND ksl_textsreceived > 0 THEN ksl_textsreceived
           ELSE 0
       END AS TextReceived
FROM
  (SELECT a.accountid, --a.[ksl_initialinquirydate], -- js 5/18
 a.ownerid AccountOwnerID,
 a.owneridname AccountOwnerName,
 b.ownerid ActivityOwnerID,
 b.[from] ActivityOwnerName,
 a.ksl_communityid AS CommunityId,
 a.ksl_communityidname AS CommunityIdName, --Get Last Attempt Information
 b.subject AS ActivitySubject,
 b.activitytypecode AS ActivityType,
 b.statuscode_displayname AS ActivityTypeDetail, --activitytypedetail
  rslt,
  activityid,
  notes,
  ksl_textssent,
  ksl_textsreceived
   FROM
     (--select * from kslcloud_mscrm.dbo.PhoneCall
 SELECT activityid,
        ksl_resultoptions_displayname AS Rslt,
        L.accountid,
        PC.subject,
        PC.activitytypecode, --PC.ksl_phonecalltype          AS ActivityTypeDetail,
 PC.regardingobjectid, --PC.ksl_datecompleted          AS CompletedDate,
 pc.description AS notes,
 pc.[from], --owneridname
 pc.ownerid,
 NULL AS ksl_textssent,
 NULL AS ksl_textsreceived,
 pc.statuscode_displayname
      FROM kslcloud_mscrm.dbo.account L WITH (nolock)
      INNER JOIN KSLCLOUD_MSCRM_RESTORE_TEST.dbo.activities PC WITH (nolock) ON PC.regardingobjectid = L.accountid
      WHERE PC.statuscode_displayname = 'Completed') AS b
   INNER JOIN kslcloud_mscrm.dbo.account a ON b.accountid = a.accountid
   UNION ALL SELECT a.contactid, --null as [ksl_initialinquirydate], -- js 5/18
 --DW 9.25.23 changed these to b from a, the next 2 lines
 b.ownerid AccountOwnerID,
 b.[from] AccountOwnerName, --owneridname
 b.ownerid ActivityOwnerID,
 b.[from] ActivityOwnerName, --owneridname
 a.ksl_communityid AS CommunityId,
 a.ksl_communityidname AS CommunityIdName, --Get Last Attempt Information
 b.subject AS ActivitySubject,
 b.activitytypecode + ' BD' AS ActivityType, --b.activitytypedetail                      AS ActivityTypeDetail,
 rslt,
 activityid,
 notes,
 ksl_textssent,
 ksl_textsreceived
   FROM
     (SELECT activityid,
             ksl_resultoptions_displayname AS Rslt,
             ownerid,
             [from], --owneridname,
 PC.subject,
 PC.activitytypecode, --PC.ksl_phonecalltype          AS ActivityTypeDetail,
 PC.regardingobjectid, --PC.ksl_datecompleted          AS CompletedDate,
 pc.description AS notes,
 NULL AS ksl_textssent,
 NULL AS ksl_textsreceived
      FROM KSLCLOUD_MSCRM_RESTORE_TEST.dbo.activities PC WITH (nolock)
      WHERE PC.statuscode_displayname = 'Completed') AS b
   INNER JOIN kslcloud_mscrm.dbo.contact a ON b.regardingobjectid = a.contactid) AS x OUTER apply
  (SELECT TOP 1 *
   FROM lastce
   WHERE X.accountid = lastce.regardingobjectid
     ORDER  BY lastce.lastcedate ASC) FCE GO
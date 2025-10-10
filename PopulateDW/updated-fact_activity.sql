--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% INSERT INTO Fact_Activity %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--BEGIN TRY;THROW 50000,'',1;END TRY BEGIN CATCH;insert into Staging.dbo.log_DW_Time (LineNumber,MinSinceLast) values (ERROR_LINE(),DATEDIFF(mi,@DtLast,getdate()));END CATCH
--set @DtLast = getdate()
--exec [dbo].[Fill_Fact_Activity]
-- Insert statements for procedure here
--TRUNCATE TABLE Fact_Activity
--INSERT INTO Fact_Activity

SELECT a.accountid,
       a.ownerid                      AccountOwnerID,
       a.owneridname                  AccountOwnerName,
       a.ksl_communityid              AS CommunityId,
       a.ksl_communityidname          AS CommunityIdName,
       --Get Last Attempt Information
       b.subject                      AS ActivitySubject,
       b.activitytypecode             AS ActivityType,
       b.activitytypedetail           AS ActivityTypeDetail,
       --CONVERT(DATE, b.completeddate) CompletedDate,
       rslt,
       activityid,
       NULL                           [notes],
       'No'                           isbd,
       CASE
         WHEN [activityid] IN (SELECT [activityid]
                               FROM   KSLCLOUD_MSCRM_RESTORE_TEST.dbo.activities
                               WHERE  description LIKE '%sm.chat%')
               OR [activityid] IN (SELECT [activityid]
                                   FROM   KSLCLOUD_MSCRM_RESTORE_TEST.dbo.activities
                                   WHERE
                  description LIKE '%See your personal message here!%'
                  AND subject NOT LIKE 'Re: %') THEN 'Yes'
         ELSE 'No'
       END                            isSalesMail,
       NULL                           google_campaignID,
       b.[from]
FROM   (
       SELECT activityid,
              ksl_resultoptions_displayname AS Rslt,
              L.accountid,
              PC.subject,
              PC.activitytypecode,
              PC.activitytypecode          AS ActivityTypeDetail,
              PC.regardingobjectid,
              --PC.ksl_datecompleted          AS CompletedDate,
              LEFT(PC.description, 300)     AS notes,
              PC.[from] --pc.createdby
       FROM   kslcloud_mscrm.dbo.account L WITH (nolock)
              INNER JOIN kslcloud_mscrm_restore_test.dbo.activities PC WITH (nolock)
                      ON PC.regardingobjectid = L.accountid
       WHERE  PC.statuscode_displayname = 'Completed'
       ) AS b
       INNER JOIN kslcloud_mscrm.dbo.account a WITH (nolock)
               ON b.accountid = a.accountid
UNION ALL
SELECT a.contactid,
       b.ownerid                      AccountOwnerID,
       b.[from]                  AccountOwnerName,
       a.ksl_communityid              AS CommunityId,
       a.ksl_communityidname          AS CommunityIdName,
       --Get Last Attempt Information
       b.subject                      AS ActivitySubject,
       b.activitytypecode + ' BD'     AS ActivityType,
       b.activitytypedetail           AS ActivityTypeDetail,
       --CONVERT(DATE, b.completeddate) CompletedDate,
       rslt,
       activityid,
       NULL,
       'Yes' --  CASE WHEN ksl_contacttype = 864960002 THEN 'Yes' Else 'No' END
       ,
       CASE
         WHEN [activityid] IN (SELECT [activityid]
                               FROM   KSLCLOUD_MSCRM_RESTORE_TEST.dbo.activities
                               WHERE  description LIKE '%sm.chat%')
               OR [activityid] IN (SELECT [activityid]
                                   FROM   KSLCLOUD_MSCRM_RESTORE_TEST.dbo.activities
                                   WHERE
                  description LIKE '%See your personal message here!%'
                  AND subject NOT LIKE 'Re: %') THEN 'Yes'
         ELSE 'No'
       END                            isSalesMail,
       NULL                           google_campaignID,
       b.[from]
FROM   (SELECT activityid,
               ksl_resultoptions_displayname AS Rslt,
               ownerid,
               PC.subject,
               PC.activitytypecode,
               PC.activitytypecode          AS ActivityTypeDetail,
               PC.regardingobjectid,
               --PC.ksl_datecompleted          AS CompletedDate,
               LEFT(PC.description, 300)     AS notes,
               pc.[from]
        FROM   KSLCLOUD_MSCRM_RESTORE_TEST.dbo.activities PC WITH (nolock)
        WHERE  PC.statuscode_displayname = 'Completed' --Workflow changed to completed
        ) AS b
       INNER JOIN (SELECT *
                   FROM   kslcloud_mscrm.dbo.contact WITH (nolock)
                   WHERE  ksl_contacttype = 864960002 --ref Source
                  ) a
               ON b.regardingobjectid = a.contactid

--- Lead Texts
-- ALL SEPERATE TEXT TALLY INSERTS GONE AS MOVED TO ONE ROW MODEL, ex. no ksl_textssent count

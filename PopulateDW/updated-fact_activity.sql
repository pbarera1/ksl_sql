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
        NULL as ActivityTypeDetail,
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
        PC.ownerid AS activityCreatedBy,
        --Assoc.USR_First + ' ' + Assoc.USR_Last AS CreatedBy,
    FROM KSLCLOUD_MSCRM_RESTORE_TEST.dbo.Account A WITH (NOLOCK)
    INNER JOIN KSLCLOUD_MSCRM_RESTORE_TEST.dbo.activities PC WITH (NOLOCK) 
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
-- DEBUG: WHERE CommunityId = '3BC35920-B2DE-E211-9163-0050568B37AC' --Byron Park
-- DEBUG: AND CompletedDate >= DATEADD(month, -1, GETDATE()) -- Last Month
-- DEBUG: ORDER BY CompletedDate DESC
ORDER BY accountid, activityid, 1
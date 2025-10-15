--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% INSERT INTO Fact_Activity %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--BEGIN TRY;THROW 50000,'',1;END TRY BEGIN CATCH;insert into Staging.dbo.log_DW_Time (LineNumber,MinSinceLast) values (ERROR_LINE(),DATEDIFF(mi,@DtLast,getdate()));END CATCH
--set @DtLast = getdate()
--exec [dbo].[Fill_Fact_Activity]
-- Insert statements for procedure here
--TRUNCATE TABLE Fact_Activity
--INSERT INTO Fact_Activity
SELECT a.accountid
	,a.ownerid AccountOwnerID
	,a.owneridname AccountOwnerName
	,a.ksl_communityid AS CommunityId
	,a.ksl_communityidname AS CommunityIdName
	,
	--Get Last Attempt Information
	b.subject AS ActivitySubject
	,b.activitytypecode AS ActivityType
	,b.activitytypedetail AS ActivityTypeDetail
	,
	--CONVERT(DATE, b.completeddate) CompletedDate,
	rslt
	,activityid
	,NULL [notes]
	,'No' isbd
	,CASE 
		WHEN [activityid] IN (
				SELECT [activityid]
				FROM KSLCLOUD_MSCRM_RESTORE_TEST.dbo.activities
				WHERE description LIKE '%sm.chat%'
				)
			OR [activityid] IN (
				SELECT [activityid]
				FROM KSLCLOUD_MSCRM_RESTORE_TEST.dbo.activities
				WHERE description LIKE '%See your personal message here!%'
					AND subject NOT LIKE 'Re: %'
				)
			THEN 'Yes'
		ELSE 'No'
		END isSalesMail
	,NULL google_campaignID
	,b.[from]
FROM (
	SELECT activityid
		,ksl_resultoptions_displayname AS Rslt
		,L.accountid
		,PC.subject
		,PC.activitytypecode
		,PC.activitytypecode AS ActivityTypeDetail
		,PC.regardingobjectid
		,
		--PC.ksl_datecompleted          AS CompletedDate,
		LEFT(PC.description, 300) AS notes
		,PC.[from] --pc.createdby
	FROM kslcloud_mscrm.dbo.account L WITH (NOLOCK)
	INNER JOIN kslcloud_mscrm_restore_test.dbo.activities PC WITH (NOLOCK) ON PC.regardingobjectid = L.accountid
	WHERE PC.statuscode_displayname = 'Completed'
	) AS b
INNER JOIN kslcloud_mscrm.dbo.account a WITH (NOLOCK) ON b.accountid = a.accountid

UNION ALL

SELECT a.contactid
	,b.ownerid AccountOwnerID
	,b.[from] AccountOwnerName
	,a.ksl_communityid AS CommunityId
	,a.ksl_communityidname AS CommunityIdName
	,
	--Get Last Attempt Information
	b.subject AS ActivitySubject
	,b.activitytypecode + ' BD' AS ActivityType
	,b.activitytypedetail AS ActivityTypeDetail
	,
	--CONVERT(DATE, b.completeddate) CompletedDate,
	rslt
	,activityid
	,NULL
	,'Yes' --  CASE WHEN ksl_contacttype = 864960002 THEN 'Yes' Else 'No' END
	,CASE 
		WHEN [activityid] IN (
				SELECT [activityid]
				FROM KSLCLOUD_MSCRM_RESTORE_TEST.dbo.activities
				WHERE description LIKE '%sm.chat%'
				)
			OR [activityid] IN (
				SELECT [activityid]
				FROM KSLCLOUD_MSCRM_RESTORE_TEST.dbo.activities
				WHERE description LIKE '%See your personal message here!%'
					AND subject NOT LIKE 'Re: %'
				)
			THEN 'Yes'
		ELSE 'No'
		END isSalesMail
	,NULL google_campaignID
	,b.[from]
FROM (
	SELECT activityid
		,ksl_resultoptions_displayname AS Rslt
		,ownerid
		,PC.subject
		,PC.activitytypecode
		,PC.activitytypecode AS ActivityTypeDetail
		,PC.regardingobjectid
		,
		--PC.ksl_datecompleted          AS CompletedDate,
		LEFT(PC.description, 300) AS notes
		,pc.[from]
	FROM KSLCLOUD_MSCRM_RESTORE_TEST.dbo.activities PC WITH (NOLOCK)
	WHERE PC.statuscode_displayname = 'Completed' --Workflow changed to completed
	) AS b
INNER JOIN (
	SELECT *
	FROM kslcloud_mscrm.dbo.contact WITH (NOLOCK)
	WHERE ksl_contacttype = 864960002 --ref Source
	) a ON b.regardingobjectid = a.contactid
	--- Lead Texts
	-- ALL SEPERATE TEXT TALLY INSERTS GONE AS MOVED TO ONE ROW MODEL, ex. no ksl_textssent count



-- TRY AGAIN --
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
  COALESCE(ac.accountid, ct.contactid)                         AS EntityId,
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
AND COALESCE(ac.ksl_communityidname,ct.ksl_communityidname) = 'La Posada';
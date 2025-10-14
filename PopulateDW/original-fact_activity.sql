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
	,a.OwnerId AccountOwnerID
	,a.OwnerIdName AccountOwnerName
	,a.ksl_CommunityId AS CommunityId
	,a.ksl_CommunityIdName AS CommunityIdName
	,
	--Get Last Attempt Information
	b.Subject AS ActivitySubject
	,b.ActivityTypeCode AS ActivityType
	,b.ActivityTypeDetail AS ActivityTypeDetail
	,convert(DATE, b.CompletedDate) CompletedDate
	,Rslt
	,activityid
	,NULL [notes]
	,'No' isbd
	,CASE 
		WHEN [activityid] IN (
				SELECT [activityid]
				FROM kslcloud_mscrm.dbo.ksl_sms
				WHERE description LIKE '%sm.chat%'
				)
			OR [activityid] IN (
				SELECT [activityid]
				FROM kslcloud_mscrm.dbo.email
				WHERE description LIKE '%See your personal message here!%'
					AND subject NOT LIKE 'Re: %'
				)
			THEN 'Yes'
		ELSE 'No'
		END isSalesMail
	,NULL google_campaignID
	,b.createdby
FROM (
	--select * from kslcloud_mscrm.dbo.PhoneCall
	SELECT activityid
		,ksl_resultoptions_displayname AS Rslt
		,L.accountid
		,PC.Subject
		,PC.ActivityTypeCode
		,PC.ksl_phonecalltype AS ActivityTypeDetail
		,PC.regardingobjectid
		,PC.ksl_datecompleted AS CompletedDate
		,left(PC.description, 300) AS notes
		,pc.createdby
	FROM kslcloud_mscrm.dbo.Account L WITH (NOLOCK)
	INNER JOIN kslcloud_mscrm.dbo.PhoneCall PC WITH (NOLOCK) ON PC.RegardingObjectId = L.accountid
	WHERE PC.statecode_displayname = 'Completed' --Workflow changed call to completed
		AND PC.ksl_resultoptions <> '864960008' --Result: Anything but cancelled
	
	UNION ALL
	
	SELECT activityid
		,ksl_resultoptions_displayname AS Rslt
		,L.accountid
		,PC.Subject
		,PC.ActivityTypeCode
		,PC.ksl_appointmenttype AS ActivityTypeDetail
		,PC.regardingobjectid
		,PC.scheduledstart AS CompletedDate
		,left(PC.description, 300) AS notes
		,pc.createdby
	FROM kslcloud_mscrm.dbo.Account L WITH (NOLOCK)
	INNER JOIN kslcloud_mscrm.dbo.appointment PC WITH (NOLOCK) ON PC.RegardingObjectId = L.accountid
	WHERE PC.statecode_displayname = 'Completed'
		AND PC.ksl_resultoptions <> '100000000' --Result: 100000000:Cancelled 
	
	UNION ALL
	
	SELECT activityid
		,ksl_emailtype_displayname AS Rslt
		,L.accountid
		,PC.Subject
		,PC.ActivityTypeCode
		,PC.ksl_emailtype AS ActivityTypeDetail
		,PC.regardingobjectid
		,PC.actualend AS CompletedDate
		,left(PC.description, 300) AS notes
		,pc.createdby
	FROM kslcloud_mscrm.dbo.Account L WITH (NOLOCK)
	INNER JOIN kslcloud_mscrm.dbo.email PC WITH (NOLOCK) ON PC.RegardingObjectId = L.accountid
	WHERE PC.statecode_displayname = 'Completed'
	
	UNION ALL
	
	SELECT activityid
		,ksl_lettertype_displayname AS Rslt
		,L.accountid
		,PC.Subject
		,PC.ActivityTypeCode
		,PC.ksl_lettertype AS ActivityTypeDetail
		,PC.regardingobjectid
		,PC.actualend AS CompletedDate
		,left(PC.description, 300) AS notes
		,pc.createdby
	FROM kslcloud_mscrm.dbo.Account L WITH (NOLOCK)
	INNER JOIN kslcloud_mscrm.dbo.letter PC WITH (NOLOCK) ON PC.RegardingObjectId = L.accountid
	WHERE PC.statecode_displayname = 'Completed'
	
	UNION ALL
	
	SELECT activityid
		,pc.statuscode_displayname AS Rslt
		,L.accountid
		,PC.Subject
		,PC.ActivityTypeCode
		,PC.ksl_tasktype AS ActivityTypeDetail
		,PC.regardingobjectid
		,PC.actualend AS CompletedDate
		,left(PC.description, 300) AS notes
		,pc.createdby
	FROM kslcloud_mscrm.dbo.Account L WITH (NOLOCK)
	INNER JOIN kslcloud_mscrm.dbo.task PC WITH (NOLOCK) ON PC.RegardingObjectId = L.accountid
	WHERE PC.statecode_displayname = 'Completed'
		--Union All
		--SELECT L.accountid, RIGHT(PC.Subject, LEN(PC.Subject) - 13) as [Subject], 'sms' as ActivityTypeCode, NULL as ActivityTypeDetail, PC.regardingobjectid, PC.actualend as CompletedDate, left(PC.description,300) as notes
		--FROM Account L WITH (NOLOCK)
		--INNER JOIN txtsync_sms PC ON PC.RegardingObjectId = L.accountid
	) AS b
INNER JOIN kslcloud_mscrm.dbo.account a WITH (NOLOCK) ON b.accountid = a.accountid

UNION ALL

SELECT a.contactid
	,b.ownerid AccountOwnerID
	,b.owneridname AccountOwnerName
	,a.ksl_CommunityId AS CommunityId
	,a.ksl_CommunityIdName AS CommunityIdName
	,
	--Get Last Attempt Information
	b.Subject AS ActivitySubject
	,b.ActivityTypeCode + ' BD' AS ActivityType
	,b.ActivityTypeDetail AS ActivityTypeDetail
	,convert(DATE, b.CompletedDate) CompletedDate
	,Rslt
	,activityid
	,NULL
	,'Yes' --  CASE WHEN ksl_contacttype = 864960002 THEN 'Yes' Else 'No' END
	,CASE 
		WHEN [activityid] IN (
				SELECT [activityid]
				FROM kslcloud_mscrm.dbo.ksl_sms
				WHERE description LIKE '%sm.chat%'
				)
			OR [activityid] IN (
				SELECT [activityid]
				FROM kslcloud_mscrm.dbo.email
				WHERE description LIKE '%See your personal message here!%'
					AND subject NOT LIKE 'Re: %'
				)
			THEN 'Yes'
		ELSE 'No'
		END isSalesMail
	,NULL google_campaignID
	,b.createdby
FROM (
	SELECT activityid
		,ksl_resultoptions_displayname AS Rslt
		,ownerid
		,owneridname
		,PC.Subject
		,PC.ActivityTypeCode
		,PC.ksl_phonecalltype AS ActivityTypeDetail
		,PC.regardingobjectid
		,PC.ksl_datecompleted AS CompletedDate
		,left(PC.description, 300) AS notes
		,pc.createdby
	FROM kslcloud_mscrm.dbo.PhoneCall PC WITH (NOLOCK)
	WHERE PC.statecode_displayname = 'Completed' --Workflow changed call to completed
		AND PC.ksl_resultoptions <> '864960008' --Result: Anything but cancelled
	
	UNION ALL
	
	SELECT activityid
		,ksl_resultoptions_displayname AS Rslt
		,ownerid
		,owneridname
		,PC.Subject
		,PC.ActivityTypeCode
		,PC.ksl_appointmenttype AS ActivityTypeDetail
		,PC.regardingobjectid
		,PC.scheduledstart AS CompletedDate
		,left(PC.description, 300) AS notes
		,pc.createdby
	FROM kslcloud_mscrm.dbo.appointment PC WITH (NOLOCK)
	WHERE PC.statecode_displayname = 'Completed'
		AND PC.ksl_resultoptions <> '100000000' --Result: 100000000:Cancelled 
	
	UNION ALL
	
	SELECT activityid
		,ksl_emailtype_displayname AS Rslt
		,ownerid
		,owneridname
		,PC.Subject
		,PC.ActivityTypeCode
		,PC.ksl_emailtype AS ActivityTypeDetail
		,PC.regardingobjectid
		,PC.actualend AS CompletedDate
		,left(PC.description, 300) AS notes
		,pc.createdby
	FROM kslcloud_mscrm.dbo.email PC WITH (NOLOCK)
	WHERE PC.statecode_displayname = 'Completed'
	
	UNION ALL
	
	SELECT activityid
		,ksl_lettertype_displayname AS Rslt
		,ownerid
		,owneridname
		,PC.Subject
		,PC.ActivityTypeCode
		,PC.ksl_lettertype AS ActivityTypeDetail
		,PC.regardingobjectid
		,PC.actualend AS CompletedDate
		,left(PC.description, 300) AS notes
		,pc.createdby
	FROM kslcloud_mscrm.dbo.letter PC WITH (NOLOCK)
	WHERE PC.statecode_displayname = 'Completed'
		--Union All
		--SELECT L.accountid, RIGHT(PC.Subject, LEN(PC.Subject) - 13) as [Subject], 'sms' as ActivityTypeCode, NULL as ActivityTypeDetail, PC.regardingobjectid, PC.actualend as CompletedDate, left(PC.description,300) as notes
		--FROM Account L WITH (NOLOCK)
		--INNER JOIN txtsync_sms PC ON PC.RegardingObjectId = L.accountid
	) AS b
INNER JOIN (
	SELECT *
	FROM kslcloud_mscrm.dbo.contact WITH (NOLOCK)
	WHERE ksl_contacttype = 864960002 --ref Source
	) a ON b.RegardingObjectId = a.contactid

-- Numbers table to create row for each text
IF object_id('tempdb..#Numbers') IS NOT NULL
	DROP TABLE #Numbers

CREATE TABLE #Numbers (NumberValue INT)

INSERT INTO #Numbers
-- TOP value should be changed so it is greater than the
-- maximum number of potential appointment slots any location can have
SELECT TOP 500 ROW_NUMBER() OVER (
		ORDER BY object_id
		)
FROM sys.objects

--- Lead Texts
INSERT INTO Fact_Activity
SELECT --NumberValue AS ReceivedMessage,[ksl_textssent],[ksl_textsreceived],
	a.accountid
	,a.OwnerId AccountOwnerID
	,a.OwnerIdName AccountOwnerName
	,a.ksl_CommunityId AS CommunityId
	,a.ksl_CommunityIdName AS CommunityIdName
	,
	--Get Last Attempt Information
	b.Subject AS ActivitySubject
	,b.ActivityTypeCode AS ActivityType
	,1002 AS ActivityTypeDetail
	,convert(DATE, b.actualend) CompletedDate
	,'Text Sent' AS Rslt
	,activityid
	,NULL
	,'No'
	,CASE 
		WHEN b.description LIKE '%sm.chat%'
			THEN 'Yes'
		ELSE 'No'
		END isSalesMail
	,NULL google_campaignID
	,b.createdby
FROM [KSLCLOUD_MSCRM].[dbo].[ksl_sms] b
INNER JOIN kslcloud_mscrm.dbo.account a WITH (NOLOCK) ON b.regardingobjectid = a.accountid
INNER JOIN #Numbers ON [ksl_textssent] >= NumberValue
ORDER BY regardingobjectid
	,activityid
	,1

INSERT INTO Fact_Activity
SELECT --NumberValue AS ReceivedMessage,[ksl_textssent],[ksl_textsreceived],
	a.accountid
	,a.OwnerId AccountOwnerID
	,a.OwnerIdName AccountOwnerName
	,a.ksl_CommunityId AS CommunityId
	,a.ksl_CommunityIdName AS CommunityIdName
	,
	--Get Last Attempt Information
	b.Subject AS ActivitySubject
	,b.ActivityTypeCode AS ActivityType
	,1001 AS ActivityTypeDetail
	,convert(DATE, b.actualend) CompletedDate
	,'Text Received' AS Rslt
	,activityid
	,NULL
	,'No'
	,CASE 
		WHEN b.description LIKE '%sm.chat%'
			THEN 'Yes'
		ELSE 'No'
		END isSalesMail
	,NULL google_campaignID
	,b.createdby
FROM [KSLCLOUD_MSCRM].[dbo].[ksl_sms] b
INNER JOIN kslcloud_mscrm.dbo.account a WITH (NOLOCK) ON b.regardingobjectid = a.accountid
INNER JOIN #Numbers ON ksl_textsreceived >= NumberValue
ORDER BY regardingobjectid
	,activityid
	,1

--- BD Texts
INSERT INTO Fact_Activity
SELECT --NumberValue AS ReceivedMessage,[ksl_textssent],[ksl_textsreceived],
	a.accountid
	,a.OwnerId AccountOwnerID
	,a.OwnerIdName AccountOwnerName
	,a.ksl_CommunityId AS CommunityId
	,a.ksl_CommunityIdName AS CommunityIdName
	,
	--Get Last Attempt Information
	b.Subject AS ActivitySubject
	,b.ActivityTypeCode AS ActivityType
	,1002 AS ActivityTypeDetail
	,convert(DATE, b.actualend) CompletedDate
	,'Text Sent' AS Rslt
	,activityid
	,NULL
	,'Yes'
	,CASE 
		WHEN b.description LIKE '%sm.chat%'
			THEN 'Yes'
		ELSE 'No'
		END isSalesMail
	,NULL google_campaignID
	,b.createdby
FROM [KSLCLOUD_MSCRM].[dbo].[ksl_sms] b
INNER JOIN (
	SELECT *
	FROM kslcloud_mscrm.dbo.contact WITH (NOLOCK)
	WHERE ksl_contacttype = 864960002 --ref Source
	) a ON b.RegardingObjectId = a.contactid
INNER JOIN #Numbers ON [ksl_textssent] >= NumberValue
ORDER BY regardingobjectid
	,activityid
	,1

INSERT INTO Fact_Activity
SELECT --NumberValue AS ReceivedMessage,[ksl_textssent],[ksl_textsreceived],
	a.accountid
	,a.OwnerId AccountOwnerID
	,a.OwnerIdName AccountOwnerName
	,a.ksl_CommunityId AS CommunityId
	,a.ksl_CommunityIdName AS CommunityIdName
	,
	--Get Last Attempt Information
	b.Subject AS ActivitySubject
	,b.ActivityTypeCode AS ActivityType
	,1001 AS ActivityTypeDetail
	,convert(DATE, b.actualend) CompletedDate
	,'Text Received' AS Rslt
	,activityid
	,NULL
	,'Yes'
	,CASE 
		WHEN b.description LIKE '%sm.chat%'
			THEN 'Yes'
		ELSE 'No'
		END isSalesMail
	,NULL google_campaignID
	,b.createdby
FROM [KSLCLOUD_MSCRM].[dbo].[ksl_sms] b
INNER JOIN (
	SELECT *
	FROM kslcloud_mscrm.dbo.contact WITH (NOLOCK)
	WHERE ksl_contacttype = 864960002 --ref Source
	) a ON b.RegardingObjectId = a.contactid
INNER JOIN #Numbers ON ksl_textsreceived >= NumberValue
ORDER BY regardingobjectid
	,activityid
	,1

--Add google campagin id from [GAds_CampaignIDs]  --> this is populated with APIGoogleAds.php script
UPDATE a
SET google_campaignID = g.gCampaignID
FROM [DataWarehouse].[dbo].[Fact_Activity] a
JOIN staging.[dbo].[GAds_CampaignIDs] g ON g.accountid = a.[accountid]
WHERE google_campaignID IS NULL
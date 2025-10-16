-- USE [DataWarehouse]
-- GO
-- /****** Object:  View [dbo].[Vw_Activities]    Script Date: 10/13/2025 9:05:38 AM ******/
-- SET ANSI_NULLS ON
-- GO
-- SET QUOTED_IDENTIFIER ON
-- GO
-- CREATE VIEW [dbo].[Vw_Activities]
-- AS
WITH LastCE
AS (
	SELECT
		--Get Last Contact Activity Information
		b.Subject AS ActivitySubject
		,b.ActivityTypeCode AS LCEType
		,b.ActivityTypeDetail AS LCETypeDetail
		,b.regardingobjectid
		,b.CompletedDate AS LastCEDate
		,b.notes AS LCENotes
		,b.activityid
	FROM (
		SELECT pc.activityid
			,PC.Subject
			,PC.ActivityTypeCode
			,PC.ksl_appointmenttype AS ActivityTypeDetail
			,PC.regardingobjectid
			,PC.scheduledstart AS CompletedDate
			,left(PC.description, 300) AS notes
		FROM [KSLCLOUD_MSCRM].dbo.appointment PC WITH (NOLOCK)
		WHERE PC.statecode_displayname = 'Completed'
			AND PC.ksl_appointmenttype IN (
				864960001
				,864960002
				)
			AND PC.ksl_resultoptions IN (
				'864960005'
				,'864960004'
				,'864960006'
				) --Result: 864960005:Completed  864960004:Community Experience  864960006: Virtual Experience
		) AS b
	)
SELECT X.*
	--,case when ROW_NUMBER() over (partition by accountid order by completeddate) = 1 then 1 else 0 end as lead  -- js 5/18
	--,ROW_NUMBER() over (partition by accountid order by completeddate) row
	,CASE 
		WHEN (
				ActivityType = 'phonecall'
				OR (
					ActivityTypeDetail = 864960000
					AND ActivityType = 'appointment'
					) /*Phone Appointment*/
				)
			AND Rslt = 'COMP - Completed'
			AND ActivityTypeDetail <> 864960000 /*incoming call*/
			THEN 1
		ELSE 0
		END AS Completed_Phone_Calls
	,CASE 
		WHEN ActivityType = 'phonecall'
			AND Rslt = 'COMP - Completed'
			AND ActivityTypeDetail = 864960000 /*incoming call*/
			THEN 1
		ELSE 0
		END AS Completed_Incoming_Phone_Calls
	,CASE 
		WHEN (
				ActivityType = 'email'
				AND ActivityTypeDetail IN (864960002) --Outgoing Email
				)
			OR (
				ActivityType = 'letter'
				AND ActivityTypeDetail IN (864960000) --Personal Letter
				)
			THEN 1
		ELSE 0
		END AS Sent_Messages
	,CASE 
		WHEN ActivityType = 'Appointment'
			AND Rslt = 'COMP - Completed'
			AND ActivityTypeDetail <> 864960000 --Phone Appointment
			AND CAST(CompletedDate AS DATE) <> CAST(LastCEDate AS DATE)
			THEN 1
		ELSE 0
		END AS Appointment
	,CASE 
		WHEN ActivityType = 'email BD'
			AND ActivityTypeDetail = 864960002 --incoming email
			THEN 1
		ELSE 0
		END AS Sent_Messages_Biz_Dev
	,CASE 
		WHEN ActivityType = 'ksl_sms BD'
			AND ksl_textssent > 0
			THEN ksl_textssent
		ELSE 0
		END AS TextSent_Biz_Dev
	,CASE 
		WHEN ActivityType = 'ksl_sms BD'
			AND ksl_textsreceived > 0
			THEN ksl_textsreceived
		ELSE 0
		END AS TextReceived_Biz_Dev
	,CASE 
		WHEN ActivityType = 'phonecall BD'
			AND Rslt = 'COMP - Completed'
			THEN 1
		ELSE 0
		END AS Completed_Phone_Calls_Biz_Dev
	,CASE 
		WHEN ActivityType = 'Appointment BD'
			AND (
				Rslt = 'COMP - Completed'
				OR Rslt = 'CEXP - Community Experience Given'
				)
			THEN 1
		ELSE 0
		END AS Appointment_Biz_Dev
	,CASE 
		WHEN ActivityType = 'Appointment'
			AND (
				Rslt = 'CEXP - Community Experience Given'
				OR (
					ActivityTypeDetail IN (
						864960001 -- face appointment
						,864960002 -- unscheduled walk-in
						)
					AND Rslt = 'COMP - Completed'
					)
				)
			AND CAST(CompletedDate AS DATE) = CAST(LastCEDate AS DATE)
			THEN 1
		ELSE 0
		END AS Community_Experience
	,CASE 
		WHEN ActivityType = 'Appointment'
			AND Rslt = 'VEXP - Virtual Comm Exp Given'
			THEN 1
		ELSE 0
		END AS Virtual_Community_Experience
	,CASE 
		WHEN ActivityType = 'phonecall BD'
			AND ActivityTypeDetail <> 864960000 --incoming phone call
			AND Rslt <> 'BDCI - Bad Contact Information'
			AND Rslt <> 'CANC - Cancelled'
			AND Rslt <> 'COMP - Completed'
			THEN 1
		ELSE 0
		END AS Phone_Call_Attempted_Biz_Dev
	,CASE 
		WHEN ActivityType = 'phonecall'
			AND ActivityTypeDetail <> 864960000 --incoming phone call
			AND Rslt <> 'BDCI - Bad Contact Information'
			AND Rslt <> 'CANC - Cancelled'
			AND Rslt <> 'COMP - Completed'
			THEN 1
		ELSE 0
		END AS Phone_Call_Attempted
	,CASE 
		WHEN ActivityType = 'ksl_sms'
			AND ksl_textssent > 0
			THEN ksl_textssent
		ELSE 0
		END AS TextSent
	,CASE 
		WHEN ActivityType = 'ksl_sms'
			AND ksl_textsreceived > 0
			THEN ksl_textsreceived
		ELSE 0
		END AS TextReceived
FROM (
	SELECT a.accountid
		,
		--a.[ksl_initialinquirydate], -- js 5/18
		a.OwnerId AccountOwnerID
		,a.OwnerIdName AccountOwnerName
		,b.ownerid ActivityOwnerID
		,b.owneridname ActivityOwnerName
		,a.ksl_CommunityId AS CommunityId
		,a.ksl_CommunityIdName AS CommunityIdName
		,
		--Get Last Attempt Information
		b.Subject AS ActivitySubject
		,b.ActivityTypeCode AS ActivityType
		,b.ActivityTypeDetail AS ActivityTypeDetail
		,isnull(dateadd(hour, (
					SELECT com.[ksl_utctimeadjust]
					FROM [KSLCLOUD_MSCRM].[dbo].[ksl_community] com
					WHERE ksl_communityid = a.ksl_communityid
					), b.CompletedDate), b.CompletedDate) CompletedDate
		,Rslt
		,activityid
		,notes
		,ksl_textssent
		,ksl_textsreceived
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
			,pc.description AS notes
			,pc.owneridname
			,pc.ownerid
			,NULL AS ksl_textssent
			,NULL AS ksl_textsreceived
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
			,pc.description AS notes
			,pc.owneridname
			,pc.ownerid
			,NULL AS ksl_textssent
			,NULL AS ksl_textsreceived
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
			,pc.description AS notes
			,pc.owneridname
			,pc.ownerid
			,NULL AS ksl_textssent
			,NULL AS ksl_textsreceived
		FROM kslcloud_mscrm.dbo.Account L WITH (NOLOCK)
		INNER JOIN kslcloud_mscrm.dbo.email PC WITH (NOLOCK) ON PC.RegardingObjectId = L.accountid
		WHERE PC.statecode_displayname = 'Completed'
			AND PC.ksl_emailtype <> 864960000
		
		UNION ALL
		
		SELECT activityid
			,ksl_lettertype_displayname AS Rslt
			,L.accountid
			,PC.Subject
			,PC.ActivityTypeCode
			,PC.ksl_lettertype AS ActivityTypeDetail
			,PC.regardingobjectid
			,PC.actualend AS CompletedDate
			,pc.description AS notes
			,pc.owneridname
			,pc.ownerid
			,NULL AS ksl_textssent
			,NULL AS ksl_textsreceived
		FROM kslcloud_mscrm.dbo.Account L WITH (NOLOCK)
		INNER JOIN kslcloud_mscrm.dbo.letter PC WITH (NOLOCK) ON PC.RegardingObjectId = L.accountid
		WHERE PC.statecode_displayname = 'Completed'
			AND PC.ksl_lettertype <> 864960004
		
		UNION ALL
		
		SELECT activityid
			,'Completed' AS Rslt
			,L.accountid
			,PC.Subject
			,PC.ActivityTypeCode
			,1001 AS ActivityTypeDetail
			,PC.regardingobjectid
			,PC.actualend AS CompletedDate
			,pc.description AS notes
			,PC.owneridname
			,pc.ownerid
			,ksl_textssent
			,ksl_textsreceived
		FROM kslcloud_mscrm.dbo.Account L WITH (NOLOCK)
		INNER JOIN kslcloud_mscrm.dbo.ksl_sms PC WITH (NOLOCK) ON PC.RegardingObjectId = L.accountid
			--SELECT L.accountid, RIGHT(PC.Subject, LEN(PC.Subject) - 13) as [Subject], 'sms' as ActivityTypeCode, NULL as ActivityTypeDetail, PC.regardingobjectid, PC.actualend as CompletedDate, pc.description as notes
			--FROM Account L WITH (NOLOCK)
			--INNER JOIN txtsync_sms PC ON PC.RegardingObjectId = L.accountid
		) AS b
	INNER JOIN kslcloud_mscrm.dbo.account a ON b.accountid = a.accountid
	
	UNION ALL
	
	SELECT a.contactid
		,
		--null as [ksl_initialinquirydate], -- js 5/18
		--DW 9.25.23 changed these to b from a, the next 2 lines
		b.ownerid AccountOwnerID
		,b.owneridname AccountOwnerName
		,b.ownerid ActivityOwnerID
		,b.owneridname ActivityOwnerName
		,a.ksl_CommunityId AS CommunityId
		,a.ksl_CommunityIdName AS CommunityIdName
		,
		--Get Last Attempt Information
		b.Subject AS ActivitySubject
		,b.ActivityTypeCode + ' BD' AS ActivityType
		,b.ActivityTypeDetail AS ActivityTypeDetail
		,isnull(dateadd(hour, (
					SELECT com.[ksl_utctimeadjust]
					FROM [KSLCLOUD_MSCRM].[dbo].[ksl_community] com
					WHERE ksl_communityid = a.ksl_communityid
					), b.CompletedDate), b.CompletedDate) CompletedDate
		,Rslt
		,activityid
		,notes
		,ksl_textssent
		,ksl_textsreceived
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
			,pc.description AS notes
			,NULL AS ksl_textssent
			,NULL AS ksl_textsreceived
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
			,pc.description AS notes
			,NULL AS ksl_textssent
			,NULL AS ksl_textsreceived
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
			,pc.description AS notes
			,NULL AS ksl_textssent
			,NULL AS ksl_textsreceived
		FROM kslcloud_mscrm.dbo.email PC WITH (NOLOCK)
		WHERE PC.statecode_displayname = 'Completed'
			AND PC.ksl_emailtype <> 864960000
		
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
			,pc.description AS notes
			,NULL AS ksl_textssent
			,NULL AS ksl_textsreceived
		FROM kslcloud_mscrm.dbo.letter PC WITH (NOLOCK)
		WHERE PC.statecode_displayname = 'Completed'
			AND PC.ksl_lettertype <> 864960004
		
		UNION ALL
		
		SELECT activityid
			,'Completed' AS Rslt
			,ownerid
			,owneridname
			,PC.Subject
			,PC.ActivityTypeCode
			,1001 AS ActivityTypeDetail
			,PC.regardingobjectid
			,PC.actualend AS CompletedDate
			,pc.description AS notes
			,ksl_textssent
			,ksl_textsreceived
		FROM kslcloud_mscrm.dbo.ksl_sms PC WITH (NOLOCK)
			--Union All
			--SELECT L.accountid, RIGHT(PC.Subject, LEN(PC.Subject) - 13) as [Subject], 'sms' as ActivityTypeCode, NULL as ActivityTypeDetail, PC.regardingobjectid, PC.actualend as CompletedDate, pc.description as notes
			--FROM Account L WITH (NOLOCK)
			--INNER JOIN txtsync_sms PC ON PC.RegardingObjectId = L.accountid
		) AS b
	INNER JOIN kslcloud_mscrm.dbo.contact a ON b.RegardingObjectId = a.contactid
	) AS x
OUTER APPLY (
	SELECT TOP 1 *
	FROM LastCE
	WHERE X.accountid = lastCE.regardingobjectid
	ORDER BY LastCE.LastCEDate ASC
	) FCE

--TESTING
--WHERE x.CommunityId = '3BC35920-B2DE-E211-9163-0050568B37AC'   -- Byron Park
--AND x.CompletedDate >= DATEADD(MONTH, -1, GETDATE())
--ORDER BY x.CompletedDate DESC;
GO


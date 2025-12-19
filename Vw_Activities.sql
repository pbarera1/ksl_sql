USE [DataWarehouse]
GO

/****** Object:  View [dbo].[Vw_Activities]    Script Date: 12/18/2025 4:48:24 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO









ALTER VIEW [dbo].[Vw_Activities]
AS



With LastCE AS
(select 

	   --Get Last Contact Activity Information
	   b.Subject as ActivitySubject,
	   b.ActivityTypeCode as LCEType,
	   b.ActivityTypeDetail as LCETypeDetail,
	   b.regardingobjectid,
	   b.CompletedDate as LastCEDate,
	   b.notes as LCENotes,
	   b.activityid
from 
(
SELECT pc.activityid, PC.Subject, PC.ActivityTypeCode, PC.ksl_appointmenttype as ActivityTypeDetail, PC.regardingobjectid, PC.scheduledstart as CompletedDate, left(PC.description,300) as notes
from [KSLCLOUD_MSCRM].dbo.appointment PC WITH (NOLOCK) 
WHERE  
PC.statecode_displayname = 'Completed'
			and PC.ksl_appointmenttype in ( 864960001, 864960002)

			and PC.ksl_resultoptions in ('864960005','864960004', '864960006') --Result: 864960005:Completed  864960004:Community Experience  864960006: Virtual Experience
			) as b
)





select X.*

--,case when ROW_NUMBER() over (partition by accountid order by completeddate) = 1 then 1 else 0 end as lead  -- js 5/18
--,ROW_NUMBER() over (partition by accountid order by completeddate) row
,case when (ActivityType = 'phonecall' or (ActivityTypeDetail = 864960000 and ActivityType = 'appointment')/*Phone Appointment*/) and Rslt ='COMP - Completed' and ActivityTypeDetail <> 864960000 /*incoming call*/ then 1 else 0 end as Completed_Phone_Calls
,case when ActivityType = 'phonecall' and Rslt ='COMP - Completed' and ActivityTypeDetail = 864960000 /*incoming call*/ then 1 else 0 end as Completed_Incoming_Phone_Calls
,case when (ActivityType = 'email' and ActivityTypeDetail in(864960002))  or (ActivityType = 'letter' and ActivityTypeDetail in( 864960000 ))  then 1 else 0 end as Sent_Messages
,case when ActivityType = 'Appointment' and  Rslt ='COMP - Completed' and ActivityTypeDetail <> 864960000/*Phone Appointment*/ and CAST(CompletedDate AS DATE) <> CAST(LastCEDate AS DATE) then 1 else 0 end as Appointment
,case when ActivityType = 'email BD' and ActivityTypeDetail =864960002 then 1 else 0 end as Sent_Messages_Biz_Dev
,case when ActivityType = 'ksl_sms BD' and ksl_textssent > 0 then ksl_textssent else 0 end as TextSent_Biz_Dev
,case when ActivityType = 'ksl_sms BD' and ksl_textsreceived > 0 then ksl_textsreceived else 0 end as TextReceived_Biz_Dev
,case when ActivityType = 'phonecall BD' and Rslt ='COMP - Completed' then 1 else 0 end as Completed_Phone_Calls_Biz_Dev
,case when ActivityType = 'Appointment BD' and  (Rslt ='COMP - Completed' or Rslt ='CEXP - Community Experience Given') then 1 else 0 end as Appointment_Biz_Dev
,case when ActivityType = 'Appointment' and ( Rslt ='CEXP - Community Experience Given' or (ActivityTypeDetail in (864960001,864960002 ) and Rslt = 'COMP - Completed') ) and CAST(CompletedDate AS DATE) = CAST(LastCEDate AS DATE) then 1 else 0 end as Community_Experience
,case when ActivityType = 'Appointment' and  Rslt ='VEXP - Virtual Comm Exp Given' then 1 else 0 end as Virtual_Community_Experience
,case when ActivityType = 'phonecall BD' and ActivityTypeDetail <> 864960000 and Rslt <> 'BDCI - Bad Contact Information' and Rslt <> 'CANC - Cancelled' and Rslt <>'COMP - Completed' then 1 else 0 end as Phone_Call_Attempted_Biz_Dev
,case when ActivityType = 'phonecall' and ActivityTypeDetail <> 864960000 and Rslt <> 'BDCI - Bad Contact Information' and Rslt <> 'CANC - Cancelled' and Rslt <>'COMP - Completed' then 1 else 0 end as Phone_Call_Attempted
,case when ActivityType = 'ksl_sms' and ksl_textssent > 0 then ksl_textssent else 0 end as TextSent
,case when ActivityType = 'ksl_sms' and ksl_textsreceived > 0 then ksl_textsreceived else 0 end as TextReceived





from (
select 
a.accountid,
--a.[ksl_initialinquirydate], -- js 5/18
a.OwnerId AccountOwnerID, 
a.OwnerIdName AccountOwnerName,
b.ownerid ActivityOwnerID, 
b.owneridname ActivityOwnerName,
a.ksl_CommunityId AS CommunityId,
a.ksl_CommunityIdName AS CommunityIdName,
	   --Get Last Attempt Information
	   b.Subject as ActivitySubject,
       b.ActivityTypeCode as ActivityType,
	   b.ActivityTypeDetail as ActivityTypeDetail,
    	   isnull(dateadd(
										hour,(select com.[ksl_utctimeadjust] 
										from [KSLCLOUD_MSCRM].[dbo].[ksl_community] com  
										where ksl_communityid = a.ksl_communityid) , b.CompletedDate
										), b.CompletedDate) CompletedDate,
	   Rslt,
	   activityid,
	   notes, 
	   ksl_textssent, ksl_textsreceived
from 
(
--select * from kslcloud_mscrm.dbo.PhoneCall
SELECT  activityid ,ksl_resultoptions_displayname as Rslt,L.accountid, PC.Subject, PC.ActivityTypeCode, PC.ksl_phonecalltype as ActivityTypeDetail, PC.regardingobjectid, PC.ksl_datecompleted as CompletedDate
, pc.description as notes,pc.owneridname,  pc.ownerid, NULL as ksl_textssent, NULL as ksl_textsreceived
FROM kslcloud_mscrm.dbo.Account L WITH (NOLOCK)
inner JOIN kslcloud_mscrm.dbo.PhoneCall PC WITH (NOLOCK) ON PC.RegardingObjectId = L.accountid
WHERE 
PC.statecode_displayname = 'Completed' --Workflow changed call to completed
and PC.ksl_resultoptions <> '864960008' --Result: Anything but cancelled
Union All
SELECT activityid ,ksl_resultoptions_displayname as Rslt,L.accountid, PC.Subject, PC.ActivityTypeCode, PC.ksl_appointmenttype as ActivityTypeDetail, PC.regardingobjectid, PC.scheduledstart as CompletedDate
, pc.description as notes,pc.owneridname,  pc.ownerid, NULL as ksl_textssent, NULL as ksl_textsreceived
FROM kslcloud_mscrm.dbo.Account L WITH (NOLOCK)
inner JOIN kslcloud_mscrm.dbo.appointment PC WITH (NOLOCK) ON PC.RegardingObjectId = L.accountid
WHERE  
PC.statecode_displayname = 'Completed'
and PC.ksl_resultoptions <> '100000000' --Result: 100000000:Cancelled 
Union All
SELECT  activityid ,ksl_emailtype_displayname as Rslt,L.accountid, PC.Subject, PC.ActivityTypeCode, PC.ksl_emailtype as ActivityTypeDetail, PC.regardingobjectid, PC.actualend as CompletedDate
, pc.description as notes,pc.owneridname,  pc.ownerid, NULL as ksl_textssent, NULL as ksl_textsreceived
FROM kslcloud_mscrm.dbo.Account L WITH (NOLOCK)
inner JOIN kslcloud_mscrm.dbo.email PC WITH (NOLOCK) ON PC.RegardingObjectId = L.accountid
WHERE  
PC.statecode_displayname = 'Completed'
and PC.ksl_emailtype <> 864960000
UNION ALL
SELECT activityid ,ksl_lettertype_displayname as Rslt,L.accountid, PC.Subject, PC.ActivityTypeCode, PC.ksl_lettertype as ActivityTypeDetail, PC.regardingobjectid, PC.actualend as CompletedDate
, pc.description as notes,pc.owneridname,  pc.ownerid, NULL as ksl_textssent, NULL as ksl_textsreceived
FROM kslcloud_mscrm.dbo.Account L WITH (NOLOCK)
inner JOIN kslcloud_mscrm.dbo.letter PC WITH (NOLOCK) ON PC.RegardingObjectId = L.accountid
WHERE  
PC.statecode_displayname = 'Completed'
and PC.ksl_lettertype <> 864960004
Union All
SELECT activityid ,'Completed' as Rslt,L.accountid, PC.Subject, PC.ActivityTypeCode, 1001 as ActivityTypeDetail, PC.regardingobjectid, PC.actualend as CompletedDate
, pc.description as notes,PC.owneridname ,  pc.ownerid, ksl_textssent, ksl_textsreceived
FROM kslcloud_mscrm.dbo.Account L WITH (NOLOCK)
inner JOIN kslcloud_mscrm.dbo.ksl_sms PC WITH (NOLOCK) ON PC.RegardingObjectId = L.accountid

--SELECT L.accountid, RIGHT(PC.Subject, LEN(PC.Subject) - 13) as [Subject], 'sms' as ActivityTypeCode, NULL as ActivityTypeDetail, PC.regardingobjectid, PC.actualend as CompletedDate, pc.description as notes
--FROM Account L WITH (NOLOCK)
--INNER JOIN txtsync_sms PC ON PC.RegardingObjectId = L.accountid
) as b inner join kslcloud_mscrm.dbo.account a on b.accountid = a.accountid



union all



select 
a.contactid,
--null as [ksl_initialinquirydate], -- js 5/18
--DW 9.25.23 changed these to b from a, the next 2 lines
b.ownerid AccountOwnerID, 
b.owneridname AccountOwnerName,
b.ownerid ActivityOwnerID, 
b.owneridname ActivityOwnerName,
a.ksl_CommunityId AS CommunityId,
a.ksl_CommunityIdName AS CommunityIdName,
	   --Get Last Attempt Information
	   b.Subject as ActivitySubject,
       b.ActivityTypeCode + ' BD' as ActivityType,
	   b.ActivityTypeDetail as ActivityTypeDetail,
    	   isnull(dateadd(
										hour,(select com.[ksl_utctimeadjust] 
										from [KSLCLOUD_MSCRM].[dbo].[ksl_community] com  
										where ksl_communityid = a.ksl_communityid) , b.CompletedDate
										), b.CompletedDate) CompletedDate,
	   	   Rslt,
	   activityid,
	   notes, 
	   ksl_textssent, ksl_textsreceived
from 
(
SELECT  activityid ,ksl_resultoptions_displayname as Rslt,ownerid,owneridname ,PC.Subject, PC.ActivityTypeCode, PC.ksl_phonecalltype as ActivityTypeDetail, PC.regardingobjectid, PC.ksl_datecompleted as CompletedDate, pc.description as notes
, NULL as ksl_textssent, NULL as ksl_textsreceived
FROM  kslcloud_mscrm.dbo.PhoneCall PC WITH (NOLOCK)
WHERE 
PC.statecode_displayname = 'Completed' --Workflow changed call to completed
and PC.ksl_resultoptions <> '864960008' --Result: Anything but cancelled
Union All
SELECT   activityid ,ksl_resultoptions_displayname as Rslt,ownerid,owneridname,PC.Subject, PC.ActivityTypeCode, PC.ksl_appointmenttype as ActivityTypeDetail, PC.regardingobjectid, PC.scheduledstart as CompletedDate, pc.description as notes
, NULL as ksl_textssent, NULL as ksl_textsreceived
FROM kslcloud_mscrm.dbo.appointment PC WITH (NOLOCK) 
WHERE  
PC.statecode_displayname = 'Completed'
and PC.ksl_resultoptions <> '100000000' --Result: 100000000:Cancelled 
Union All
SELECT   activityid ,ksl_emailtype_displayname as Rslt,ownerid,owneridname,PC.Subject, PC.ActivityTypeCode, PC.ksl_emailtype as ActivityTypeDetail, PC.regardingobjectid, PC.actualend as CompletedDate, pc.description as notes
, NULL as ksl_textssent, NULL as ksl_textsreceived
FROM kslcloud_mscrm.dbo.email PC WITH (NOLOCK) 
WHERE  
PC.statecode_displayname = 'Completed'
and PC.ksl_emailtype <> 864960000
UNION ALL
SELECT   activityid ,ksl_lettertype_displayname as Rslt,ownerid,owneridname,PC.Subject, PC.ActivityTypeCode, PC.ksl_lettertype as ActivityTypeDetail, PC.regardingobjectid, PC.actualend as CompletedDate, pc.description as notes
, NULL as ksl_textssent, NULL as ksl_textsreceived
FROM kslcloud_mscrm.dbo.letter PC WITH (NOLOCK)
WHERE  
PC.statecode_displayname = 'Completed'
and PC.ksl_lettertype <> 864960004
Union All
SELECT 
activityid ,'Completed' as Rslt, ownerid,owneridname, PC.Subject, PC.ActivityTypeCode, 1001 as ActivityTypeDetail, PC.regardingobjectid, PC.actualend as CompletedDate
, pc.description as notes, ksl_textssent, ksl_textsreceived
FROM kslcloud_mscrm.dbo.ksl_sms PC WITH (NOLOCK) 
--Union All
--SELECT L.accountid, RIGHT(PC.Subject, LEN(PC.Subject) - 13) as [Subject], 'sms' as ActivityTypeCode, NULL as ActivityTypeDetail, PC.regardingobjectid, PC.actualend as CompletedDate, pc.description as notes
--FROM Account L WITH (NOLOCK)
--INNER JOIN txtsync_sms PC ON PC.RegardingObjectId = L.accountid
) as b inner join kslcloud_mscrm.dbo.contact a on b.RegardingObjectId = a.contactid 
) as x

OUTER APPLY (select top 1 *  from LastCE where X.accountid = lastCE.regardingobjectid order by LastCE.LastCEDate asc) FCE




GO



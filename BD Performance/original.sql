use KSLCLOUD_MSCRM_RESTORE_TEST;
declare @Year int = 2025;


with activity as (


select 
b.ownerid AccountOwnerID, 
b.owneridname AccountOwnerName,
a.ksl_CommunityId AS CommunityId,
a.ksl_CommunityIdName AS CommunityIdName,
	   --Get Last Attempt Information
	   b.Subject as ActivitySubject,
       b.ActivityTypeCode + ' BD' as ActivityType,
	   b.ActivityTypeDetail as ActivityTypeDetail,
       convert(date,b.CompletedDate) CompletedDate
	   	  
from 
(
SELECT  activityid ,ksl_resultoptions_displayname as Rslt,ownerid,owneridname,PC.Subject, PC.ActivityTypeCode, PC.ksl_phonecalltype as ActivityTypeDetail, PC.regardingobjectid, PC.ksl_datecompleted as CompletedDate, left(PC.description,300) as notes
FROM  kslcloud_mscrm.dbo.PhoneCall PC WITH (NOLOCK)
WHERE 
PC.statecode_displayname = 'Completed' --Workflow changed call to completed
and PC.ksl_resultoptions <> '864960008' --Result: Anything but cancelled


Union All
SELECT   activityid ,ksl_resultoptions_displayname as Rslt,ownerid,owneridname,PC.Subject, PC.ActivityTypeCode, PC.ksl_appointmenttype as ActivityTypeDetail, PC.regardingobjectid, PC.scheduledstart as CompletedDate, left(PC.description,300) as notes
FROM kslcloud_mscrm.dbo.appointment PC WITH (NOLOCK) 
WHERE  
PC.statecode_displayname = 'Completed'
and PC.ksl_resultoptions <> '100000000' --Result: 100000000:Cancelled 


Union All
SELECT   activityid ,ksl_emailtype_displayname as Rslt,ownerid,owneridname,PC.Subject, PC.ActivityTypeCode, PC.ksl_emailtype as ActivityTypeDetail, PC.regardingobjectid, PC.actualend as CompletedDate, left(PC.description,300) as notes
FROM kslcloud_mscrm.dbo.email PC WITH (NOLOCK) 
WHERE  
PC.statecode_displayname = 'Completed'
and PC.ksl_emailtype <> 864960000

UNION ALL
SELECT   activityid ,ksl_lettertype_displayname as Rslt,ownerid,owneridname,PC.Subject, PC.ActivityTypeCode, PC.ksl_lettertype as ActivityTypeDetail, PC.regardingobjectid, PC.actualend as CompletedDate, left(PC.description,300) as notes
FROM kslcloud_mscrm.dbo.letter PC WITH (NOLOCK)
WHERE  
PC.statecode_displayname = 'Completed'
and PC.ksl_lettertype <> 864960004
--Union All
--SELECT L.accountid, RIGHT(PC.Subject, LEN(PC.Subject) - 13) as [Subject], 'sms' as ActivityTypeCode, NULL as ActivityTypeDetail, PC.regardingobjectid, PC.actualend as CompletedDate, left(PC.description,300) as notes
--FROM Account L WITH (NOLOCK)
--INNER JOIN txtsync_sms PC ON PC.RegardingObjectId = L.accountid
) as b inner join kslcloud_mscrm.dbo.contact a WITH (NOLOCK) on b.RegardingObjectId = a.contactid 
where 
   YEAR(CompletedDate) = @Year -- Filter by the selected year
    AND CompletedDate between DATEFROMPARTS(@Year, 1, 1) -- Start from January 1st of the selected year
						and  CASE 
                            WHEN @Year = YEAR(GETDATE()) THEN GETDATE() -- If it's the current year, go up to today
                            ELSE DATEFROMPARTS(@Year, 12, 31) -- If it's a past year, go up to December 31st of that year
                         END



Union all 
-- Appointments with active residents - appointments for generating Resident referrals

select 
e.ownerid AccountOwnerID, 
e.owneridname AccountOwnerName,
e.ksl_CommunityId AS CommunityId,
e.ksl_CommunityIdName AS CommunityIdName,
	   --Get Last Attempt Information
	   e.Subject as ActivitySubject,
       'RR ' + e.ActivityTypeCode + ' BD' as ActivityType,
	   e.ActivityTypeDetail as ActivityTypeDetail,
       convert(date,e.CompletedDate) CompletedDate
	   	 
from (

SELECT  top 1000  activityid ,ksl_resultoptions_displayname as Rslt, pc.ownerid, pc.owneridname,PC.Subject, PC.ActivityTypeCode, PC.ksl_appointmenttype as ActivityTypeDetail, PC.regardingobjectid, PC.scheduledstart as CompletedDate, c.MoveInDate ,  left(PC.description,300) as notes
, c.ksl_CommunityId, c.ksl_CommunityIdName
FROM kslcloud_mscrm.dbo.appointment PC WITH (NOLOCK) 
 join [DataWarehouse].[dbo].[Fact_Lead] c on c.Lead_AccountID = pc.regardingobjectid
WHERE  
PC.statecode_displayname = 'Completed'
and PC.ksl_resultoptions <> '100000000' --Result: 100000000:Cancelled 
and pc.ksl_appointmenttype	= '864960003' 	-- Bus Development Drop In
--and pc.compl

and scheduledstart > c.MoveInDate
and 
   YEAR(scheduledstart) = @Year -- Filter by the selected year
    AND scheduledstart between DATEFROMPARTS(@Year, 1, 1) -- Start from January 1st of the selected year
						and  CASE 
                            WHEN @Year = YEAR(GETDATE()) THEN GETDATE() -- If it's the current year, go up to today
                            ELSE DATEFROMPARTS(@Year, 12, 31) -- If it's a past year, go up to December 31st of that year
                         END

) e

), actSUM as (
SELECT 
AccountOwnerID
	  ,sum(case when [ActivityType] = 'appointment BD' then 1 else 0 end ) As appointment_BD
	  ,sum(case when [ActivityType] = 'RR appointment BD' then 1 else 0 end )*1.0 As RR_appointment_BD
	  ,sum(case when [ActivityType] = 'email BD' then 1 else 0 end ) As email_BD
	  ,sum(case when [ActivityType] = 'letter BD' then 1 else 0 end ) As letter_BD
	  ,sum(case when [ActivityType] = 'phonecall BD' then 1 else 0 end ) As phonecall_BD
	  
  FROM Activity 
	  group by AccountOwnerID
  
  ) , NRR as (

  Select sum(RentRev) RentRev
 ,ksl_securityregionteamid
 FROM (
				SELECT 
				isnull(sum(ksl_ACT_CommTransFee + new_ApartmentRate-ISNULL(est.ksl_ACT_CommTransFeeSpecial,0)),0) AS RentRev 
					,a.ksl_CommunityId


	
				FROM 	(
								SELECT
									afh.ksl_BeginDate
									,afh.ksl_ApartmentId
									,afh.ksl_ApartmentIdName
									,afh.ksl_CommunityId
									--,afh.AccountId
									,afh.ksl_communityIdName
									,afh.ksl_accountLeadId
									,MAX(afh.ksl_endDate) AS EndDt
									,afh.ksl_estimateId
									,afh.ksl_BeginTransactionType
									,MAX(afh.ksl_EndTransactionType) ksl_EndTransactionType
									,MAX(afh.ksl_ReasonDetailIDName) AS ksl_ReasonDetailIDName
									,MAX(afh.ksl_MoveOutDestinationIdName) AS ksl_MoveOutDestinationIdName

									,MAX(afh.OwnerId) AS afh_OwnerID
		
								--,LEA.ksl_ReasonDetailIdName AS ReasonDetail
								,MAX(ksl_MoveOutReasonDetailIdName) AS MoveOutReasonDetail
		


								FROM ksl_apartmentfinancialhistory afh WITH (NOLOCK)   --history of what happened 
									LEFT JOIN account A WITH (NOLOCK)
										ON a.AccountID = ksl_accountleadid
									LEFT JOIN Quote q WITH (NOLOCK)
										ON q.QuoteID = ksl_estimateid
									WHERE (afh.ksl_BeginTransactionType IN (864960001 , 864960003 , 864960007 , 864960008) -- 01=Actual Move In, 03=Actual Transfer In, Scheduled Transfer, Scheduled Move In
										AND a.[ksl_initialsourcecategory] = '25AC1CB4-C27F-E311-986A-0050568B37AC'
										AND afh.statecode = 0
										AND (afh.ksl_EndTransactionType IN (864960004 , 864960006 , 864960002 , 864960005)
											OR afh.ksl_EndTransactionType IS NULL)) -- Actual Transfer Out, Actual move out, Scheduled Transfer,Scheduled move out
										OR (
											afh.ksl_BeginTransactionType = 864960000
											AND afh.statecode = 0
											AND afh.ksl_EndTransactionType IS NULL
											AND CAST(afh.ksl_BeginDate AS DATE) >= CAST(GETDATE() - 15 AS DATE)
											)
											--" . $WhereSDSQL . "
								GROUP BY	afh.ksl_BeginDate
										,afh.ksl_ApartmentId
										,afh.ksl_accountLeadId
										,afh.ksl_estimateId
										,afh.ksl_BeginTransactionType
										,afh.ksl_ApartmentIdName
										,afh.ksl_CommunityId
										--,afh.AccountId
										,afh.ksl_communityIdName
							) AS y
			full outer JOIN [Quote]	 est
				ON QuoteID = ksl_estimateId
			LEFT JOIN account A WITH (NOLOCK)
				ON a.accountid = est.customerid
	
	
			where coalesce(
						CASE
							WHEN  y.ksl_BeginTransactionType = 864960001 THEN 'Actual Move in'
							WHEN  y.ksl_BeginTransactionType = 864960003 THEN 'Actual Transfer In'
							WHEN  y.ksl_BeginTransactionType = 864960007 THEN 'Short Term Stay Begin'
							WHEN  y.ksl_BeginTransactionType = 864960008 THEN 'Seasonal Stay Begin'
							WHEN  y.ksl_BeginTransactionType = 864960000 THEN 'Scheduled Move in'
							--ELSE 'Other'
						END,est.ksl_estimatetype_displayname)  in ('Actual Move in', 'Moved In')
					AND a.[ksl_initialsourcecategory] = '25AC1CB4-C27F-E311-986A-0050568B37AC'

	
					--and isnull(y.ksl_CommunityId,est.ksl_CommunityId) = '0DC35920-B2DE-E211-9163-0050568B37AC'


					and isnull(ksl_BeginDate,est.ksl_schfinanmovein) BETWEEN 
																				DATEFROMPARTS(@Year, 1, 1)  -- Start from January 1st of the selected year
																				AND CASE 
																						WHEN @Year = YEAR(GETDATE()) THEN GETDATE()  -- If the selected year is the current year, use today's date
																						ELSE DATEFROMPARTS(@Year, 12, 31)  -- Otherwise, use December 31st of the selected year
																					END
		
		group by a.ksl_CommunityId
	) d

	inner join [KSLCLOUD_MSCRM].[dbo].ksl_community c WITH (NOLOCK) on d.ksl_CommunityId = c.ksl_communityid
	--where 	ksl_securityregionteamid = '0933038A-375D-E811-A94F-000D3A3ACDE0'
		group by 
		 ksl_securityregionteamid

)  , leads as (

  SELECT  count(accountid) as newLeadsavg
		 ,ksl_securityregionteamid
  FROM [KSLCLOUD_MSCRM].[dbo].[account] a
	  inner join [KSLCLOUD_MSCRM].[dbo].ksl_community c on a.ksl_communityid = c.ksl_communityid
	  --inner join [KSLCLOUD_MSCRM].[dbo].[systemuser] u on u.ksl_regionalteamid = c.ksl_securityregionteamid
  where  [ksl_initialsourcecategory] = '25AC1CB4-C27F-E311-986A-0050568B37AC'
		and  
		YEAR(ksl_initialinquirydate) = @Year -- Filter by the selected year
				AND ksl_initialinquirydate between DATEFROMPARTS(@Year, 1, 1) -- Start from January 1st of the selected year
									and  CASE 
										WHEN @Year = YEAR(GETDATE()) THEN GETDATE() -- If it's the current year, go up to today
										ELSE DATEFROMPARTS(@Year, 12, 31) -- If it's a past year, go up to December 31st of that year
                         END
  group by ksl_securityregionteamid

  ) , MoveIns as (    SELECT 
	count(est.quoteid)  as MoveInavg
	
	,c.ksl_securityregionteamid
	

	
FROM 	(
		SELECT
			afh.ksl_BeginDate
			,afh.ksl_ApartmentId
			,afh.ksl_ApartmentIdName
			,afh.ksl_CommunityId
			--,afh.AccountId
			,afh.ksl_communityIdName
			,afh.ksl_accountLeadId
			,MAX(afh.ksl_endDate) AS EndDt
			,afh.ksl_estimateId
			,afh.ksl_BeginTransactionType
			,MAX(afh.ksl_EndTransactionType) ksl_EndTransactionType
			,MAX(afh.ksl_ReasonDetailIDName) AS ksl_ReasonDetailIDName
			,MAX(afh.ksl_MoveOutDestinationIdName) AS ksl_MoveOutDestinationIdName

			,MAX(afh.OwnerId) AS afh_OwnerID
			
		
		--,LEA.ksl_ReasonDetailIdName AS ReasonDetail
		,MAX(ksl_MoveOutReasonDetailIdName) AS MoveOutReasonDetail
		


		FROM ksl_apartmentfinancialhistory afh WITH (NOLOCK)   --history of what happened 
			LEFT JOIN account A WITH (NOLOCK)
				ON a.AccountID = ksl_accountleadid
			LEFT JOIN Quote q WITH (NOLOCK)
				ON q.QuoteID = ksl_estimateid
			WHERE (afh.ksl_BeginTransactionType IN (864960001 , 864960003 , 864960007 , 864960008) -- 01=Actual Move In, 03=Actual Transfer In, Scheduled Transfer, Scheduled Move In
				AND afh.statecode = 0
				AND [ksl_initialsourcecategory] = '25AC1CB4-C27F-E311-986A-0050568B37AC'
				AND (afh.ksl_EndTransactionType IN (864960004 , 864960006 , 864960002 , 864960005)
					OR afh.ksl_EndTransactionType IS NULL)) -- Actual Transfer Out, Actual move out, Scheduled Transfer,Scheduled move out
				OR (
					afh.ksl_BeginTransactionType = 864960000
					AND afh.statecode = 0
					AND afh.ksl_EndTransactionType IS NULL
					AND CAST(afh.ksl_BeginDate AS DATE) >= CAST(GETDATE() - 15 AS DATE)
					)
					
		GROUP BY	afh.ksl_BeginDate
				,afh.ksl_ApartmentId
				,afh.ksl_accountLeadId
				,afh.ksl_estimateId
				,afh.ksl_BeginTransactionType
				,afh.ksl_ApartmentIdName
				,afh.ksl_CommunityId
				--,afh.AccountId
				,afh.ksl_communityIdName
				
		) AS y
	full outer JOIN [Quote]	 est
		ON QuoteID = ksl_estimateId

	
	LEFT JOIN account A WITH (NOLOCK)
		ON a.accountid = est.customerid

	Left Join contact c1 
		on est.ksl_primaryresident1id = c1.contactid
	Left Join contact c2 
		on est.ksl_potentialsecondaryresidentid = c2.contactid
	Left Join ksl_apartment apt
		on est.ksl_ApartmentId = apt.ksl_ApartmentID
	Left Join ksl_apartment tra
		on est.ksl_act_transferfromapartmentid = tra.ksl_ApartmentID
	inner join [KSLCLOUD_MSCRM].[dbo].ksl_community c 
		on a.ksl_communityid = c.ksl_communityid

		
		where coalesce(
				CASE
					WHEN  y.ksl_BeginTransactionType = 864960001 THEN 'Actual Move in'
					WHEN  y.ksl_BeginTransactionType = 864960003 THEN 'Actual Transfer In'
					WHEN  y.ksl_BeginTransactionType = 864960007 THEN 'Short Term Stay Begin'
					WHEN  y.ksl_BeginTransactionType = 864960008 THEN 'Seasonal Stay Begin'
					WHEN  y.ksl_BeginTransactionType = 864960000 THEN 'Scheduled Move in'
					--ELSE 'Other'
				END,est.ksl_estimatetype_displayname)  in ('Actual Move in')
		and  
		YEAR(isnull(ksl_BeginDate,est.ksl_schfinanmovein)) = @Year -- Filter by the selected year
				AND isnull(ksl_BeginDate,est.ksl_schfinanmovein) between DATEFROMPARTS(@Year, 1, 1) -- Start from January 1st of the selected year
									and  CASE 
										WHEN @Year = YEAR(GETDATE()) THEN GETDATE() -- If it's the current year, go up to today
										ELSE DATEFROMPARTS(@Year, 12, 31) -- If it's a past year, go up to December 31st of that year
                         END
 

		--and isnull(y.ksl_CommunityId,est.ksl_CommunityId) = '0DC35920-B2DE-E211-9163-0050568B37AC'

		group by c.ksl_securityregionteamid
) , newRS as (
	SELECT 
	 count(contactid) RSourceAvg
		 ,c.createdby ownerid
	  FROM [KSLCLOUD_MSCRM].[dbo].[contact] c	
	  where       [ksl_contacttype] = '864960002'
	  and YEAR(c.createdon) = @Year -- Filter by the selected year
		AND c.createdon between DATEFROMPARTS(@Year, 1, 1) -- Start from January 1st of the selected year
						and  CASE 
                            WHEN @Year = YEAR(GETDATE()) THEN GETDATE() -- If it's the current year, go up to today
                            ELSE DATEFROMPARTS(@Year, 12, 31) -- If it's a past year, go up to December 31st of that year
                         END
	  group by c.createdby
	  )

, ResRef as (
	SELECT 
	 count(accountid)*1.0 RRAvg
		 ,[ksl_associtateduser] 
		 , [ksl_associtatedusername]
	  FROM [KSLCLOUD_MSCRM].[dbo].account c
	  inner join [KSLCLOUD_MSCRM].[dbo].[ksl_referralorgs] r  on r.ksl_referralorgsid = c.ksl_referralorganization
	  where 
		YEAR(c.createdon) = @Year -- Filter by the selected year
		AND c.createdon between DATEFROMPARTS(@Year, 1, 1) -- Start from January 1st of the selected year
						and  CASE 
                            WHEN @Year = YEAR(GETDATE()) THEN GETDATE() -- If it's the current year, go up to today
                            ELSE DATEFROMPARTS(@Year, 12, 31) -- If it's a past year, go up to December 31st of that year
                         END
	  and ksl_initialsource = '07E31289-00A3-E311-B839-0050568B7D16'  --Resident Referral
	  group by [ksl_associtateduser], [ksl_associtatedusername]
) 


  --SELECT *
  --FROM  actSUM
  --where systemuserid ='FE6E9B1A-ABAB-E811-A95E-000D3A360847'



    Select u.fullname, CASE WHEN u.Title like 'Business Development Director' 
                                        or u.Title like 'Buisness Developement Director' 
                                        or u.Title like 'Director, Business Development'
                                        or u.Title like 'Director of Strategic Partnership%' THEN 'Business Development' 
							 WHEN u.Title like 'Executive%'  or u.title like 'General Manager' THEN 'Executive Director'
							 ELSE 'Sales' END Title 
  ,u.ksl_regionalteamidname
  ,a.*,newLeadsavg, nrr.RentRev RentRevYTD, mi.MoveInavg, nr.RSourceAvg,  RRAvg,  u.ksl_regionalteamid 
  
  from actSUM a
    inner join [KSLCLOUD_MSCRM].[dbo].[systemuser] u on u.systemuserid = a.AccountOwnerID
	left join leads l on u.ksl_regionalteamid = l.ksl_securityregionteamid
	left join nrr on nrr.ksl_securityregionteamid = u.ksl_regionalteamid
	left join MoveIns mi on mi.ksl_securityregionteamid = u.ksl_regionalteamid
	left join newRS nr on nr.ownerid = u.systemuserid
	left join ResRef rr on rr.[ksl_associtateduser] = u.systemuserid

	where appointment_BD + email_BD+ phonecall_BD > 5
	
	order by 2, 1

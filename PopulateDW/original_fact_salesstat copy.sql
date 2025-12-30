 --########################################################################################################################################################
 --###################################################### INSERT Fact_SalesStats #####################################################################
 --########################################################################################################################################################


 BEGIN TRY;THROW 50000,'',1;END TRY BEGIN CATCH;insert into Staging.dbo.log_DW_Time (LineNumber,MinSinceLast) values (ERROR_LINE(),DATEDIFF(mi,@DtLast,getdate()));END CATCH
set @DtLast = getdate()


 ;WITH 
		LastContact AS
						(select 
						b.accountid,
							   --Get Last Contact Activity Information
							   b.Subject as ActivitySubject,
							   b.ActivityTypeCode as LCType,
							   b.ActivityTypeDetail as LCTypeDetail,
							   b.regardingobjectid,
							   b.CompletedDate as LastContactDate,
							   b.notes as LCNotes,
						ROW_NUMBER() OVER (PARTITION BY b.accountid ORDER BY b.CompletedDate  desc) AS RowNum 
						from 
						(
						SELECT L.accountid, PC.Subject, PC.ActivityTypeCode, PC.ksl_phonecalltype as ActivityTypeDetail, PC.regardingobjectid, PC.ksl_datecompleted as CompletedDate, PC.description as notes
						FROM [KSLCLOUD_MSCRM].dbo.Account L WITH (NOLOCK)
						inner JOIN [KSLCLOUD_MSCRM].dbo.PhoneCall PC WITH (NOLOCK) ON PC.RegardingObjectId = L.accountid
						WHERE 
						PC.statecode_displayname = 'Completed' --Workflow changed call to completed
						and PC.ksl_resultoptions = '864960007' --Result: Completed
						Union All
						SELECT L.accountid, PC.Subject, PC.ActivityTypeCode, PC.ksl_appointmenttype as ActivityTypeDetail, PC.regardingobjectid, PC.scheduledstart as CompletedDate, PC.description as notes
						FROM [KSLCLOUD_MSCRM].dbo.Account L WITH (NOLOCK)
						inner JOIN [KSLCLOUD_MSCRM].dbo.appointment PC WITH (NOLOCK) ON PC.RegardingObjectId = L.accountid
						WHERE  
						PC.statecode_displayname = 'Completed'
						and PC.ksl_resultoptions in ('864960005','864960004','864960006') --Result: 864960005:Completed  864960004:Community Experience  864960006: Virtual Experience
						Union All
						SELECT L.accountid, PC.Subject, PC.ActivityTypeCode, PC.ksl_emailtype as ActivityTypeDetail, PC.regardingobjectid, PC.actualend as CompletedDate, PC.description as notes
						FROM [KSLCLOUD_MSCRM].dbo.Account L WITH (NOLOCK)
						inner JOIN [KSLCLOUD_MSCRM].dbo.email PC WITH (NOLOCK) ON PC.RegardingObjectId = L.accountid
						WHERE  
						PC.statecode_displayname = 'Completed'
						and PC.ksl_emailtype = '864960001' --incoming
						Union All
						SELECT activityid ,PC.Subject, PC.ActivityTypeCode, 1001 as ActivityTypeDetail, PC.regardingobjectid,PC.actualend as CompletedDate, left(PC.description,300) as notes

						FROM kslcloud_mscrm.dbo.Account L WITH (NOLOCK)
						inner JOIN kslcloud_mscrm.dbo.ksl_sms PC WITH (NOLOCK) ON PC.RegardingObjectId = L.accountid
 

						 ) as b
						)
		,
		LastCE AS
						(select 
						b.accountid,
							   --Get Last Contact Activity Information
							   b.Subject as ActivitySubject,
							   b.ActivityTypeCode as LCEType,
							   b.ActivityTypeDetail as LCETypeDetail,
							   b.regardingobjectid,
							   b.CompletedDate as LastCEDate,
							   b.notes as LCENotes,
						ROW_NUMBER() OVER (PARTITION BY b.accountid ORDER BY b.CompletedDate  desc) AS RowNum 
						from 
						(
						SELECT L.accountid, PC.Subject, PC.ActivityTypeCode, PC.ksl_appointmenttype as ActivityTypeDetail, PC.regardingobjectid, PC.scheduledstart as CompletedDate, PC.description as notes
						FROM [KSLCLOUD_MSCRM].dbo.Account L WITH (NOLOCK)
						inner JOIN [KSLCLOUD_MSCRM].dbo.appointment PC WITH (NOLOCK) ON PC.RegardingObjectId = L.accountid
						WHERE  
						PC.statecode_displayname = 'Completed'
						and PC.ksl_resultoptions in ('864960005','864960004','864960006') -- 864960004:Community Experience  864960006: Virtual Experience
						 ) as b
						)
		,
		 NextActivity AS
						(select 
						b.accountid,
							   --Get Next Activity Information
							   b.Subject as ActivitySubject,
							   b.ActivityTypeCode as NAType,
							   b.ActivityTypeDetail as NATypeDetail,
							   b.regardingobjectid,
							   b.scheduledend as NextActivityDate,
							   b.notes as NANotes,
							   b.activityid as NAActivityid,
							   b.ownerid,
						ROW_NUMBER() OVER (PARTITION BY accountid ORDER BY b.scheduledend  asc) AS RowNum 
						from 
						(
						SELECT L.accountid, PC.Subject, PC.ActivityTypeCode, PC.ksl_phonecalltype as ActivityTypeDetail, PC.regardingobjectid, PC.scheduledend, PC.description as notes, PC.activityid, PC.ownerid
						FROM [KSLCLOUD_MSCRM].dbo.Account L WITH (NOLOCK)
						inner JOIN [KSLCLOUD_MSCRM].dbo.PhoneCall PC WITH (NOLOCK) ON PC.RegardingObjectId = L.accountid
						WHERE --PC.actualend IS NULL AND PC.scheduledend IS NOT NULL
						 PC.statecode_displayname <> 'Completed'
						Union All
						SELECT L.accountid, PC.Subject, PC.ActivityTypeCode, PC.ksl_appointmenttype as ActivityTypeDetail, PC.regardingobjectid, PC.scheduledstart as scheduledend, PC.description as notes, PC.activityid, PC.ownerid
						FROM [KSLCLOUD_MSCRM].dbo.Account L WITH (NOLOCK)
						inner JOIN [KSLCLOUD_MSCRM].dbo.appointment PC WITH (NOLOCK) ON PC.RegardingObjectId = L.accountid
						WHERE  PC.statecode_displayname <> 'Completed'
						Union All
						SELECT L.accountid, PC.Subject, PC.ActivityTypeCode, NULL as ActivityTypeDetail, PC.regardingobjectid, PC.scheduledend, PC.description as notes, PC.activityid, PC.ownerid
						FROM [KSLCLOUD_MSCRM].dbo.Account L WITH (NOLOCK)
						inner JOIN [KSLCLOUD_MSCRM].dbo.task PC WITH (NOLOCK) ON PC.RegardingObjectId = L.accountid
						WHERE  PC.statecode_displayname <> 'Completed'
						Union All
						SELECT L.accountid, PC.Subject, PC.ActivityTypeCode, PC.ksl_emailtype as ActivityTypeDetail, PC.regardingobjectid, PC.scheduledend, PC.description as notes, PC.activityid, PC.ownerid
						FROM [KSLCLOUD_MSCRM].dbo.Account L WITH (NOLOCK)
						inner JOIN [KSLCLOUD_MSCRM].dbo.email PC WITH (NOLOCK) ON PC.RegardingObjectId = L.accountid
						WHERE  PC.statecode_displayname <> 'Completed'
						 ) as b
						)
		,
		 LastAttempt AS
						(select 
						b.accountid,
							   --Get Last Attempt Information
							   b.Subject as ActivitySubject,
							   b.ActivityTypeCode as LAType,
							   b.ActivityTypeDetail as LATypeDetail,
							   b.regardingobjectid,
							   b.CompletedDate as LastAttemptDate,
							   b.notes as LANotes,
						ROW_NUMBER() OVER (PARTITION BY accountid ORDER BY b.CompletedDate  desc) AS RowNum 
						from 
						(
						SELECT L.accountid, PC.Subject, PC.ActivityTypeCode, PC.ksl_phonecalltype as ActivityTypeDetail, PC.regardingobjectid, PC.ksl_datecompleted as CompletedDate, left(PC.description,300) as notes
						FROM [KSLCLOUD_MSCRM].dbo.Account L WITH (NOLOCK)
						inner JOIN [KSLCLOUD_MSCRM].dbo.PhoneCall PC WITH (NOLOCK) ON PC.RegardingObjectId = L.accountid
						WHERE 
						PC.statecode_displayname = 'Completed' --Workflow changed call to completed
						and PC.ksl_resultoptions <> '864960008' --Result: Anything but cancelled
						Union All
						SELECT L.accountid, PC.Subject, PC.ActivityTypeCode, PC.ksl_appointmenttype as ActivityTypeDetail, PC.regardingobjectid, PC.scheduledstart as CompletedDate, left(PC.description,300) as notes
						FROM [KSLCLOUD_MSCRM].dbo.Account L WITH (NOLOCK)
						inner JOIN [KSLCLOUD_MSCRM].dbo.appointment PC WITH (NOLOCK) ON PC.RegardingObjectId = L.accountid
						WHERE  
						PC.statecode_displayname = 'Completed'
						and PC.ksl_resultoptions <> '100000000' --Result: 100000000:Cancelled 
						Union All
						SELECT L.accountid, PC.Subject, PC.ActivityTypeCode, PC.ksl_emailtype as ActivityTypeDetail, PC.regardingobjectid, PC.actualend as CompletedDate, left(PC.description,300) as notes
						FROM [KSLCLOUD_MSCRM].dbo.Account L WITH (NOLOCK)
						inner JOIN [KSLCLOUD_MSCRM].dbo.email PC WITH (NOLOCK) ON PC.RegardingObjectId = L.accountid
						WHERE  
						PC.statecode_displayname = 'Completed'
						and PC.ksl_emailtype = '864960002' --Outgoing
						UNION ALL
						SELECT L.accountid, PC.Subject, PC.ActivityTypeCode, PC.ksl_lettertype as ActivityTypeDetail, PC.regardingobjectid, PC.actualend as CompletedDate, left(PC.description,300) as notes
						FROM [KSLCLOUD_MSCRM].dbo.Account L WITH (NOLOCK)
						inner JOIN [KSLCLOUD_MSCRM].dbo.letter PC WITH (NOLOCK) ON PC.RegardingObjectId = L.accountid
						WHERE  
						PC.statecode_displayname = 'Completed'
						Union All
						SELECT activityid ,PC.Subject, PC.ActivityTypeCode, 1001 as ActivityTypeDetail, PC.regardingobjectid,PC.actualend as CompletedDate, left(PC.description,300) as notes

						FROM kslcloud_mscrm.dbo.Account L WITH (NOLOCK)
						inner JOIN kslcloud_mscrm.dbo.ksl_sms PC WITH (NOLOCK) ON PC.RegardingObjectId = L.accountid
 
						 ) as b
		)

Select u.dt, u.[FullName], u.[SystemUserId], [ksl_CommunityIdName]
      ,[ksl_CommunityId] --, u.Title
		,coalesce(RADcount,0) RADcount  
		,coalesce(SourceCategoryCount,0)  DataCompliance 
		,coalesce(PastDueActivityCount ,0) PastDueActivityCount
		,coalesce(activeLeads ,0) activeLeads
		from 
			--
				(SELECT  
				
						cast(getdate() as date) as dt, 
						[FullName], [SystemUserId] ,[ksl_CommunityIdName]
							,[ksl_CommunityId], Title

										  FROM [DataWarehouse].[dbo].[Dim_User]
										  where [isUserActive] = 'yes'
										  and Title like '%sales%'
										 
										  and Title not like '%VP%') u


left outer join 
						--RADcount
									(
								SELECT
								cast(getdate() as date) as dt, 
								systemuserid,
								u.fullname,
								title,
								count(A.accountID) as RADcount

								--'RADcount' Description


								FROM [KSLCLOUD_MSCRM].dbo.Account A
								OUTER APPLY (select top 1 *  from NextActivity where regardingobjectid = A.accountid order by NextActivity.NextActivityDate asc) NA
								OUTER APPLY (select top 1 *  from LastContact where regardingobjectid = A.accountid order by LastContact.LastContactDate desc) LC
								OUTER APPLY (select top 1 *  from LastAttempt where regardingobjectid = A.accountid order by LastAttempt.LastAttemptDate desc) LA
								OUTER APPLY (select top 1 *  from LastCE where regardingobjectid = A.accountid order by LastCE.LastCEDate desc) LCE
								LEFT JOIN [KSLCLOUD_MSCRM].dbo.SystemUser U ON U.SystemUserId = A.OwnerID
								LEFT JOIN [KSLCLOUD_MSCRM].dbo.ksl_community C ON C.ksl_communityId = A.ksl_CommunityId
								LEFT JOIN [KSLCLOUD_MSCRM].dbo.contact con ON con.contactid = A.primarycontactid

								Where 
								--A.ksl_communityid = '39C35920-B2DE-E211-9163-0050568B37AC' 

								--and 
								a.statuscode_displayname in ( 'Lead')
								--and
								--[isUserActive] = 'yes'
								--		  and Title like '%sales%'
										 
										  and Title not like '%VP%'
								and (a.ksl_mostrecentcommunityexperience < getdate() -30 or a.ksl_mostrecentcommunityexperience is null )
								and a.ksl_initialinquirydate < getdate() -30
								and (a.ksl_reservationfeetransactiondate is null  )


								and (0 <= 
								case 

								when a.ksl_moveintiming_displayname = '> 2 Years'
								then datediff(day,coalesce(LA.LastAttemptDate,getdate()-90) + 90, getdate()) 

								when ksl_mostrecentcommunityexperience >= getdate()-120 and LC.LastContactDate > getdate() - 60
										and (ksl_waitlisttransactiondate is null and a.ksl_waitlistenddate is not NULL)  
								then datediff(day,LA.LastAttemptDate + 14, getdate())

								when  ksl_mostrecentcommunityexperience >= getdate()-270 and LC.LastContactDate > getdate() - 180 
										and (ksl_waitlisttransactiondate is null and a.ksl_waitlistenddate is not NULL) 
								then datediff(day,LA.LastAttemptDate + 45, getdate())

								when  ksl_losttocompetitoron is not null --and (ksl_waitlisttransactiondate is null and a.ksl_waitlistenddate is not NULL)  
								then datediff(day,LA.LastAttemptDate + 180, getdate())

								else datediff(day,coalesce(LA.LastAttemptDate,getdate()-90) + 90, getdate()) 
								end 
								or 
								CONVERT(DATE, dateadd(hour,C.ksl_UTCTimeAdjust,NA.NextActivityDate)) < CONVERT(DATE, getdate()) 
								)

								group by systemuserid ,					u.title,			u.fullname) x  on u.SystemUserId = x.systemuserid


Left join 
		--DataCompliance
			(select OwnerID,owneridname, count(*) as SourceCategoryCount from 
									
														
									(
											SELECT 
											a.ksl_initialsourcecategoryname as SourceCategory
											,a.OwnerID
											,a.[accountid]
											,a.owneridname
											,a.ksl_initialsourcecategory as SourceCategoryID 		
											,a.ksl_moveintiming_displayname as MoveInTiming
											,a.ksl_leveloflivingpreference_displayname as CarePref
									,a.ksl_leveloflivingpreference as CarePrefID 	
									,a.ksl_moveintiming as MoveInTimingID 	
										,a.ksl_initialinquirydate
										--,fp.accountid as FloorPlanPref
										,modifiedon
											FROM [KSLCLOUD_MSCRM].dbo.Account A
												--left join ( SELECT distinct [accountid] 
												--				FROM [KSLCLOUD_MSCRM].[dbo].[ksl_account_ksl_unitfloorplan]) fp on a.accountid = fp.accountid 
											Where  a.statuscode_displayname IN ('Lead') 				

									) q  
									
									left join (	
													select a.accountid, fp.accountid fpaccountid, CompletedDate,a.createdon
													FROM (SELECT * FROM  [KSLCLOUD_MSCRM].dbo.Account Where statuscode_displayname IN ('Lead') ) A
						
													-- INNER Join with all account that have had a CE or Appointment 
													inner join (SELECT * FROM  (

																					select X.*
																					,row_number() over(partition by accountid order by completeddate desc) rw

																					,case when ActivityType = 'Appointment' and ( Rslt ='CEXP - Community Experience Given' or (ActivityTypeDetail in (864960001 ) and Rslt = 'COMP - Completed') ) 
																									and CAST(CompletedDate AS DATE) = CAST(LastCEDate AS DATE) then 1 else 0 end as Community_Experience

																					,case when ActivityType = 'Appointment' and  Rslt ='COMP - Completed' and ActivityTypeDetail in (864960001 ) and CAST(CompletedDate AS DATE) <> CAST(LastCEDate AS DATE) then 1 else 0 end as Appointment


																					from (
																									select 
																									a.accountid,
																									--a.[ksl_initialinquirydate], -- js 5/18
																									a.OwnerId AccountOwnerID, 
																									b.OwnerIdName AccountOwnerName,
																									a.ksl_CommunityId AS CommunityId,
																									a.ksl_CommunityIdName AS CommunityIdName,
																										   --Get Last Attempt Information
																										   b.Subject as ActivitySubject,
																										   b.ActivityTypeCode as ActivityType,
																										   b.ActivityTypeDetail as ActivityTypeDetail,
																										   convert(date,b.CompletedDate) CompletedDate,
																										   Rslt,
																										   activityid,
																										   notes, 
																										   ksl_textssent, ksl_textsreceived
																									from 
																									(

																									SELECT activityid ,ksl_resultoptions_displayname as Rslt,L.accountid, PC.Subject, PC.ActivityTypeCode, PC.ksl_appointmenttype as ActivityTypeDetail, PC.regardingobjectid, PC.scheduledstart as CompletedDate
																									, pc.description as notes,PC.owneridname, NULL as ksl_textssent, NULL as ksl_textsreceived
																									FROM kslcloud_mscrm.dbo.Account L WITH (NOLOCK)
																									inner JOIN kslcloud_mscrm.dbo.appointment PC WITH (NOLOCK) ON PC.RegardingObjectId = L.accountid
																									WHERE  
																									PC.statecode_displayname = 'Completed'
																									and PC.ksl_resultoptions <> '100000000' --Result: 100000000:Cancelled 

																									) as b 
																									inner join kslcloud_mscrm.dbo.account a on b.accountid = a.accountid

 


																					) as x

																					OUTER APPLY (select top 1 *  from (select 

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
																																		and PC.ksl_appointmenttype in ( 864960001)

																																		and PC.ksl_resultoptions in ('864960005','864960004', '864960006') --Result: 864960005:Completed  864960004:Community Experience  864960006: Virtual Experience
																																		) as b) LastCE where X.accountid = lastCE.regardingobjectid order by LastCE.LastCEDate asc
																													) FCE

																					) E 
																		where (Community_Experience =1 OR Appointment =1)
																		
																		AND CAST(CompletedDate AS DATE) >= '3/9/2022' -- this process started on this date, no need to pull extra and extend the run time. 
																		and rw = 1 


																		) v on v.accountid = a.accountid
						
													-- All the accounts with FP filled out. 
													left join ( SELECT distinct [accountid] 
																							FROM [KSLCLOUD_MSCRM].[dbo].[ksl_account_ksl_unitfloorplan]) fp on a.accountid = fp.accountid 

												) u on q.accountid = u.accountid



									where  
										( 
										SourceCategory is null 
										or
										  MoveInTiming IS NULL 
										  or
										 CarePref is null
										 or( fpaccountid is null 
												and CompletedDate < getdate() -7 
												--and createdon > '1/1/2022'
												)
										) 
										and ksl_initialinquirydate < getdate() -30
							
										
									group by 
									OwnerID ,owneridname									) k on u.SystemUserId =k.ownerid

left join (select ownerid, count(*) activeLeads
			from [KSLCLOUD_MSCRM].dbo.account A 
				
				where  a.statuscode_displayname = 'Lead'
				group by a.ownerid)  ac  on u.SystemUserId = ac.ownerid

left join 
		--PastDueActivityCount
			(select a.ownerid,
				count(b.activityid) as PastDueActivityCount

				from 
				(
				SELECT PC.Subject, PC.ActivityTypeCode, PC.ksl_phonecalltype as ActivityTypeDetail, PC.regardingobjectid, PC.scheduledend, PC.description as notes, PC.activityid, PC.ownerid
				FROM [KSLCLOUD_MSCRM].dbo.PhoneCall PC WITH (NOLOCK) 
				WHERE --PC.actualend IS NULL AND PC.scheduledend IS NOT NULL
				 PC.statecode_displayname <> 'Completed'
				and PC.ksl_phonecalltype <> '864960003'
				Union All
				SELECT PC.Subject, PC.ActivityTypeCode, PC.ksl_appointmenttype as ActivityTypeDetail, PC.regardingobjectid, PC.scheduledstart as scheduledend, PC.description as notes, PC.activityid, PC.ownerid
				FROM [KSLCLOUD_MSCRM].dbo.appointment PC WITH (NOLOCK) 
				WHERE  PC.statecode_displayname <> 'Completed'
				Union All
				SELECT PC.Subject, PC.ActivityTypeCode, NULL as ActivityTypeDetail, PC.regardingobjectid, PC.scheduledend, PC.description as notes, PC.activityid, PC.ownerid
				FROM  [KSLCLOUD_MSCRM].dbo.task PC 
				WHERE  PC.statecode_displayname <> 'Completed'
				Union All
				SELECT  PC.Subject, PC.ActivityTypeCode, PC.ksl_emailtype as ActivityTypeDetail, PC.regardingobjectid, PC.scheduledend, PC.description as notes, PC.activityid, PC.ownerid
				FROM [KSLCLOUD_MSCRM].dbo.email PC WITH (NOLOCK) 
				WHERE  PC.statecode_displayname <> 'Completed'
				and PC.ksl_emailtype <> '864960004'
				 ) as b
				INNER JOIN [KSLCLOUD_MSCRM].dbo.account A WITH (NOLOCK) on A.accountid = b.regardingobjectid
				LEFT JOIN [KSLCLOUD_MSCRM].dbo.SystemUser U ON U.SystemUserId = A.OwnerID
				LEFT JOIN [KSLCLOUD_MSCRM].dbo.ksl_community C ON C.ksl_communityId = A.ksl_CommunityId

				where CONVERT(DATE, dateadd(hour,C.ksl_UTCTimeAdjust,b.scheduledend)) < CONVERT(DATE, getdate()) 
				--and A.ksl_CommunityId = '$CRM_CommunityID' 
				and a.statuscode_displayname = 'Lead'
				group by a.ownerid)  pd  on u.SystemUserId = pd.ownerid



								where  u.Title <> 'Sales Coordinator'
								and u.FullName not in ('# Dynamic.Test' ,'Cedarwood Sales')
								and [ksl_CommunityId] is not null 



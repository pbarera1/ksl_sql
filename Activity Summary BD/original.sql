use DataWarehouse;
declare @c NVARCHAR(4000) = '119C1A08-0142-E511-96FE-0050568B37AC'; --La Posada

select FullName Label
			--,[FullName]
			,Case when FullName like 'Elizabeth Sykes' then '[Dim_User].[FullName].&[Betsy Sykes]'
				when FullName like 'Carol Lowe' then '[Dim_User].[FullName].&[Lynn Lowe]'
				when FullName like 'Leala Connors-Gillespie' then '[Dim_User].[FullName].&[Leala Connors]'
				when FullName like 'Mary Romaine' then '[Dim_User].[FullName].&[Abby Romaine]'
				when FullName like 'Michael Jacobs' then '[Dim_User].[FullName].&[Mike Jacobs]'
				when FullName like 'Tesshanna Berry' then '[Dim_User].[FullName].&[Tess Berry]'
				when FullName like 'Francisco Campos-Bautista' then '[Dim_User].[FullName].&[kiko Campos-Bautista]'
				when FullName like 'Sandra Wilson' then '[Dim_User].[FullName].&[Sandie Wilson]'
				when FullName like 'Samantha Martin' then '[Dim_User].[FullName].&[Sam Martin]'

				when FullName like 'Genevieve Wood' then '[Dim_User].[FullName].&[Jen Wood]'
		
				else concat('[Dim_User].[FullName].&[',FullName,']')  end Filter
			
			,Case when FullName like 'Genevieve Wood' then 'EF0600C1-95BA-EC11-983F-000D3A5C5E3E'
				when FullName like 'Courtney Heyboer' then 'EF0600C1-95BA-EC11-983F-000D3A5C5E3E'
				when FullName like 'Samantha Martin' then 'EF0600C1-95BA-EC11-983F-000D3A5C5E3E'
				else [ksl_communityId] end [ksl_communityId]




			
				
  from	Dim_User	where 	systemuserid in (																				




	SELECT distinct ownerid
	FROM  (
	
	select APPT.ownerid
	FROM  KSLCLOUD_MSCRM..Appointment APPT 
		inner join KSLCLOUD_MSCRM..contact LD on appt.regardingobjectid = ld.contactid
		inner join  KSLCLOUD_MSCRM..ksl_referralorgs r on  LD.ksl_referralorgid = r.ksl_referralorgsid
		WHERE LD.statecode = 0 
	and (
		 ( select top 1 ksl_name
	from KSLCLOUD_MSCRM..ksl_community
	where   ksl_communityId in (@c) ) in  (select u1.name from KSLCLOUD_MSCRM..businessunit u left join KSLCLOUD_MSCRM..businessunitmap m on u.businessunitid = m.businessid left join KSLCLOUD_MSCRM..businessunit u1 on u1.businessunitid = m.subbusinessid 
	where u.businessunitid = (select top 1 businessunitid from KSLCLOUD_MSCRM..team where teamid = r.ownerid)
	or 
	u.businessunitid = (select ksl_regionalteamid from KSLCLOUD_MSCRM..systemuser where systemuserid = r.ownerid)
	)
		)
	and   APPT.scheduledstart between getdate() - 45 and  getdate()+14
	and r.ksl_referralorgtypeidname <> 'Paid Referral Agency'
	
	union all 
	
	select APPT.ownerid
	FROM  KSLCLOUD_MSCRM..phonecall APPT 
		inner join KSLCLOUD_MSCRM..contact LD on appt.regardingobjectid = ld.contactid
		inner join  KSLCLOUD_MSCRM..ksl_referralorgs r on  LD.ksl_referralorgid = r.ksl_referralorgsid
		WHERE LD.statecode = 0 
	and (
		 ( select top 1 ksl_name
	from KSLCLOUD_MSCRM..ksl_community
	where   ksl_communityId in (@c) ) in  (select u1.name from KSLCLOUD_MSCRM..businessunit u left join KSLCLOUD_MSCRM..businessunitmap m on u.businessunitid = m.businessid left join KSLCLOUD_MSCRM..businessunit u1 on u1.businessunitid = m.subbusinessid 
	where u.businessunitid = (select top 1 businessunitid from KSLCLOUD_MSCRM..team where teamid = r.ownerid)
	or 
	u.businessunitid = (select ksl_regionalteamid from KSLCLOUD_MSCRM..systemuser where systemuserid = r.ownerid)
	)
		)
	and   APPT.scheduledstart between getdate() - 45 and  getdate()+14
	and r.ksl_referralorgtypeidname <> 'Paid Referral Agency'
	
	) k 
	)
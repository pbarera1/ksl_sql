USE DataWarehouse;
DECLARE @c NVARCHAR(4000) = '119C1A08-0142-E511-96FE-0050568B37AC';--La Posada

SELECT fullname Label
	--,[FullName]
	,CASE 
		WHEN fullname LIKE 'Elizabeth Sykes'
			THEN '[Dim_User].[FullName].&[Betsy Sykes]'
		WHEN fullname LIKE 'Carol Lowe'
			THEN '[Dim_User].[FullName].&[Lynn Lowe]'
		WHEN fullname LIKE 'Leala Connors-Gillespie'
			THEN '[Dim_User].[FullName].&[Leala Connors]'
		WHEN fullname LIKE 'Mary Romaine'
			THEN '[Dim_User].[FullName].&[Abby Romaine]'
		WHEN fullname LIKE 'Michael Jacobs'
			THEN '[Dim_User].[FullName].&[Mike Jacobs]'
		WHEN fullname LIKE 'Tesshanna Berry'
			THEN '[Dim_User].[FullName].&[Tess Berry]'
		WHEN fullname LIKE 'Francisco Campos-Bautista'
			THEN '[Dim_User].[FullName].&[kiko Campos-Bautista]'
		WHEN fullname LIKE 'Sandra Wilson'
			THEN '[Dim_User].[FullName].&[Sandie Wilson]'
		WHEN fullname LIKE 'Samantha Martin'
			THEN '[Dim_User].[FullName].&[Sam Martin]'
		WHEN fullname LIKE 'Genevieve Wood'
			THEN '[Dim_User].[FullName].&[Jen Wood]'
		ELSE CONCAT (
				'[Dim_User].[FullName].&['
				,fullname
				,']'
				)
		END Filter
	,CASE 
		WHEN fullname LIKE 'Genevieve Wood'
			THEN 'EF0600C1-95BA-EC11-983F-000D3A5C5E3E'
		WHEN fullname LIKE 'Courtney Heyboer'
			THEN 'EF0600C1-95BA-EC11-983F-000D3A5C5E3E'
		WHEN fullname LIKE 'Samantha Martin'
			THEN 'EF0600C1-95BA-EC11-983F-000D3A5C5E3E'
		ELSE [ksl_communityid]
		END [ksl_communityId]
FROM dim_user
WHERE systemuserid IN (
		SELECT DISTINCT ownerid
		FROM (
			SELECT DISTINCT act.ownerid
			-- systemuserid for users with an activity on a Referral Org account
			FROM KSLCLOUD_MSCRM..activities act
			INNER JOIN KSLCLOUD_MSCRM.dbo.Account AS A WITH (NOLOCK) ON A.accountid = act.RegardingObjectId
			INNER JOIN KiscoCustom.dbo.Associate AS u ON u.SalesAppID = act.ownerid
			JOIN KiscoCustom.dbo.Community as c ON c.CommunityIDY = u.USR_CommunityIDY
			JOIN KSLCLOUD_MSCRM.dbo.ksl_community as comm ON comm.ksl_communityid = c.CRM_CommunityID
			-- ksl_community region col matches the region for @c (ex. la posada)
			WHERE comm.ksl_regionid = (SELECT TOP 1 ksl_regionid FROM KSLCLOUD_MSCRM.dbo.ksl_community WHERE ksl_communityid IN (@c))
			--AND A.statuscode_displayname LIKE 'referral org%' -- brings results to 0
			AND A.statecode = 0 --active
			AND act.scheduledstart BETWEEN getdate() - 45 AND getdate() + 14
			AND act.activitytypecode IN ('Committed Face Appointment', 'Unscheduled Walk-In', 'Outgoing Phone Call', 'Incoming Phone Call')
			) k
		)
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
			SELECT act.ownerid
			FROM KSLCLOUD_MSCRM_RESTORE_TEST..activities act
			INNER JOIN kslcloud_mscrm..contact LD ON act.regardingobjectid = ld.contactid
			INNER JOIN kslcloud_mscrm..ksl_referralorgs r ON LD.ksl_referralorgid = r.ksl_referralorgsid
			WHERE LD.statecode = 0
				--AND (act.activitytypecode LIKE '%face appointment%' OR act.activitytypecode LIKE '%walk-in%') --todo
				AND (
					(
						SELECT TOP 1 ksl_name
						FROM kslcloud_mscrm..ksl_community
						WHERE ksl_communityid IN (@c)
						) IN (
						SELECT u1.NAME
						FROM kslcloud_mscrm..businessunit u
						LEFT JOIN kslcloud_mscrm..businessunitmap m ON u.businessunitid = m.businessid
						LEFT JOIN kslcloud_mscrm..businessunit u1 ON u1.businessunitid = m.subbusinessid
						WHERE u.businessunitid = (
								SELECT TOP 1 businessunitid
								FROM kslcloud_mscrm..team
								WHERE teamid = r.ownerid
								)
							OR u.businessunitid = (
								SELECT ksl_regionalteamid
								FROM kslcloud_mscrm..systemuser
								WHERE systemuserid = r.ownerid
								)
						)
					)
			--AND act.activitytypecode LIKE '%appointment%'
			--AND act.scheduledstart BETWEEN
			--Getdate() - 45 AND
			--Getdate() + 14
			--AND r.ksl_referralorgtypeidname <>
			--'Paid Referral Agency'
			
			UNION ALL
			
			SELECT act.ownerid
			FROM KSLCLOUD_MSCRM_RESTORE_TEST..activities act
			INNER JOIN kslcloud_mscrm..contact LD ON act.regardingobjectid = ld.contactid
			INNER JOIN kslcloud_mscrm..ksl_referralorgs r ON LD.ksl_referralorgid = r.ksl_referralorgsid
			WHERE LD.statecode = 0
				AND act.activitytypecode LIKE '%phone%'
				AND (
					(
						SELECT TOP 1 ksl_name
						FROM kslcloud_mscrm..ksl_community
						WHERE ksl_communityid IN (@c)
						) IN (
						SELECT u1.NAME
						FROM kslcloud_mscrm..businessunit u
						LEFT JOIN kslcloud_mscrm..businessunitmap m ON u.businessunitid = m.businessid
						LEFT JOIN kslcloud_mscrm..businessunit u1 ON u1.businessunitid = m.subbusinessid
						WHERE u.businessunitid = (
								SELECT TOP 1 businessunitid
								FROM kslcloud_mscrm..team
								WHERE teamid = r.ownerid
								)
							OR u.businessunitid = (
								SELECT ksl_regionalteamid
								FROM kslcloud_mscrm..systemuser
								WHERE systemuserid = r.ownerid
								)
						)
					)
				AND act.scheduledstart BETWEEN Getdate() - 45
					AND Getdate() + 14
				AND r.ksl_referralorgtypeidname <> 'Paid Referral Agency'
			) k
		)
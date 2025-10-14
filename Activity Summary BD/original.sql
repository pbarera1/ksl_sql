USE DataWarehouse;

DECLARE @c NVARCHAR(4000) = '119C1A08-0142-E511-96FE-0050568B37AC';--La Posada

SELECT FullName Label
	--,[FullName]
	,CASE 
		WHEN FullName LIKE 'Elizabeth Sykes'
			THEN '[Dim_User].[FullName].&[Betsy Sykes]'
		WHEN FullName LIKE 'Carol Lowe'
			THEN '[Dim_User].[FullName].&[Lynn Lowe]'
		WHEN FullName LIKE 'Leala Connors-Gillespie'
			THEN '[Dim_User].[FullName].&[Leala Connors]'
		WHEN FullName LIKE 'Mary Romaine'
			THEN '[Dim_User].[FullName].&[Abby Romaine]'
		WHEN FullName LIKE 'Michael Jacobs'
			THEN '[Dim_User].[FullName].&[Mike Jacobs]'
		WHEN FullName LIKE 'Tesshanna Berry'
			THEN '[Dim_User].[FullName].&[Tess Berry]'
		WHEN FullName LIKE 'Francisco Campos-Bautista'
			THEN '[Dim_User].[FullName].&[kiko Campos-Bautista]'
		WHEN FullName LIKE 'Sandra Wilson'
			THEN '[Dim_User].[FullName].&[Sandie Wilson]'
		WHEN FullName LIKE 'Samantha Martin'
			THEN '[Dim_User].[FullName].&[Sam Martin]'
		WHEN FullName LIKE 'Genevieve Wood'
			THEN '[Dim_User].[FullName].&[Jen Wood]'
		ELSE CONCAT (
				'[Dim_User].[FullName].&['
				,FullName
				,']'
				)
		END Filter
	,CASE 
		WHEN FullName LIKE 'Genevieve Wood'
			THEN 'EF0600C1-95BA-EC11-983F-000D3A5C5E3E'
		WHEN FullName LIKE 'Courtney Heyboer'
			THEN 'EF0600C1-95BA-EC11-983F-000D3A5C5E3E'
		WHEN FullName LIKE 'Samantha Martin'
			THEN 'EF0600C1-95BA-EC11-983F-000D3A5C5E3E'
		ELSE [ksl_communityId]
		END [ksl_communityId]
FROM Dim_User
WHERE systemuserid IN (
		SELECT DISTINCT ownerid
		FROM (
			SELECT APPT.ownerid
			FROM KSLCLOUD_MSCRM..Appointment APPT
			INNER JOIN KSLCLOUD_MSCRM..contact LD ON appt.regardingobjectid = ld.contactid
			INNER JOIN KSLCLOUD_MSCRM..ksl_referralorgs r ON LD.ksl_referralorgid = r.ksl_referralorgsid
			WHERE LD.statecode = 0
				AND (
					(
						SELECT TOP 1 ksl_name
						FROM KSLCLOUD_MSCRM..ksl_community
						WHERE ksl_communityId IN (@c)
						) IN (
						SELECT u1.name
						FROM KSLCLOUD_MSCRM..businessunit u
						LEFT JOIN KSLCLOUD_MSCRM..businessunitmap m ON u.businessunitid = m.businessid
						LEFT JOIN KSLCLOUD_MSCRM..businessunit u1 ON u1.businessunitid = m.subbusinessid
						WHERE u.businessunitid = (
								SELECT TOP 1 businessunitid
								FROM KSLCLOUD_MSCRM..team
								WHERE teamid = r.ownerid
								)
							OR u.businessunitid = (
								SELECT ksl_regionalteamid
								FROM KSLCLOUD_MSCRM..systemuser
								WHERE systemuserid = r.ownerid
								)
						)
					)
				AND APPT.scheduledstart BETWEEN getdate() - 45
					AND getdate() + 14
				AND r.ksl_referralorgtypeidname <> 'Paid Referral Agency'
			
			UNION ALL
			
			SELECT APPT.ownerid
			FROM KSLCLOUD_MSCRM..phonecall APPT
			INNER JOIN KSLCLOUD_MSCRM..contact LD ON appt.regardingobjectid = ld.contactid
			INNER JOIN KSLCLOUD_MSCRM..ksl_referralorgs r ON LD.ksl_referralorgid = r.ksl_referralorgsid
			WHERE LD.statecode = 0
				AND (
					(
						SELECT TOP 1 ksl_name
						FROM KSLCLOUD_MSCRM..ksl_community
						WHERE ksl_communityId IN (@c)
						) IN (
						SELECT u1.name
						FROM KSLCLOUD_MSCRM..businessunit u
						LEFT JOIN KSLCLOUD_MSCRM..businessunitmap m ON u.businessunitid = m.businessid
						LEFT JOIN KSLCLOUD_MSCRM..businessunit u1 ON u1.businessunitid = m.subbusinessid
						WHERE u.businessunitid = (
								SELECT TOP 1 businessunitid
								FROM KSLCLOUD_MSCRM..team
								WHERE teamid = r.ownerid
								)
							OR u.businessunitid = (
								SELECT ksl_regionalteamid
								FROM KSLCLOUD_MSCRM..systemuser
								WHERE systemuserid = r.ownerid
								)
						)
					)
				AND APPT.scheduledstart BETWEEN getdate() - 45
					AND getdate() + 14
				AND r.ksl_referralorgtypeidname <> 'Paid Referral Agency'
			) k
		)
--########################################################################################################################################################
--###################################################### Fill in Dim_User  #####################################################################
--########################################################################################################################################################
-- Query should only take 1-2 seconds to run
-- TRUNCATE TABLE Dim_User;
;WITH CTE(ksl_CommunityIdName, ksl_CommunityId, FullName, Title, InternalEmailAddress, DomainName, isUserActive, SystemUserId, dupcnt) AS (
		SELECT c.name
			,c.CRM_CommunityID
			,a.USR_First + ' ' + a.USR_Last
			,r.Name
			,a.USR_Email
			,ISNULL(a.USR_Email, '') AS DomainName -- NULL to Empty String, column doesn't allow null
			,IIF(a.USR_Active = 1, 'Yes', 'No') AS isUserActive
			,a.SalesAppId
			,ROW_NUMBER() OVER (
				PARTITION BY a.USR_Email ORDER BY a.USR_Active DESC
					,LEN(a.USR_First + ' ' + a.USR_Last) ASC
				) AS dupcnt
		FROM KiscoCustom.dbo.Associate a
		JOIN KiscoCustom.dbo.KSL_Roles r ON r.RoleID = a.RoleID
		JOIN KiscoCustom.dbo.Community c ON c.CommunityIDY = a.USR_CommunityIDY
		WHERE a.USR_Email IS NOT NULL
		)

-- INSERT INTO Dim_User
SELECT ksl_CommunityIdName
	,ksl_CommunityId
	,FullName
	,Title
	,InternalEmailAddress
	,DomainName
	,isUserActive
	,SystemUserId
FROM CTE
WHERE dupcnt = 1
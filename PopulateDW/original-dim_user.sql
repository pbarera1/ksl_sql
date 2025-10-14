--########################################################################################################################################################
--###################################################### Fill in Dim_User  #####################################################################
--########################################################################################################################################################
TRUNCATE TABLE Dim_User;

WITH CTE (
	ksl_CommunityIdName
	,ksl_CommunityId
	,FullName
	,Title
	,InternalEmailAddress
	,DomainName
	,isUserActive
	,SystemUserId
	,dupcnt
	)
AS (
	SELECT ksl_CommunityIdName
		,ksl_CommunityId
		,FullName
		,Title
		,InternalEmailAddress
		,DomainName
		,IIF(isDisabled = 1, 'No', 'Yes') AS isUserActive
		,SystemUserId
		,ROW_NUMBER() OVER (
			PARTITION BY internalemailaddress ORDER BY isDisabled ASC
				,len(FullName) ASC
			) AS dupcnt
	FROM kslcloud_mscrm.dbo.systemuser
	) --select * from CTE where dupcnt = 1
INSERT INTO Dim_User
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
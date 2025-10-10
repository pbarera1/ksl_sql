--########################################################################################################################################################
 --###################################################### Fill in Dim_User  #####################################################################
 --########################################################################################################################################################


--TRUNCATE TABLE Dim_User;


 WITH CTE (ksl_CommunityIdName
,ksl_CommunityId
,FullName
,Title
,InternalEmailAddress
,DomainName
, isUserActive 
,SystemUserId
,dupcnt)
AS
(SELECT ksl_CommunityIdName
,ksl_CommunityId
,FullName
,Title
,InternalEmailAddress
,DomainName
,IIF(isDisabled=1,'No','Yes') AS isUserActive 
,SystemUserId,
ROW_NUMBER() OVER (PARTITION BY internalemailaddress ORDER BY isDisabled asc, len(FullName) asc) AS dupcnt
FROM kslcloud_mscrm.dbo.systemuser
)--select * from CTE where dupcnt = 1


--INSERT INTO Dim_User
SELECT 
ksl_CommunityIdName
,ksl_CommunityId
,FullName
,Title
,InternalEmailAddress
,DomainName
,isUserActive 
,SystemUserId
 FROM CTE where dupcnt = 1


 -- UPDATED MAPPING --
WITH CTE (
  ksl_CommunityIdName,
  ksl_CommunityId,
  FullName,
  Title,
  InternalEmailAddress,
  DomainName,
  isUserActive,
  SystemUserId,
  dupcnt
) AS (
  SELECT
      c.name,
      c.CRM_CommunityID,
      a.USR_First + ' ' + a.USR_Last,
      r.Name,
      a.USR_Email,
      a.USR_Email,
      IIF(a.USR_Active = 1, 'Yes', 'No') AS isUserActive,
      a.SalesAppId,
      ROW_NUMBER() OVER (
        PARTITION BY a.USR_Email
        ORDER BY a.USR_Active DESC, LEN(a.USR_First + ' ' + a.USR_Last) ASC
      ) AS dupcnt
  FROM KiscoCustom.dbo.Associate a
  JOIN KiscoCustom.dbo.KSL_Roles   r ON r.RoleID = a.RoleID
  JOIN KiscoCustom.dbo.Community   c ON c.CommunityIDY = a.USR_CommunityIDY
  --Should we add? WHERE a.SalesAppID IS NOT NULL
  --Should we add? AND a.USR_Email IS NOT NULL
)
SELECT *
FROM CTE;
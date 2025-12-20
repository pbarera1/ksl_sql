-- DECLARE @AsOfDate DATE;
-- DECLARE @comm UNIQUEIDENTIFIER;
-- SET @AsOfDate = '2024-09-30';
-- SET @comm = '27C35920-B2DE-E211-9163-0050568B37AC';

WITH BudgetZero AS (
    SELECT c.Community AS ksl_name
        ,(u.USR_First + ' ' + u.USR_Last) AS fullname
        ,b.description
        ,c.ksl_communityid
        ,c.ShortName AS ksl_shortname
        ,(
           SELECT MAX(amt)
           FROM kiscocustom..PIP_FinalCommission
           WHERE sd = (u.USR_First + ' ' + u.USR_Last)
              AND MONTH(dt) = MONTH(@AsOfDate)
              AND YEAR(dt) = YEAR(@AsOfDate)
              AND shortname = c.ShortName
           ) AS FinalAmount1
        ,(
           SELECT MAX(Notes)
           FROM kiscocustom..PIP_FinalCommission
           WHERE sd = (u.USR_First + ' ' + u.USR_Last)
              AND MONTH(dt) = MONTH(@AsOfDate)
              AND YEAR(dt) = YEAR(@AsOfDate)
              AND shortname = c.ShortName
           ) AS Notes
        -- This logic identifies duplicates and ranks them
        ,ROW_NUMBER() OVER (
            PARTITION BY c.ksl_communityid, b.description
            ORDER BY c.Shortname -- Use a column here if you have a preference (e.g., ORDER BY b.dt DESC)
        ) AS RowNum
    FROM ksldb252.datawarehouse.dbo.budgets AS b
    INNER JOIN KiscoCustom.dbo.Associate AS u
        ON b.description = u.USR_Email
    INNER JOIN (
        SELECT CASE
              WHEN ShortName = 'KSL'
                 THEN 'HO'
              ELSE ShortName
              END AS ShortName
           ,ksl_communityid
           ,CASE
              WHEN Community = 'Kisco Senior Living, LLC'
                 THEN 'Home Office'
              ELSE Community
              END AS Community
        FROM datawarehouse.dbo.Dim_Community
        ) AS c ON c.ShortName = b.community
    WHERE MONTH(CONVERT(DATE, b.dt)) = MONTH(@AsOfDate)
        AND YEAR(CONVERT(DATE, b.dt)) = YEAR(@AsOfDate)
        AND budget = '0'
        AND (
           c.ksl_communityid = @comm
           OR @comm = '27C35920-B2DE-E211-9163-0050568B37AC'
           )
)
SELECT
    ksl_name,
    fullname,
    description,
    ksl_communityid,
    ksl_shortname,
    FinalAmount1,
    Notes
FROM BudgetZero
WHERE RowNum = 1 -- This keeps only one row per unique ksl_communityid + description

UNION ALL

-- Home Office specialists block
SELECT 'Home Office' AS ksl_name
	,(u.USR_First + ' ' + u.USR_Last) AS fullname
	,u.USR_Email AS description
	,'27C35920-B2DE-E211-9163-0050568B37AC' AS ksl_communityid
	,'HO' AS ksl_shortname
	,(
		SELECT MAX(amt)
		FROM kiscocustom..PIP_FinalCommission
		WHERE sd = (u.USR_First + ' ' + u.USR_Last)
			AND MONTH(dt) = MONTH(@AsOfDate)
			AND YEAR(dt) = YEAR(@AsOfDate)
			AND shortname = 'HO'
		) AS FinalAmount1
	,(
		SELECT MAX(Notes)
		FROM kiscocustom..PIP_FinalCommission
		WHERE sd = (u.USR_First + ' ' + u.USR_Last)
			AND MONTH(dt) = MONTH(@AsOfDate)
			AND YEAR(dt) = YEAR(@AsOfDate)
			AND shortname = 'HO'
		) AS Notes
FROM KiscoCustom.dbo.Associate AS u
INNER JOIN KiscoCustom.dbo.Community kc ON kc.CommunityIDY = u.USR_CommunityIDY
INNER JOIN KSLCLOUD_MSCRM.dbo.ksl_community commCrm ON commCrm.ksl_communityid = kc.CRM_CommunityID
LEFT JOIN KiscoCustom.dbo.KSL_Roles r ON r.RoleID = u.RoleID
WHERE (
		commCrm.ksl_communityid = @comm
		OR @comm = '27C35920-B2DE-E211-9163-0050568B37AC'
		)
	AND (
		r.Name LIKE '%Sales Specialist%'
		OR u.USR_Role LIKE '%Sales Specialist%'
		)
	AND u.USR_Active = 1
ORDER BY ksl_shortname;
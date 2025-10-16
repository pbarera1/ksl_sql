--62 results
--declare @AsOfDate date
--declare @comm uniqueidentifier
--set @AsOfDate = '9/30/24'
--set @comm = '27C35920-B2DE-E211-9163-0050568B37AC'  ;
SELECT c.Community AS ksl_name
	,u.fullname
	,b.description
	,c.ksl_communityid
	,c.shortname AS ksl_shortname
	,(
		SELECT max(amt)
		FROM kiscocustom..PIP_FinalCommission
		WHERE sd = u.fullname
			AND month(dt) = month(@AsOfDate)
			AND year(dt) = year(@AsOfDate)
			AND shortname = c.shortname
		) AS FinalAmount1
	,(
		SELECT Max(Notes)
		FROM kiscocustom..PIP_FinalCommission
		WHERE sd = u.fullname
			AND month(dt) = month(@AsOfDate)
			AND year(dt) = year(@AsOfDate)
			AND shortname = c.shortname
		) AS Notes
FROM ksldb252.datawarehouse.dbo.budgets b
INNER JOIN systemuser u ON b.description = u.internalemailaddress
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
	) c ON c.shortname = b.community
WHERE month(convert(DATE, b.dt)) = month(@AsOfDate)
	--   and u.islicensed = 1
	AND year(convert(DATE, b.dt)) = year(@AsOfDate)
	AND budget = '0'
	AND (
		c.ksl_communityid = @comm
		OR @comm = '27C35920-B2DE-E211-9163-0050568B37AC'
		)
--and description = 'Rebekah.deMoss@kiscosl.com'

UNION ALL

SELECT 'Home Office' AS ksl_name
	,u.fullname
	,internalemailaddress description
	,'27C35920-B2DE-E211-9163-0050568B37AC' ksl_communityid
	,'HO' AS ksl_shortname
	,(
		SELECT max(amt)
		FROM kiscocustom..PIP_FinalCommission
		WHERE sd = u.fullname
			AND month(dt) = month(@AsOfDate)
			AND year(dt) = year(@AsOfDate)
			AND shortname = 'HO'
		) AS FinalAmount1
	,(
		SELECT Max(Notes)
		FROM kiscocustom..PIP_FinalCommission
		WHERE sd = u.fullname
			AND month(dt) = month(@AsOfDate)
			AND year(dt) = year(@AsOfDate)
			AND shortname = 'HO'
		) AS Notes
FROM systemuser u
WHERE (
		u.ksl_communityid = @comm
		OR @comm = '27C35920-B2DE-E211-9163-0050568B37AC'
		)
	AND (
		u.title LIKE '%Sales Specialist%'
		--OR internalemailaddress in ( select description from  ksldb252.datawarehouse.dbo.budgets where Community = 'HO')
		)
	AND u.islicensed = 1
ORDER BY ShortName
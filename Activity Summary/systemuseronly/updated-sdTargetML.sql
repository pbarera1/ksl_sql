USE DataWarehouse
declare @DimUserFullName varchar (100)
set @DimUserFullName = 'Michelle Taylor'
SELECT x.GroupedShortName,
	z.fullname,
	x.SDs,
	y.budget,
	d.NRRbudget,
	CEILING(cast(budget AS FLOAT) / cast(SDs AS FLOAT)) AS SDtarget,
	d.NRRbudget SDtargetNRR
FROM (
	SELECT c.GroupedShortName,
		count(*) SDs
	FROM Dim_Associate a
	LEFT JOIN Dim_Community c ON a.Location = c.Community
	WHERE [Hire_Date] <= getdate()
		AND [Termination_Date] >= getdate()
		AND job LIKE '%Sales Director'
		AND [Groupedksl_communityId] IS NOT NULL
	GROUP BY GroupedShortName
	) x
INNER JOIN (
	SELECT CASE 
			WHEN [Community] LIKE 'CNH.HC'
				THEN 'CNH'
			WHEN [Community] LIKE 'LPEX'
				THEN 'LP'
			ELSE [Community]
			END [Community],
		sum(cast([Budget] AS FLOAT)) budget
	FROM [DataWarehouse].[dbo].[Budgets]
	WHERE (
			[Description] = 'Move In'
			OR [Description] = 'Move-In'
			)
		AND DATEPART(YEAR, dt) = DATEPART(YEAR, EOMONTH(dateadd(day, - 1, getdate())))
		AND DATEPART(m, dt) = DATEPART(m, EOMONTH(dateadd(day, - 1, getdate())))
	GROUP BY CASE 
			WHEN [Community] LIKE 'CNH.HC'
				THEN 'CNH'
			WHEN [Community] LIKE 'LPEX'
				THEN 'LP'
			ELSE [Community]
			END
	) y ON x.GroupedShortName = y.Community
INNER JOIN (
	SELECT c.GroupedShortName Community,
		sum(cast([Budget] AS FLOAT)) NRRbudget
	FROM ksldb252.DataWarehouse.dbo.budgets b
	INNER JOIN ksldb252.DataWarehouse.dbo.dim_community c ON b.Community = c.shortname
	LEFT JOIN KiscoCustom.dbo.Associate a ON a.USR_Email = b.description
	WHERE
		--a.fullname = @DimUserFullName	
		LTRIM(RTRIM(a.USR_First + ' ' + a.USR_Last)) = replace(substring(ltrim(rtrim(@DimUserFullName)), 25, 100), ']', '')
		AND b.description LIKE '%kiscosl.com%' --'New Base Rent + Comm Fees'
		AND DATEPART(YEAR, dt) = DATEPART(YEAR, EOMONTH(dateadd(day, - 1, getdate())))
		AND DATEPART(m, dt) = DATEPART(m, EOMONTH(dateadd(day, - 1, getdate())))
	GROUP BY c.GroupedShortName
	) d ON x.GroupedShortName = d.Community
INNER JOIN (
	SELECT c.GroupedShortName,
		fullname
	FROM [DataWarehouse].[dbo].[Dim_User] a
	LEFT JOIN Dim_Community c ON a.[ksl_CommunityIdName] COLLATE DATABASE_DEFAULT = c.Community COLLATE DATABASE_DEFAULT
	WHERE isUserActive = 'yes'
	--  and title like '%Sales Director'
	GROUP BY GroupedShortName,
		fullname
	) z ON x.GroupedShortName = z.GroupedShortName
	AND fullname = replace(substring(ltrim(rtrim(@DimUserFullName)), 25, 100), ']', '')
	--and fullname = @DimUserFullName
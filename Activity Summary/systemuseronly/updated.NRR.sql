--DECLARE @DimUserFullName NVARCHAR(4000) = '[Dim_User].[FullName].&[Mike Jacobs]';

SELECT convert(VARCHAR(50), month(isnull(ksl_BeginDate, est.ksl_schfinanmovein))) + '/1/' + convert(VARCHAR(50), year(isnull(ksl_BeginDate, est.ksl_schfinanmovein))) AS dt,
	isnull(sum(ksl_ACT_CommTransFee + new_ApartmentRate - ISNULL(est.ksl_ACT_CommTransFeeSpecial, 0)), 0) AS RentRev,
	(
		SELECT sum(convert(DECIMAL, budget)) AS budget
		FROM ksldb252.DataWarehouse.dbo.budgets b
		INNER JOIN ksldb252.DataWarehouse.dbo.dim_community c ON b.Community = c.shortname
		INNER JOIN KiscoCustom.dbo.Associate a ON a.USR_Email = b.description
		WHERE a.USR_First + ' ' + a.USR_Last IN (replace(substring(ltrim(rtrim(@DimUserFullName)), 25, 100), ']', ''))
			AND month(isnull(ksl_BeginDate, est.ksl_schfinanmovein)) = month(b.dt)
			AND year(isnull(ksl_BeginDate, est.ksl_schfinanmovein)) = year(b.dt)
			AND a.USR_Active = 1
		) budget
FROM (
	SELECT afh.ksl_BeginDate,
		afh.ksl_ApartmentId,
		afh.ksl_ApartmentIdName,
		afh.ksl_CommunityId
		--,afh.AccountId
		,
		afh.ksl_communityIdName,
		afh.ksl_accountLeadId,
		MAX(afh.ksl_endDate) AS EndDt,
		afh.ksl_estimateId,
		afh.ksl_BeginTransactionType,
		MAX(afh.ksl_EndTransactionType) ksl_EndTransactionType,
		MAX(afh.ksl_ReasonDetailIDName) AS ksl_ReasonDetailIDName,
		MAX(afh.ksl_MoveOutDestinationIdName) AS ksl_MoveOutDestinationIdName,
		MAX(afh.OwnerId) AS afh_OwnerID
		--,LEA.ksl_ReasonDetailIdName AS ReasonDetail
		,
		MAX(ksl_MoveOutReasonDetailIdName) AS MoveOutReasonDetail
	FROM kslcloud_mscrm.dbo.ksl_apartmentfinancialhistory afh WITH (NOLOCK) --history of what happened 
	LEFT JOIN kslcloud_mscrm.dbo.account A WITH (NOLOCK) ON a.AccountID = ksl_accountleadid
	LEFT JOIN kslcloud_mscrm.dbo.Quote q WITH (NOLOCK) ON q.QuoteID = ksl_estimateid
	WHERE (
			afh.ksl_BeginTransactionType IN (
				864960001,
				864960003,
				864960007,
				864960008
				) -- 01=Actual Move In, 03=Actual Transfer In, Scheduled Transfer, Scheduled Move In
			AND afh.statecode = 0
			AND (
				afh.ksl_EndTransactionType IN (
					864960004,
					864960006,
					864960002,
					864960005
					)
				OR afh.ksl_EndTransactionType IS NULL
				)
			) -- Actual Transfer Out, Actual move out, Scheduled Transfer,Scheduled move out
		OR (
			afh.ksl_BeginTransactionType = 864960000
			AND afh.statecode = 0
			AND afh.ksl_EndTransactionType IS NULL
			AND CAST(afh.ksl_BeginDate AS DATE) >= CAST(GETDATE() - 15 AS DATE)
			)
	GROUP BY afh.ksl_BeginDate,
		afh.ksl_ApartmentId,
		afh.ksl_accountLeadId,
		afh.ksl_estimateId,
		afh.ksl_BeginTransactionType,
		afh.ksl_ApartmentIdName,
		afh.ksl_CommunityId
		--,afh.AccountId
		,
		afh.ksl_communityIdName
	) AS y
FULL OUTER JOIN kslcloud_mscrm.dbo.[Quote] est ON QuoteID = ksl_estimateId
LEFT JOIN kslcloud_mscrm.dbo.account A WITH (NOLOCK) ON a.accountid = est.customerid
WHERE coalesce(CASE 
			WHEN y.ksl_BeginTransactionType = 864960001
				THEN 'Actual Move in'
			WHEN y.ksl_BeginTransactionType = 864960003
				THEN 'Actual Transfer In'
			WHEN y.ksl_BeginTransactionType = 864960007
				THEN 'Short Term Stay Begin'
			WHEN y.ksl_BeginTransactionType = 864960008
				THEN 'Seasonal Stay Begin'
			WHEN y.ksl_BeginTransactionType = 864960000
				THEN 'Scheduled Move in'
					--ELSE 'Other'
			END, est.ksl_estimatetype_displayname) IN (
		'Actual Move in',
		'Moved In'
		)
	AND a.owneridname IN (replace(substring(ltrim(rtrim(@DimUserFullName)), 25, 100), ']', ''))
	AND isnull(ksl_BeginDate, est.ksl_schfinanmovein) BETWEEN DateAdd(Year, - 1, DateAdd(Month, DateDiff(Month, 0, GetDate()), 0) - 1) + 1
		AND getdate()
GROUP BY year(isnull(ksl_BeginDate, est.ksl_schfinanmovein)),
	month(isnull(ksl_BeginDate, est.ksl_schfinanmovein))
	--select * from kslcloud_mscrm.dbo.systemuser
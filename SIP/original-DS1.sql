USE KSLCLOUD_MSCRM_RESTORE_TEST;
DECLARE @AsOfDate DATE
DECLARE @comm UNIQUEIDENTIFIER
SET @AsOfDate = '3/31/25'
SET @comm = 'ef0600c1-95ba-ec11-983f-000d3a5c5e3e';

WITH t
AS (
	SELECT 'New Revenue IL' AS ID
		,avg(new_apartmentrate) AS apt_Rate
		,CASE 
			WHEN count(*) = 1
				THEN .1 * avg(new_apartmentrate + coalesce(ksl_dbloccfee, 0) + coalesce(q.MealFee, 0))
			WHEN count(*) = 2
				THEN (.1 * avg(new_apartmentrate + coalesce(ksl_dbloccfee, 0) + coalesce(q.MealFee, 0))) + (.15 * avg(new_apartmentrate + coalesce(ksl_dbloccfee, 0) + coalesce(q.MealFee, 0)))
			WHEN count(*) = 3
				THEN (.1 * avg(new_apartmentrate + coalesce(ksl_dbloccfee, 0) + coalesce(q.MealFee, 0))) + (.15 * avg(new_apartmentrate + coalesce(ksl_dbloccfee, 0) + coalesce(q.MealFee, 0))) + (.30 * avg(new_apartmentrate + coalesce(ksl_dbloccfee, 0) + coalesce(q.MealFee, 0)))
			WHEN count(*) = 4
				THEN (.1 * avg(new_apartmentrate + coalesce(ksl_dbloccfee, 0) + coalesce(q.MealFee, 0))) + (.15 * avg(new_apartmentrate + coalesce(ksl_dbloccfee, 0) + coalesce(q.MealFee, 0))) + (.30 * avg(new_apartmentrate + coalesce(ksl_dbloccfee, 0) + coalesce(q.MealFee, 0))) + (.40 * avg(new_apartmentrate + coalesce(ksl_dbloccfee, 0) + coalesce(q.MealFee, 0)))
			ELSE (.1 * avg(new_apartmentrate + coalesce(ksl_dbloccfee, 0) + coalesce(q.MealFee, 0))) + (.15 * avg(new_apartmentrate + coalesce(ksl_dbloccfee, 0) + coalesce(q.MealFee, 0))) + (.30 * avg(new_apartmentrate + coalesce(ksl_dbloccfee, 0) + coalesce(q.MealFee, 0))) + (.40 * avg(new_apartmentrate + coalesce(ksl_dbloccfee, 0) + coalesce(q.MealFee, 0))) + (.50 * (avg(new_apartmentrate + coalesce(ksl_dbloccfee, 0) + coalesce(q.MealFee, 0)) * (count(*) - 4)))
			END AS amt
		,sum((coalesce(q.ksl_act_commtransfee, 0) - coalesce(q.ksl_act_commtransfeespecial, 0))) * .1 AS Community_Fee
		,max(account.ksl_soldbyname) AS OWNER
		,account.ksl_soldby AS ownerid
		,max(a.ksl_communityidname) AS Community
		,a.ksl_communityid
		,count(*) AS cnt
	FROM (
		SELECT q.*
			,coalesce(o1.ksl_amount, 0) + coalesce(o2.ksl_amount, 0) + coalesce(o3.ksl_amount, 0) + coalesce(o4.ksl_amount, 0) + coalesce(o5.ksl_amount, 0) + coalesce(o6.ksl_amount, 0) MealFee
		FROM (
			SELECT *
			FROM quote
			WHERE ksl_respitestay_displayname = 'No'
			) q
		LEFT JOIN ksl_otherrates o1 ON o1.ksl_otherratesid = new_otherfee1
			AND o1.ksl_communityid = q.ksl_communityid
			AND o1.ksl_name LIKE '%*%'
		LEFT JOIN ksl_otherrates o2 ON o2.ksl_otherratesid = new_otherfee2
			AND o2.ksl_communityid = q.ksl_communityid
			AND o2.ksl_name LIKE '%*%'
		LEFT JOIN ksl_otherrates o3 ON o3.ksl_otherratesid = new_otherfee3
			AND o3.ksl_communityid = q.ksl_communityid
			AND o3.ksl_name LIKE '%*%'
		LEFT JOIN ksl_otherrates o4 ON o4.ksl_otherratesid = new_otherfee4
			AND o4.ksl_communityid = q.ksl_communityid
			AND o4.ksl_name LIKE '%*%'
		LEFT JOIN ksl_otherrates o5 ON o5.ksl_otherratesid = new_otherfee5
			AND o5.ksl_communityid = q.ksl_communityid
			AND o5.ksl_name LIKE '%*%'
		LEFT JOIN ksl_otherrates o6 ON o6.ksl_otherratesid = new_otherfee6
			AND o6.ksl_communityid = q.ksl_communityid
			AND o6.ksl_name LIKE '%*%'
		) q
	INNER JOIN ksl_apartment a ON q.ksl_apartmentid = a.ksl_apartmentid
	INNER JOIN account ON account.accountid = q.customerid
	WHERE ksl_estimatetype_displayname IN (
			'Moved In'
			,'Actual Move in'
			)
		AND month(convert(DATE, ksl_schfinanmovein)) = month(@AsOfDate)
		AND year(convert(DATE, ksl_schfinanmovein)) = year(@AsOfDate)
		AND (
			a.ksl_leveloflivingidname IN (
				'Independent Living'
				,'Cottages'
				)
			OR (
				a.ksl_leveloflivingidname IN (
					'Assisted Living'
					,'Memory Care'
					,'Skilled Nursing'
					)
				AND (
					(
						(
							ksl_carelevelidname IN (
								'Independent Living'
								,'No Care'
								,'Assisted Living No Care'
								,'Assited Living No Care'
								)
							OR ksl_carelevelidname IS NULL
							)
						AND (
							(
								ksl_careleveli2dname IN (
									'Independent Living'
									,'No Care'
									,'Assisted Living No Care'
									,'Assited Living No Care'
									)
								OR q.ksl_careleveli2dname IS NULL
								)
							)
						)
					)
				)
			)
		AND (
			account.ksl_initialsourcecategoryname <> 'Paid Referral Agency'
			OR account.ksl_initialsourcecategoryname IS NULL
			)
		AND q.ksl_communityid <> '119C1A08-0142-E511-96FE-0050568B37AC' -- LP
		AND (
			account.ksl_affordablehousing = 0
			OR account.ksl_affordablehousing IS NULL
			) -- No Affordable Housing
	GROUP BY account.ksl_soldby
		,a.ksl_communityid
	--New Revenue AL_________________________________________________________________________________________________________________
	
	UNION ALL
	
	SELECT 'New Revenue AL'
		,avg(new_apartmentrate)
		,CASE 
			WHEN count(*) = 1
				THEN 350
			WHEN count(*) = 2
				THEN 350 + 450
			WHEN count(*) = 3
				THEN 350 + 450 + 550
			WHEN count(*) = 4
				THEN 350 + 450 + 550 + 650
			ELSE 350 + 450 + 550 + 650 + (750 * (count(*) - 4))
			END AS amt
		,sum(coalesce(ksl_act_commtransfee, 0) - coalesce(ksl_act_commtransfeespecial, 0)) * .1 AS Community_Fee
		,max(account.ksl_soldbyname)
		,account.ksl_soldby AS ownerid
		,max(a.ksl_communityidname)
		,a.ksl_communityid
		,count(*) AS cnt
	FROM (
		SELECT *
		FROM quote
		WHERE ksl_respitestay_displayname = 'No'
		) q
	INNER JOIN ksl_apartment a ON q.ksl_apartmentid = a.ksl_apartmentid
	INNER JOIN account ON account.accountid = q.customerid
	WHERE ksl_estimatetype_displayname IN (
			'Moved In'
			,'Actual Move in'
			)
		AND month(convert(DATE, ksl_schfinanmovein)) = month(@AsOfDate)
		AND year(convert(DATE, ksl_schfinanmovein)) = year(@AsOfDate)
		AND a.ksl_leveloflivingidname NOT IN (
			'Independent Living'
			,'Cottages'
			,'Skilled Nursing'
			)
		AND (
			ksl_carelevelidname NOT IN (
				'Independent Living'
				,'No Care'
				,'Assisted Living No Care'
				,'Assited Living No Care'
				)
			AND ksl_carelevelidname IS NOT NULL
			OR ksl_careleveli2dname NOT IN (
				'Independent Living'
				,'No Care'
				,'Assisted Living No Care'
				,'Assited Living No Care'
				)
			AND ksl_careleveli2dname IS NOT NULL
			)
		AND (
			account.ksl_initialsourcecategoryname <> 'Paid Referral Agency'
			OR account.ksl_initialsourcecategoryname IS NULL
			)
		AND q.ksl_communityid <> '119C1A08-0142-E511-96FE-0050568B37AC' -- LP
		AND (
			account.ksl_affordablehousing = 0
			OR account.ksl_affordablehousing IS NULL
			) -- No Affordable Housing
	GROUP BY account.ksl_soldby
		,a.ksl_communityid
	
	UNION ALL
	
	--3rd Party Referrals_________________________________________________________________________________________________________________
	SELECT 'Third Party Referral Bonus'
		,avg(coalesce(ksl_act_commtransfee, 0) - coalesce(ksl_act_commtransfeespecial, 0))
		,(Count(*) * 300) AS amt
		,sum(coalesce(ksl_act_commtransfee, 0) - coalesce(ksl_act_commtransfeespecial, 0)) * .1 AS Community_Fee
		,max(account.ksl_soldbyname)
		,account.ksl_soldby AS ownerid
		,max(a.ksl_communityidname)
		,a.ksl_communityid
		,count(*) AS cnt
	FROM (
		SELECT *
		FROM quote
		WHERE ksl_respitestay_displayname = 'No'
		) q
	INNER JOIN ksl_apartment a ON q.ksl_apartmentid = a.ksl_apartmentid
	INNER JOIN account ON account.accountid = q.customerid
	WHERE ksl_estimatetype_displayname IN (
			'Moved In'
			,'Actual Move in'
			)
		AND month(convert(DATE, ksl_schfinanmovein)) = month(@AsOfDate)
		AND year(convert(DATE, ksl_schfinanmovein)) = year(@AsOfDate)
		AND account.ksl_initialsourcecategoryname = 'Paid Referral Agency'
		AND q.ksl_communityid <> '119C1A08-0142-E511-96FE-0050568B37AC' -- LP
		AND (
			account.ksl_affordablehousing = 0
			OR account.ksl_affordablehousing IS NULL
			) -- No Affordable Housing
	GROUP BY account.ksl_soldby
		,a.ksl_communityid
	--Qtly Bonus to target________________________________________________________________________________________________________________
	--union all
	--select 'Quarterly New Rent Revenue Bonus',sum(coalesce(ksl_act_commtransfee,0)-coalesce(ksl_act_commtransfeespecial,0)+coalesce(new_apartmentrate,0)), 
	--case 
	--	when sum(coalesce(ksl_act_commtransfee,0)-coalesce(ksl_act_commtransfeespecial,0)+coalesce(new_apartmentrate,0)) > (select sum(convert(float,budget)) from ksldb252.datawarehouse.dbo.budgets b inner join systemuser u on b.description = u.internalemailaddress
	--where  b.dt >= DATEADD(qq, DATEDIFF(qq, 0, @AsOfDate), 0) and b.dt <= DATEADD (dd, -1, DATEADD(qq, DATEDIFF(qq, 0, @AsOfDate) +1, 0)) and u.systemuserid = account.ksl_soldby
	--) then  3750
	--	else 0
	--End as amt
	--,0 as Community_Fee
	--,max(account.ksl_soldbyname),account.ksl_soldby as ownerid,max(a.ksl_communityidname),a.ksl_communityid,count(*) as cnt
	--from quote q  inner join ksl_apartment a on q.ksl_apartmentid = a.ksl_apartmentid inner join account on account.accountid = q.customerid
	--where ksl_estimatetype_displayname in ('Moved In','Actual Move in')   
	--and ksl_schfinanmovein >= DATEADD(qq, DATEDIFF(qq, 0, @AsOfDate), 0) and ksl_schfinanmovein <= DATEADD (dd, -1, DATEADD(qq, DATEDIFF(qq, 0, @AsOfDate) +1, 0))
	--and @AsOfDate = DATEADD (dd, -1, DATEADD(qq, DATEDIFF(qq, 0, @AsOfDate) +1, 0))
	--and q.ksl_communityid <> '119C1A08-0142-E511-96FE-0050568B37AC' -- LP
	--group by account.ksl_soldby,a.ksl_community
	
	UNION ALL
	
	SELECT 'Monthly Community Fee Bonus'
		,sum(ksl_act_commtransfee - ksl_act_commtransfeespecial + coalesce(new_apartmentrate, 0))
		,sum(coalesce(ksl_act_commtransfee, 0) - coalesce(ksl_act_commtransfeespecial, 0)) * .1 AS amt
		,0 AS Community_Fee
		,max(account.ksl_soldbyname)
		,account.ksl_soldby AS ownerid
		,max(a.ksl_communityidname)
		,a.ksl_communityid
		,count(*) AS cnt
	FROM (
		SELECT *
		FROM quote
		WHERE ksl_respitestay_displayname = 'No'
		) q
	INNER JOIN ksl_apartment a ON q.ksl_apartmentid = a.ksl_apartmentid
	INNER JOIN account ON account.accountid = q.customerid
	WHERE ksl_estimatetype_displayname IN (
			'Moved In'
			,'Actual Move in'
			)
		AND month(convert(DATE, ksl_schfinanmovein)) = month(@AsOfDate)
		AND year(convert(DATE, ksl_schfinanmovein)) = year(@AsOfDate)
		AND q.ksl_communityid <> '119C1A08-0142-E511-96FE-0050568B37AC' -- LP
		AND (
			account.ksl_affordablehousing = 0
			OR account.ksl_affordablehousing IS NULL
			) -- No Affordable Housing
	GROUP BY account.ksl_soldby
		,a.ksl_communityid
	
	UNION ALL
	
	SELECT 'Monthly Community Fee Bonus'
		,0 AS apt_Rate
		,0 AS amt
		,0 AS Community_Fee
		,[FullName] COLLATE SQL_Latin1_General_CP1_CI_AS
		,[SystemUserId]
		,ksl_communityidname COLLATE SQL_Latin1_General_CP1_CI_AS
		,ksl_communityid
		,0 AS cnt
	FROM [DataWarehouse].[dbo].[Dim_User]
	WHERE isUserActive = 'Yes'
		AND ksl_communityid = '119C1A08-0142-E511-96FE-0050568B37AC' -- LP
		AND Title IN ('Sales Director')
	)
SELECT t.*
	,ksl_shortname
	,(
		SELECT max(amt)
		FROM kiscocustom..PIP_FinalCommission
		WHERE sd = convert(VARCHAR(100), ownerid)
			AND month(dt) = month(@AsOfDate)
			AND year(dt) = year(@AsOfDate)
			AND shortname = ksl_shortname
		) AS FinalAmount
	,(
		SELECT max(Notes)
		FROM kiscocustom..PIP_FinalCommission
		WHERE sd = convert(VARCHAR(100), ownerid)
			AND month(dt) = month(@AsOfDate)
			AND year(dt) = year(@AsOfDate)
			AND shortname = ksl_shortname
		) AS Notes
FROM t
INNER JOIN ksl_community c ON t.ksl_communityid = c.ksl_communityid
JOIN DataWarehouse..Dim_Community dc ON c.ksl_communityid = dc.ksl_communityid
INNER JOIN KiscoCustom.dbo.Associate u ON u.SalesAppID = ownerid
LEFT JOIN KiscoCustom.dbo.KSL_Roles r -- UPDATED (get role name for title filtering)
	ON r.RoleID = u.RoleID
WHERE (
		t.ksl_communityid = @comm
		OR (
			@comm = '27C35920-B2DE-E211-9163-0050568B37AC'
			AND isactivecommunity = 'yes'
			)
		)
	AND r.Name NOT LIKE '%resident%'
	AND r.Name NOT LIKE '%hospitality%'
--and  ( ksl_communityid  not in ('39C35920-B2DE-E211-9163-0050568B37AC','29C35920-B2DE-E211-9163-0050568B37AC','119C1A08-0142-E511-96FE-0050568B37AC'))
ORDER BY community
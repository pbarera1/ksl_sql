--use KSLCLOUD_MSCRM_RESTORE_TEST
--declare @AsOfDate Date = '01-01-2025';

SELECT c.ksl_name
	,u.fullname
	,count(*)
FROM ksldb252.datawarehouse.dbo.budgets b
INNER JOIN KiscoCustom.dbo.Associate u ON b.description = u.USR_Email
INNER JOIN ksl_community c ON c.ksl_shortname = b.community
WHERE b.dt >= DATEADD(qq, DATEDIFF(qq, 0, @AsOfDate), 0)
	AND b.dt <= DATEADD(dd, - 1, DATEADD(qq, DATEDIFF(qq, 0, @AsOfDate) + 1, 0))
	AND budget = '0'
GROUP BY c.ksl_name
	,u.fullname
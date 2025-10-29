USE KSLCLOUD_MSCRM_RESTORE_TEST;
DECLARE @DimUserFullName NVARCHAR(4000) = '[Dim_User].[FullName].&[Mike Jacobs]';

SELECT count(b.activityid) AS PastDueActivityCount
FROM (
	SELECT 
        PC.Subject,
		PC.ActivityTypeCode,
		PC.activitytypecode AS ActivityTypeDetail,
		PC.regardingobjectid,
		PC.scheduledstart as scheduledend,
		PC.description AS notes,
		PC.activityid,
		PC.ownerid
		--U.USR_First + ' ' + U.USR_Last AS OwnerIDname
	FROM KSLCLOUD_MSCRM_RESTORE_TEST.dbo.activities PC WITH (NOLOCK)
	--JOIN KiscoCustom.dbo.Associate U ON U.SalesAppID = PC.OwnerID
	WHERE PC.activitytypecode IN ('Outbound Phone Call', 'Incoming Phone Call', 'Committed Face Appointment', 'Unscheduled Walk-In', 'Task', 'Inbound Email', 'Outbound Email', 'Draft Email')
		AND PC.statuscode_displayname <> 'Completed'
		AND PC.ksl_resultoptions_displayname <> 'Reactivate Call'
		--AND PC.ksl_emailtype <> '864960004' -- not an email type anymore
	) AS b
INNER JOIN account A WITH (NOLOCK) ON A.accountid = b.regardingobjectid
INNER JOIN KiscoCustom.dbo.Associate U ON U.SalesAppID = A.OwnerID
LEFT JOIN ksl_community C ON C.ksl_communityId = A.ksl_CommunityId
WHERE CONVERT(DATE, dateadd(hour, C.ksl_UTCTimeAdjust, b.scheduledend)) < CONVERT(DATE, getdate())
	AND U.USR_First + ' ' + U.USR_Last = replace(substring(ltrim(rtrim(@DimUserFullName)), 25, 100), ']', '')
	AND a.statuscode_displayname = 'Lead'
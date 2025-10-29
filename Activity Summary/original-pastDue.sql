USE KSLCLOUD_MSCRM_RESTORE_TEST;
DECLARE @DimUserFullName NVARCHAR(4000) = '[Dim_User].[FullName].&[Mike Jacobs]';

SELECT count(b.activityid) AS PastDueActivityCount
FROM (
	SELECT PC.Subject,
		PC.ActivityTypeCode,
		PC.ksl_phonecalltype AS ActivityTypeDetail,
		PC.regardingobjectid,
		PC.scheduledend,
		PC.description AS notes,
		PC.activityid,
		PC.ownerid,
		PC.OwnerIDname
	FROM PhoneCall PC WITH (NOLOCK)
	WHERE --PC.actualend IS NULL AND PC.scheduledend IS NOT NULL
		PC.statecode_displayname <> 'Completed'
		AND PC.ksl_phonecalltype <> '864960003'
	
	UNION ALL
	
	SELECT PC.Subject,
		PC.ActivityTypeCode,
		PC.ksl_appointmenttype AS ActivityTypeDetail,
		PC.regardingobjectid,
		PC.scheduledstart AS scheduledend,
		PC.description AS notes,
		PC.activityid,
		PC.ownerid,
		PC.OwnerIDname
	FROM appointment PC WITH (NOLOCK)
	WHERE PC.statecode_displayname <> 'Completed'
	
	UNION ALL
	
	SELECT PC.Subject,
		PC.ActivityTypeCode,
		NULL AS ActivityTypeDetail,
		PC.regardingobjectid,
		PC.scheduledend,
		PC.description AS notes,
		PC.activityid,
		PC.ownerid,
		PC.OwnerIDname
	FROM task PC
	WHERE PC.statecode_displayname <> 'Completed'
	
	UNION ALL
	
	SELECT PC.Subject,
		PC.ActivityTypeCode,
		PC.ksl_emailtype AS ActivityTypeDetail,
		PC.regardingobjectid,
		PC.scheduledend,
		PC.description AS notes,
		PC.activityid,
		PC.ownerid,
		PC.OwnerIDname
	FROM email PC WITH (NOLOCK)
	WHERE PC.statecode_displayname <> 'Completed'
		AND PC.ksl_emailtype <> '864960004'
	) AS b
INNER JOIN account A WITH (NOLOCK) ON A.accountid = b.regardingobjectid
INNER JOIN SystemUser U ON U.SystemUserId = A.OwnerID
LEFT JOIN ksl_community C ON C.ksl_communityId = A.ksl_CommunityId
WHERE CONVERT(DATE, dateadd(hour, C.ksl_UTCTimeAdjust, b.scheduledend)) < CONVERT(DATE, getdate())
	AND b.OwnerIDname = replace(substring(ltrim(rtrim(@DimUserFullName)), 25, 100), ']', '')
	AND a.statuscode_displayname = 'Lead'
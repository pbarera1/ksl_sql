--USE KSLCLOUD_MSCRM;
--DECLARE @DimUserFullName NVARCHAR(4000) = 'robin howland';
WITH LastContact
AS (
	SELECT b.accountid,
		--Get Last Contact Activity Information
		b.Subject AS ActivitySubject,
		b.ActivityTypeCode AS LCType,
		b.ActivityTypeDetail AS LCTypeDetail,
		b.regardingobjectid,
		b.CompletedDate AS LastContactDate,
		b.notes AS LCNotes
	FROM (
		SELECT L.accountid,
			PC.Subject,
			PC.ActivityTypeCode,
			PC.ksl_phonecalltype AS ActivityTypeDetail,
			PC.regardingobjectid,
			PC.ksl_datecompleted AS CompletedDate,
			left(PC.description, 300) AS notes
		FROM Account L WITH (NOLOCK)
		INNER JOIN PhoneCall PC WITH (NOLOCK) ON PC.RegardingObjectId = L.accountid
		WHERE PC.statecode_displayname = 'Completed' --Workflow changed call to completed
			AND PC.ksl_resultoptions = '864960007' --Result: Completed
		
		UNION ALL
		
		SELECT L.accountid,
			PC.Subject,
			PC.ActivityTypeCode,
			PC.ksl_appointmenttype AS ActivityTypeDetail,
			PC.regardingobjectid,
			PC.scheduledstart AS CompletedDate,
			left(PC.description, 300) AS notes
		FROM Account L WITH (NOLOCK)
		INNER JOIN appointment PC WITH (NOLOCK) ON PC.RegardingObjectId = L.accountid
		WHERE PC.statecode_displayname = 'Completed'
			AND PC.ksl_resultoptions IN (
				'864960005',
				'864960004',
				'864960006'
				) --Result: 864960005:Completed  864960004:Community Experience  864960006: Virtual Experience
		
		UNION ALL
		
		SELECT L.accountid,
			PC.Subject,
			PC.ActivityTypeCode,
			PC.ksl_emailtype AS ActivityTypeDetail,
			PC.regardingobjectid,
			PC.actualend AS CompletedDate,
			left(PC.description, 300) AS notes
		FROM Account L WITH (NOLOCK)
		INNER JOIN email PC WITH (NOLOCK) ON PC.RegardingObjectId = L.accountid
		WHERE PC.statecode_displayname = 'Completed'
			AND PC.ksl_emailtype = '864960001' --incoming
			--Union All
			--SELECT L.accountid, RIGHT(PC.Subject, LEN(PC.Subject) - 13) as [Subject], 'sms' as ActivityTypeCode, NULL as ActivityTypeDetail, PC.regardingobjectid, PC.actualend as CompletedDate, left(PC.description,300) as notes
			--FROM Account L WITH (NOLOCK)
			--INNER JOIN txtsync_sms PC ON PC.RegardingObjectId = L.accountid
			--WHERE  
			--[from] <> '' --incoming sms
		) AS b
	),
NextActivity
AS (
	SELECT b.accountid,
		--Get Next Activity Information
		b.Subject AS ActivitySubject,
		b.ActivityTypeCode AS NAType,
		b.ActivityTypeDetail AS NATypeDetail,
		b.regardingobjectid,
		b.scheduledend AS NextActivityDate,
		b.notes AS NANotes,
		b.activityid AS NAActivityid,
		b.ownerid
	FROM (
		SELECT L.accountid,
			PC.Subject,
			PC.ActivityTypeCode,
			PC.ksl_phonecalltype AS ActivityTypeDetail,
			PC.regardingobjectid,
			PC.scheduledend,
			left(PC.description, 300) AS notes,
			PC.activityid,
			PC.ownerid
		FROM Account L WITH (NOLOCK)
		INNER JOIN PhoneCall PC WITH (NOLOCK) ON PC.RegardingObjectId = L.accountid
		WHERE --PC.actualend IS NULL AND PC.scheduledend IS NOT NULL
			PC.statecode_displayname <> 'Completed'
		
		UNION ALL
		
		SELECT L.accountid,
			PC.Subject,
			PC.ActivityTypeCode,
			PC.ksl_appointmenttype AS ActivityTypeDetail,
			PC.regardingobjectid,
			PC.scheduledstart AS scheduledend,
			left(PC.description, 300) AS notes,
			PC.activityid,
			PC.ownerid
		FROM Account L WITH (NOLOCK)
		INNER JOIN appointment PC WITH (NOLOCK) ON PC.RegardingObjectId = L.accountid
		WHERE PC.statecode_displayname <> 'Completed'
		
		UNION ALL
		
		SELECT L.accountid,
			PC.Subject,
			PC.ActivityTypeCode,
			NULL AS ActivityTypeDetail,
			PC.regardingobjectid,
			PC.scheduledend,
			left(PC.description, 300) AS notes,
			PC.activityid,
			PC.ownerid
		FROM Account L WITH (NOLOCK)
		INNER JOIN task PC ON PC.RegardingObjectId = L.accountid
		WHERE PC.statecode_displayname <> 'Completed'
		
		UNION ALL
		
		SELECT L.accountid,
			PC.Subject,
			PC.ActivityTypeCode,
			PC.ksl_lettertype AS ActivityTypeDetail,
			PC.regardingobjectid,
			PC.scheduledend,
			left(PC.description, 300) AS notes,
			PC.activityid,
			PC.ownerid
		FROM Account L WITH (NOLOCK)
		INNER JOIN letter PC WITH (NOLOCK) ON PC.RegardingObjectId = L.accountid
		WHERE PC.statecode_displayname <> 'Completed'
		
		UNION ALL
		
		SELECT L.accountid,
			PC.Subject,
			PC.ActivityTypeCode,
			PC.ksl_emailtype AS ActivityTypeDetail,
			PC.regardingobjectid,
			PC.scheduledend,
			left(PC.description, 300) AS notes,
			PC.activityid,
			PC.ownerid
		FROM Account L WITH (NOLOCK)
		INNER JOIN email PC WITH (NOLOCK) ON PC.RegardingObjectId = L.accountid
		WHERE PC.statecode_displayname <> 'Completed'
		) AS b
	),
LastAttempt
AS (
	SELECT b.accountid,
		--Get Last Attempt Information
		b.Subject AS ActivitySubject,
		b.ActivityTypeCode AS LAType,
		b.ActivityTypeDetail AS LATypeDetail,
		b.regardingobjectid,
		b.CompletedDate AS LastAttemptDate,
		b.notes AS LANotes
	FROM (
		SELECT L.accountid,
			PC.Subject,
			PC.ActivityTypeCode,
			PC.ksl_phonecalltype AS ActivityTypeDetail,
			PC.regardingobjectid,
			PC.ksl_datecompleted AS CompletedDate,
			left(PC.description, 300) AS notes
		FROM Account L WITH (NOLOCK)
		INNER JOIN PhoneCall PC WITH (NOLOCK) ON PC.RegardingObjectId = L.accountid
		WHERE PC.statecode_displayname = 'Completed' --Workflow changed call to completed
			AND PC.ksl_resultoptions <> '864960008' --Result: Anything but cancelled
		
		UNION ALL
		
		SELECT L.accountid,
			PC.Subject,
			PC.ActivityTypeCode,
			PC.ksl_appointmenttype AS ActivityTypeDetail,
			PC.regardingobjectid,
			PC.scheduledstart AS CompletedDate,
			left(PC.description, 300) AS notes
		FROM Account L WITH (NOLOCK)
		INNER JOIN appointment PC WITH (NOLOCK) ON PC.RegardingObjectId = L.accountid
		WHERE PC.statecode_displayname = 'Completed'
			AND PC.ksl_resultoptions <> '100000000' --Result: 100000000:Cancelled 
		
		UNION ALL
		
		SELECT L.accountid,
			PC.Subject,
			PC.ActivityTypeCode,
			PC.ksl_emailtype AS ActivityTypeDetail,
			PC.regardingobjectid,
			PC.actualend AS CompletedDate,
			left(PC.description, 300) AS notes
		FROM Account L WITH (NOLOCK)
		INNER JOIN email PC WITH (NOLOCK) ON PC.RegardingObjectId = L.accountid
		WHERE PC.statecode_displayname = 'Completed'
			AND PC.ksl_emailtype = '864960002' --Outgoing
		
		UNION ALL
		
		SELECT L.accountid,
			PC.Subject,
			PC.ActivityTypeCode,
			PC.ksl_lettertype AS ActivityTypeDetail,
			PC.regardingobjectid,
			PC.actualend AS CompletedDate,
			left(PC.description, 300) AS notes
		FROM Account L WITH (NOLOCK)
		INNER JOIN letter PC WITH (NOLOCK) ON PC.RegardingObjectId = L.accountid
		WHERE PC.statecode_displayname = 'Completed'
			--Union All
			--SELECT L.accountid, RIGHT(PC.Subject, LEN(PC.Subject) - 13) as [Subject], 'sms' as ActivityTypeCode, NULL as ActivityTypeDetail, PC.regardingobjectid, PC.actualend as CompletedDate, left(PC.description,300) as notes
			--FROM Account L WITH (NOLOCK)
			--INNER JOIN txtsync_sms PC ON PC.RegardingObjectId = L.accountid
		) AS b
	)
SELECT count(A.accountID) AS RADcount
FROM account A WITH (NOLOCK)
OUTER APPLY (
	SELECT TOP 1 *
	FROM NextActivity
	WHERE regardingobjectid = A.accountid
	ORDER BY NextActivity.NextActivityDate ASC
	) NA
OUTER APPLY (
	SELECT TOP 1 *
	FROM LastContact
	WHERE regardingobjectid = A.accountid
	ORDER BY LastContact.LastContactDate DESC
	) LC
OUTER APPLY (
	SELECT TOP 1 *
	FROM LastAttempt
	WHERE regardingobjectid = A.accountid
	ORDER BY LastAttempt.LastAttemptDate DESC
	) LA
LEFT JOIN SystemUser U ON U.SystemUserId = A.OwnerID
LEFT JOIN ksl_community C ON C.ksl_communityId = A.ksl_CommunityId
WHERE a.OwnerIDname = replace(substring(ltrim(rtrim(@DimUserFullName)), 25, 100), ']', '')
	AND a.statuscode_displayname = 'Lead'
	AND (
		a.ksl_mostrecentcommunityexperience < getdate() - 30
		OR a.ksl_mostrecentcommunityexperience IS NULL
		)
	AND a.ksl_initialinquirydate < getdate() - 30
	AND a.ksl_reservationfeetransactiondate IS NULL
	AND fullname NOT IN (
		'# Dynamic.Test',
		'INTEGRATION',
		'David Watkins',
		'Jonathan Sharp'
		)
	AND ksl_shortname IS NOT NULL
	AND ksl_shortname NOT IN (
		'KT',
		'VSA',
		'HW',
		'TW',
		'HO'
		)
	AND (
		0 <= CASE 
			WHEN a.ksl_moveintiming_displayname = '> 2 Years'
				THEN datediff(day, coalesce(LA.LastAttemptDate, getdate() - 90) + 90, getdate())
			WHEN ksl_mostrecentcommunityexperience >= getdate() - 120
				AND LC.LastContactDate > getdate() - 60
				AND (
					ksl_waitlisttransactiondate IS NULL
					AND a.ksl_waitlistenddate IS NOT NULL
					)
				THEN datediff(day, LA.LastAttemptDate + 14, getdate())
			WHEN ksl_mostrecentcommunityexperience >= getdate() - 270
				AND LC.LastContactDate > getdate() - 180
				AND (
					ksl_waitlisttransactiondate IS NULL
					AND a.ksl_waitlistenddate IS NOT NULL
					)
				THEN datediff(day, LA.LastAttemptDate + 45, getdate())
			WHEN ksl_losttocompetitoron IS NOT NULL
				AND (
					ksl_waitlisttransactiondate IS NULL
					AND a.ksl_waitlistenddate IS NOT NULL
					)
				THEN datediff(day, LA.LastAttemptDate + 180, getdate())
			ELSE datediff(day, coalesce(LA.LastAttemptDate, getdate() - 90) + 90, getdate())
			END
		OR CONVERT(DATE, dateadd(hour, C.ksl_UTCTimeAdjust, NA.NextActivityDate)) < CONVERT(DATE, getdate())
		)
USE KSLCLOUD_MSCRM_RESTORE_TEST;
DECLARE @DimUserFullName NVARCHAR(4000) = '[Dim_User].[FullName].&[Mike Jacobs]';
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
			PC.ActivityTypeCode AS ActivityTypeDetail,
			PC.regardingobjectid,
			PC.scheduledstart AS CompletedDate,
			left(PC.description, 300) AS notes
		FROM Account L WITH (NOLOCK)
		INNER JOIN KSLCLOUD_MSCRM_RESTORE_TEST.dbo.activities PC WITH (NOLOCK) ON PC.RegardingObjectId = L.accountid
		-- phonecall, appointment, inbound email - activities
		WHERE PC.activitytypecode IN ('Outbound Phone Call', 'Incoming Phone Call', 'Committed Face Appointment', 'Unscheduled Walk-In', 'Inbound Email')
			AND PC.statuscode_displayname = 'Completed'
			AND PC.ksl_resultoptions_displayname = 'Completed'
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
		b.scheduledstart AS NextActivityDate,
		b.notes AS NANotes,
		b.activityid AS NAActivityid,
		b.ownerid
	FROM (
		SELECT L.accountid,
			PC.Subject,
			PC.ActivityTypeCode,
			PC.ActivityTypeCode AS ActivityTypeDetail,
			PC.regardingobjectid,
			PC.scheduledstart,
			left(PC.description, 300) AS notes,
			PC.activityid,
			PC.ownerid
		FROM Account L WITH (NOLOCK)
		INNER JOIN KSLCLOUD_MSCRM_RESTORE_TEST.dbo.activities PC WITH (NOLOCK) ON PC.RegardingObjectId = L.accountid
		-- phonecall, appointment,letter, tasks, email - activities
		WHERE (PC.activitytypecode IN ('Outbound Phone Call', 'Incoming Phone Call', 'Committed Face Appointment', 'Unscheduled Walk-In', 'Letter', 'Task')
			OR (PC.activitytypecode LIKE '%email%'))
			AND PC.statuscode_displayname <> 'Completed'
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
			PC.ActivityTypeCode AS ActivityTypeDetail,
			PC.regardingobjectid,
			PC.scheduledstart AS CompletedDate,
			left(PC.description, 300) AS notes

		FROM Account L WITH (NOLOCK)
		INNER JOIN KSLCLOUD_MSCRM_RESTORE_TEST.dbo.activities PC WITH (NOLOCK) ON PC.RegardingObjectId = L.accountid
		WHERE (PC.activitytypecode IN ('Outbound Phone Call', 'Incoming Phone Call', 'Committed Face Appointment', 'Unscheduled Walk-In', 'Outbound Email', 'Letter')
			OR (PC.activitytypecode LIKE '%email%'))
			AND PC.statuscode_displayname = 'Completed'
			AND PC.ksl_resultoptions_displayname <> 'Cancelled'
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
LEFT JOIN KiscoCustom.dbo.Associate U ON U.SalesAppID = A.OwnerID
LEFT JOIN ksl_community C ON C.ksl_communityId = A.ksl_CommunityId
WHERE a.OwnerIDname = replace(substring(ltrim(rtrim(@DimUserFullName)), 25, 100), ']', '')
	AND a.statuscode_displayname = 'Lead'
	AND (
		a.ksl_mostrecentcommunityexperience < getdate() - 30
		OR a.ksl_mostrecentcommunityexperience IS NULL
		)
	AND a.ksl_initialinquirydate < getdate() - 30
	AND a.ksl_reservationfeetransactiondate IS NULL
	AND U.USR_First + ' ' + U.USR_Last NOT IN (
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
USE DataWarehouse;

DECLARE @c NVARCHAR(4000) = '119C1A08-0142-E511-96FE-0050568B37AC'; -- La Posada

SELECT
  fullname AS Label,
  CASE
    WHEN fullname LIKE 'Elizabeth Sykes'           THEN '[Dim_User].[FullName].&[Betsy Sykes]'
    WHEN fullname LIKE 'Carol Lowe'                THEN '[Dim_User].[FullName].&[Lynn Lowe]'
    WHEN fullname LIKE 'Leala Connors-Gillespie'   THEN '[Dim_User].[FullName].&[Leala Connors]'
    WHEN fullname LIKE 'Mary Romaine'              THEN '[Dim_User].[FullName].&[Abby Romaine]'
    WHEN fullname LIKE 'Michael Jacobs'            THEN '[Dim_User].[FullName].&[Mike Jacobs]'
    WHEN fullname LIKE 'Tesshanna Berry'           THEN '[Dim_User].[FullName].&[Tess Berry]'
    WHEN fullname LIKE 'Francisco Campos-Bautista' THEN '[Dim_User].[FullName].&[kiko Campos-Bautista]'
    WHEN fullname LIKE 'Sandra Wilson'             THEN '[Dim_User].[FullName].&[Sandie Wilson]'
    WHEN fullname LIKE 'Samantha Martin'           THEN '[Dim_User].[FullName].&[Sam Martin]'
    WHEN fullname LIKE 'Genevieve Wood'            THEN '[Dim_User].[FullName].&[Jen Wood]'
    ELSE CONCAT('[Dim_User].[FullName].&[', fullname, ']')
  END AS Filter,
  CASE
    WHEN fullname LIKE 'Genevieve Wood'   THEN 'EF0600C1-95BA-EC11-983F-000D3A5C5E3E'
    WHEN fullname LIKE 'Courtney Heyboer' THEN 'EF0600C1-95BA-EC11-983F-000D3A5C5E3E'
    WHEN fullname LIKE 'Samantha Martin'  THEN 'EF0600C1-95BA-EC11-983F-000D3A5C5E3E'
    ELSE [ksl_communityid]
  END AS [ksl_communityId]
FROM dim_user
WHERE systemuserid IN (
  SELECT DISTINCT ownerid
  FROM (
    SELECT a.ownerid
    FROM KSLCLOUD_MSCRM_RESTORE_TEST..activities a                      -- UPDATED: unified activities (replaces appointment/phonecall)
    LEFT JOIN KSLCLOUD_MSCRM_RESTORE_TEST..contact c
      ON c.contactid = a.regardingobjectid                              -- UPDATED: if activity still regards a Contact, pull it
    LEFT JOIN KSLCLOUD_MSCRM_RESTORE_TEST..ksl_referralorgs r
      ON r.ksl_referralorgsid = COALESCE(c.ksl_referralorgid,            -- UPDATED: resolve to Referral Org Account
                                         a.regardingobjectid)            -- UPDATED: if already Account-regarded, use it directly
    WHERE
      (
        (SELECT TOP 1 ksl_name
         FROM KSLCLOUD_MSCRM_RESTORE_TEST..ksl_community
         WHERE ksl_communityid IN (@c))
        IN (
          SELECT u1.name
          FROM KSLCLOUD_MSCRM_RESTORE_TEST..businessunit u
          LEFT JOIN KSLCLOUD_MSCRM_RESTORE_TEST..businessunitmap m
            ON u.businessunitid = m.businessid
          LEFT JOIN KSLCLOUD_MSCRM_RESTORE_TEST..businessunit u1
            ON u1.businessunitid = m.subbusinessid
          WHERE
            u.businessunitid = (
              SELECT TOP 1 businessunitid
              FROM KSLCLOUD_MSCRM_RESTORE_TEST..team
              WHERE teamid = r.ownerid
            )
            OR u.businessunitid = (
              SELECT ksl_regionalteamid
              FROM KSLCLOUD_MSCRM_RESTORE_TEST..systemuser
              WHERE systemuserid = r.ownerid
            )
        )
      )
      AND a.scheduledstart BETWEEN GETDATE() - 45 AND GETDATE() + 14      -- unchanged time window
      AND r.ksl_referralorgtypeidname <> 'Paid Referral Agency'           -- unchanged exclusion
      --AND a.activitytypecode LIKE '%face appointment%'
      --OR a.activitytypecode LIKE '%phone%'
      --OR a.activitytypecode LIKE 'walk-in%'
      --AND a.activitystatuscode IN ('Open','Scheduled','Completed')        -- UPDATED: scope by status using activities.activitystatuscode
      AND (c.statecode = 0 OR c.contactid IS NULL)                        -- UPDATED: keep “active contact” when applicable, allow account-regarded
  ) k
);

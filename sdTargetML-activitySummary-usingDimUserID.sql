USE DataWarehouse
DECLARE @DimUserOwnerID uniqueidentifier = '4AF48E66-DE53-E811-A951-000D3A3606DE'; -- Erika McMillin

SELECT
    x.GroupedShortName,
    z.fullname,
    x.SDs,
    y.budget,
    d.NRRbudget,
    CEILING(CAST(budget AS float) / CAST(SDs AS float)) AS SDtarget,
    d.NRRbudget AS SDtargetNRR
FROM (
    -- x: count of SDs per GroupedShortName
    SELECT
        c.GroupedShortName,
        COUNT(*) AS SDs
    FROM Dim_Associate a
    LEFT JOIN Dim_Community c
        ON a.Location = c.Community
    WHERE [Hire_Date] <= GETDATE()
      AND [Termination_Date] >= GETDATE()
      AND job LIKE '%Sales Director'
      AND [Groupedksl_communityId] IS NOT NULL
    GROUP BY GroupedShortName
) x

INNER JOIN (
    -- y: total Move-In budget per community for this month
    SELECT
        CASE
            WHEN [Community] LIKE 'CNH.HC' THEN 'CNH'
            WHEN [Community] LIKE 'LPEX'   THEN 'LP'
            ELSE [Community]
        END AS Community,
        SUM(CAST([Budget] AS float)) AS budget
    FROM [DataWarehouse].[dbo].[Budgets]
    WHERE ([Description] = 'Move In' OR [Description] = 'Move-In')
      AND DATEPART(YEAR, dt) = DATEPART(YEAR, EOMONTH(DATEADD(day,-1,GETDATE())))
      AND DATEPART(MONTH, dt) = DATEPART(MONTH, EOMONTH(DATEADD(day,-1,GETDATE())))
    GROUP BY
        CASE
            WHEN [Community] LIKE 'CNH.HC' THEN 'CNH'
            WHEN [Community] LIKE 'LPEX'   THEN 'LP'
            ELSE [Community]
        END
) y
    ON x.GroupedShortName = y.Community

INNER JOIN (
    -- d: NRR budget for the selected SD only (using OwnerID/Guid)
    SELECT
        c.GroupedShortName AS Community,
        SUM(CAST([Budget] AS float)) AS NRRbudget
    FROM ksldb252.DataWarehouse.dbo.budgets b
    INNER JOIN ksldb252.DataWarehouse.dbo.dim_community c
        ON b.Community = c.shortname
    LEFT JOIN DataWarehouse.dbo.Dim_User a
        ON a.internalemailaddress = b.description
    WHERE
        -- OLD (fullname-based):
        -- a.fullname = replace(substring(ltrim(rtrim(@DimUserFullName)),25,100),']','')
        -- NEW: filter by SystemUserId / OwnerID
        a.systemuserid = CONVERT(uniqueidentifier, @DimUserOwnerID)
        AND b.description LIKE '%kiscosl.com%'  -- 'New Base Rent + Comm Fees'
        AND DATEPART(YEAR, dt) = DATEPART(YEAR, EOMONTH(DATEADD(day,-1,GETDATE())))
        AND DATEPART(MONTH, dt) = DATEPART(MONTH, EOMONTH(DATEADD(day,-1,GETDATE())))
    GROUP BY c.GroupedShortName
) d
    ON x.GroupedShortName = d.Community

INNER JOIN (
    -- z: SDs by community from Dim_User, now including SystemUserId
    SELECT
        c.GroupedShortName,
        a.fullname,
        a.SystemUserId
    FROM [DataWarehouse].[dbo].[Dim_User] a
    LEFT JOIN Dim_Community c
        ON a.[ksl_CommunityIdName] COLLATE DATABASE_DEFAULT
         = c.Community COLLATE DATABASE_DEFAULT
    WHERE isUserActive = 'yes'
    GROUP BY
        c.GroupedShortName,
        a.fullname,
        a.SystemUserId
) z
    ON x.GroupedShortName = z.GroupedShortName
   -- OLD (fullname-based):
   -- AND z.fullname = REPLACE(SUBSTRING(LTRIM(RTRIM(@DimUserFullName)),25,100),']','')
   -- NEW: join on SystemUserId / OwnerID
   AND z.SystemUserId = CONVERT(uniqueidentifier, @DimUserOwnerID);

## Notes

## Migrations

Combining activities into one table
- KSLCLOUD_MSCRM database tables: ksl_sms, appointment, letter, phonecall, email, task are being combined into a new table: activities

The KSLCLOUD_MSCRM systemuser table will be moved to KiscoCustom.Associate, some items like title will need to be gathered via join to ksl_roles
- KISCOCLOUD_MSCRM.systemuser.systemuserid → KiscoCustom.Associate.SalesAppID
- KISCOCLOUD_MSCRM.systemuser.fullname → KiscoCustom.Associate.USR_First + ' ' +  KiscoCustom.Associate.USR_First.USR_Last
- KISCOCLOUD_MSCRM.systemuser.title → KiscoCustom.dbo.KSL_Roles.Name 

## Common Joins
```
   INNER JOIN [KiscoCustom].[dbo].[Associate] u
           ON u.SalesAppID = a.accountownerid
    JOIN KiscoCustom.dbo.KSL_Roles r on r.roleid = u.RoleID
    JOIN  KiscoCustom.dbo.Community as c ON c.CommunityIDY = u.USR_CommunityIDY
    JOIN KSLCLOUD_MSCRM_RESTORE_TEST.dbo.ksl_community as commCrm ON commCrm.ksl_communityid = c.CRM_CommunityID
   LEFT JOIN leads l
          ON commCrm.ksl_securityregionteamid = l.ksl_securityregionteamid
   LEFT JOIN nrr
          ON nrr.ksl_securityregionteamid = commCrm.ksl_securityregionteamid
   LEFT JOIN moveins mi
          ON mi.ksl_securityregionteamid = commCrm.ksl_securityregionteamid
   LEFT JOIN newrs nr
          ON nr.ownerid = u.SalesAppID
   LEFT JOIN resref rr
          ON rr.[ksl_associtateduser] = u.SalesAppID
          
   INNER JOIN kslcloud_mscrm_restore_test.dbo.activities PC WITH (nolock)
        ON PC.regardingobjectid = L.accountid
        
   Associate.SalesAppId = contact.contactid
JOIN KiscoCustom.dbo.KSL_Roles r on r.roleid = s.roleid

    FROM KSLCLOUD_MSCRM_RESTORE_TEST.dbo.Contact C WITH (NOLOCK)
    INNER JOIN KSLCLOUD_MSCRM_RESTORE_TEST.dbo.activities PC WITH (NOLOCK) 
        ON PC.RegardingObjectId = C.contactid
    LEFT JOIN KSLCLOUD_MSCRM_RESTORE_TEST.dbo.Account A 
        ON A.primarycontactid = C.contactid  -- Contacts roll up to accounts
    LEFT JOIN KiscoCustom.dbo.Associate Assoc ON PC.ownerid = Assoc.SalesAppID
```


Other Updates
- LIKE = 'Lead' or NOT LIKE = 'Do NOt contact%'
- appointment types are gone
- activities tie to an account via account.statuscodedisplayname = referral org (BD) or Lead (Sales)
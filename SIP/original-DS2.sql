declare @AsOfDate date
declare @comm uniqueidentifier
set @AsOfDate = '9/30/24'
set @comm = '27C35920-B2DE-E211-9163-0050568B37AC'  ;


select c.Community as ksl_name,
       u.fullname,
	   b.description,
       c.ksl_communityid,
       c.shortname as ksl_shortname,
       (
           select max(amt)
           from kiscocustom..PIP_FinalCommission
           where sd = u.fullname
                 and month(dt) = month(@AsOfDate)
                 and year(dt) = year(@AsOfDate)
                 and shortname = c.shortname
       ) as FinalAmount1,
	      (
           select Max(Notes)
           from kiscocustom..PIP_FinalCommission
           where sd = u.fullname
                 and month(dt) = month(@AsOfDate)
                 and year(dt) = year(@AsOfDate)
                 and shortname = c.shortname
       ) as Notes
from  ksldb252.datawarehouse.dbo.budgets  b
    inner join systemuser u
        on b.description = u.internalemailaddress
    inner join (select case when ShortName = 'KSL' then 'HO' else ShortName end AS ShortName, ksl_communityid, 
					case when Community = 'Kisco Senior Living, LLC' then 'Home Office' else Community end AS Community
				from datawarehouse.dbo.Dim_Community)  c
        on c.shortname = b.community
where month(convert(date, b.dt)) = month(@AsOfDate)
   --   and u.islicensed = 1
      and year(convert(date, b.dt)) = year(@AsOfDate)
      and budget = '0'
      and (
              c.ksl_communityid = @comm
              or @comm = '27C35920-B2DE-E211-9163-0050568B37AC'
          )

--and description = 'Rebekah.deMoss@kiscosl.com'

union all


select 'Home Office' as ksl_name,
       u.fullname,
	  internalemailaddress  description,
       '27C35920-B2DE-E211-9163-0050568B37AC' ksl_communityid,
       'HO' as ksl_shortname,
       (
           select max(amt)
           from kiscocustom..PIP_FinalCommission
           where sd = u.fullname
                 and month(dt) = month(@AsOfDate)
                 and year(dt) = year(@AsOfDate)
                and shortname = 'HO'
       ) as FinalAmount1,
	      (
           select Max(Notes)
           from kiscocustom..PIP_FinalCommission
           where sd = u.fullname
                 and month(dt) = month(@AsOfDate)
                 and year(dt) = year(@AsOfDate)
                 and shortname =  'HO'
       ) as Notes
from  systemuser u
where 
       (
              u.ksl_communityid = @comm
              or @comm = '27C35920-B2DE-E211-9163-0050568B37AC'
          )
	and ( u.title like '%Sales Specialist%'
			--OR internalemailaddress in ( select description from  ksldb252.datawarehouse.dbo.budgets where Community = 'HO')
		)
		
	and u.islicensed = 1


order by ShortName
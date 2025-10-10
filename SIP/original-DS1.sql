use KSLCLOUD_MSCRM;

declare @AsOfDate date
declare @comm uniqueidentifier
set @AsOfDate = '3/31/25'
set @comm = 'ef0600c1-95ba-ec11-983f-000d3a5c5e3e'  ;

with t as (
select 'New Revenue IL' as ID ,avg(new_apartmentrate) as apt_Rate, 
case 
	when count(*) = 1 then  .1 * avg(new_apartmentrate + coalesce(ksl_dbloccfee,0) + coalesce(q.MealFee,0))
	when count(*) = 2 then  (.1 * avg(new_apartmentrate + coalesce(ksl_dbloccfee,0) + coalesce(q.MealFee,0))) + (.15 * avg(new_apartmentrate + coalesce(ksl_dbloccfee,0) + coalesce(q.MealFee,0)))
	when count(*) = 3 then  (.1 * avg(new_apartmentrate + coalesce(ksl_dbloccfee,0) + coalesce(q.MealFee,0))) + (.15 * avg(new_apartmentrate + coalesce(ksl_dbloccfee,0) + coalesce(q.MealFee,0)))
			+ (.30 * avg(new_apartmentrate + coalesce(ksl_dbloccfee,0) + coalesce(q.MealFee,0)))
	when count(*) = 4 then  (.1 * avg(new_apartmentrate + coalesce(ksl_dbloccfee,0) + coalesce(q.MealFee,0))) + (.15 * avg(new_apartmentrate + coalesce(ksl_dbloccfee,0) + coalesce(q.MealFee,0)))
			+ (.30 * avg(new_apartmentrate + coalesce(ksl_dbloccfee,0) + coalesce(q.MealFee,0))) + (.40 * avg(new_apartmentrate + coalesce(ksl_dbloccfee,0) + coalesce(q.MealFee,0)))
	else (.1 * avg(new_apartmentrate + coalesce(ksl_dbloccfee,0) + coalesce(q.MealFee,0))) + (.15 * avg(new_apartmentrate + coalesce(ksl_dbloccfee,0) + coalesce(q.MealFee,0)))
			+ (.30 * avg(new_apartmentrate + coalesce(ksl_dbloccfee,0) + coalesce(q.MealFee,0))) + (.40 * avg(new_apartmentrate + coalesce(ksl_dbloccfee,0) + coalesce(q.MealFee,0))) 
			+ (.50 * (avg(new_apartmentrate + coalesce(ksl_dbloccfee,0) + coalesce(q.MealFee,0))*(count(*)-4)) )
End as amt
,sum((coalesce(q.ksl_act_commtransfee,0)- coalesce(q.ksl_act_commtransfeespecial,0)))*.1 as Community_Fee
,max(account.ksl_soldbyname) as owner,account.ksl_soldby as ownerid,max(a.ksl_communityidname) as Community,a.ksl_communityid,count(*) as cnt
from 
(select q.*,coalesce(o1.ksl_amount,0)+ coalesce(o2.ksl_amount,0)+ coalesce(o3.ksl_amount,0)
		+ coalesce(o4.ksl_amount,0)+ coalesce(o5.ksl_amount,0)+ coalesce(o6.ksl_amount,0) MealFee from (select * from quote where ksl_respitestay_displayname = 'No') q
left join ksl_otherrates o1 on o1.ksl_otherratesid = new_otherfee1 and o1.ksl_communityid = q.ksl_communityid  and o1.ksl_name like '%*%'
left join ksl_otherrates o2 on o2.ksl_otherratesid = new_otherfee2 and o2.ksl_communityid = q.ksl_communityid  and o2.ksl_name like '%*%'
left join ksl_otherrates o3 on o3.ksl_otherratesid = new_otherfee3 and o3.ksl_communityid = q.ksl_communityid  and o3.ksl_name like '%*%'
left join ksl_otherrates o4 on o4.ksl_otherratesid = new_otherfee4 and o4.ksl_communityid = q.ksl_communityid  and o4.ksl_name like '%*%'
left join ksl_otherrates o5 on o5.ksl_otherratesid = new_otherfee5 and o5.ksl_communityid = q.ksl_communityid  and o5.ksl_name like '%*%'
left join ksl_otherrates o6 on o6.ksl_otherratesid = new_otherfee6 and o6.ksl_communityid = q.ksl_communityid  and o6.ksl_name like '%*%') q 
inner join ksl_apartment a on q.ksl_apartmentid = a.ksl_apartmentid inner join account on account.accountid = q.customerid
where ksl_estimatetype_displayname in ('Moved In','Actual Move in') and  
	month(convert(date,ksl_schfinanmovein)) = month(@AsOfDate) and year(convert(date,ksl_schfinanmovein)) = year(@AsOfDate)
	and (a.ksl_leveloflivingidname in ('Independent Living','Cottages') 
					or (a.ksl_leveloflivingidname in ('Assisted Living','Memory Care','Skilled Nursing') 
						and					( ((ksl_carelevelidname in ('Independent Living', 'No Care','Assisted Living No Care','Assited Living No Care') or ksl_carelevelidname is null)
							AND ((ksl_careleveli2dname in ('Independent Living', 'No Care','Assisted Living No Care','Assited Living No Care') or q.ksl_careleveli2dname is null))
						))) )
					and (account.ksl_initialsourcecategoryname <> 'Paid Referral Agency' 
					or account.ksl_initialsourcecategoryname is null) 
	and q.ksl_communityid <> '119C1A08-0142-E511-96FE-0050568B37AC' -- LP
	and (account.ksl_affordablehousing = 0 or account.ksl_affordablehousing is null) -- No Affordable Housing
group by account.ksl_soldby,a.ksl_communityid

--New Revenue AL_________________________________________________________________________________________________________________

union all
select 'New Revenue AL',avg(new_apartmentrate), 
case 
	when count(*) = 1 then  350
	when count(*) = 2 then  350 + 450
	when count(*) = 3 then  350 + 450 + 550
	when count(*) = 4 then  350 + 450 + 550 + 650
	else 350 + 450 + 550 + 650 +  (750 * (count(*)-4))
End as amt
,sum(coalesce(ksl_act_commtransfee,0)-coalesce(ksl_act_commtransfeespecial,0))*.1 as Community_Fee
,max(account.ksl_soldbyname),account.ksl_soldby as ownerid,max(a.ksl_communityidname),a.ksl_communityid,count(*) as cnt
from (select * from quote where ksl_respitestay_displayname = 'No') q inner join ksl_apartment a on q.ksl_apartmentid = a.ksl_apartmentid inner join account on account.accountid = q.customerid
where ksl_estimatetype_displayname in ('Moved In','Actual Move in') and  
month(convert(date,ksl_schfinanmovein)) = month(@AsOfDate) and year(convert(date,ksl_schfinanmovein)) = year(@AsOfDate)
and a.ksl_leveloflivingidname not in ('Independent Living','Cottages', 'Skilled Nursing') 
and (ksl_carelevelidname not in ('Independent Living', 'No Care','Assisted Living No Care','Assited Living No Care') and  ksl_carelevelidname is not null
				 or ksl_careleveli2dname not in ('Independent Living', 'No Care','Assisted Living No Care','Assited Living No Care') and  ksl_careleveli2dname is not null)
and (account.ksl_initialsourcecategoryname <> 'Paid Referral Agency' or account.ksl_initialsourcecategoryname is null) 
and q.ksl_communityid <> '119C1A08-0142-E511-96FE-0050568B37AC' -- LP
and (account.ksl_affordablehousing = 0 or account.ksl_affordablehousing is null) -- No Affordable Housing
group by account.ksl_soldby,a.ksl_communityid



union all
--3rd Party Referrals_________________________________________________________________________________________________________________
select 'Third Party Referral Bonus',avg(coalesce(ksl_act_commtransfee,0)-coalesce(ksl_act_commtransfeespecial,0)), 
(Count(*)*300) as amt
,sum(coalesce(ksl_act_commtransfee,0)-coalesce(ksl_act_commtransfeespecial,0))*.1 as Community_Fee
,max(account.ksl_soldbyname),account.ksl_soldby as ownerid,max(a.ksl_communityidname),a.ksl_communityid,count(*) as cnt
from (select * from quote where ksl_respitestay_displayname = 'No') q inner join ksl_apartment a on q.ksl_apartmentid = a.ksl_apartmentid inner join account on account.accountid = q.customerid
where ksl_estimatetype_displayname in ('Moved In','Actual Move in') and  
month(convert(date,ksl_schfinanmovein)) = month(@AsOfDate) and year(convert(date,ksl_schfinanmovein)) = year(@AsOfDate)
and account.ksl_initialsourcecategoryname = 'Paid Referral Agency'
	and q.ksl_communityid <> '119C1A08-0142-E511-96FE-0050568B37AC' -- LP
	and (account.ksl_affordablehousing = 0 or account.ksl_affordablehousing is null) -- No Affordable Housing
	group by account.ksl_soldby,a.ksl_communityid

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


union all

select 'Monthly Community Fee Bonus',sum(ksl_act_commtransfee-ksl_act_commtransfeespecial+coalesce(new_apartmentrate,0)), 
sum(coalesce(ksl_act_commtransfee,0)-coalesce(ksl_act_commtransfeespecial,0))*.1 as amt
,0 as Community_Fee
,max(account.ksl_soldbyname),account.ksl_soldby as ownerid,max(a.ksl_communityidname),a.ksl_communityid,count(*) as cnt
from (select * from quote where ksl_respitestay_displayname = 'No') q  inner join ksl_apartment a on q.ksl_apartmentid = a.ksl_apartmentid inner join account on account.accountid = q.customerid
where ksl_estimatetype_displayname in ('Moved In','Actual Move in')   
and month(convert(date,ksl_schfinanmovein)) = month(@AsOfDate) and year(convert(date,ksl_schfinanmovein)) = year(@AsOfDate)
and q.ksl_communityid <> '119C1A08-0142-E511-96FE-0050568B37AC' -- LP
and (account.ksl_affordablehousing = 0 or account.ksl_affordablehousing is null) -- No Affordable Housing
group by account.ksl_soldby,a.ksl_communityid

union all

select 'Monthly Community Fee Bonus'
, 0 as apt_Rate
, 0 as amt
,0 as Community_Fee
,[FullName] COLLATE SQL_Latin1_General_CP1_CI_AS 
, [SystemUserId], ksl_communityidname COLLATE SQL_Latin1_General_CP1_CI_AS  
, ksl_communityid
,0 as cnt
from [DataWarehouse].[dbo].[Dim_User] 
where isUserActive = 'Yes'
and ksl_communityid = '119C1A08-0142-E511-96FE-0050568B37AC' -- LP
and Title in ('Sales Director')


)

Select t.*,ksl_shortname
,(select max(amt) from kiscocustom..PIP_FinalCommission where sd = convert(varchar(100),ownerid) and month(dt) = month(@AsOfDate) and year(dt) = year(@AsOfDate) and shortname = ksl_shortname) as FinalAmount
,(select max(Notes) from kiscocustom..PIP_FinalCommission where sd = convert(varchar(100),ownerid) and month(dt) = month(@AsOfDate) and year(dt) = year(@AsOfDate) and shortname = ksl_shortname) as Notes
  from t inner join ksl_community c on t.ksl_communityid = c.ksl_communityid
		join DataWarehouse..Dim_Community dc on c.ksl_communityid = dc.ksl_communityid
 inner join systemuser u on u.systemuserid = ownerid
 where (t.ksl_communityid = @comm or (@comm = '27C35920-B2DE-E211-9163-0050568B37AC' and  isactivecommunity = 'yes' ) )
	and u. title not like '%resident%' and u. title not like '%hospitality%'

--and  ( ksl_communityid  not in ('39C35920-B2DE-E211-9163-0050568B37AC','29C35920-B2DE-E211-9163-0050568B37AC','119C1A08-0142-E511-96FE-0050568B37AC'))

Order by community
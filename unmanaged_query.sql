/*Unmanaged analysis queries for O365 consumption*/

------------------Data at PartnerOne level------------------

/*First, set globa variables.  For aggregation, important to select the most recent time period.  If you want rolling 
  time periods, simply change the globa variables to reflect the intended date */ 
DECLARE @FMCloseDate bigint 
SET @FMCloseDate = (select MAX(ReportingSnapshotDateKey) from o365.vw_Fact_O365ActiveUsage )

--Get the set of managed/unmanaged partners
with managed_partners as (
	select distinct 
		pos.PartnerOneKey
	from pm.vw_dim_partneroneSub POS
	inner join pm.vw_managedpractices MP
		ON MP.PartneroneSubID = POS.PartneroneSubID
	where primaryroletype IN ('PDM', 'TBH')
	and pos.PartnerSpecialization in ('ISV', 'Services')
)
select distinct
	a.partneronekey,
	case when b.partneronekey is null then 'Unmanaged' 
		 else 'Managed'
	end as managed_flag
into #unmanagedpartners
from pm.vw_dim_partneroneSub a 
left join managed_partners b on a.partneronekey = b.partneronekey
;

SELECT DISTINCT 
	M.PartnerOneKey,
	managed_flag,
	O365ActiveUsageKey
into #temps
FROM o365.vw_Bridge_O365ActiveUsagePartner M
Inner Join pm.vw_Dim_PartnerOneSub PS On PS.PartnerOneSubKey = M.PartnerOneSubKey
INNER JOIN #UnmanagedPartners up on up.partneronekey = m.partneronekey
;

SELECT 
	PartnerOneKey,
	managed_flag,
	Workload, 
	SUM(F.ActiveEntitlements) AS ActiveEntitlements, 
	SUM(F.QualifiedEntitlements) AS QualifiedEntitlements
into sandbox.jweindel_partner_usage
FROM o365.vw_Fact_O365ActiveUsage F 
INNER JOIN #temps C ON C.O365ActiveUsageKey = F.O365ActiveUsageKey
INNER Join o365.vw_Dim_O365Workload W On W.O365WorkloadKey = F.O365WorkloadKey
where ReportingSnapshotDateKey=@FMCloseDate
Group by 
	PartnerOneKey,
	managed_flag,
	Workload
;
________________________________________________________________________________________
------------------ Data at All Up level ------------------

DECLARE @FMCloseDate bigint 
SET @FMCloseDate = (select MAX(ReportingSnapshotDateKey) from o365.vw_Fact_O365ActiveUsage )

--Get the set of managed/unmanaged partners
with managed_partners as (
	select distinct 
		pos.PartnerOneKey
	from pm.vw_dim_partneroneSub POS
	inner join pm.vw_managedpractices MP
		ON MP.PartneroneSubID = POS.PartneroneSubID
	where primaryroletype IN ('PDM', 'TBH')
	and pos.PartnerSpecialization in ('ISV', 'Services')
)
select distinct
	a.partneronekey,
	case when b.partneronekey is null then 'Unmanaged' 
		 else 'Managed'
	end as managed_flag
into #unmanagedpartners
from pm.vw_dim_partneroneSub a 
left join managed_partners b on a.partneronekey = b.partneronekey
;

SELECT DISTINCT 
	IsManaged , 
	managed_flag,
	O365ActiveUsageKey   
into #temps2
FROM o365.vw_Bridge_O365ActiveUsagePartner M
Inner Join pm.vw_Dim_PartnerOneSub PS On PS.PartnerOneSubKey = M.PartnerOneSubKey
INNER JOIN #UnmanagedPartners up on up.partneronekey = m.partneronekey
;

SELECT 
	managed_flag,
	Workload, 
	SUM(F.ActiveEntitlements) AS ActiveEntitlements, 
	SUM(F.QualifiedEntitlements) AS QualifiedEntitlements
FROM o365.vw_Fact_O365ActiveUsage F 
INNER JOIN CTE C ON C.O365ActiveUsageKey = F.O365ActiveUsageKey
INNER Join o365.vw_Dim_O365Workload W On W.O365WorkloadKey = F.O365WorkloadKey
where ReportingSnapshotDateKey=20191201
And  Workload <> 'Unknown'
Group by 
	IsManaged,
	Workload
;


### Notes

| ReportPath | Views | ksl_sms | appointment | letter | phonecall | email | task | systemuser | Status | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| /Sales Reports/Sales Director NRR | 1025 | 0 | 0 | 0 | 0 | 0 | 0 | 1 |  | Looks clear except NRR dataset refs to DataWarehouse.Dim_User.SystemUserId  |
| **/Sales Reports/SIP** | 612 | 0 | 0 | 0 | 0 | 1 | 0 | 1 | 🔴 | Draft - of **DataSet2**

[DataWarehouse].[dbo].[Dim_User].SystemserId ref in DataSet1 |
| **/Sales Reports/Activity Summary** | 148 | 0 | 1 | 1 | 1 | 1 | 1 | 1 |  | SDTargetMI, SDList, NRR, MoveIns – systemuser

GraphTrend, GraphTrendWeekly, GrpahTrendMoQtr  - ref to Vw_Activities
PastDue – various refs

ReactiveDue - phonecall 

Avg3mo - DimUser, Measures |
| /Sales Reports/Sales Counselor Performance | 134 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 🟡 | Updated systemuserid - other refs are to DataWarehouse/Fact_activity |
| /Sales Reports/Lead Source Trend | 97 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | ✅ | No refs, per query |
| /Sales Reports/Pricing Report | 92 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | ✅ | No refs, per query |
| /Sales Reports/Sales Performance | 83 | 0 | 1 | 0 | 0 | 1 | 0 | 0 | 🔴 | Ref to [Measures].[Appointments Subsequent Monthly Avg], no email

MDX query? DataSource1 |
| /Sales Reports/Competitors_Rates | 71 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | ✅ | No refs, per query |
| /Sales Reports/ReferralPrediction | 46 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | ✅ | No refs, per query |
| /Sales Reports/Source Analysis | 37 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | ✅ | No refs, per query |
| /Sales Reports/SIP_CE | 35 | 0 | 1 | 0 | 0 | 0 | 0 | 0 | ✅ | Refs are to “Appointments - Face” - to appointment table |
| /Sales Reports/Competitor Analysis | 30 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | ✅ | No refs, per query |
| **/Sales Reports/BD Performance** | 29 | 0 | 1 | 1 | 1 | 1 | 0 | 1 |  |  |
| /Sales Reports/SIP_Targets | 29 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | ✅ | No refs, per query |
| **/Sales Reports/Activity Summary BD** | 25 | 0 | 1 | 0 | 1 | 0 | 0 | 1 | 🟡 | **SDLList - draft**
GraphTrend - ref to Vw_Activities table |
| /Sales Reports/Move In Analysis | 21 | 0 | 1 | 0 | 0 | 0 | 0 | 0 | ✅ | Ref to “Appointments - CE ALL DATES” |
| /Sales Reports/Scheduled_Visits | 17 | 0 | 1 | 0 | 0 | 1 | 0 | 0 | ✅ | Ref to non email tables, [Staging].[dbo].[calendly], [KSLCLOUD_MSCRM].[dbo].[account], and ksl_community. No appointment ref |
| /Sales Reports/PriceValueAnalysis | 14 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | ✅ | No refs, per query |
| /Sales Reports/BD Analytics | 12 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | ✅ | No refs, per query |
| /Sales Reports/MI Source Trend | 11 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | ✅ | No refs, per query |
| /Sales Reports/DOW_LeadTrend | 8 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | ✅ | No refs, per query |
| /Sales Reports/Professional Ref Move Ins | 7 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | ✅ | No refs, per query |
| /Sales Reports/Resident Referral Analytics | 7 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | ✅ | No refs, per query |
| /Sales Reports/Zip Code Trend | 6 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | ✅ | No refs, per query |
| **/Sales Reports/Event Analysis** | 4 | 0 | 0 | 1 | 0 | 1 | 0 | 0 | 🟡 | Copy with todos. Only one activitytypecode letter |
| **/Sales Reports/Event Analysis BD** | 1 | 0 | 0 | 1 | 0 | 1 | 0 | 0 | 🟡 | Copy made with todos. No email open or click data |
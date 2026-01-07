-- This was the old filter on the report
-- Come 1/1 nothong showed because of it, so removing the whole thing
-- =IIF(
--     Fields!New_Rent___Comm_Fee_YTD.Value > 0
--     OR Fields!GroupedShortName.Value = "CAR"
--     OR Fields!GroupedShortName.Value = "NWB"
--     OR Fields!GroupedShortName.Value = "FTZ",
--     1,
--     0
-- )


-- Changed Text Box properties from
-- =Avg(Fields!Active_Leads_Missing_Data__.Value) => =Aggregate(Fields!Active_Leads_Missing_Data__.Value)
-- Wasn't showing vlaues before

SELECT
  {
    [Measures].[Completed Phone Calls],
    [Measures].[Phone Calls Attempted],
    [Measures].[Past Due Activity Avg],
    [Measures].[Active Leads Missing Data %],
    [Measures].[RAD Past Due Avg],
    [Measures].[Appointments Subsequent Monthly Avg],
    [Measures].[Texts Sent Monthly Avg],
    [Measures].[Texts Received Monthly Avg],
    [Measures].[Texts Received],
    [Measures].[Texts Sent],
    [Measures].[Phone Calls Attempted Monthly Avg],
    [Measures].[Waitlist Count - ALL DATES],
    [Measures].[Appointments Biz Dev Monthly Avg],
    [Measures].[Active Leads Current],
    [Measures].[Sales Generated Leads Monthly Avg],
    [Measures].[Community Experience Monthly Avg],
    [Measures].[Sent Messages Monthly Avg],
    [Measures].[Completed Phone Calls Monthly Avg],
    [Measures].[New Rent + Comm Fee YTD],
    [Measures].[Sales Director Rent Target YTD],
    [Measures].[Sales Mail Monthly Avg]
  } ON COLUMNS,

  NON EMPTY {
    -- Logic: (All Users MINUS the Test User) MULTIPLIED by Communities
    EXCEPT(
        [Dim_User].[FullName].[FullName].ALLMEMBERS, 
        {[Dim_User].[FullName].&[# Dynamic.Test]}
    ) * [Dim_Community].[GroupedShortName].[GroupedShortName].ALLMEMBERS
  } DIMENSION PROPERTIES MEMBER_CAPTION, MEMBER_UNIQUE_NAME ON ROWS

FROM [Model]

WHERE (
  [Dim_Date].[isRolling3Months].&[Yes],
  [Dim_User].[isUserActive].&[Yes],
  [Dim_Community].[IsActiveCommunity].[All],
  -- Filter for Job Titles
  {
    [Dim_User].[Title].&[Sales Director],
    [Dim_User].[Title].&[Sales Counselor],
    [Dim_User].[Title].&[Sales Specialist],
    [Dim_User].[Title].&[Senior Sales Director],
    [Dim_User].[Title].&[Membership Director],
    [Dim_User].[Title].&[Senior Director, Sales & Marketing],
    [Dim_User].[Title].&[Senior Director,Sales & Associate Executive Director],
    [Dim_User].[Title].&[Leasing Counselor]
  },
  -- Filter for Transaction Types
  {
    [Fact_Lease].[MoveinTransactionType].&[Scheduled Move in],
    [Fact_Lease].[MoveinTransactionType].&[Actual Move in]
  }
)
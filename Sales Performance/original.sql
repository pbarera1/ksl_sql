SELECT NON EMPTY { [Measures].[Phone Calls Attempted]
	,[Measures].[Past Due Activity Avg]
	,[Measures].[Active Leads Missing Data %]
	,[Measures].[RAD Past Due Avg]
	,[Measures].[Appointments Subsequent Monthly Avg]
	,[Measures].[Texts Sent Monthly Avg]
	,[Measures].[Texts Received Monthly Avg]
	,[Measures].[Texts Received]
	,[Measures].[Texts Sent]
	,[Measures].[Phone Calls Attempted Monthly Avg]
	,[Measures].[Waitlist Count - ALL DATES]
	,[Measures].[Appointments Biz Dev Monthly Avg]
	,[Measures].[Active Leads Current]
	,[Measures].[Sales Generated Leads Monthly Avg]
	,[Measures].[Community Experience Monthly Avg]
	,[Measures].[Sent Messages Monthly Avg]
	,[Measures].[Completed Phone Calls Monthly Avg]
	,[Measures].[New Rent + Comm Fee YTD]
	,[Measures].[Sales Director Rent Target YTD]
	,[Measures].[Sales Mail Monthly Avg] } ON COLUMNS
	,NON EMPTY {([Dim_User].[FullName].[FullName].ALLMEMBERS * [Dim_Community].[GroupedShortName].[GroupedShortName].ALLMEMBERS) } DIMENSION PROPERTIES MEMBER_CAPTION
	,MEMBER_VALUE
	,MEMBER_UNIQUE_NAME ON ROWS FROM (
	SELECT (- { [Dim_User].[FullName].& [# Dynamic.Test] }) ON COLUMNS
	FROM (
		SELECT (
				{ [Dim_User].[Title].& [Sales Director]
				,[Dim_User].[Title].& [Sales Counselor]
				,[Dim_User].[Title].& [Sales Specialist]
				,[Dim_User].[Title].& [Senior Sales Director]
				,[Dim_User].[Title].& [Membership Director]
				,[Dim_User].[Title].& [Senior Director, Sales & Marketing]
				,[Dim_User].[Title].& [Senior Director,Sales & Associate Executive Director]
				,[Dim_User].[Title].& [Leasing Counselor] }
				) ON COLUMNS
		FROM (
			SELECT (
					{ [Fact_Lease].[MoveinTransactionType].& [Scheduled Move in]
					,[Fact_Lease].[MoveinTransactionType].& [Actual Move in] }
					) ON COLUMNS
			FROM (
				SELECT ({ [Dim_User].[isUserActive].& [Yes] }) ON COLUMNS
				FROM (
					SELECT ({ [Dim_Community].[IsActiveCommunity].[All] }) ON COLUMNS
					FROM (
						SELECT ({ [Dim_Date].[isYesterday].& [Yes] }) ON COLUMNS
						FROM [Model]
						)
					)
				)
			)
		)
	)
WHERE (
		[Dim_Date].[isYesterday].& [Yes]
		,[Dim_Community].[IsActiveCommunity].[All]
		,[Dim_User].[isUserActive].& [Yes]
		,[Fact_Lease].[MoveinTransactionType].CurrentMember
		,[Dim_User].[Title].CurrentMember
		) CELL PROPERTIES VALUE
	,BACK_COLOR
	,FORE_COLOR
	,FORMATTED_VALUE
	,FORMAT_STRING
	,FONT_NAME
	,FONT_SIZE
	,FONT_FLAGS
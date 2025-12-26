USE [DataWarehouse]
GO

/****** Object:  StoredProcedure [dbo].[Populate_DW_Job]    Script Date: 12/22/2025 10:16:48 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Populate_DW_Job] @AsOfDt datetime
AS
BEGIN
declare @DtLast as datetime
set @DtLast = getdate()
	--DECLARE @AsOfDt datetime    SET @AsOfDt = GETDATE()
	--if DATEPART(hh,@AsOfDt) < 17
	--begin
	--set @AsOfDt = @AsOfDt -1
	--end
	--exec Populate_DW_Job @AsOfDt; 

	DECLARE @dt_start date
DECLARE @dt_end date
DECLARE @dt_startx date

SET @dt_start = @AsOfDt - 90
SET @dt_end = @AsOfDt			-- @AsOfDt = GETDATE()

	-- SET NOCOUNT ON added to prevent extra result sets FROM
	-- interfering with SELECT statements.	
	SET NOCOUNT ON;
	--SET ANSI_WARNINGS OFF;
	--SET ANSI_NULLS ON;

	
	
	
	IF OBJECT_ID('staging.dbo.SafetyCompliance', 'U') IS NOT NULL
		drop TABLE staging.dbo.SafetyCompliance
	SELECT * INTO staging.dbo.SafetyCompliance
	FROM OPENROWSET('Microsoft.ACE.OLEDB.12.0',
  'Excel 12.0 Xml; HDR=YES; IMEX=1;
   Database=C:\UserUpload\SafetyCompliance.xlsx',
   [Data$]);


   
   

 
IF OBJECT_ID('staging.dbo.ksl_apartmentfinancialhistory', 'U') IS NOT NULL
drop TABLE staging.dbo.ksl_apartmentfinancialhistory
	SELECT * INTO staging.dbo.ksl_apartmentfinancialhistory FROM kslcloud_mscrm.dbo.ksl_apartmentfinancialhistory WITH (NOLOCK) 

	CREATE NONCLUSTERED INDEX [NonClusteredIndex-20220223-084215] ON staging.[dbo].[ksl_apartmentfinancialhistory]
(
	[ksl_enddate] ASC,
	[ksl_endtransactiontype] ASC,
	[ksl_apartmentid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]


	   IF OBJECT_ID('staging.dbo.ksl_residentoccupancyhistory', 'U') IS NOT NULL
   drop TABLE staging.dbo.ksl_residentoccupancyhistory
	SELECT * INTO staging.dbo.ksl_residentoccupancyhistory FROM kslcloud_mscrm.dbo.ksl_residentoccupancyhistory WITH (NOLOCK) 
	    IF OBJECT_ID('staging.dbo.KSL_Community', 'U') IS NOT NULL
	drop TABLE staging.dbo.KSL_Community
	SELECT * INTO staging.dbo.KSL_Community FROM kslcloud_mscrm.dbo.KSL_Community WITH (NOLOCK) 
		IF OBJECT_ID('staging.dbo.ksl_apartment', 'U') IS NOT NULL
	 drop TABLE staging.dbo.ksl_apartment
	SELECT * INTO staging.dbo.ksl_apartment FROM kslcloud_mscrm.dbo.ksl_apartment WITH (NOLOCK) 
	
	 IF OBJECT_ID('staging.dbo.Account', 'U') IS NOT NULL
	 drop TABLE staging.dbo.Account
	SELECT * INTO staging.dbo.Account FROM kslcloud_mscrm.dbo.Account WITH (NOLOCK) 


		 IF OBJECT_ID('staging.dbo.StringMap', 'U') IS NOT NULL
	 drop TABLE staging.dbo.StringMap
	SELECT * INTO staging.dbo.StringMap FROM kslcloud_mscrm.dbo.StringMap WITH (NOLOCK)

		 IF OBJECT_ID('staging.dbo.ksl_inquirysource', 'U') IS NOT NULL
	 drop TABLE staging.dbo.ksl_inquirysource 
	SELECT * INTO staging.dbo.ksl_inquirysource FROM kslcloud_mscrm.dbo.ksl_inquirysource WITH (NOLOCK)

		IF OBJECT_ID('staging.dbo.PhoneCall', 'U') IS NOT NULL
	 drop TABLE staging.dbo.PhoneCall 
	SELECT * INTO staging.dbo.PhoneCall FROM kslcloud_mscrm.dbo.PhoneCall WITH (NOLOCK) WHERE ksl_DateCompleted > '1/1/2016'
		 	IF OBJECT_ID('staging.dbo.Appointment', 'U') IS NOT NULL
	 drop TABLE staging.dbo.Appointment 
	SELECT * INTO staging.dbo.Appointment FROM kslcloud_mscrm.dbo.Appointment WITH (NOLOCK) WHERE scheduledstart > '1/1/2016'


BEGIN TRY;THROW 50000,'',1;END TRY BEGIN CATCH;insert into Staging.dbo.log_DW_Time (LineNumber,MinSinceLast) values (ERROR_LINE(),DATEDIFF(mi,@DtLast,getdate()));END CATCH
set @DtLast = getdate()
	
	
	
	DBCC USEROPTIONS 

	IF OBJECT_ID('staging.dbo.NS_transactions_TEMP', 'U') IS NOT NULL
	 drop TABLE staging.dbo.NS_transactions_TEMP 
	--SELECT * INTO staging.dbo.NS_transactions FROM Netsuite.[Kisco Senior Living, LLC].[Administrator].transactions
	SELECT * into staging.dbo.NS_transactions_TEMP FROM OPENQUERY(NETSUITE, 'SELECT transaction_id,trandate,Accounting_Period_ID,TRANSACTION_TYPE,Memo,Transaction_Number
	,Create_Date
	,BillAddress,TranID,CREATED_FROM_ID
	,due_date
	,Related_TranID,Transaction_ExtID,ENTITY_ID,Status,EXTERNAL_REF_NUMBER
	FROM transactions')

	IF OBJECT_ID('staging.dbo.NS_transactions', 'U') IS NOT NULL
	 drop TABLE staging.dbo.NS_transactions 
	SELECT * into staging.dbo.NS_transactions FROM staging.dbo.NS_transactions_TEMP
	/*
	SELECT transaction_id,trandate,Accounting_Period_ID,TRANSACTION_TYPE,Memo,Transaction_Number
	,Create_Date
	,BillAddress,TranID,CREATED_FROM_ID
	,due_date
	,Related_TranID,Transaction_ExtID,ENTITY_ID,Status,EXTERNAL_REF_NUMBER
	INTO staging.dbo.NS_transactions 
	FROM Netsuite.[Kisco Senior Living, LLC].[Administrator].transactions
	*/



CREATE NONCLUSTERED INDEX [_dta_index_NS_transactions_14_2083459888__K14_K4_2_9_11] ON Staging.[dbo].[NS_transactions]
(
	[ENTITY_ID] ASC,
	[TRANSACTION_TYPE] ASC
)
INCLUDE([trandate],[TranID],[due_date]) WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON [PRIMARY]




BEGIN TRY;THROW 50000,'',1;END TRY BEGIN CATCH;insert into Staging.dbo.log_DW_Time (LineNumber,MinSinceLast) values (ERROR_LINE(),DATEDIFF(mi,@DtLast,getdate()));END CATCH
set @DtLast = getdate()


/*	

		declare @NetsuiteDt datetime
set @NetsuiteDt = DATEADD(hour,DATEDIFF (hour, GETDATE(), GETUTCDATE()),getdate()-5)
	delete  from staging.dbo.NS_transactions where transaction_id in (
select transaction_id from Netsuite.[Kisco Senior Living, LLC].[Administrator].transactions where DATE_LAST_MODIFIED >= @NetsuiteDt
)
insert into staging.dbo.NS_transactions select transaction_id,trandate,Accounting_Period_ID,TRANSACTION_TYPE,Memo,Transaction_Number,Create_Date,BillAddress,TranID,CREATED_FROM_ID,due_date
	,Related_TranID,Transaction_ExtID,ENTITY_ID,Status,EXTERNAL_REF_NUMBER
	from Netsuite.[Kisco Senior Living, LLC].[Administrator].transactions where DATE_LAST_MODIFIED >= @NetsuiteDt





delete  from staging.dbo.NS_transaction_lines where UNIQUE_KEY in (
select UNIQUE_KEY from Netsuite.[Kisco Senior Living, LLC].[Administrator].transaction_lines where DATE_LAST_MODIFIED_GMT >= @NetsuiteDt
)
insert into staging.dbo.NS_transaction_lines select * from Netsuite.[Kisco Senior Living, LLC].[Administrator].transaction_lines where DATE_LAST_MODIFIED_GMT >= @NetsuiteDt
*/


	IF OBJECT_ID('staging.dbo.NS_transaction_lines_TEMP', 'U') IS NOT NULL
	 drop TABLE staging.dbo.NS_transaction_lines_TEMP 

	 SELECT 

	 ACCOUNT_ID,AMOUNT,AVID_COMMUNITY_CODE,AVID_LINE_AMOUNT,AVID_PROJECT_TASK_ID,CHARGE_TYPE,CHARGE_TYPE_ID,CLASS_ID,COMMUNITY_ID
	,COMPANY_ID,CUSTOMER_EXTERNAL_ID,CUSTOMER_INFO,DEPARTMENT_ID
	,GROSS_AMOUNT,INVESTMENT_ID,INVOICE_LINK,ISBILLABLE,ISCLEARED,ITEM_COUNT,ITEM_ID,ITEM_RECEIVED,ITEM_SORT_BY
	,ITEM_UNIT_PRICE,MEMO,NET_AMOUNT,NON_POSTING_LINE,NUMBER_BILLED,OLD_GL_ACCOUNT_CODE,TRY_CONVERT(datetime2, PERIOD_CLOSED) PERIOD_CLOSED
	,PROJECT_TASK_ID,SUBSCRIPTION_LINE_ID,SUBSIDIARY_ID
	,TRANSACTION_DISCOUNT_LINE,TRANSACTION_ID,TRANSACTION_LINE_ID,TRANSACTION_ORDER,UNIQUE_KEY,TRY_CONVERT(datetime2, SHIPDATE) SHIPDATE,TRY_CONVERT(datetime2, POS_CHARGE_DATE) POS_CHARGE_DATE
	,POS_CHARGE_DESCRIPTION
	 
	 
	 into staging.dbo.NS_transaction_lines_TEMP FROM OPENQUERY(NETSUITE, 'select ACCOUNT_ID,AMOUNT,AVID_COMMUNITY_CODE,AVID_LINE_AMOUNT,AVID_PROJECT_TASK_ID,CHARGE_TYPE,CHARGE_TYPE_ID,CLASS_ID,COMMUNITY_ID
	,COMPANY_ID,CUSTOMER_EXTERNAL_ID,CUSTOMER_INFO,DEPARTMENT_ID
	,GROSS_AMOUNT,INVESTMENT_ID,INVOICE_LINK,ISBILLABLE,ISCLEARED,ITEM_COUNT,ITEM_ID,ITEM_RECEIVED,ITEM_SORT_BY
	,ITEM_UNIT_PRICE,MEMO,NET_AMOUNT,NON_POSTING_LINE,NUMBER_BILLED,OLD_GL_ACCOUNT_CODE,PERIOD_CLOSED
	,PROJECT_TASK_ID,SUBSCRIPTION_LINE_ID,SUBSIDIARY_ID
	,TRANSACTION_DISCOUNT_LINE,TRANSACTION_ID,TRANSACTION_LINE_ID,TRANSACTION_ORDER,UNIQUE_KEY,SHIPDATE,POS_CHARGE_DATE,POS_CHARGE_DESCRIPTION FROM transaction_lines')
	--,KISCO_FIXED_ASSET_ID,KISCO_UNIT_RENOVATION_ASSET_ID,HAS_COST_LINE,DO_NOT_DISPLAY_LINE,DO_NOT_PRINT_LINE
	IF OBJECT_ID('staging.dbo.NS_transaction_lines', 'U') IS NOT NULL
	 drop TABLE staging.dbo.NS_transaction_lines 

	 SELECT * into staging.dbo.NS_transaction_lines FROM staging.dbo.NS_transaction_lines_TEMP


	/*
	SELECT ACCOUNT_ID,AMOUNT,AVID_COMMUNITY_CODE,AVID_LINE_AMOUNT,AVID_PROJECT_TASK_ID,CHARGE_TYPE,CHARGE_TYPE_ID,CLASS_ID,COMMUNITY_ID
	,COMPANY_ID,CUSTOMER_EXTERNAL_ID,CUSTOMER_INFO,DEPARTMENT_ID,DO_NOT_DISPLAY_LINE,DO_NOT_PRINT_LINE
	,GROSS_AMOUNT,HAS_COST_LINE,INVESTMENT_ID,INVOICE_LINK,ISBILLABLE,ISCLEARED,ITEM_COUNT,ITEM_ID,ITEM_RECEIVED,ITEM_SORT_BY,ITEM_SOURCE
	,ITEM_UNIT_PRICE,KISCO_FIXED_ASSET_ID,KISCO_UNIT_RENOVATION_ASSET_ID,MEMO,NET_AMOUNT,NON_POSTING_LINE,NUMBER_BILLED,OLD_GL_ACCOUNT_CODE,PERIOD_CLOSED
	,PROJECT_TASK_ID,PURCHASE_CONTRACT_ID,QUANTITY_ALLOCATED,QUANTITY_COMMITTED,RELATED_COMPANY_ID,SOURCE_SUBSIDIARY_ID,SUBSCRIPTION_LINE_ID,SUBSIDIARY_ID
	,TRANSACTION_DISCOUNT_LINE,TRANSACTION_ID,TRANSACTION_LINE_ID,TRANSACTION_ORDER,UNIQUE_KEY,SHIPDATE
	INTO staging.dbo.NS_transaction_lines FROM Netsuite.[Kisco Senior Living, LLC].[Administrator].transaction_lines
	 */	 	
			
BEGIN TRY;THROW 50000,'',1;END TRY BEGIN CATCH;insert into Staging.dbo.log_DW_Time (LineNumber,MinSinceLast) values (ERROR_LINE(),DATEDIFF(mi,@DtLast,getdate()));END CATCH
set @DtLast = getdate()




IF OBJECT_ID('staging.dbo.NS_accounts_TEMP', 'U') IS NOT NULL
	 drop TABLE staging.dbo.NS_accounts_TEMP 
	SELECT * INTO staging.dbo.NS_accounts_TEMP FROM Netsuite.[Kisco Senior Living, LLC].[Administrator].accounts

	IF OBJECT_ID('staging.dbo.NS_accounts', 'U') IS NOT NULL
	 drop TABLE staging.dbo.NS_accounts 
	 SELECT * into staging.dbo.NS_accounts FROM staging.dbo.NS_accounts_TEMP


	IF OBJECT_ID('staging.dbo.NS_SUBSIDIARIES_TEMP', 'U') IS NOT NULL
	 drop TABLE staging.dbo.NS_SUBSIDIARIES_TEMP 
	SELECT * INTO staging.dbo.NS_SUBSIDIARIES_TEMP FROM Netsuite.[Kisco Senior Living, LLC].[Administrator].[SUBSIDIARIES]

		IF OBJECT_ID('staging.dbo.NS_SUBSIDIARIES', 'U') IS NOT NULL
	 drop TABLE staging.dbo.NS_SUBSIDIARIES 
	SELECT * INTO staging.dbo.NS_SUBSIDIARIES FROM staging.dbo.NS_SUBSIDIARIES_TEMP

			 	 	IF OBJECT_ID('staging.dbo.NS_SEGMENTATION_LIST', 'U') IS NOT NULL
	 drop TABLE staging.dbo.NS_SEGMENTATION_LIST 
	SELECT * INTO staging.dbo.NS_SEGMENTATION_LIST FROM Netsuite.[Kisco Senior Living, LLC].[Administrator].[SEGMENTATION_LIST]


				 	 	IF OBJECT_ID('staging.dbo.NS_PROPERTY_TYPE_LIST', 'U') IS NOT NULL
	 drop TABLE staging.dbo.NS_PROPERTY_TYPE_LIST 
	SELECT * INTO staging.dbo.NS_PROPERTY_TYPE_LIST FROM Netsuite.[Kisco Senior Living, LLC].[Administrator].[PROPERTY_TYPE_LIST]







	
	IF OBJECT_ID('staging.dbo.NS_CAPITAL_PARTNER', 'U') IS NOT NULL
	 drop TABLE staging.dbo.NS_CAPITAL_PARTNER 
	SELECT * INTO staging.dbo.NS_CAPITAL_PARTNER FROM Netsuite.[Kisco Senior Living, LLC].[Administrator].[CAPITAL_PARTNER]
	

	BEGIN TRY;THROW 50000,'',1;END TRY BEGIN CATCH;insert into Staging.dbo.log_DW_Time (LineNumber,MinSinceLast) values (ERROR_LINE(),DATEDIFF(mi,@DtLast,getdate()));END CATCH
set @DtLast = getdate()



	--CUSTOM DELETE THIS LATER
	update staging.dbo.NS_SUBSIDIARIES set name = 'BP' where name = 'BP40'

		 	 	IF OBJECT_ID('staging.dbo.NS_DEPARTMENTS_TEMP', 'U') IS NOT NULL
	 drop TABLE staging.dbo.NS_DEPARTMENTS_TEMP 
	SELECT * INTO staging.dbo.NS_DEPARTMENTS_TEMP FROM Netsuite.[Kisco Senior Living, LLC].[Administrator].[DEPARTMENTS]
	
	IF OBJECT_ID('staging.dbo.NS_DEPARTMENTS', 'U') IS NOT NULL
	 drop TABLE staging.dbo.NS_DEPARTMENTS 
	SELECT * INTO staging.dbo.NS_DEPARTMENTS FROM staging.dbo.NS_DEPARTMENTS_TEMP


	 	 	IF OBJECT_ID('staging.dbo.NS_CLASSES_TEMP', 'U') IS NOT NULL	 drop TABLE staging.dbo.NS_CLASSES_TEMP 
	SELECT * INTO staging.dbo.NS_CLASSES_TEMP FROM Netsuite.[Kisco Senior Living, LLC].[Administrator].[CLASSES]

		 	 	IF OBJECT_ID('staging.dbo.NS_CLASSES', 'U') IS NOT NULL	 drop TABLE staging.dbo.NS_CLASSES 
	SELECT * INTO staging.dbo.NS_CLASSES FROM staging.dbo.NS_CLASSES_TEMP




IF OBJECT_ID('staging.dbo.NS_Budget_TEMP', 'U') IS NOT NULL
drop TABLE staging.dbo.NS_Budget_TEMP 
SELECT * INTO staging.dbo.NS_Budget_TEMP FROM Netsuite.[Kisco Senior Living, LLC].[Administrator].[Budget]

	IF OBJECT_ID('staging.dbo.NS_Budget', 'U') IS NOT NULL
	 drop TABLE staging.dbo.NS_Budget 
	 SELECT * into staging.dbo.NS_Budget FROM staging.dbo.NS_Budget_TEMP



IF OBJECT_ID('staging.dbo.NS_Accounting_Periods_TEMP', 'U') IS NOT NULL
	 drop TABLE staging.dbo.NS_Accounting_Periods_TEMP 
	SELECT * INTO staging.dbo.NS_Accounting_Periods_TEMP FROM Netsuite.[Kisco Senior Living, LLC].[Administrator].[Accounting_Periods]

	IF OBJECT_ID('staging.dbo.NS_Accounting_Periods', 'U') IS NOT NULL
	 drop TABLE staging.dbo.NS_Accounting_Periods 
	SELECT * INTO staging.dbo.NS_Accounting_Periods FROM staging.dbo.NS_Accounting_Periods_TEMP



	 	 	 	 	 	IF OBJECT_ID('staging.dbo.NS_GROUPINGS_LIST', 'U') IS NOT NULL
	 drop TABLE staging.dbo.NS_GROUPINGS_LIST 
	SELECT * INTO staging.dbo.NS_GROUPINGS_LIST FROM Netsuite.[Kisco Senior Living, LLC].[Administrator].[GROUPINGS_LIST]
	
	
IF OBJECT_ID('staging.dbo.NS_Customers_TEMP', 'U') IS NOT NULL
	 drop TABLE staging.dbo.NS_Customers_TEMP 	 	
	SELECT * INTO staging.dbo.NS_Customers_TEMP FROM Netsuite.[Kisco Senior Living, LLC].[Administrator].[Customers] 

		IF OBJECT_ID('staging.dbo.NS_Customers', 'U') IS NOT NULL
	 drop TABLE staging.dbo.NS_Customers 
	 SELECT * into staging.dbo.NS_Customers FROM staging.dbo.NS_Customers_TEMP


		 IF OBJECT_ID('staging.dbo.NS_PROJECT_TASKS', 'U') IS NOT NULL
	 drop TABLE staging.dbo.NS_PROJECT_TASKS 
SELECT * INTO staging.dbo.NS_PROJECT_TASKS FROM Netsuite.[Kisco Senior Living, LLC].[Administrator].[PROJECT_TASKS] 
	 	 IF OBJECT_ID('staging.dbo.NS_PROJECT_COST_BUDGETS', 'U') IS NOT NULL
	 drop TABLE staging.dbo.NS_PROJECT_COST_BUDGETS 
SELECT * INTO staging.dbo.NS_PROJECT_COST_BUDGETS FROM Netsuite.[Kisco Senior Living, LLC].[Administrator].[PROJECT_COST_BUDGETS] 
		 	 IF OBJECT_ID('staging.dbo.NS_PROJECT_EXPENSE_TYPES', 'U') IS NOT NULL
	 drop TABLE staging.dbo.NS_PROJECT_EXPENSE_TYPES  
SELECT * INTO staging.dbo.NS_PROJECT_EXPENSE_TYPES FROM Netsuite.[Kisco Senior Living, LLC].[Administrator].[PROJECT_EXPENSE_TYPES] 
	 		 	 IF OBJECT_ID('staging.dbo.NS_Project_task_cost_budgets', 'U') IS NOT NULL
	 drop TABLE staging.dbo.NS_Project_task_cost_budgets  
SELECT * INTO staging.dbo.NS_Project_task_cost_budgets FROM Netsuite.[Kisco Senior Living, LLC].[Administrator].[Project_task_cost_budgets] 
	 	 		 	 IF OBJECT_ID('staging.dbo.NS_DEPARTMENT_GROUPINGS', 'U') IS NOT NULL
	 drop TABLE staging.dbo.NS_DEPARTMENT_GROUPINGS  
SELECT * INTO staging.dbo.NS_DEPARTMENT_GROUPINGS FROM Netsuite.[Kisco Senior Living, LLC].[Administrator].[DEPARTMENT_GROUPINGS]
	 	 	 		 	 IF OBJECT_ID('staging.dbo.NS_AVID_AI_IMPORTED_INVOICES', 'U') IS NOT NULL
	 drop TABLE staging.dbo.NS_AVID_AI_IMPORTED_INVOICES  
SELECT 	 Bill_ID, AI_Image_URL INTO staging.dbo.NS_AVID_AI_IMPORTED_INVOICES FROM Netsuite.[Kisco Senior Living, LLC].[Administrator].[AVID_AI_IMPORTED_INVOICES]

IF OBJECT_ID('staging.dbo.NS_Items_TEMP', 'U') IS NOT NULL drop TABLE staging.dbo.NS_Items_TEMP  
	 SELECT * INTO staging.dbo.NS_Items_TEMP FROM Netsuite.[Kisco Senior Living, LLC].[Administrator].items

	 IF OBJECT_ID('staging.dbo.NS_Items', 'U') IS NOT NULL drop TABLE staging.dbo.NS_Items  
	 SELECT * INTO staging.dbo.NS_Items FROM staging.dbo.NS_Items_TEMP

IF OBJECT_ID('staging.dbo.NS_Budget_Category', 'U') IS NOT NULL
	 drop TABLE staging.dbo.NS_Budget_Category  
SELECT * INTO staging.dbo.NS_Budget_Category FROM Netsuite.[Kisco Senior Living, LLC].[Administrator].Budget_Category

IF OBJECT_ID('staging.dbo.NS_Entity', 'U') IS NOT NULL
	 drop TABLE staging.dbo.NS_Entity 
SELECT * INTO staging.dbo.NS_Entity FROM Netsuite.[Kisco Senior Living, LLC].[Administrator].Entity

		IF OBJECT_ID('staging.dbo.NS_TRANSACTION_TAX_DETAIL', 'U') IS NOT NULL
	 drop TABLE staging.dbo.NS_TRANSACTION_TAX_DETAIL 
	SELECT * INTO staging.dbo.NS_TRANSACTION_TAX_DETAIL FROM Netsuite.[Kisco Senior Living, LLC].[Administrator].TRANSACTION_TAX_DETAIL

CREATE NONCLUSTERED INDEX [_dta_index_NS_Entity_14_255977380__K57_K34] ON Staging.[dbo].[NS_Entity]
(
	[NAME] ASC,
	[ENTITY_ID] ASC
)WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON [PRIMARY]


IF OBJECT_ID('staging.dbo.NS_POS_NS_ITEM_MAPPING', 'U') IS NOT NULL
	 drop TABLE staging.dbo.NS_POS_NS_ITEM_MAPPING 
SELECT * INTO staging.dbo.NS_POS_NS_ITEM_MAPPING FROM Netsuite.[Kisco Senior Living, LLC].[Administrator].POS_NS_ITEM_MAPPING

IF OBJECT_ID('staging.dbo.NS_Asset_Type', 'U') IS NOT NULL
	 drop TABLE staging.dbo.NS_Asset_Type 
SELECT * INTO staging.dbo.NS_Asset_Type FROM Netsuite.[Kisco Senior Living, LLC].[Administrator].FAM_ASSET_TYPE



CREATE NONCLUSTERED INDEX [_dta_index_NS_transaction_lines_14_407593882__K10_K26_K20_K8_K13_K32_K1_K34_2_19_24_39_40] ON staging.[dbo].[NS_transaction_lines]
(
	[COMPANY_ID] ASC,
	[NON_POSTING_LINE] ASC,
	[ITEM_ID] ASC,
	[CLASS_ID] ASC,
	[DEPARTMENT_ID] ASC,
	[SUBSIDIARY_ID] ASC,
	[ACCOUNT_ID] ASC,
	[TRANSACTION_ID] ASC
)
INCLUDE([AMOUNT],[ITEM_COUNT],[MEMO],[POS_CHARGE_DATE],[POS_CHARGE_DESCRIPTION]) WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON [PRIMARY]






CREATE NONCLUSTERED INDEX [_dta_index_NS_transactions_14_375593768__K1_K4_K2_K12_3_6_9_13] ON staging.[dbo].[NS_transactions]
(
	[transaction_id] ASC,
	[TRANSACTION_TYPE] ASC,
	[trandate] ASC,
	[Related_TranID] ASC
)
INCLUDE([Accounting_Period_ID],[Transaction_Number],[TranID],[Transaction_ExtID]) WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON [PRIMARY]






CREATE NONCLUSTERED INDEX [_dta_index_NS_Customers_14_551594395__K44_45_86_151] ON staging.[dbo].[NS_Customers]
(
	[CUSTOMER_EXTID] ASC
)
INCLUDE([CUSTOMER_ID],[FULL_NAME],[ROOM_NUMBER_ID]) WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON [PRIMARY]






CREATE NONCLUSTERED INDEX [_dta_index_NS_accounts_14_423593939__K3_K1_K29_K30_K27] ON staging.[dbo].[NS_accounts]
(
	[ACCOUNT_ID] ASC,
	[ACCOUNTNUMBER] ASC,
	[PARENT_ID] ASC,
	[TYPE_NAME] ASC,
	[NAME] ASC
)WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON [PRIMARY]












BEGIN TRY
truncate TABLE staging.dbo.STANLEY_tblECEventLog
declare @shortname varchar(50)
declare @sql as varchar(500)
DECLARE db_cursor CURSOR FOR 
select distinct groupedshortname from Dim_Community where IsActiveCommunity = 'Yes'
OPEN db_cursor  
FETCH NEXT FROM db_cursor INTO @shortname  
WHILE @@FETCH_STATUS = 0  
BEGIN  
if exists(select * from sys.servers where name = @shortname+'_STANLEY')
BEGIN
select @sql = 'insert into  staging.dbo.STANLEY_tblECEventLog select 
AutoID
,DateTime
,ApartmentDescription
,DeviceDescription
,EventID
,CategoryDescription
,ResetTime
,DeviceType
,''' + @shortname+''' as shortname  from ' + @shortname+'_STANLEY.Xmark.[dbo].[tblECEventLog]'
/*select @sql = 'select  
AutoID
,DateTime
,ApartmentDescription
,DeviceDescription
,EventID
,CategoryDescription
,ResetTime
,DeviceType
,''' + @shortname+''' as shortname into staging.dbo.STANLEY_tblECEventLog  from ' + @shortname+'_STANLEY.Xmark.[dbo].[tblECEventLog]'*/
exec (@sql)
END
      FETCH NEXT FROM db_cursor INTO @shortname 
END 
CLOSE db_cursor  
DEALLOCATE db_cursor 

END TRY
BEGIN CATCH
     print 'There was an error connecting to the Stanley Arial servers';
END CATCH;



BEGIN TRY;THROW 50000,'',1;END TRY BEGIN CATCH;insert into Staging.dbo.log_DW_Time (LineNumber,MinSinceLast) values (ERROR_LINE(),DATEDIFF(mi,@DtLast,getdate()));END CATCH
set @DtLast = getdate()



exec Netsuite_Rent_Roll_Import


BEGIN TRY;THROW 50000,'',1;END TRY BEGIN CATCH;insert into Staging.dbo.log_DW_Time (LineNumber,MinSinceLast) values (ERROR_LINE(),DATEDIFF(mi,@DtLast,getdate()));END CATCH
set @DtLast = getdate()


	--UPDATE Date TABLE to include isYesterday
	UPDATE dim_date SET isYesterday = 'No' WHERE isYesterday = 'Yes'
	UPDATE dim_date SET isrolling30days = 'No' WHERE isrolling30days = 'Yes'
	UPDATE dim_date SET isCurrentYear = 'No' WHERE isCurrentYear = 'Yes'
	UPDATE dim_date SET isRolling1Year = 'No' WHERE isRolling1Year = 'Yes'
	UPDATE dim_date SET isRolling2Years = 'No' WHERE isRolling2Years = 'Yes'
	UPDATE dim_date SET isRolling3Years = 'No' WHERE isRolling3Years = 'Yes'
	UPDATE dim_date SET isCurrentMonth = 'No' WHERE isCurrentMonth = 'Yes'
	UPDATE dim_date SET isYearToDate = 'No' WHERE isYearToDate = 'Yes'
	UPDATE dim_date SET isrolling7days = 'No' WHERE isrolling7days = 'Yes'
	UPDATE dim_date SET is30Days = 'No' WHERE is30Days = 'Yes'
	UPDATE dim_date SET isLastDayOfMonth = 'No' WHERE isLastDayOfMonth = 'Yes' 
	UPDATE dim_date SET isLastMonth = 'No' WHERE isLastMonth = 'Yes' 
	UPDATE dim_date SET isLatestClosedMonth = 'No' WHERE isLatestClosedMonth = 'Yes'
	UPDATE dim_date SET isRolling1YrFrmLstClosedMnth = 'No' WHERE isRolling1YrFrmLstClosedMnth = 'Yes'
	UPDATE dim_date SET isClosed = 'No'
	UPDATE dim_date SET isRolling12Months = 'No'
	UPDATE dim_date SET isThisMonthAndNext = 'No'
	UPDATE dim_date SET isLastToNextMonth = 'No'  WHERE isLastToNextMonth = 'Yes'
	UPDATE dim_date SET isYTDFrmLstClosedMnth = 'No'
	UPDATE dim_date SET isYTDtoEndOfMonth = 'No'
	UPDATE dim_date SET isRolling3Months = 'No'
	UPDATE dim_date SET isRolling2Months = 'No'
	UPDATE dim_date SET isThisMonthAndNextAll = 'No'

	UPDATE dim_date SET isYesterday = 'Yes' WHERE [date] = convert(date,@AsOfDt)
	UPDATE dim_date SET isrolling30days = 'Yes' WHERE [date] > convert(date,@AsOfDt-30) and [date] <= convert(date,@AsOfDt)
	UPDATE dim_date SET isCurrentYear = 'Yes' WHERE datepart(year,[date]) = datepart(year,@AsOfDt)
	UPDATE dim_date SET isRolling1Year = 'Yes' WHERE [date] > EOMONTH(dateadd(Month,-13,@AsOfDt),1) and [date] <= EOMONTH(convert(date,@AsOfDt))
	UPDATE dim_date SET isRolling2Years = 'Yes' WHERE [date] > EOMONTH(dateadd(Month,-25,@AsOfDt),1) and [date] <= EOMONTH(convert(date,@AsOfDt))
	UPDATE dim_date SET isRolling3Years = 'Yes' WHERE [date] > EOMONTH(dateadd(Month,-37,@AsOfDt),1) and [date] <= EOMONTH(convert(date,@AsOfDt))
	UPDATE dim_date SET isCurrentMonth = 'Yes' WHERE datepart(year,[date]) = datepart(year,@AsOfDt) and datepart(month,[date]) = datepart(month,@AsOfDt)
	UPDATE dim_date SET isYearToDate = 'Yes' WHERE [date] >= DATEADD(yy, DATEDIFF(yy, 0, @AsOfDt), 0) and [date] <= convert(date,@AsOfDt)
	UPDATE dim_date SET isrolling7days = 'Yes' WHERE [date] > convert(date,@AsOfDt-7) and [date] <= convert(date,@AsOfDt)
	UPDATE dim_date SET is30Days = 'Yes' WHERE [date] = convert(date,@AsOfDt-30) 
	UPDATE dim_date SET isLastDayOfMonth = 'Yes' WHERE [date] = LastDayOfMonth 
	UPDATE dim_date SET isLastMonth = 'Yes' WHERE DATEPART(m, [date]) = DATEPART(m, DATEADD(m, -1, @AsOfDt)) AND DATEPART(yyyy, [date]) = DATEPART(yyyy, DATEADD(m, -1, @AsOfDt))
	UPDATE dim_date SET isRolling12Months = 'Yes' WHERE [date] > EOMONTH(dateadd(Month,-13,@AsOfDt),1) and [date] <= convert(date,@AsOfDt)

	UPDATE dim_date SET isThisMonthAndNext = 'Yes' WHERE [date] >= convert(date,@AsOfDt) and [date] <= EOMONTH(@AsOfDt,1)
	UPDATE dim_date SET isLastToNextMonth = 'Yes' WHERE DATEPART(m, [date]) >= DATEPART(m, DATEADD(m, -1, @AsOfDt)) 
															and DATEPART(yyyy, [date]) = DATEPART(yyyy, DATEADD(m, -1, @AsOfDt))
															and [date] <= EOMONTH(@AsOfDt,1)

	UPDATE dim_date SET isClosed = 'Yes'
	FROM dim_date INNER JOIN staging.dbo.NS_Accounting_Periods p ON DATEPART(m, [date]) = DATEPART(m, p.Ending) and  DATEPART(yyyy, [date]) = DATEPART(yyyy, p.Ending)
	and Closed = 'Yes'
	UPDATE dim_date SET isLatestClosedMonth = 'Yes' WHERE YYYYMM = (SELECT MAX(YYYYMM) FROM dim_date WHERE isClosed = 'Yes')

	--UPDATE dim_date SET isRolling1YrFrmLstClosedMnth = 'Yes' WHERE [date] >= '12/1/2016' and [date] <= DATEADD(mm, DATEDIFF(mm, 0, GETDATE()) - 1, 0)
	UPDATE dim_date SET isRolling1YrFrmLstClosedMnth = 'Yes' 
	WHERE date <=
	(SELECT date FROM dim_date WHERE isLatestClosedMonth = 'Yes' and isLastDayOfMonth = 'Yes')
	and date >=
	(SELECT dateadd(d,1,dateadd(m,-12,date)) FROM dim_date WHERE isLatestClosedMonth = 'Yes' and isLastDayOfMonth = 'Yes')


	--UPDATE dim_date SET isYTDFrmLstClosedMnth = 'Yes' 
	--WHERE date <=
	--(SELECT date FROM dim_date WHERE isLatestClosedMonth = 'Yes' and isLastDayOfMonth = 'Yes')
	--and date >=	DATEADD(yy, DATEDIFF(yy, 0, GETDATE()), 0)

	UPDATE dim_date SET isYTDFrmLstClosedMnth = 'Yes' 
		WHERE date <=
	(SELECT date FROM dim_date WHERE isLatestClosedMonth = 'Yes' and isLastDayOfMonth = 'Yes')
	and year(date) = (SELECT year(date) FROM dim_date WHERE isLatestClosedMonth = 'Yes' and isLastDayOfMonth = 'Yes')

	UPDATE dim_date SET isYTDtoEndOfMonth = 'Yes' WHERE date >=	DATEADD(yy, DATEDIFF(yy, 0, @AsOfDt), 0) and [date] <= EOMONTH(convert(date,@AsOfDt))
	UPDATE dim_date SET isRolling3Months = 'Yes' WHERE [date] > EOMONTH(dateadd(Month,-5,@AsOfDt),1) and [date] <= EOMONTH(convert(date,@AsOfDt))
	UPDATE dim_date SET isRolling2Months = 'Yes' WHERE [date] > EOMONTH(dateadd(Month,-4,@AsOfDt),1) and [date] <= EOMONTH(convert(date,@AsOfDt))
	UPDATE dim_date SET isThisMonthAndNextAll = 'Yes' WHERE [date] >= DATEADD(month, DATEDIFF(month, 0, @AsOfDt), 0) and [date] <= EOMONTH(@AsOfDt,1)
	UPDATE dim_date SET isrolling14days = 'No'
	UPDATE dim_date SET isrolling14days = 'Yes' WHERE [date] > convert(date,@AsOfDt-14) and [date] <= convert(date,@AsOfDt)
		
	UPDATE dim_date SET isrolling60days = 'No' WHERE isrolling60days = 'Yes'
	UPDATE dim_date SET isrolling60days = 'Yes' WHERE [date] > convert(date,@AsOfDt-60) and [date] <= convert(date,@AsOfDt)

    UPDATE dim_date SET isrolling60daysFrm60DaysAgo = 'No' 
	UPDATE dim_date SET isrolling60daysFrm60DaysAgo = 'Yes' WHERE [date] > dateadd(day,-120,@AsOfDt) and [date] <= dateadd(day,-60,@AsOfDt)

	UPDATE dim_date SET isRolling12MnthsFrmLastMnth = 'No' 
	UPDATE dim_date SET isRolling12MnthsFrmLastMnth = 'Yes' WHERE [date] > EOMONTH(dateadd(Month,-14,@AsOfDt),1) and [date] <= EOMONTH(dateadd(Month,-1,@AsOfDt))

		UPDATE dim_date SET isRolling24MnthsFrmLastMnth = 'No' 
	UPDATE dim_date SET isRolling24MnthsFrmLastMnth = 'Yes' WHERE [date] > EOMONTH(dateadd(Month,-26,@AsOfDt),1) and [date] <= EOMONTH(dateadd(Month,-1,@AsOfDt))

		UPDATE dim_date SET isRolling6MnthsFrmLastMnth = 'No' 
	UPDATE dim_date SET isRolling6MnthsFrmLastMnth = 'Yes' WHERE [date] > EOMONTH(dateadd(Month,-8,@AsOfDt),1) and [date] <= EOMONTH(dateadd(Month,-1,@AsOfDt))
	
	UPDATE dim_date SET isRolling6MnthsFrm90DaysAgo = 'No' 
	UPDATE dim_date SET isRolling6MnthsFrm90DaysAgo = 'Yes' WHERE [date] > dateadd(day,-270,@AsOfDt) and [date] <= dateadd(day,-90,@AsOfDt)

	
		UPDATE dim_date SET isRolling6Months = 'No' 
	UPDATE dim_date SET isRolling6Months = 'Yes' WHERE [date] > EOMONTH(dateadd(Month,-7,@AsOfDt),1) and [date] <= convert(date,@AsOfDt)


	UPDATE dim_date SET isClosedYear = 'No'
		UPDATE dim_date SET isClosedYear = 'Yes' 
	WHERE year(date) =
	(SELECT year(date) FROM dim_date WHERE isLatestClosedMonth = 'Yes' and isLastDayOfMonth = 'Yes')
	
	UPDATE dim_date SET isCurrentQuarter = 'No'
	UPDATE dim_date SET isCurrentQuarter = 'Yes' WHERE [date] >= DATEADD(qq, DATEDIFF(qq, 0, @AsOfDt), 0) and [date] <= DATEADD (dd, -1, DATEADD(qq, DATEDIFF(qq, 0, @AsOfDt) +1, 0))

	UPDATE dim_date SET isLastQuarter = 'No'
	UPDATE dim_date SET isLastQuarter = 'Yes' WHERE [date] >= DATEADD(month,-3,DATEADD(qq, DATEDIFF(qq, 0, getdate()), 0)) and [date] <= DATEADD(month,-3,DATEADD (dd, -1, DATEADD(qq, DATEDIFF(qq, 0, getdate()) +1, 0)) )

	
	BEGIN TRY;THROW 50000,'',1;END TRY BEGIN CATCH;insert into Staging.dbo.log_DW_Time (LineNumber,MinSinceLast) values (ERROR_LINE(),DATEDIFF(mi,@DtLast,getdate()));END CATCH
set @DtLast = getdate()







--########################################################################################################################################################
 --###################################################### Fill in Dim_User  #####################################################################
 --########################################################################################################################################################


TRUNCATE TABLE Dim_User;
;WITH CTE(ksl_CommunityIdName, ksl_CommunityId, FullName, Title, InternalEmailAddress, DomainName, isUserActive, SystemUserId, dupcnt) AS (
		SELECT c.name
			,c.CRM_CommunityID
			,a.USR_First + ' ' + a.USR_Last
			,r.Name
			,a.USR_Email
			,ISNULL(a.USR_Email, '') AS DomainName -- NULL to Empty String, column doesn't allow null
			,IIF(a.USR_Active = 1, 'Yes', 'No') AS isUserActive
			,a.SalesAppId
			,ROW_NUMBER() OVER (
				PARTITION BY a.USR_Email ORDER BY a.USR_Active DESC
					,LEN(a.USR_First + ' ' + a.USR_Last) ASC
				) AS dupcnt
		FROM KiscoCustom.dbo.Associate a
		JOIN KiscoCustom.dbo.KSL_Roles r ON r.RoleID = a.RoleID
		JOIN KiscoCustom.dbo.Community c ON c.CommunityIDY = a.USR_CommunityIDY
		WHERE a.USR_Email IS NOT NULL
		)

INSERT INTO Dim_User
SELECT ksl_CommunityIdName
	,ksl_CommunityId
	,FullName
	,Title
	,InternalEmailAddress
	,DomainName
	,isUserActive
	,SystemUserId
FROM CTE
WHERE dupcnt = 1


--select * from kslcloud_mscrm.dbo.systemuser
--#############################################################################################################################################
--########################################################################################################################################################
 --###################################################### Fill in Dim_Community  #####################################################################
 --########################################################################################################################################################

 BEGIN TRY;THROW 50000,'',1;END TRY BEGIN CATCH;insert into Staging.dbo.log_DW_Time (LineNumber,MinSinceLast) values (ERROR_LINE(),DATEDIFF(mi,@DtLast,getdate()));END CATCH
set @DtLast = getdate()


TRUNCATE TABLE Dim_Community
INSERT INTO Dim_Community
/*SELECT ksl_name AS 'Community',
ksl_regionIdName AS 'Region'
,ksl_communityId
,ksl_street AS 'Street'
,ksl_city AS 'City'
,ksl_State AS 'State'
,ksl_zip AS Zip
,ksl_COM_Units AS Apartments
,ksl_ShortName AS ShortName
,CASE WHEN  statuscode = 2 THEN 'Inactive'
	WHEN  statuscode = 1 THEN 'Active'
	WHEN  statuscode = 864960000 THEN 'Community in Development'
	WHEN  statuscode = 864960001 THEN 'HQ'
	else 'Other'
	end AS 'Status'
	FROM [172.20.12.111].kslcloud_mscrm.dbo.ksl_community
	*/
	
SELECT ISNULL(ksl_name,Community_Name) AS 'Community'
,ksl_regionIdName AS 'Region'
,ksl_communityId
,ksl_communityId AS Groupedksl_communityId
,coalesce(ksl_street,RETURN_ADDRESS1) AS 'Street'
,coalesce(ksl_city,RETURN_CITY) AS 'City'
,coalesce(ksl_State,RETURN_STATE) AS 'State'
,coalesce(ksl_zip,RETURN_ZIPCODE) AS Zip
,ksl_COM_Units AS Apartments
,ISNULL(ksl_ShortName,s.NAme) AS ShortName
,CASE WHEN  statuscode = 2 or IsInActive = 'Yes' THEN 'Inactive'
	WHEN  statuscode = 1 or IsInActive = 'No' THEN 'Active'
	WHEN  statuscode = 864960000 THEN 'Community in Development'
	WHEN  statuscode = 864960001 THEN 'HQ'
	else 'Other'
	end AS 'Status'
		,ISNULL(
		(select List_Item_Name from staging.dbo.ns_GROUPINGS_LIST where List_ID = GROUPINGs_ID)
	,s.NAme) 'GroupedShortName'
		,CASE WHEN  Include_In_Portfolio_Report_ID = 1 and IsInActive = 'No' --and statuscode = 1 
		THEN 'Portfolio'
	WHEN   Include_In_Portfolio_Report_ID = 2 and IsInActive = 'No' --and statuscode = 1 
	THEN 'CCRC'
	WHEN   Include_In_Portfolio_Report_ID = 3 and IsInActive = 'No' --and statuscode = 1 
	THEN 'Lease-Up'
	--WHEN   IsInActive = 'No' and statuscode = 864960000 
	--THEN 'In-Development'
	Else 'NA' END AS 'IsStabilized'
	,NULL
	,NULL as AssociateMealMultiplier
	,CASE WHEN  Include_In_Portfolio_Report_ID = 1 and IsInActive = 'No' and statuscode = 1 THEN 'Yes'
	WHEN   Include_In_Portfolio_Report_ID = 2 and IsInActive = 'No' and statuscode = 1 THEN 'Yes'
	WHEN   Include_In_Portfolio_Report_ID = 3 and IsInActive = 'No' and statuscode = 1 THEN 'Yes'
	--WHEN ISNULL(ksl_ShortName,s.NAme) = 'CNHEX' then 'Yes'
	Else 'No' END AS IsActiveCommunity

--,(select top 1 LIST_ITEM_NAME from Staging.dbo.NS_OPS_REGIONAL where LIST_ID = OPS_REGIONAL_ID) as OpsRegional
,null as OpsRegional
,null as [IsActiveSalesCommunity]
,null as [IsActiveWithKSL]
,l.list_item_name as Segment
,(select top 1 List_Item_Name from staging.dbo.NS_CAPITAL_PARTNER where List_ID = CAPITAL_PARTNER_ID) Capital_Partner
,pl.LIST_ITEM_NAME Netsuite_Propety_Type 
FROM staging.dbo.NS_SUBSIDIARIES s LEFT JOIN staging.dbo.ksl_community c 
	on c.ksl_ShortName collate SQL_Latin1_General_CP1_CI_AS = s.NAme collate SQL_Latin1_General_CP1_CI_AS and c.ksl_ShortName <> 'MED2'
	left join staging.dbo.NS_Segmentation_list l on s.SEGMENTATION_ID = l.List_id
	left join staging.dbo.NS_PROPERTY_TYPE_LIST pl on s.PROPERTY_TYPE_ID = pl.LIST_ID

UPDATE Dim_Community SET Groupedksl_communityId = (SELECT MAX(c.ksl_communityId) FROM Dim_Community c WHERE c.GroupedShortName = Dim_Community.GroupedShortName and c.Status <> 'Inactive' group by GroupedShortName)
UPDATE Dim_Community SET ksl_communityId = NEWID() WHERE ksl_communityId is null	
update Dim_Community set ksl_communityId = '3F232BA8-C8CF-47D3-B698-526EB8146146' where ShortName = 'LPEX'


update subs set subs.IsStabilized = toplevel.IsStabilized from
--select * from 
(select ShortName,GroupedShortName,IsStabilized from Dim_Community where GroupedShortName <> ShortName) as subs
inner join
(select ShortName,GroupedShortName,IsStabilized from Dim_Community where GroupedShortName = ShortName) as toplevel
on subs.GroupedShortName = toplevel.GroupedShortName
where subs.ShortName <> 'CNHEX'


update subs set subs.IsActiveCommunity = toplevel.IsActiveCommunity from
(select ShortName,GroupedShortName,IsActiveCommunity from Dim_Community where GroupedShortName <> ShortName) as subs
inner join
(select ShortName,GroupedShortName,IsActiveCommunity from Dim_Community where GroupedShortName = ShortName) as toplevel
on subs.GroupedShortName = toplevel.GroupedShortName

update Dim_Community set AssociateMealMultiplier = 0.558580456976179 where shortname = 'AIP'
update Dim_Community set AssociateMealMultiplier = .95 where shortname = 'ASH'
update Dim_Community set AssociateMealMultiplier = .95 where shortname = 'BLA'
update Dim_Community set AssociateMealMultiplier = 0.95 where shortname = 'BP'
update Dim_Community set AssociateMealMultiplier = 0.9375 where shortname = 'CC'
update Dim_Community set AssociateMealMultiplier = 0.863038277511962 where shortname = 'CNH'
update Dim_Community set AssociateMealMultiplier = 0.676699029126214 where shortname = 'CW'
update Dim_Community set AssociateMealMultiplier = 0.838778409090909 where shortname = 'DT'
update Dim_Community set AssociateMealMultiplier = 0.778723404255319 where shortname = 'EC'
update Dim_Community set AssociateMealMultiplier = 0.93484626647145 where shortname = 'FCI'
update Dim_Community set AssociateMealMultiplier = 0.798224374495561 where shortname = 'HG'
update Dim_Community set AssociateMealMultiplier = 0.89863184079602 where shortname = 'LP'
update Dim_Community set AssociateMealMultiplier = 0.84640522875817 where shortname = 'MG'
update Dim_Community set AssociateMealMultiplier = 0.680421422300263 where shortname = 'PP'
update Dim_Community set AssociateMealMultiplier = 0.895004061738424 where shortname = 'PT'
update Dim_Community set AssociateMealMultiplier = .95 where shortname = 'SW'
update Dim_Community set AssociateMealMultiplier = .95 where shortname = 'TF'
update Dim_Community set AssociateMealMultiplier = 0.535454545454545 where shortname = 'VT'
update Dim_Community set AssociateMealMultiplier = 0.885661595205164 where shortname = 'WT'



--Update Quickmar Data
update Dim_Community set QuickmarID = '527' where ShortName = 'PT'
update Dim_Community set QuickmarID = 'KMGL' where ShortName = 'MG'
update Dim_Community set QuickmarID = '83,951' where ShortName = 'VT'
--SELECT * FROM Dim_Community	where GROUPINGs_ID = '6' --order by s.GROUPINGs_ID SELECT * FROM staging.dbo.NS_SUBSIDIARIES
--SELECT Include_In_Portfolio_Report_ID,IsInActive,* FROM staging.dbo.NS_SUBSIDIARIES
--select * FROM [172.20.12.111].kslcloud_mscrm.dbo.KSL_Community 
--select * from staging.dbo.NS_SUBSIDIARIES where GROUPINGs_ID = '6'
--select * From Netsuite.[Kisco Senior Living, LLC].[Administrator].[GROUPINGS_LIST]
--select * from staging.dbo.NS_SUBSIDIARIES where subsidiary_id = 6
--select List_Item_Name,List_ID,* from staging.dbo.ns_GROUPINGS_LIST
--select * from Dim_Community order by groupedshortname
--1FC35920-B2DE-E211-9163-0050568B37AC
update a set a.region = b.region
from Dim_Community a inner join Dim_Community b on a.GroupedShortName = b.ShortName  
where a.Region is null and b.Region is not null

update  Dim_Community set region = 'Sagewood at Daybreak Region' where region = 'Cedarwood at Sandy'


--Set the flag for the communities that are active for sales reports
update Dim_Community set IsActiveSalesCommunity 
							
							= CASE WHEN (([IsStabilized] in ( 'Portfolio') and IsActiveCommunity = 'yes') OR ShortName in ('CV', 'TK', 'CNHEX', 'CAR', 'NWB', 'PRS', 'FTZ')) and ShortName not in ('CNH.HC','LPHC')      
								
								THEN 'Yes' else 'No' END  

update Dim_Community set [IsActiveWithKSL] = CASE WHEN IsActiveCommunity = 'yes' or  GroupedShortName = 'KSL'  Then 'Yes' Else 'No' END




--###################################################################################################################################################################
--######################################################## Fill in Dim_Apartment ####################################################################################
--###################################################################################################################################################################


BEGIN TRY;THROW 50000,'',1;END TRY BEGIN CATCH;insert into Staging.dbo.log_DW_Time (LineNumber,MinSinceLast) values (ERROR_LINE(),DATEDIFF(mi,@DtLast,getdate()));END CATCH
set @DtLast = getdate()
--This is the SP that truncates and populates the Dim_apartment 


--EXEC [dbo].[Fill_Dim_Apartment]


TRUNCATE TABLE Dim_Apartment
INSERT INTO Dim_Apartment
SELECT 
		a.ksl_apartmentId 
		,a.ksl_CommunityIdName
		,a.ksl_name AS Apt_Name
		,a.ksl_UnitFloorPlanIdName AS Floor_Plan
		,f.ksl_UnitTypeIdName AS Unit_Type
		,t.ksl_unitTypeCategoryIdName AS Unit_Type_Category
		,a.ksl_UnitFloorPlanId
		,a.ksl_LevelofLivingIdName AS Level_of_Living
		,a.ksl_CommunityId
		,a.ksl_ApartmentNumber Apt_Number
		--,CASE	WHEN  a.ksl_ApartmentStatus = 864960003 THEN 'Expansion' 
		--		WHEN  a.ksl_ApartmentStatus = 864960000 THEN 'Vacant Not Rent Ready' 
		--		WHEN  a.ksl_ApartmentStatus = 864960001 THEN 'Vacant Rent Ready' 
		--		WHEN  a.ksl_ApartmentStatus = 864960002 THEN 'Occupied' 
		--			END AS 'Apt_Status' 


			  -- This is to get the appropriate status for a given apt, looking both to see if it's finnancially occupied then to see what the status is in the inventory pricing
		--,(SELECT top 1
		--			CASE WHEN 	(SELECT top 1 finOccupancy 
		--							FROM  #temp u
									
		--							where  a.ksl_apartmentid  = u.ksl_apartmentid ) = 1 THEN 'Occupied' 
		--				ELSE 					
		--						CASE Status
		--							WHEN '1' THEN 'Not Rent Ready'
		--							WHEN '2' THEN 'Rent Ready'
		--							WHEN '12' THEN 'Reserved'
		--							WHEN '3' THEN 'Show Ready'
		--							WHEN '4' THEN 'Model'
		--							WHEN '5' THEN 'Reno in progress'
		--							WHEN '6' THEN 'Turn in progress'
		--							WHEN '7' THEN 'Sealed Apartment'
		--							WHEN '10' THEN 'Soon'
		--							WHEN '8' THEN 'Storage/Office'
		--							WHEN '9' THEN 'Respite'
		--							WHEN '11' THEN 'Guest'
		--							ELSE 'Unknown Status'
		--						END 
		--			END AS StatusName
		--		FROM KiscoCustom.dbo.KSL_Apartment a2 where a.ksl_apartmentid = a2.ksl_apartmentid)
		
		, NULL as 'Apt_Status' 
		, CASE	WHEN  a.ksl_LevelofLivingIdName = 'Independent Living' THEN 'IL' 
				WHEN  a.ksl_LevelofLivingIdName = 'Memory Care' THEN 'MC' 
				WHEN  a.ksl_LevelofLivingIdName = 'Assisted Living' THEN 'AL' 
				WHEN  a.ksl_LevelofLivingIdName like 'Skilled Nursing%' THEN 'SNF'
				WHEN  a.ksl_LevelofLivingIdName = 'Cottages' THEN 'CT'
				WHEN  a.ksl_LevelofLivingIdName = 'Not known at this time' THEN 'SNF'
				else 'Undefined'
					END AS Level_of_Living_Short
		,CASE	WHEN a.statecode = 0 THEN 'Active'
				WHEN a.statecode = 1 THEN 'Inactive'
					END AS Apt_State
					
FROM kslcloud_mscrm.dbo.ksl_apartment a WITH (NOLOCK)
LEFT JOIN kslcloud_mscrm.dbo.ksl_unitfloorplan f WITH (NOLOCK) ON a.ksl_UnitFloorPlanId = f.ksl_UnitFloorPlanId
LEFT JOIN kslcloud_mscrm.dbo.ksl_unittype t WITH (NOLOCK) ON t.ksl_unitTypeId = f.ksl_unitTypeId
--WHERE a.ksl_ApartmentStatus <> 864960003  -- 
where a.statecode = 0 and a.ksl_communityid is not null
and a.ksl_ApartmentStatus <> 864960003 --expansion



insert into Dim_Apartment
select RoomID,'La Posada',RoomDescription + ' - La Posada','Skilled Nursing', 'Studio','Studio','ad755977-cbca-ea11-a812-000d3a347e8a','Skilled Nursing','119C1A08-0142-E511-96FE-0050568B37AC'
,RoomDescription + '-SNF', 'Occupied', 'SNF', 'Active'
from [colo-sqlep-1].LP_PCC.[dbo].[view_ods_room] where  Deleted = 'N' order by RoomDescription 







--select * from Dim_Apartment where isinactive = 'No' order by name
--select * from staging.dbo.NS_DEPARTMENTS where isinactive = 'No' order by name
--select distinct deptname from Fact_Financial where not exists(select * from Dim_Department where deptname = name) and deptname is not null





--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Daily Unit Fact %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

BEGIN TRY;THROW 50000,'',1;END TRY BEGIN CATCH;insert into Staging.dbo.log_DW_Time (LineNumber,MinSinceLast) values (ERROR_LINE(),DATEDIFF(mi,@DtLast,getdate()));END CATCH
set @DtLast = getdate()

--DECLARE @AsOfDt datetime
--SET @AsOfDt = GETDATE() -1 







--SELECT * FROM Dim_Apartment
INSERT INTO Fact_Unit (dt,ksl_CommunityId,ksl_apartmentId,Level_of_Living_Short)
SELECT [date],ksl_CommunityId,ksl_apartmentId,left(Level_of_Living_Short,5)
FROM Dim_Date,Dim_Apartment  
WHERE date between convert(date,@AsOfDt - 3) and convert(date,@AsOfDt)
--and not exists(SELECT * FROM Fact_Unit f WHERE f.dt = Dim_Date.date  and f.ksl_CommunityId = Dim_Apartment.ksl_CommunityId)
and not exists(SELECT * FROM Fact_Unit f WHERE f.dt = Dim_Date.date  and f.ksl_apartmentId = Dim_Apartment.ksl_apartmentId)
AND  Dim_Apartment.Apt_State = 'Active' 




 --### Update Fincancial Occupancy


 BEGIN TRY;THROW 50000,'',1;END TRY BEGIN CATCH;insert into Staging.dbo.log_DW_Time (LineNumber,MinSinceLast) values (ERROR_LINE(),DATEDIFF(mi,@DtLast,getdate()));END CATCH
set @DtLast = getdate()
			 --If this section needs to be run on it's own, uncomment the below
					/*
						DECLARE @AsOfDt datetime
						SET @AsOfDt = GETDATE()

						DECLARE @dt_start date
						DECLARE @dt_end date
						DECLARE @dt_startx date

						SET @dt_start = @AsOfDt - 90
						SET @dt_end = @AsOfDt			-- @AsOfDt = GETDATE()
				  --*/

			-- Run below from 90 days ago up through today
					SET @dt_startx = @dt_start				-- = GETDATE() - 90
							WHILE @dt_startx <= @dt_end
					BEGIN

			--INSERT months AS resident
					UPDATE Fact_Unit SET FinOccupancy = 0
						, MonthsAsResidentU = NULL 
					WHERE dt = @dt_startx

					UPDATE f SET f.FinOccupancy = x.Proj_Occupancy
						,MonthsAsResidentU = DATEDIFF(Month,CAST(ksl_begindate AS DATE),@dt_startx)
					FROM Fact_Unit f INNER JOIN
					(
							SELECT
								C.ksl_communityid AS CommunityID,
								C.ksl_Name AS CommunityName,
								convert(varchar(100),AFH.ksl_ApartmentId) as ksl_ApartmentId,
								CONVERT(decimal,COUNT(DISTINCT APT.ksl_apartmentid)) AS Proj_Occupancy,
								MAX(AFH.ksl_begindate) AS ksl_begindate
							FROM staging.dbo.ksl_apartmentfinancialhistory AFH
								LEFT JOIN staging.dbo.KSL_Community C 
									ON C.ksl_Communityid = AFH.ksl_communityid
								LEFT JOIN staging.dbo.ksl_apartment APT 
									ON APT.ksl_apartmentid = convert(varchar(100),AFH.ksl_apartmentid)
		
							WHERE --AFH.ksl_communityid IN (@Community) and 
							AFH.statecode = 0
							AND AFH.ksl_begintransactiontype IN ('864960001','864960003') -- Actual Move In, Actual Transfer In
							AND 
								(
									(
										CAST(AFH.ksl_enddate AS DATE) > @dt_startx AND CAST(AFH.ksl_begindate AS DATE) <= @dt_startx
										AND AFH.ksl_endtransactiontype IN ('864960006','864960004') -- Actual Move Out, Actual Transfer Out, Scheduled Transfer, Scheduled Move Out
									)
								OR 
								(
									@dt_startx >= CAST(AFH.ksl_begindate AS DATE)  AND
									((CAST(AFH.ksl_enddate AS DATE)  IS NULL) or (AFH.ksl_endtransactiontype IN ('864960002','864960005')))--Scheduled Transfer, Scheduled Move Out
		
		 
								)
							)
									GROUP BY C.ksl_Name, C.ksl_communityid ,AFH.ksl_ApartmentId
					) AS x 

						ON f.ksl_ApartmentId = x.ksl_ApartmentId 
						WHERE f.dt = @dt_startx 
						SET @dt_startx = DATEADD(dd,1,@dt_startx)
	
				END


				--Select * from Fact_Unit where dt > getdate() -30


			--Move select units to other communities
			/*
					UPDATE fact_unit 
					SET    ksl_communityid = (SELECT TOP 1 ksl_communityid 
											  FROM   dim_community 
											  WHERE  shortname = 'CNH.HC') 
					WHERE  ksl_apartmentid IN (SELECT ksl_apartmentid 
											   FROM   dim_apartment 
											   WHERE 
								  ksl_communityid = '39C35920-B2DE-E211-9163-0050568B37AC' 
								  AND level_of_living_short <> 'IL') 


					UPDATE fact_unit 
					SET    ksl_communityid = (SELECT TOP 1 ksl_communityid 
											  FROM   dim_community 
											  WHERE  shortname = 'CNHEX') 
					WHERE  ksl_apartmentid IN (select convert(varchar(100),ksl_apartmentid) from staging..ksl_apartment where ksl_legalentity = 'CNHEX') 



					UPDATE fact_unit 
					SET    ksl_communityid = (SELECT TOP 1 ksl_communityid 
											  FROM   dim_community 
											  WHERE  shortname = 'LPEX') 
					WHERE  ksl_apartmentid IN (SELECT ksl_apartmentid 
											   FROM   dim_apartment 
											   WHERE  ksl_communityidname = 'La Posada' 
													  AND level_of_living_short = 'IL' 
													  AND apt_number LIKE '4%') 

					UPDATE fact_unit 
					SET    ksl_communityid = (SELECT TOP 1 ksl_communityid 
											  FROM   dim_community 
											  WHERE  shortname = 'LPHC') 
					WHERE  ksl_apartmentid IN (SELECT ksl_apartmentid 
											   FROM   dim_apartment 
											   WHERE  ksl_communityidname = 'La Posada' 
													  AND level_of_living_short <> 'IL') 






						UPDATE fact_unit 
					SET    ksl_communityid = (SELECT TOP 1 ksl_communityid 
											  FROM   dim_community 
											  WHERE  shortname = 'CWEX') 
					WHERE  ksl_apartmentid IN (select convert(varchar(100),ksl_apartmentid) from staging..ksl_apartment where ksl_legalentity = 'CWEX') 

					*/



					/*
								UPDATE u SET u.ksl_communityid = c.ksl_communityId
														--SELECT *  
														FROM fact_unit u  inner JOIN KSLCLOUD_MSCRM..ksl_apartment apt ON u.ksl_apartmentId = convert(varchar(100),apt.ksl_apartmentid)
														INNER JOIN dim_community c ON c.ShortName = apt.ksl_legalentity
														WHERE apt.statecode_displayname = 'Active' AND u.ksl_communityid <> c.ksl_communityId
														*/
	;WITH Map AS (
    SELECT
        AptIdVarchar = CONVERT(varchar(100), apt.ksl_apartmentid),
        CommunityId  = c.ksl_communityId
    FROM KSLCLOUD_MSCRM..ksl_apartment apt
    JOIN dim_community c
      ON c.ShortName = apt.ksl_legalentity
    WHERE apt.statecode_displayname = 'Active'   -- Active (use the code, not *_displayname)
)
UPDATE u
SET u.ksl_communityid = m.CommunityId
FROM fact_unit u
JOIN Map m
  ON m.AptIdVarchar = u.ksl_apartmentId
WHERE
    u.ksl_communityid IS NULL
 OR u.ksl_communityid <> m.CommunityId;



--For LP, PCC Import

					UPDATE fact_unit 
					SET    ksl_communityid = (SELECT TOP 1 ksl_communityid 
											  FROM   dim_community 
											  WHERE  shortname = 'LPHC') 
					where len(ksl_apartmentId) < 10
					and ksl_communityid <> (SELECT TOP 1 ksl_communityid 
											  FROM   dim_community 
											  WHERE  shortname = 'LPHC') 

													  


											   
											   

					




--select * from staging..ksl_apartment where ksl_legalentity = 'LPHC'



			--select * from Dim_Apartment where ksl_CommunityIdName = 'La Posada' and apt_number like '4%'
			--select * from Dim_Community where shortname = 'CNHEX'



			-- Now update Physical Occupancy

					SET @dt_startx = @dt_start
							WHILE @dt_startx <= @dt_end
					BEGIN
					UPDATE Fact_Unit SET PhysOccupancy = 0 WHERE dt = @dt_startx

							UPDATE f SET f.PhysOccupancy = x.Proj_Occupancy
							FROM Fact_Unit f INNER JOIN
							(
							SELECT
								C.ksl_communityid AS CommunityID,
								C.ksl_Name AS CommunityName,
								convert(varchar(100),ROH.ksl_ApartmentId) as ksl_ApartmentId,
								CONVERT(decimal,COUNT(APT.ksl_apartmentid)) AS Proj_Occupancy
							FROM (select ksl_begindate,ksl_contactid,ksl_begintxntype,ksl_ApartmentId,statecode,ksl_enddate,ksl_endtxntype ,ksl_communityid
							from staging.dbo.ksl_residentoccupancyhistory
					group by ksl_begindate,ksl_contactid,ksl_begintxntype,ksl_ApartmentId,statecode,ksl_begintxntype,ksl_enddate,ksl_communityid,ksl_endtxntype) ROH
							inner JOIN staging.dbo.KSL_Community C ON C.ksl_Communityid = ROH.ksl_communityid
							inner JOIN staging.dbo.ksl_apartment APT ON APT.ksl_apartmentid = convert(varchar(100),ROH.ksl_apartmentid)
		
							WHERE --AFH.ksl_communityid IN (@Community) and 
							ROH.statecode = 0
							AND ROH.ksl_begintxntype IN ('864960001','864960003') -- Actual Move In, Actual Transfer In
					AND 
					((
						ROH.ksl_enddate > @dt_startx AND ROH.ksl_begindate <= @dt_startx
						AND ROH.ksl_endtxntype IN ('864960006','864960004') -- Actual Move Out, Actual Transfer Out
						)
						OR 
						(
						ROH.ksl_enddate IS NULL AND @dt_startx >= ROH.ksl_begindate  
					))
							GROUP BY C.ksl_Name, C.ksl_communityid ,ROH.ksl_ApartmentId
						) AS x ON f.ksl_ApartmentId = x.ksl_ApartmentId WHERE f.dt = @dt_startx 
						SET @dt_startx = DATEADD(dd,1,@dt_startx)
					END





BEGIN TRY;THROW 50000,'',1;END TRY BEGIN CATCH;insert into Staging.dbo.log_DW_Time (LineNumber,MinSinceLast) values (ERROR_LINE(),DATEDIFF(mi,@DtLast,getdate()));END CATCH
set @DtLast = getdate()

--Update Sq Ft**********************************************************
	
--select ksl_marketrate,* from kslcloud_mscrm.dbo.ksl_apartment
SET @dt_start = @AsOfDt - 4
SET @dt_end = @AsOfDt	


					SET @dt_startx = @dt_start
							WHILE @dt_startx <= @dt_end
					BEGIN
update y set Square_Ft = x.ksl_squarefootage,Draft_Market_Rate = x.ksl_marketrate
from Fact_Unit y
inner join
(select ksl_squarefootage ,convert(varchar(100),ksl_apartmentId) as ksl_apartmentId,ksl_marketrate
FROM kslcloud_mscrm.dbo.ksl_apartment a WITH (NOLOCK)
LEFT JOIN kslcloud_mscrm.dbo.ksl_unitfloorplan f WITH (NOLOCK) ON a.ksl_UnitFloorPlanId = f.ksl_UnitFloorPlanId
) x on x.ksl_apartmentId = y.ksl_ApartmentId and y.dt = @dt_startx
					SET @dt_startx = DATEADD(dd,1,@dt_startx)
					END




--Update Fact_Unit with days vacant

					SET @dt_startx = @dt_start
							WHILE @dt_startx <= @dt_end
					BEGIN
update Fact_Unit set Days_Vacant = NULL where dt = @dt_startx
update y set Days_Vacant = x.dvacant
from Fact_Unit y
inner join
(select
 (select datediff(day,isnull(max(ksl_EndDate),@AsOfDt),@dt_startx) from [staging].[dbo].[ksl_apartmentfinancialhistory] f 
 where a.ksl_apartmentId = convert(varchar(100),f.ksl_ApartmentId) and ksl_EndTransactionType in ('864960006','864960004')) as dvacant
,a.ksl_apartmentId from Dim_Apartment a inner join [dbo].[Fact_Unit] u on a.ksl_apartmentId = u.ksl_apartmentId and u.dt = @dt_startx where  FinOccupancy = 0
) x on x.ksl_apartmentId = y.ksl_ApartmentId and y.dt = @dt_startx
					SET @dt_startx = DATEADD(dd,1,@dt_startx)
					END

	/*				
	;WITH LastEnd AS (
    SELECT
        ApartmentId = CONVERT(varchar(100), f.ksl_ApartmentId),
        LastEndDate = MAX(f.ksl_EndDate)
    FROM staging.dbo.ksl_apartmentfinancialhistory f
    WHERE f.ksl_EndTransactionType IN ('864960006','864960004')
    GROUP BY CONVERT(varchar(100), f.ksl_ApartmentId)
)
-- 2) Clear once for the whole range (instead of per day)
UPDATE fu
SET Days_Vacant = NULL
FROM dbo.Fact_Unit fu
WHERE fu.dt >= @dt_start
  AND fu.dt <= @dt_end;

-- 3) Set Days_Vacant for all dates in one shot
UPDATE fu
SET fu.Days_Vacant = DATEDIFF(day, ISNULL(le.LastEndDate, @AsOfDt), fu.dt)
FROM dbo.Fact_Unit fu
JOIN dbo.Dim_Apartment a
  ON a.ksl_apartmentId = fu.ksl_apartmentId
LEFT JOIN LastEnd le
  ON le.ApartmentId = a.ksl_apartmentId
WHERE fu.dt >= @dt_start
  AND fu.dt <= @dt_end
  AND fu.FinOccupancy = 0;

*/








SET @dt_start = @AsOfDt - 90
SET @dt_end = @AsOfDt	
					--,ScheduledOutNextMnth =

					update  u set ScheduledOutThisMnth =  cnt
					from Fact_Unit u inner join (select count(*) as cnt ,convert(varchar(100),ksl_apartmentId) as ksl_apartmentId from
					 staging.dbo.ksl_apartmentfinancialhistory where ksl_endtransactiontype_displayname in ('Scheduled Move Out','Actual Move out')
					 and statuscode_displayname = 'active'
					and  year(ksl_enddate) = year(@AsOfDt)  
					and  month(ksl_enddate) = month(@AsOfDt) 
					--and ksl_leveloflivingidname <> 'Skilled Nursing'
					 group by ksl_apartmentId) as afh on afh.ksl_apartmentId = u.ksl_ApartmentId 
					where convert(date,u.dt)  = convert(date,@AsOfDt)
					
					
					update  u set ScheduledOutNextMnth =  cnt
					from Fact_Unit u inner join (select count(*) as cnt ,convert(varchar(100),ksl_apartmentId) as ksl_apartmentId from
					 staging.dbo.ksl_apartmentfinancialhistory where ksl_endtransactiontype_displayname in ('Scheduled Move Out','Actual Move out')
					 and statuscode_displayname = 'active'
					and  year(ksl_enddate) = year(DATEADD(month, 1,@AsOfDt))  
					and  month(ksl_enddate) = month(DATEADD(month, 1,@AsOfDt)) 
					--and ksl_leveloflivingidname <> 'Skilled Nursing'
					 group by ksl_apartmentId) as afh on afh.ksl_apartmentId = u.ksl_ApartmentId 
					where convert(date,u.dt) = convert(date,@AsOfDt)


					--select * from staging.dbo.ksl_apartmentfinancialhistory where 


----Update La Posada with data from PCC
----TODO uncomment this
update u set FinOccupancy = 1, PhysOccupancy = 1
from Fact_Unit u inner join [colo-sqlep-1].LP_PCC.dbo.[view_ods_daily_census_v2] pcc on u.dt = pcc.CensusDate where u.ksl_apartmentId = convert(varchar(50),pcc.RoomID) and u.dt > convert(date,getdate()-1500) 
--order by PatientLastName 
----update PhysOccupancy

			



 -- This is to get the appropriate status for a given apt, looking both to see if it's finnancially occupied then to see what the status is in the inventory pricing
 -- Set to run after Fact_unit update to get most current financial occupancy date
	











	

























		








IF object_id('tempdb..#temp') IS NOT NULL
DROP TABLE #temp

SELECT * into #temp FROM  Fact_Unit inner join dim_date on dt = date
									where isyesterday= 'yes' and  TRY_CAST(ksl_apartmentid AS UNIQUEIDENTIFIER) IS NOT NULL



Update a 
set Apt_Status =
	 (SELECT top 1
					CASE WHEN 	(SELECT top 1 finOccupancy 
									FROM  #temp u
									
									where  a.ksl_apartmentid  = u.ksl_apartmentid ) = 1 THEN 'Occupied' 
						ELSE 					
								CASE Status
									WHEN '1' THEN 'Not Rent Ready'
									WHEN '2' THEN 'Rent Ready'
									WHEN '12' THEN 'Reserved'
									WHEN '3' THEN 'Show Ready'
									WHEN '4' THEN 'Model'
									WHEN '5' THEN 'Reno in progress'
									WHEN '6' THEN 'Turn in progress'
									WHEN '7' THEN 'Sealed Apartment'
									WHEN '10' THEN 'Soon'
									WHEN '8' THEN 'Storage/Office'
									WHEN '9' THEN 'Respite'
									WHEN '11' THEN 'Guest'
									ELSE 'Unknown Status'
								END 
					END AS StatusName
				FROM KiscoCustom.dbo.KSL_Apartment a2 where a.ksl_apartmentid = a2.ksl_apartmentid) 
FROM  (SELECT *
	FROM  Dim_Apartment
	where TRY_CAST(ksl_apartmentid AS UNIQUEIDENTIFIER) IS not NULL ) a 
	
	 
 --### Update Apt VacancyStatus
 update u
set VacancyStatus = 
	 
	 (SELECT top 1
					CASE WHEN 	finOccupancy 
									 = 1 THEN 'Occupied' 
						ELSE 					
								CASE Status
									WHEN '1' THEN 'Not Rent Ready'
									WHEN '2' THEN 'Rent Ready'
									WHEN '12' THEN 'Reserved'
									WHEN '3' THEN 'Show Ready'
									WHEN '4' THEN 'Model'
									WHEN '5' THEN 'Reno in progress'
									WHEN '6' THEN 'Turn in progress'
									WHEN '7' THEN 'Sealed Apartment'
									WHEN '10' THEN 'Soon'
									WHEN '8' THEN 'Storage/Office'
									WHEN '9' THEN 'Respite'
									WHEN '11' THEN 'Guest'
									ELSE 'Unknown Status'
								END 
					END AS StatusName
				FROM KiscoCustom.dbo.KSL_Apartment a2 where a.ksl_apartmentid = a2.ksl_apartmentid) 
FROM (SELECT * FROM  Fact_Unit WHERE TRY_CAST(ksl_apartmentId AS UNIQUEIDENTIFIER) IS not NULL  AND ksl_apartmentId IS NOT NULL )  u 
			left join  KiscoCustom.dbo.KSL_Apartment  a on cast(u.ksl_apartmentId as uniqueidentifier) = cast(a.ksl_apartmentId as uniqueidentifier)
  WHERE dt between convert(date,@AsOfDt - 1) and convert(date,@AsOfDt)



  
--Update Fact_Unit with days vacant for operationally sellable units 

/*
					SET @dt_startx = @dt_start
							WHILE @dt_startx <= @dt_end
					BEGIN
update Fact_Unit set Days_Vacant_Sellable = NULL where dt = @dt_startx
update y set Days_Vacant_Sellable = x.dvacant
from Fact_Unit y
inner join
(  select
		 (  select datediff(day,isnull(min(dt),@AsOfDt), @dt_startx
					) from [DataWarehouse].[dbo].[Fact_Unit] f 
		 where convert(varchar(100),f.ksl_ApartmentId) = a.ksl_apartmentId
		 and VacancyStatus not in (	'Turn in progress' , 'Reno in progress', 'Not Rent Ready')
) 
		 as dvacant
		,a.ksl_apartmentId 
  from Dim_Apartment a 
  inner join [dbo].[Fact_Unit] u on a.ksl_apartmentId = u.ksl_apartmentId and u.dt = @dt_startx 
  where  FinOccupancy = 0
	and VacancyStatus not in (	'Turn in progress' , 'Reno in progress', 'Not Rent Ready')
							) x on x.ksl_apartmentId = y.ksl_ApartmentId and y.dt = @dt_startx
					SET @dt_startx = DATEADD(dd,1,@dt_startx)
					END
					*/



-- #################################################################################################
--########################################################################################################################################################
 --###################################################### INSERT Department #####################################################################
 --########################################################################################################################################################


 BEGIN TRY;THROW 50000,'',1;END TRY BEGIN CATCH;insert into Staging.dbo.log_DW_Time (LineNumber,MinSinceLast) values (ERROR_LINE(),DATEDIFF(mi,@DtLast,getdate()));END CATCH
set @DtLast = getdate()


TRUNCATE TABLE Dim_Department
INSERT  INTO Dim_Department 
([AOD_DEPT_CODE],[APPROVER_ID],[DATE_LAST_MODIFIED],[DEPARTMENT_EXTID],[DEPARTMENT_ID],[DEPT_CODE],[FULL_NAME],[ISINACTIVE],[NAME],[PARENT_ID],Grouping

)
SELECT [AOD_DEPT_CODE],[APPROVER_ID],[DATE_LAST_MODIFIED],[DEPARTMENT_EXTID],[DEPARTMENT_ID],[DEPT_CODE],[FULL_NAME],[ISINACTIVE],
[NAME],[PARENT_ID],coalesce((SELECT List_Item_Name from  staging.dbo.NS_DEPARTMENT_GROUPINGS where NS_DEPARTMENT_GROUPINGS.List_ID = Department_Groupings_ID),Name) as Grouping FROM staging.dbo.NS_DEPARTMENTS




-- #################################################################################################
 --########################################################################################################################################################
 --###################################################### INSERT Product Type #####################################################################
 --########################################################################################################################################################




 BEGIN TRY;THROW 50000,'',1;END TRY BEGIN CATCH;insert into Staging.dbo.log_DW_Time (LineNumber,MinSinceLast) values (ERROR_LINE(),DATEDIFF(mi,@DtLast,getdate()));END CATCH
set @DtLast = getdate()


TRUNCATE TABLE Dim_Product_Type
INSERT INTO Dim_Product_Type
SELECT 
[CLASS_EXTID], [CLASS_ID], [DATE_LAST_MODIFIED], [FULL_NAME], [ISINACTIVE], [NAME], [PARENT_ID], [PRODUCT_TYPE_CODE]
,CASE name WHEN  'IL' THEN  'Independent Living'
WHEN  'MC' THEN  'Memory Care'
WHEN  'AL' THEN  'Assisted Living'
WHEN  'SNF' THEN  'Skilled Nursing'
else 'Undefined'
END AS Long_Name
 FROM  [staging]..[NS_CLASSES]
Union All
SELECT 10,10,'1/1/2018','CT','No','CT',NULL,10,'Cottages'




 --########################################################################################################################################################
 --###################################################### INSERT Fact_SalesStats #####################################################################
 --########################################################################################################################################################


 BEGIN TRY;THROW 50000,'',1;END TRY BEGIN CATCH;insert into Staging.dbo.log_DW_Time (LineNumber,MinSinceLast) values (ERROR_LINE(),DATEDIFF(mi,@DtLast,getdate()));END CATCH
set @DtLast = getdate()


 ;WITH 
		LastContact AS
						(select 
						b.accountid,
							   --Get Last Contact Activity Information
							   b.Subject as ActivitySubject,
							   b.ActivityTypeCode as LCType,
							   b.ActivityTypeDetail as LCTypeDetail,
							   b.regardingobjectid,
							   b.CompletedDate as LastContactDate,
							   b.notes as LCNotes,
						ROW_NUMBER() OVER (PARTITION BY b.accountid ORDER BY b.CompletedDate  desc) AS RowNum 
						from 
						(
						SELECT L.accountid, PC.Subject, PC.ActivityTypeCode, NULL as ActivityTypeDetail, PC.regardingobjectid, PC.scheduledstart as CompletedDate, PC.description as notes
						FROM [KSLCLOUD_MSCRM].dbo.Account L WITH (NOLOCK)
						inner JOIN [KSLCLOUD_MSCRM].dbo.activities PC WITH (NOLOCK) ON PC.RegardingObjectId = L.accountid
						WHERE PC.activitytypecode IN ('Outbound Phone Call', 'Incoming Phone Call', 'Committed Face Appointment', 'Unscheduled Walk-In', 'Inbound Email')
							AND PC.ksl_resultoptions_displayname = 'Completed
						 ) as b
						)
		,
		LastCE AS
						(select 
						b.accountid,
							   --Get Last Contact Activity Information
							   b.Subject as ActivitySubject,
							   b.ActivityTypeCode as LCEType,
							   b.ActivityTypeDetail as LCETypeDetail,
							   b.regardingobjectid,
							   b.CompletedDate as LastCEDate,
							   b.notes as LCENotes,
						ROW_NUMBER() OVER (PARTITION BY b.accountid ORDER BY b.CompletedDate  desc) AS RowNum 
						from 
						(
						SELECT L.accountid, PC.Subject, PC.ActivityTypeCode, PC.ksl_appointmenttype as ActivityTypeDetail, PC.regardingobjectid, PC.scheduledstart as CompletedDate, PC.description as notes
						FROM [KSLCLOUD_MSCRM].dbo.Account L WITH (NOLOCK)
						inner JOIN [KSLCLOUD_MSCRM].dbo.appointment PC WITH (NOLOCK) ON PC.RegardingObjectId = L.accountid
						WHERE  
						PC.statecode_displayname = 'Completed'
						and PC.ksl_resultoptions in ('864960005','864960004','864960006') -- 864960004:Community Experience  864960006: Virtual Experience
						 ) as b
						)
		,
		 NextActivity AS
						(select 
						b.accountid,
							   --Get Next Activity Information
							   b.Subject as ActivitySubject,
							   b.ActivityTypeCode as NAType,
							   b.ActivityTypeDetail as NATypeDetail,
							   b.regardingobjectid,
							   b.scheduledend as NextActivityDate,
							   b.notes as NANotes,
							   b.activityid as NAActivityid,
							   b.ownerid,
						ROW_NUMBER() OVER (PARTITION BY accountid ORDER BY b.scheduledend  asc) AS RowNum 
						from 
						(
						SELECT L.accountid, PC.Subject, PC.ActivityTypeCode, PC.ksl_phonecalltype as ActivityTypeDetail, PC.regardingobjectid, PC.scheduledend, PC.description as notes, PC.activityid, PC.ownerid
						FROM [KSLCLOUD_MSCRM].dbo.Account L WITH (NOLOCK)
						inner JOIN [KSLCLOUD_MSCRM].dbo.PhoneCall PC WITH (NOLOCK) ON PC.RegardingObjectId = L.accountid
						WHERE --PC.actualend IS NULL AND PC.scheduledend IS NOT NULL
						 PC.statecode_displayname <> 'Completed'
						Union All
						SELECT L.accountid, PC.Subject, PC.ActivityTypeCode, PC.ksl_appointmenttype as ActivityTypeDetail, PC.regardingobjectid, PC.scheduledstart as scheduledend, PC.description as notes, PC.activityid, PC.ownerid
						FROM [KSLCLOUD_MSCRM].dbo.Account L WITH (NOLOCK)
						inner JOIN [KSLCLOUD_MSCRM].dbo.appointment PC WITH (NOLOCK) ON PC.RegardingObjectId = L.accountid
						WHERE  PC.statecode_displayname <> 'Completed'
						Union All
						SELECT L.accountid, PC.Subject, PC.ActivityTypeCode, NULL as ActivityTypeDetail, PC.regardingobjectid, PC.scheduledend, PC.description as notes, PC.activityid, PC.ownerid
						FROM [KSLCLOUD_MSCRM].dbo.Account L WITH (NOLOCK)
						inner JOIN [KSLCLOUD_MSCRM].dbo.task PC WITH (NOLOCK) ON PC.RegardingObjectId = L.accountid
						WHERE  PC.statecode_displayname <> 'Completed'
						Union All
						SELECT L.accountid, PC.Subject, PC.ActivityTypeCode, PC.ksl_emailtype as ActivityTypeDetail, PC.regardingobjectid, PC.scheduledend, PC.description as notes, PC.activityid, PC.ownerid
						FROM [KSLCLOUD_MSCRM].dbo.Account L WITH (NOLOCK)
						inner JOIN [KSLCLOUD_MSCRM].dbo.email PC WITH (NOLOCK) ON PC.RegardingObjectId = L.accountid
						WHERE  PC.statecode_displayname <> 'Completed'
						 ) as b
						)
		,
		 LastAttempt AS
						(select 
						b.accountid,
							   --Get Last Attempt Information
							   b.Subject as ActivitySubject,
							   b.ActivityTypeCode as LAType,
							   b.ActivityTypeDetail as LATypeDetail,
							   b.regardingobjectid,
							   b.CompletedDate as LastAttemptDate,
							   b.notes as LANotes,
						ROW_NUMBER() OVER (PARTITION BY accountid ORDER BY b.CompletedDate  desc) AS RowNum 
						from 
						(
						SELECT L.accountid, PC.Subject, PC.ActivityTypeCode, PC.ksl_phonecalltype as ActivityTypeDetail, PC.regardingobjectid, PC.ksl_datecompleted as CompletedDate, left(PC.description,300) as notes
						FROM [KSLCLOUD_MSCRM].dbo.Account L WITH (NOLOCK)
						inner JOIN [KSLCLOUD_MSCRM].dbo.PhoneCall PC WITH (NOLOCK) ON PC.RegardingObjectId = L.accountid
						WHERE 
						PC.statecode_displayname = 'Completed' --Workflow changed call to completed
						and PC.ksl_resultoptions <> '864960008' --Result: Anything but cancelled
						Union All
						SELECT L.accountid, PC.Subject, PC.ActivityTypeCode, PC.ksl_appointmenttype as ActivityTypeDetail, PC.regardingobjectid, PC.scheduledstart as CompletedDate, left(PC.description,300) as notes
						FROM [KSLCLOUD_MSCRM].dbo.Account L WITH (NOLOCK)
						inner JOIN [KSLCLOUD_MSCRM].dbo.appointment PC WITH (NOLOCK) ON PC.RegardingObjectId = L.accountid
						WHERE  
						PC.statecode_displayname = 'Completed'
						and PC.ksl_resultoptions <> '100000000' --Result: 100000000:Cancelled 
						Union All
						SELECT L.accountid, PC.Subject, PC.ActivityTypeCode, PC.ksl_emailtype as ActivityTypeDetail, PC.regardingobjectid, PC.actualend as CompletedDate, left(PC.description,300) as notes
						FROM [KSLCLOUD_MSCRM].dbo.Account L WITH (NOLOCK)
						inner JOIN [KSLCLOUD_MSCRM].dbo.email PC WITH (NOLOCK) ON PC.RegardingObjectId = L.accountid
						WHERE  
						PC.statecode_displayname = 'Completed'
						and PC.ksl_emailtype = '864960002' --Outgoing
						UNION ALL
						SELECT L.accountid, PC.Subject, PC.ActivityTypeCode, PC.ksl_lettertype as ActivityTypeDetail, PC.regardingobjectid, PC.actualend as CompletedDate, left(PC.description,300) as notes
						FROM [KSLCLOUD_MSCRM].dbo.Account L WITH (NOLOCK)
						inner JOIN [KSLCLOUD_MSCRM].dbo.letter PC WITH (NOLOCK) ON PC.RegardingObjectId = L.accountid
						WHERE  
						PC.statecode_displayname = 'Completed'
						Union All
						SELECT activityid ,PC.Subject, PC.ActivityTypeCode, 1001 as ActivityTypeDetail, PC.regardingobjectid,PC.actualend as CompletedDate, left(PC.description,300) as notes

						FROM kslcloud_mscrm.dbo.Account L WITH (NOLOCK)
						inner JOIN kslcloud_mscrm.dbo.ksl_sms PC WITH (NOLOCK) ON PC.RegardingObjectId = L.accountid
 
						 ) as b
		)

 --%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Insert into [DataWarehouse].[dbo].[Fact_SalesStats] ( [dt],[Owner],[OwnerID],[Community],[CommunityID], RADcount  ,DataComplianceCount ,PastDueActivityCount, activeLeads )

 --%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



Select u.dt, u.[FullName], u.[SystemUserId], [ksl_CommunityIdName]
      ,[ksl_CommunityId] --, u.Title
		,coalesce(RADcount,0) RADcount  
		,coalesce(SourceCategoryCount,0)  DataCompliance 
		,coalesce(PastDueActivityCount ,0) PastDueActivityCount
		,coalesce(activeLeads ,0) activeLeads
		from 
			--
				(SELECT  
				
						cast(getdate() as date) as dt, 
						[FullName], [SystemUserId] ,[ksl_CommunityIdName]
							,[ksl_CommunityId], Title

										  FROM [DataWarehouse].[dbo].[Dim_User]
										  where [isUserActive] = 'yes'
										  and Title like '%sales%'
										 
										  and Title not like '%VP%') u


left outer join 
						--RADcount
									(
								SELECT
								cast(getdate() as date) as dt, 
								systemuserid,
								u.fullname,
								title,
								count(A.accountID) as RADcount

								--'RADcount' Description


								FROM [KSLCLOUD_MSCRM].dbo.Account A
								OUTER APPLY (select top 1 *  from NextActivity where regardingobjectid = A.accountid order by NextActivity.NextActivityDate asc) NA
								OUTER APPLY (select top 1 *  from LastContact where regardingobjectid = A.accountid order by LastContact.LastContactDate desc) LC
								OUTER APPLY (select top 1 *  from LastAttempt where regardingobjectid = A.accountid order by LastAttempt.LastAttemptDate desc) LA
								OUTER APPLY (select top 1 *  from LastCE where regardingobjectid = A.accountid order by LastCE.LastCEDate desc) LCE
								LEFT JOIN [KSLCLOUD_MSCRM].dbo.SystemUser U ON U.SystemUserId = A.OwnerID
								LEFT JOIN [KSLCLOUD_MSCRM].dbo.ksl_community C ON C.ksl_communityId = A.ksl_CommunityId
								LEFT JOIN [KSLCLOUD_MSCRM].dbo.contact con ON con.contactid = A.primarycontactid

								Where 
								--A.ksl_communityid = '39C35920-B2DE-E211-9163-0050568B37AC' 

								--and 
								a.statuscode_displayname in ( 'Lead')
								--and
								--[isUserActive] = 'yes'
								--		  and Title like '%sales%'
										 
										  and Title not like '%VP%'
								and (a.ksl_mostrecentcommunityexperience < getdate() -30 or a.ksl_mostrecentcommunityexperience is null )
								and a.ksl_initialinquirydate < getdate() -30
								and (a.ksl_reservationfeetransactiondate is null  )


								and (0 <= 
								case 

								when a.ksl_moveintiming_displayname = '> 2 Years'
								then datediff(day,coalesce(LA.LastAttemptDate,getdate()-90) + 90, getdate()) 

								when ksl_mostrecentcommunityexperience >= getdate()-120 and LC.LastContactDate > getdate() - 60
										and (ksl_waitlisttransactiondate is null and a.ksl_waitlistenddate is not NULL)  
								then datediff(day,LA.LastAttemptDate + 14, getdate())

								when  ksl_mostrecentcommunityexperience >= getdate()-270 and LC.LastContactDate > getdate() - 180 
										and (ksl_waitlisttransactiondate is null and a.ksl_waitlistenddate is not NULL) 
								then datediff(day,LA.LastAttemptDate + 45, getdate())

								when  ksl_losttocompetitoron is not null --and (ksl_waitlisttransactiondate is null and a.ksl_waitlistenddate is not NULL)  
								then datediff(day,LA.LastAttemptDate + 180, getdate())

								else datediff(day,coalesce(LA.LastAttemptDate,getdate()-90) + 90, getdate()) 
								end 
								or 
								CONVERT(DATE, dateadd(hour,C.ksl_UTCTimeAdjust,NA.NextActivityDate)) < CONVERT(DATE, getdate()) 
								)

								group by systemuserid ,					u.title,			u.fullname) x  on u.SystemUserId = x.systemuserid


Left join 
		--DataCompliance
			(select OwnerID,owneridname, count(*) as SourceCategoryCount from 
									
														
									(
											SELECT 
											a.ksl_initialsourcecategoryname as SourceCategory
											,a.OwnerID
											,a.[accountid]
											,a.owneridname
											,a.ksl_initialsourcecategory as SourceCategoryID 		
											,a.ksl_moveintiming_displayname as MoveInTiming
											,a.ksl_leveloflivingpreference_displayname as CarePref
									,a.ksl_leveloflivingpreference as CarePrefID 	
									,a.ksl_moveintiming as MoveInTimingID 	
										,a.ksl_initialinquirydate
										--,fp.accountid as FloorPlanPref
										,modifiedon
											FROM [KSLCLOUD_MSCRM].dbo.Account A
												--left join ( SELECT distinct [accountid] 
												--				FROM [KSLCLOUD_MSCRM].[dbo].[ksl_account_ksl_unitfloorplan]) fp on a.accountid = fp.accountid 
											Where  a.statuscode_displayname IN ('Lead') 				

									) q  
									
									left join (	
													select a.accountid, fp.accountid fpaccountid, CompletedDate,a.createdon
													FROM (SELECT * FROM  [KSLCLOUD_MSCRM].dbo.Account Where statuscode_displayname IN ('Lead') ) A
						
													-- INNER Join with all account that have had a CE or Appointment 
													inner join (SELECT * FROM  (

																					select X.*
																					,row_number() over(partition by accountid order by completeddate desc) rw

																					,case when ActivityType = 'Appointment' and ( Rslt ='CEXP - Community Experience Given' or (ActivityTypeDetail in (864960001 ) and Rslt = 'COMP - Completed') ) 
																									and CAST(CompletedDate AS DATE) = CAST(LastCEDate AS DATE) then 1 else 0 end as Community_Experience

																					,case when ActivityType = 'Appointment' and  Rslt ='COMP - Completed' and ActivityTypeDetail in (864960001 ) and CAST(CompletedDate AS DATE) <> CAST(LastCEDate AS DATE) then 1 else 0 end as Appointment


																					from (
																									select 
																									a.accountid,
																									--a.[ksl_initialinquirydate], -- js 5/18
																									a.OwnerId AccountOwnerID, 
																									b.OwnerIdName AccountOwnerName,
																									a.ksl_CommunityId AS CommunityId,
																									a.ksl_CommunityIdName AS CommunityIdName,
																										   --Get Last Attempt Information
																										   b.Subject as ActivitySubject,
																										   b.ActivityTypeCode as ActivityType,
																										   b.ActivityTypeDetail as ActivityTypeDetail,
																										   convert(date,b.CompletedDate) CompletedDate,
																										   Rslt,
																										   activityid,
																										   notes, 
																										   ksl_textssent, ksl_textsreceived
																									from 
																									(

																									SELECT activityid ,ksl_resultoptions_displayname as Rslt,L.accountid, PC.Subject, PC.ActivityTypeCode, PC.ksl_appointmenttype as ActivityTypeDetail, PC.regardingobjectid, PC.scheduledstart as CompletedDate
																									, pc.description as notes,PC.owneridname, NULL as ksl_textssent, NULL as ksl_textsreceived
																									FROM kslcloud_mscrm.dbo.Account L WITH (NOLOCK)
																									inner JOIN kslcloud_mscrm.dbo.appointment PC WITH (NOLOCK) ON PC.RegardingObjectId = L.accountid
																									WHERE  
																									PC.statecode_displayname = 'Completed'
																									and PC.ksl_resultoptions <> '100000000' --Result: 100000000:Cancelled 

																									) as b 
																									inner join kslcloud_mscrm.dbo.account a on b.accountid = a.accountid

 


																					) as x

																					OUTER APPLY (select top 1 *  from (select 

																															   --Get Last Contact Activity Information
																															   b.Subject as ActivitySubject,
																															   b.ActivityTypeCode as LCEType,
																															   b.ActivityTypeDetail as LCETypeDetail,
																															   b.regardingobjectid,
																															   b.CompletedDate as LastCEDate,
																															   b.notes as LCENotes,
																															   b.activityid
																														from 
																														(
																															SELECT pc.activityid, PC.Subject, PC.ActivityTypeCode, PC.ksl_appointmenttype as ActivityTypeDetail, PC.regardingobjectid, PC.scheduledstart as CompletedDate, left(PC.description,300) as notes
																															from [KSLCLOUD_MSCRM].dbo.appointment PC WITH (NOLOCK) 
																															WHERE  
																															PC.statecode_displayname = 'Completed'
																																		and PC.ksl_appointmenttype in ( 864960001)

																																		and PC.ksl_resultoptions in ('864960005','864960004', '864960006') --Result: 864960005:Completed  864960004:Community Experience  864960006: Virtual Experience
																																		) as b) LastCE where X.accountid = lastCE.regardingobjectid order by LastCE.LastCEDate asc
																													) FCE

																					) E 
																		where (Community_Experience =1 OR Appointment =1)
																		
																		AND CAST(CompletedDate AS DATE) >= '3/9/2022' -- this process started on this date, no need to pull extra and extend the run time. 
																		and rw = 1 


																		) v on v.accountid = a.accountid
						
													-- All the accounts with FP filled out. 
													left join ( SELECT distinct [accountid] 
																							FROM [KSLCLOUD_MSCRM].[dbo].[ksl_account_ksl_unitfloorplan]) fp on a.accountid = fp.accountid 

												) u on q.accountid = u.accountid



									where  
										( 
										SourceCategory is null 
										or
										  MoveInTiming IS NULL 
										  or
										 CarePref is null
										 or( fpaccountid is null 
												and CompletedDate < getdate() -7 
												--and createdon > '1/1/2022'
												)
										) 
										and ksl_initialinquirydate < getdate() -30
							
										
									group by 
									OwnerID ,owneridname									) k on u.SystemUserId =k.ownerid

left join (select ownerid, count(*) activeLeads
			from [KSLCLOUD_MSCRM].dbo.account A 
				
				where  a.statuscode_displayname = 'Lead'
				group by a.ownerid)  ac  on u.SystemUserId = ac.ownerid

left join 
		--PastDueActivityCount
			(select a.ownerid,
				count(b.activityid) as PastDueActivityCount

				from 
				(
				SELECT PC.Subject, PC.ActivityTypeCode, PC.ksl_phonecalltype as ActivityTypeDetail, PC.regardingobjectid, PC.scheduledend, PC.description as notes, PC.activityid, PC.ownerid
				FROM [KSLCLOUD_MSCRM].dbo.PhoneCall PC WITH (NOLOCK) 
				WHERE --PC.actualend IS NULL AND PC.scheduledend IS NOT NULL
				 PC.statecode_displayname <> 'Completed'
				and PC.ksl_phonecalltype <> '864960003'
				Union All
				SELECT PC.Subject, PC.ActivityTypeCode, PC.ksl_appointmenttype as ActivityTypeDetail, PC.regardingobjectid, PC.scheduledstart as scheduledend, PC.description as notes, PC.activityid, PC.ownerid
				FROM [KSLCLOUD_MSCRM].dbo.appointment PC WITH (NOLOCK) 
				WHERE  PC.statecode_displayname <> 'Completed'
				Union All
				SELECT PC.Subject, PC.ActivityTypeCode, NULL as ActivityTypeDetail, PC.regardingobjectid, PC.scheduledend, PC.description as notes, PC.activityid, PC.ownerid
				FROM  [KSLCLOUD_MSCRM].dbo.task PC 
				WHERE  PC.statecode_displayname <> 'Completed'
				Union All
				SELECT  PC.Subject, PC.ActivityTypeCode, PC.ksl_emailtype as ActivityTypeDetail, PC.regardingobjectid, PC.scheduledend, PC.description as notes, PC.activityid, PC.ownerid
				FROM [KSLCLOUD_MSCRM].dbo.email PC WITH (NOLOCK) 
				WHERE  PC.statecode_displayname <> 'Completed'
				and PC.ksl_emailtype <> '864960004'
				 ) as b
				INNER JOIN [KSLCLOUD_MSCRM].dbo.account A WITH (NOLOCK) on A.accountid = b.regardingobjectid
				LEFT JOIN [KSLCLOUD_MSCRM].dbo.SystemUser U ON U.SystemUserId = A.OwnerID
				LEFT JOIN [KSLCLOUD_MSCRM].dbo.ksl_community C ON C.ksl_communityId = A.ksl_CommunityId

				where CONVERT(DATE, dateadd(hour,C.ksl_UTCTimeAdjust,b.scheduledend)) < CONVERT(DATE, getdate()) 
				--and A.ksl_CommunityId = '$CRM_CommunityID' 
				and a.statuscode_displayname = 'Lead'
				group by a.ownerid)  pd  on u.SystemUserId = pd.ownerid



								where  u.Title <> 'Sales Coordinator'
								and u.FullName not in ('# Dynamic.Test' ,'Cedarwood Sales')
								and [ksl_CommunityId] is not null 









--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% INSERT INTO Dim_Title %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		/* Added by JSharp 
			Date: 12/10/2019			
		*/

BEGIN TRY;THROW 50000,'',1;END TRY BEGIN CATCH;insert into Staging.dbo.log_DW_Time (LineNumber,MinSinceLast) values (ERROR_LINE(),DATEDIFF(mi,@DtLast,getdate()));END CATCH
set @DtLast = getdate()


truncate table Dim_Title
insert into Dim_Title

--SELECT distinct job
	--FROM [dbo].[Dim_Associate]
	--where job is not null 
select distinct Job_Description	
from Fact_Punch where Job_Description is not null

union all 

SELECT distinct title 
	FROM [dbo].[Budgets]
	where title is not null 
	 AND title not in (select distinct Job_Description	
from Fact_Punch where Job_Description is not null )



--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% INSERT INTO Dim_CRM %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

BEGIN TRY;THROW 50000,'',1;END TRY BEGIN CATCH;insert into Staging.dbo.log_DW_Time (LineNumber,MinSinceLast) values (ERROR_LINE(),DATEDIFF(mi,@DtLast,getdate()));END CATCH
set @DtLast = getdate()

truncate table Dim_CRM
insert into Dim_CRM
SELECT 
LEA.AccountId AS 'Lead_AccountID'
		--,SM3.Value AS LEA_Status
		,statuscode_displayname as LEA_Status
		,case when exists(select * from staging.dbo.ksl_apartmentfinancialhistory where LEA.accountid = ksl_accountleadid and ksl_begintransactiontype_displayname ='Actual Move in') 
			then 'Yes' else 'No' end as 'IsMovedIn'
		--,CASE WHEN  OPP.ActualCloseDate IS NULL THEN 'No' ELSE 'Yes' END AS 'IsMovedIn'
		--,CASE	WHEN  SM3.Value IN ('To Be Reactivated', 'Do Not Contact') THEN LEA.ksl_reasoncategoryidname 
		--					END AS ksl_reasoncategoryidname
		--,CASE	WHEN  SM3.Value IN ('To Be Reactivated', 'Do Not Contact') THEN LEA.ksl_reasondetailidname 
		--			END AS ksl_reasondetailidname
		--,LEA.ksl_mainContactRelationshiptoPotentIdName AS 'MainContactRelationtoRes'
		--MainContact, use the latest info
		,ksl_initialinquirydate as InitialInquiryDate
		,ksl_moveindate as MoveInDate
	,ksl_initialsourcename as 'Initial_Source'
,ksl_referralsourcename as Referral_Source
,isnull((select top 1 ksl_name ksl_name from kslcloud_mscrm.dbo.ksl_inquirycategory WITH (NOLOCK) 
		where ksl_inquirycategoryid = LEA.ksl_initialsourcecategory),'blank') as 'Source_Category'
,ksl_reactivatesourcename as 'Reactivate_Source'
,ksl_referralorganizationname as 'Referral_Organization'


	
		,LEA.ksl_donotcontactreason_displayname AS ReasonDetail

		,NULL AS MoveOutReasonCategory
		,LEA.ksl_LostToCompetitorIdName AS LostToCompetitor
		
		,LEA.ksl_MoveOutDestinationIdName AS MoveOutDestination
		,LEA.ksl_MoveOutReasonDetailIdName AS MoveOutReasonDetail
		,LEA.ksl_potentialresident1idname
		--select from staging.dbo.Account
	,(select ksl_categorytype_displayname from kslcloud_mscrm.dbo.ksl_inquirycategory WITH (NOLOCK) where LEA.ksl_initialsourcecategory = ksl_inquirycategoryid) as CategoryType	
		
		
	,case when exists(select * from kslcloud_mscrm.dbo.account a WITH (NOLOCK) where LEA.accountid = a.accountid and ksl_objectionstoovercome like '%12%') 
			then 'Yes' else 'No' end as 'Covid_Objection'
	,lea.ksl_leveloflivingpreference_displayname
	,lea.ksl_donotcontactreason_displayname
	,lea.ksl_moveintiming_displayname
	, case when [primarytwitterid]  like '%hubspot%' or (description like '%calendly%' and [primarytwitterid] is not null) 
				then 'Web Scheduler' 
		WHEN primarytwitterid IS NOT NULL AND TRY_CONVERT(uniqueidentifier, primarytwitterid) IS NULL AND TRY_CONVERT(bigint, primarytwitterid) IS NULL and [primarytwitterid] not like '%hubspot%' and (description not like '%calendly%' )
			THEN 'Web Form'
		else null 
			end platformSource
		,LEA.ksl_potentialresident2idname

FROM  staging.dbo.Account 
					AS LEA
		--Just take the latest opportunity
		--LEFT OUTER JOIN
		--	staging.dbo.StringMap AS SM 
		--		ON SM.AttributeValue = INQ.StatusCode AND SM.ObjectTypeCode = 'Lead' AND SM.AttributeName = 'StatusCode' AND SM.LangId = '1033' 
		
		--select * from [kslcloud_mscrm_DEV].dbo.StringMap SM2 where SM2.ObjectTypeCode = 'Account'  AND 
		--LEFT OUTER JOIN
		--	staging.dbo.StringMap AS SM3 
			--	ON SM3.AttributeValue = LEA.StatusCode AND SM3.ObjectTypeCode = 'Account' AND SM3.AttributeName = 'StatusCode' AND SM3.LangId = '1033' 

update Dim_CRM set CategoryType = 'Other' where CategoryType is Null


--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% INSERT INTO Fact_Lease %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

BEGIN TRY;THROW 50000,'',1;END TRY BEGIN CATCH;insert into Staging.dbo.log_DW_Time (LineNumber,MinSinceLast) values (ERROR_LINE(),DATEDIFF(mi,@DtLast,getdate()));END CATCH
set @DtLast = getdate()

  ----  exec [Fill_Fact_Lease_Staging]


  TRUNCATE TABLE fact_lease
  


  INSERT INTO fact_lease 
            ( 
                        ksl_apartmentid , 
                        ksl_apartmentidname , 
                        ksl_communityid , 
                        quoteid , 
                        opportunityid , 
                        accountid , 
                        ownerid , 
                        ksl_primaryresident1idname , 
                        ksl_communityidname , 
                        ksl_carelevelidname , 
                        ksl_primocccarelevelrate , 
                        doubleoccupancyfee , 
                        carelevelrate , 
                        transferfeebase , 
                        reservationfee , 
                        initialfeebalancedue , 
                        othercharges , 
                        totalmonthlyfee , 
                        transferfee , 
                        marketrate , 
                        mthlyrateadjustment , 
                        aptrate , 
						NrrAdjustment,
						  CommTransFeeSpecial ,
                        startdate , 
                        enddate , 
                        moveintransactiontype , 
                        moveouttransactiontype , 
                        moveoutreason , 
                        moveoutdestination , 
                        monthsasresident , 
                        opportunitysource , 
                        opportunitysourcecategory , 
                        primarybirthdate , 
                        daysinquirytomovein ,	
						MoveOutReasonDetail  
						
            ) 


	
SELECT isnull(y.ksl_ApartmentId,est.ksl_ApartmentId) as ksl_ApartmentId
	,isnull(y.ksl_ApartmentIdName,est.ksl_ApartmentIdName) as ksl_ApartmentIdName
	,isnull(y.ksl_CommunityId,est.ksl_CommunityId) as ksl_CommunityId
	,QuoteID
	,null--OpportunityId
	,y.ksl_accountLeadId--est.AccountId
	,y.OwnerId--,afh_OwnerID OwnerId
	,ksl_primaryResident1IdName
	,isnull(y.ksl_communityIdName,est.ksl_communityIdName) as ksl_communityIdName
	,ksl_CareLevelIdName
	,ksl_primocccarelevelrate
	,ksl_dbloccfee AS DoubleOccupancyFee
	,ksl_primocccarelevelrate AS CareLevelRate
	,ksl_ACT_CommTransFee_Base AS TransferFeeBase
	,ksl_ACT_ReservationFee AS 'ReservationFee'
	,ksl_totalinitfeebaldue_Base AS 'InitialFeeBalanceDue'
	,ksl_TotalOtherCharges AS OtherCharges
	,ksl_TotalMonthlyFee AS TotalMonthlyFee
	,ksl_ACT_CommTransFee AS TransferFee
	,ksl_aptmarketrate AS MarketRate
	,ksl_aptdisc AS MthlyRateAdjustment
	,new_ApartmentRate AS AptRate
	
	,ISNULL(est.ksl_nrradjustment,0) AS NrrAdjustment
	,ISNULL(est.ksl_ACT_CommTransFeeSpecial,0) AS CommTransFeeSpecial
	,isnull(ksl_BeginDate,est.ksl_schfinanmovein) AS StartDate
	,EndDt AS EndDate
	,coalesce(
	CASE
		WHEN  y.ksl_BeginTransactionType = 864960001 THEN 'Actual Move in'
		WHEN  y.ksl_BeginTransactionType = 864960003 THEN 'Actual Transfer In'
		WHEN  y.ksl_BeginTransactionType = 864960007 THEN 'Short Term Stay Begin'
		WHEN  y.ksl_BeginTransactionType = 864960008 THEN 'Seasonal Stay Begin'
		WHEN  y.ksl_BeginTransactionType = 864960000 THEN 'Scheduled Move in'
		--ELSE 'Other'
	END,est.ksl_estimatetype_displayname)
	 AS 'MoveinTransactionType'
	--Taking care of leases that have no moveout date
	--,(SELECT top 1 f.ksl_BeginDate FROM ksl_apartmentfinancialhistory f WHERE y.ksl_ApartmentId = f.ksl_ApartmentId and y.ksl_BeginDate < f.ksl_BeginDate and y.EndDt IS NULL 
	--and ksl_BeginTransactionType  in (864960001,864960003,864960007,864960008) and statecode = 0 ) AS 'Bad'
	,CASE
		WHEN  y.ksl_EndTransactionType = 864960004 THEN 'Actual Transfer Out'
		WHEN  y.ksl_EndTransactionType = 864960006 THEN 'Actual Move Out'
		WHEN  y.ksl_EndTransactionType = 864960002 THEN 'Scheduled Transfer Out'
		WHEN  y.ksl_EndTransactionType = 864960005 THEN 'Scheduled Move Out'		END AS 'MoveOutTransactionType'
	,ksl_ReasonDetailIDName AS MoveOutReason
	,ksl_MoveOutDestinationIdName AS MoveOutDestination
	, DATEDIFF(DAY , ksl_BeginDate , ISNULL(EndDt , GETDATE()))/30 AS MonthsAsResident
	,ksl_InquirySourceIdName
	,ksl_InquiryCategoryIdName
	,CON.Birthdate
	--, * 
	,
	(
		SELECT --select InitialInquiryDate from kslcloud_mscrm.dbo.Account WITH (NOLOCK)
			DATEDIFF(DAY , MIN(InitialInquiryDate) , ksl_BeginDate)
		FROM Dim_CRM c
		WHERE c.Lead_AccountID = ksl_accountleadid
			AND ksl_BeginTransactionType = 864960001
	)
	AS 'DaysInquiryToMoveIn'
	,MoveOutReasonDetail
	--select * from fact_lease

FROM 	(
		SELECT
			afh.ksl_BeginDate
			,afh.ksl_ApartmentId
			,afh.ksl_ApartmentIdName
			,afh.ksl_CommunityId
			--,afh.AccountId
			,ld.ksl_soldby OwnerId
			,afh.ksl_communityIdName
			,afh.ksl_accountLeadId
			,q.ksl_respitestay
			,q.ksl_nrradjustment
			,MAX(afh.ksl_endDate) AS EndDt
			,afh.ksl_estimateId
			,afh.ksl_BeginTransactionType
			,MAX(afh.ksl_EndTransactionType) ksl_EndTransactionType
			,MAX(afh.ksl_ReasonDetailIDName) AS ksl_ReasonDetailIDName
			,MAX(afh.ksl_MoveOutDestinationIdName) AS ksl_MoveOutDestinationIdName
			,MAX(ksl_initialsourceName) AS ksl_InquirySourceIdName
			,MAX(ksl_initialsourcecategoryName) AS ksl_InquiryCategoryIdName
			,MAX(afh.OwnerId) AS afh_OwnerID
			,max(ld.ksl_potentialresident1id) as ksl_potentialresident1id
		
		--,LEA.ksl_ReasonDetailIdName AS ReasonDetail
		--,coalesce(MAX(ksl_MoveOutReasonDetailIdName),MAX(ksl_undoreasonname)) AS MoveOutReasonDetail
		,MAX(ksl_MoveOutReasonDetailIdName) AS MoveOutReasonDetail
		

		FROM kslcloud_mscrm.dbo.ksl_apartmentfinancialhistory afh WITH (NOLOCK)   --history of what happened 
			LEFT JOIN kslcloud_mscrm.dbo.Account ld WITH (NOLOCK)
				ON ld.AccountID = ksl_accountleadid
			left join    (SELECT * FROM  kslcloud_mscrm.dbo.quote   where ksl_estimatetype  in (864960001, 864960003,864960005,864960006,864960008,864960009 ) ) q 
				on afh.ksl_estimateid = q.quoteid

			--LEFT JOIN kslcloud_mscrm.dbo.opportunity o
				--ON o.opportunityid = q.opportunityid
				--on o.parentaccountid = ld.accountid
			WHERE (afh.ksl_BeginTransactionType IN (864960001 , 864960003 , 864960007 , 864960008) -- 01=Actual Move In, 03=Actual Transfer In, Scheduled Transfer, Scheduled Move In
				AND afh.statecode = 0
				AND (afh.ksl_EndTransactionType IN (864960004 , 864960006 , 864960002 , 864960005)
					OR afh.ksl_EndTransactionType IS NULL)) -- Actual Transfer Out, Actual move out, Scheduled Transfer,Scheduled move out
				OR (
					afh.ksl_BeginTransactionType = 864960000
					AND afh.statecode = 0
					AND afh.ksl_EndTransactionType IS NULL
					AND CAST(afh.ksl_BeginDate AS DATE) >= CAST(GETDATE() - 15 AS DATE)
					)
			and (q.ksl_respitestay = 0 or q.ksl_respitestay is null )
		
		GROUP BY	afh.ksl_BeginDate
				,afh.ksl_ApartmentId
				 ,q.ksl_respitestay
				 ,ksl_nrradjustment
				,afh.ksl_accountLeadId
				,afh.ksl_estimateId
				,afh.ksl_BeginTransactionType
				,afh.ksl_ApartmentIdName
				,afh.ksl_CommunityId
				--,afh.AccountId
				,ld.ksl_soldby
				,afh.ksl_communityIdName
	--22,803


	union all 

-- To bring in all the quotes that have NRR adjustments

	SELECT
			ksl_schfinanmovein
			,null ksl_ApartmentId
			,null ksl_ApartmentIdName
			,q.ksl_CommunityId
			--,afh.AccountId
			,q.ksl_sdtoadjustnrr OwnerId 
			,q.ksl_communityidname ksl_communityIdName
			,q.accountid ksl_accountLeadId
			,q.ksl_respitestay
			,q.ksl_nrradjustment
			,null AS EndDt
			,q.quoteid
			,case when ksl_nrradjustment is not null then 1001 else null end  ksl_BeginTransactionType
			,null ksl_EndTransactionType
			,null AS ksl_ReasonDetailIDName
			,null AS ksl_MoveOutDestinationIdName
			,MAX(ksl_initialsourceName) AS ksl_InquirySourceIdName
			,MAX(ksl_initialsourcecategoryName) AS ksl_InquiryCategoryIdName
			,null AS afh_OwnerID
			,max(ld.ksl_potentialresident1id) as ksl_potentialresident1id
		
			--,LEA.ksl_ReasonDetailIdName AS ReasonDetail
			--,coalesce(MAX(ksl_MoveOutReasonDetailIdName),MAX(ksl_undoreasonname)) AS MoveOutReasonDetail

			,null AS MoveOutReasonDetail
		

		FROM kslcloud_mscrm.dbo.quote q WITH (NOLOCK)
				LEFT JOIN kslcloud_mscrm.dbo.Account ld WITH (NOLOCK)
				ON ld.AccountID = q.accountid
		 where ksl_estimatetype not in (864960001, 864960003,864960005,864960006,864960008,864960009 )
		 and ksl_nrradjustment is not null 
		 GROUP BY  			ksl_schfinanmovein
			,q.ksl_CommunityId
			,q.ksl_sdtoadjustnrr 
			,q.ksl_communityidname 
			,q.accountid 
			,q.ksl_respitestay
			,ksl_nrradjustment
			,q.quoteid


		) AS y
	--full outer JOIN kslcloud_mscrm.dbo.[Quote]	 est
		--ON QuoteID = ksl_estimateId 
	LEFT JOIN kslcloud_mscrm.dbo.contact CON WITH (NOLOCK)
		ON CON.contactid = ksl_potentialresident1id
		outer apply (
								  select top 1 * 
								  from 
									kslcloud_mscrm.dbo.[Quote] q WITH (NOLOCK) 
								  where 
									(
									  QuoteID = ksl_estimateId 
									  or (y.ksl_accountleadid = q.customerid 
											and ABS( DATEDIFF(day, q.ksl_schfinanmovein, y.ksl_BeginDate) ) < 5
									  )
									) 
									--and ksl_estimatetype_displayname <> 'Quote'  -- removed this filter so that the NRR adjustment quotes would be grabbed as well 
								  order by 
									case when QuoteID = ksl_estimateId then 1 else 0 end desc, 
									ABS(
									  DATEDIFF(
										day, q.ksl_schfinanmovein, y.ksl_BeginDate
									  )
									), 
									createdon desc
				) as est	

		--outer apply (select top 1 * from kslcloud_mscrm.dbo.[Quote] q whereand ksl_estimatetype_displayname <> 'Quote' order by ABS( DATEDIFF(day,q.ksl_schfinanmovein,y.ksl_BeginDate)) asc) as est2
	where coalesce(
	CASE
		WHEN  y.ksl_BeginTransactionType = 864960001 THEN 'Actual Move in'
		WHEN  y.ksl_BeginTransactionType = 864960003 THEN 'Actual Transfer In'
		WHEN  y.ksl_BeginTransactionType = 864960007 THEN 'Short Term Stay Begin'
		WHEN  y.ksl_BeginTransactionType = 864960008 THEN 'Seasonal Stay Begin'
		WHEN  y.ksl_BeginTransactionType = 864960000 THEN 'Scheduled Move in'
		--ELSE 'Other'
	END,est.ksl_estimatetype_displayname) is not null

	and (y.ksl_respitestay = 0 or y.ksl_respitestay is null )
	--and (y.ksl_respitestay = 1 )

	--and est.quoteid = '5b020fdc-167b-ed11-81ad-000d3a5a8929'




	--22,952




UPDATE a
	SET Prev_AptRate =
				(
				SELECT TOP 1
					b.AptRate
				FROM fact_Lease b
					WHERE a.ksl_apartmentID = b.ksl_apartmentID
					AND a.StartDate > b.StartDate
				ORDER BY StartDate DESC
				)
	FROM fact_Lease a

UPDATE a
	SET Prev_TransferFee =
				(
				SELECT TOP 1
					b.TransferFee
				FROM fact_Lease b
					WHERE a.ksl_apartmentID = b.ksl_apartmentID
					AND a.StartDate > b.StartDate
				ORDER BY StartDate DESC
				)
	FROM fact_Lease a

UPDATE fact_Lease
	SET MonthsAsResident = NULL
	WHERE MonthsAsResident < 0


	/*
--select * from fact_lease
UPDATE fact_lease set ksl_CommunityId = (select top 1 ksl_communityId from Dim_Community where shortNAme = 'CNH.HC') where ksl_apartmentId in 
(select ksl_apartmentId from Dim_Apartment where ksl_CommunityId = '39C35920-B2DE-E211-9163-0050568B37AC' and Level_of_Living_Short <> 'IL')


UPDATE fact_lease set ksl_CommunityId = (select top 1 ksl_communityId from Dim_Community where shortNAme = 'LPEX') where ksl_apartmentId in 
(select ksl_apartmentId from Dim_Apartment where ksl_CommunityIdName = 'La Posada' and Level_of_Living_Short = 'IL' and apt_number like '4%' )

UPDATE fact_lease set ksl_CommunityId = (select top 1 ksl_communityId from Dim_Community where shortNAme = 'LPHC') where ksl_apartmentId in 
(select ksl_apartmentId from Dim_Apartment where ksl_CommunityIdName = 'La Posada' and Level_of_Living_Short <> 'IL' )



										UPDATE fact_lease 
					SET    ksl_communityid = (SELECT TOP 1 ksl_communityid 
											  FROM   dim_community 
											  WHERE  shortname = 'CNHEX') 
					WHERE  ksl_apartmentid IN (select convert(varchar(100),ksl_apartmentid) from staging..ksl_apartment where ksl_legalentity = 'CNHEX') 



															UPDATE fact_lease 
					SET    ksl_communityid = (SELECT TOP 1 ksl_communityid 
											  FROM   dim_community 
											  WHERE  shortname = 'CWEX') 
					WHERE  ksl_apartmentid IN (select convert(varchar(100),ksl_apartmentid) from staging..ksl_apartment where ksl_legalentity = 'CWEX') 

					*/


														UPDATE u SET u.ksl_communityid = c.ksl_communityId
														--SELECT *  
														FROM fact_lease u  inner JOIN KSLCLOUD_MSCRM..ksl_apartment apt ON u.ksl_apartmentId = convert(varchar(100),apt.ksl_apartmentid)
														INNER JOIN dim_community c ON c.ShortName = apt.ksl_legalentity
														WHERE apt.statecode_displayname = 'Active' AND u.ksl_communityid <> c.ksl_communityId

--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% INSERT INTO Dim_SourceCategory %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  BEGIN TRY;THROW 50000,'',1;END TRY BEGIN CATCH;insert into Staging.dbo.log_DW_Time (LineNumber,MinSinceLast) values (ERROR_LINE(),DATEDIFF(mi,@DtLast,getdate()));END CATCH
set @DtLast = getdate()

Truncate table Dim_SourceCategory 
INSERT INTO Dim_SourceCategory

select KSL_name from kslcloud_mscrm.dbo.ksl_inquirycategory WITH (NOLOCK) 
where statecode = 0

Union all

select 'blank'



--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% INSERT INTO Fact_Lead %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

BEGIN TRY;THROW 50000,'',1;END TRY BEGIN CATCH;insert into Staging.dbo.log_DW_Time (LineNumber,MinSinceLast) values (ERROR_LINE(),DATEDIFF(mi,@DtLast,getdate()));END CATCH
set @DtLast = getdate()


TRUNCATE TABLE Fact_Lead
INSERT INTO Fact_Lead
SELECT convert(Date,LEA.ksl_initialinquirydate) AS dt 
,LEA.AccountId AS 'Lead_AccountID'
,LEA.ksl_CommunityId
,LEA.ksl_CommunityIdName
--,SM3.Value AS LEA_Status
,CASE WHEN MoveInDate is null  THEN OwnerIdName else iif(ksl_soldbyname is null, OwnerIdName, ksl_soldbyname)  end as OwnerIdName
,CASE WHEN MoveInDate is null  THEN OwnerId else iif(ksl_soldby is null,OwnerId,ksl_soldby) end as OwnerId
--,CASE WHEN  statuscode_displayname IN ('To Be Reactivated', 'Do Not Contact') 
,CASE WHEN  statuscode_displayname <> 'Lead' 

                         THEN LEA.ksl_reasoncategoryidname END AS ksl_reasoncategoryidname
						 --Removed after Sales App DW 12.16.25
,null  AS ksl_reasondetailidname
--,LEA.ksl_mainContactRelationshiptoPotentIdName AS 'MainContactRelationtoRes'


--,LEA.ksl_2ndrelationto1stIdName AS 'Resident2Relationshipto1'
,null AS 'Resident2Relationshipto1'
,LEA.ksl_LastInactivatedDate
,(select top 1 scheduledstart from staging.dbo.appointment where (ksl_resultoptions_displayname = 'CEXP - Community Experience Given' or ksl_resultoptions_displayname ='VEXP - Virtual Comm Exp Given')
		and regardingobjectid = LEA.Accountid order by createdon desc) as LatestCommunityExperience

,case when ksl_leveloflivingpreference_displayname = 'IL - No Care Services' then 'IL'
when ksl_leveloflivingpreference_displayname = 'IL - With Assistance Services' then 'IL'
else ksl_leveloflivingpreference_displayname end as 'LevelOfLivingPreference'
,statuscode_displayname as Status
,ksl_waitlisttransactiondate as WaitListTranDate
,ksl_waitlistenddate
,ksl_potentialmoveindate
,coalesce(
			(select top 1 convert(varchar(100),ksl_apartmentid) as ksl_apartmentid from  [KSLCLOUD_MSCRM].[dbo].[ksl_account_ksl_unitfloorplan] u inner join [KSLCLOUD_MSCRM].[dbo].ksl_apartment apt on apt.ksl_unitfloorplanid = u.ksl_unitfloorplanid where LEA.accountid = u.accountid)
			,
			(select top 1 convert(varchar(100),ksl_apartmentid) as ksl_apartmentid from [KSLCLOUD_MSCRM].[dbo].ksl_apartment apt inner join [KSLCLOUD_MSCRM].[dbo].ksl_levelofliving l 
				on apt.ksl_leveloflivingid = l.ksl_leveloflivingid where l.ksl_leveloflivingcode = rtrim(left(LEA.ksl_leveloflivingpreference_displayname,3)) and apt.ksl_communityid = LEA.ksl_communityid )
		) as ApartmentID

, Case WHEN daystoCE <=30 THEN 1 Else 0 END AS CEin30days
, Case WHEN daysCEtoMI <=60 THEN 1 Else 0 END AS MIin60days

,CompletedDate as FirstCEdate
,  MoveInDate
      ,case when [ksl_donotcontactreason] is not null and [ksl_donotcontactreason] not in (7,4) Then 1 else 0 end as [DNC]  --Deceased , Former Resident 
      ,case when  ksl_losttocompetitorid is not null then 1 else 0 end as [lostToCompetitor]
	  ,case when    [ksl_edfollowup] is not null  then 1 else 0 end [ED_Followup]
      ,case when    [ksl_sdhandwrittennote] is not null  then 1 else 0 end[SD_Note]
      ,( select count(*) from [KSLCLOUD_MSCRM].[dbo].[ksl_account_competitor] ac where ac.accountid = LEA.accountid) [CompetitorVisits]

	  ,isnull((select top 1 ksl_name ksl_name from kslcloud_mscrm.dbo.ksl_inquirycategory WITH (NOLOCK) 
		where ksl_inquirycategoryid = LEA.ksl_initialsourcecategory),'blank') as 'Source_Category'
	  ,isnull((select top 1 ksl_name ksl_name from kslcloud_mscrm.dbo.[ksl_inquirysource] WITH (NOLOCK) 
		where [ksl_inquirysourceid] = LEA.ksl_initialsource),'blank') as 'Initial_Source'

,LastDateOut
,DATEDIFF(Month,CAST(MoveInDate AS DATE),coalesce(LastDateOut,getdate())) as MonthsAsResident
,Null google_campaignID
FROM					 staging.dbo.Account AS LEA  
outer apply ( select top 1 AFH.ksl_begindate as MoveInDate from staging.dbo.ksl_apartmentfinancialhistory AFH
							WHERE AFH.statecode = 0 and afh.ksl_accountleadid = LEA.accountid
							AND AFH.ksl_begintransactiontype IN ('864960001','864960003') -- Actual Move In, Actual Transfer In
							order by AFH.ksl_begindate asc) as BeginDate
outer apply (select top 1 AFH.ksl_enddate as LastDateOut from staging.dbo.ksl_apartmentfinancialhistory AFH
							WHERE AFH.statecode = 0 AND AFH.ksl_begintransactiontype IN ('864960001','864960003') -- Actual Move In, Actual Transfer In
							AND 
								(
									(
									AFH.ksl_endtransactiontype IN ('864960006','864960004') -- Actual Move Out, Actual Transfer Out, Scheduled Transfer, Scheduled Move Out
									)
								OR 
								(
									((CAST(AFH.ksl_enddate AS DATE)  IS NULL) or (AFH.ksl_endtransactiontype IN ('864960002','864960005')))--Scheduled Transfer, Scheduled Move Out
		
		 
								)
							)
									 and afh.ksl_accountleadid = LEA.accountid
					order by AFH.ksl_enddate desc) as LastDateOutTable
						--LEFT JOIN staging.dbo.StringMap AS SM3 ON SM3.AttributeValue = LEA.StatusCode AND SM3.ObjectTypeCode = 'Account' AND SM3.AttributeName = 'StatusCode' AND SM3.LangId = '1033'
						LEFT JOIN (select  l.accountid		,l.ksl_initialinquirydate	,ce.CompletedDate, DATEDIFF(day,l.ksl_initialinquirydate	,ce.CompletedDate) as daystoCE	,DATEDIFF(day,ce.CompletedDate,BeginDate.MoveInDate) as daysCEtoMI	
								FROM kslcloud_mscrm.dbo.Account L WITH (NOLOCK)	
								outer apply ( select top 1 * from [dbo].[Vw_Activities] ce 
												where ce.accountid = l.accountid and (Community_Experience = 1 or Virtual_Community_Experience = 1) 
												order by CompletedDate asc) ce
								outer apply ( select top 1 AFH.ksl_begindate as MoveInDate from staging.dbo.ksl_apartmentfinancialhistory AFH
							WHERE AFH.statecode = 0 and afh.ksl_accountleadid = l.accountid
							AND AFH.ksl_begintransactiontype IN ('864960001','864960003') -- Actual Move In, Actual Transfer In
							order by AFH.ksl_begindate asc) as BeginDate
								
								Where ce.CompletedDate  is not null ) as C on lea.accountid = C.accountid
									--and (LEA.ksl_donotcontactreason not in (864960001,11,6) or   LEA.ksl_donotcontactreason is null ) --Duplicate - Please Delete,Invalid Contact Info, Confirmed Secret Shopper

where 
 (LEA.ksl_donotcontactreason not in (864960001,11,6) or   LEA.ksl_donotcontactreason is null ) --Duplicate - Please Delete,Invalid Contact Info, Confirmed Secret Shopper
  and coalesce(LEA.ownerid,ksl_soldby) is not null

--Add google campagin id from [GAds_CampaignIDs]  --> this is populated with APIGoogleAds.php script

 update l
set google_campaignID = g.gCampaignID
  FROM [DataWarehouse].[dbo].[Fact_Lead] l
  join staging.[dbo].[GAds_CampaignIDs] g on g.accountid = l.lead_accountID
  where google_campaignID is null 



--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% INSERT INTO Fact_Activity %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
					
BEGIN TRY;THROW 50000,'',1;END TRY BEGIN CATCH;insert into Staging.dbo.log_DW_Time (LineNumber,MinSinceLast) values (ERROR_LINE(),DATEDIFF(mi,@DtLast,getdate()));END CATCH
set @DtLast = getdate()

	--exec [dbo].[Fill_Fact_Activity]




    -- Insert statements for procedure here
TRUNCATE TABLE Fact_Activity;
WITH AllActivities AS (
    SELECT 
        A.accountid,
        A.OwnerID                     AS AccountOwnerID,
        A.OwnerIDname                 AS AccountOwnerName,
        A.ksl_CommunityId             AS CommunityId,
        A.ksl_CommunityIdName         AS CommunityIdName,
        PC.Subject                    AS ActivitySubject,
        PC.ActivityTypeCode           AS ActivityType,
        CAST(NULL AS int)             AS ActivityTypeDetail,
        PC.scheduledstart             AS CompletedDate,
        CASE 
            WHEN PC.ActivityTypeCode = 'Outgoing Text Message' THEN 'Text Sent'
            WHEN PC.ActivityTypeCode = 'Incoming Text Message' THEN 'Text Received'
            ELSE PC.ksl_resultoptions_displayname
        END AS Result,
        PC.activityid,
        left(PC.description,250)                AS notes,
        CASE WHEN A.statuscode_displayname = 'Referral Org' THEN 'Yes' ELSE 'No' END AS isBD,
        CASE WHEN PC.description LIKE '%sm.chat%' THEN 'Yes' ELSE 'No' END AS isSalesMail,
        CAST(NULL AS varchar(50))     AS google_campaignID,
        PC.ownerid                    AS activityCreatedBy,
        PC.EmailBody
    FROM KSLCLOUD_MSCRM.dbo.Account    AS A WITH (NOLOCK)
    JOIN KSLCLOUD_MSCRM.dbo.activities AS PC WITH (NOLOCK)
      ON PC.RegardingObjectId = A.accountid
),
-- Add Sent/Recieved notes for text conversations
TextConversationEvents AS (
    SELECT
        a.accountid,
        a.AccountOwnerID,
        a.AccountOwnerName,
        a.CommunityId,
        a.CommunityIdName,
        a.ActivitySubject,
        a.ActivityType,
        -- Check if EmailBody starts with SENT or RCVD pattern
        CASE 
            WHEN LEFT(COALESCE(a.EmailBody, a.notes, ''), 4) = 'SENT' THEN 1002 
            WHEN LEFT(COALESCE(a.EmailBody, a.notes, ''), 4) = 'RCVD' THEN 1001 
            ELSE NULL 
        END AS ActivityTypeDetail,
        a.CompletedDate,
        CASE 
            WHEN LEFT(COALESCE(a.EmailBody, a.notes, ''), 4) = 'SENT' THEN 'Text Sent' 
            WHEN LEFT(COALESCE(a.EmailBody, a.notes, ''), 4) = 'RCVD' THEN 'Text Received' 
            ELSE NULL 
        END AS Result,
        a.activityid,
        left(a.notes,250) notes,
        a.isBD,
        a.isSalesMail,
        a.google_campaignID,
        a.activityCreatedBy
    FROM AllActivities a
    WHERE a.ActivityType = 'Text Message Conversation'
      AND (LEFT(COALESCE(a.EmailBody, a.notes, ''), 4) = 'SENT' 
           OR LEFT(COALESCE(a.EmailBody, a.notes, ''), 4) = 'RCVD')
),
-- Non-conversation activities (pass through unchanged)
NonConversation AS (
    SELECT
        accountid,
        AccountOwnerID,
        AccountOwnerName,
        CommunityId,
        CommunityIdName,
        ActivitySubject,
        ActivityType,
        ActivityTypeDetail,   -- stays NULL for non-text, old value was number like 864960001, maybe we can remove
        CompletedDate,
        Result,
        activityid,
        left(notes,250) notes,
        isBD,
        isSalesMail,
        google_campaignID,
        activityCreatedBy
    FROM AllActivities
    WHERE ActivityType <> 'Text Message Conversation'
)
-- Final unified set
INSERT INTO Fact_Activity WITH (TABLOCK) -- TABLOCK speeds up bulk inserts
SELECT *
FROM NonConversation

UNION ALL

SELECT
    accountid,
    AccountOwnerID,
    AccountOwnerName,
    CommunityId,
    CommunityIdName,
    ActivitySubject,
    ActivityType,
    ActivityTypeDetail,
    CompletedDate,
    Result,
    activityid,
    left(notes,250) notes,
    isBD,
    isSalesMail,
    google_campaignID,
    activityCreatedBy
FROM TextConversationEvents;

--TESTING filters
-- WHERE CommunityId = '3BC35920-B2DE-E211-9163-0050568B37AC'
--   AND CompletedDate >= DATEADD(MONTH, -1, GETDATE())
-- ORDER BY activityid, CompletedDate;
-- TESTING END

-- Phil comment out 12/1/8/25 - gads doesn't appear to be used anymore, and this query is very slow
	--Add google campagin id from [GAds_CampaignIDs]  --> this is populated with APIGoogleAds.php script

--	  update a
--set google_campaignID = g.gCampaignID
--  FROM [DataWarehouse].[dbo].[Fact_Activity] a
--  join staging.[dbo].[GAds_CampaignIDs] g on g.accountid = a.[accountid]
--  where google_campaignID is null 
    
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% UPDATE INTO Fact_Unit %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

BEGIN TRY;THROW 50000,'',1;END TRY BEGIN CATCH;insert into Staging.dbo.log_DW_Time (LineNumber,MinSinceLast) values (ERROR_LINE(),DATEDIFF(mi,@DtLast,getdate()));END CATCH
set @DtLast = getdate()


SET @dt_start = @AsOfDt - 7
SET @dt_end = @AsOfDt

SET @dt_startx = @dt_start
		WHILE @dt_startx <= @dt_end
BEGIN
UPDATE f SET f.CurrentAge = currage
FROM Fact_Unit f INNER JOIN
(SELECT ksl_ApartmentId,DATEDIFF(Year,PrimaryBirthDate,@dt_startx) AS currage FROM Fact_Lease WHERE @dt_startx between StartDate and ISNULL(EndDate,@AsOfDt+1) and PrimaryBirthDate < @AsOfDt-1000)
 AS x ON x.ksl_ApartmentId = f.ksl_ApartmentId WHERE f.dt = @dt_startx  
	SET @dt_startx = DATEADD(dd,1,@dt_startx)
	
END

--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% INSERT INTO Fact_Financial %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

BEGIN TRY;THROW 50000,'',1;END TRY BEGIN CATCH;insert into Staging.dbo.log_DW_Time (LineNumber,MinSinceLast) values (ERROR_LINE(),DATEDIFF(mi,@DtLast,getdate()));END CATCH
set @DtLast = getdate()

--FINANCIAL &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
UPDATE staging.dbo.NS_accounts SET Type_Name = 'Operating Expenses' WHERE Type_Name = 'Cost of Goods Sold'
--UPDATE staging.dbo.NS_accounts SET Type_Name = 'Net Operating Income' WHERE Type_Name = 'Gross Profit'
UPDATE staging.dbo.NS_accounts SET Type_Name = 'Revenue' WHERE Type_Name = 'Income'
--select * from Fact_Financial where trandate = '1/31/2018' and entityshortname = 'PT' and accountnumber = '520100' and deptname = 'Assisted Living'
--SELECT * FROM staging.dbo.NS_SUBSIDIARIES
TRUNCATE TABLE Fact_Financial
INSERT INTO Fact_Financial
SELECT
MAX(s.name) EntityShortName,
case when MAX(d.Name) = 'General Administrative' then 'Hospitality'
else MAX(d.Name)
end as  DeptName,
c.Name Product,
a.AccountNumber,
a.type_name AccountType,
a.name AccountName,
sum(tl.amount) balance,
0 budget,
ap.ending trandate,
'Actuals' BudgetVersion,
NULL as SourceCategory


FROM
staging.dbo.NS_transactions t INNER JOIN staging.dbo.NS_transaction_lines tl ON t.transaction_id = tl.transaction_id
INNER JOIN staging.dbo.NS_accounts a ON a.account_id = tl.account_id
LEFT JOIN  staging.dbo.NS_accounts b ON b.Account_ID = a.Parent_ID
LEFT JOIN  staging.dbo.NS_SUBSIDIARIES s ON tl.SUBSIDIARY_ID =  s.SUBSIDIARY_ID 
LEFT JOIN staging.dbo.NS_DEPARTMENTS d ON tl.DEPARTMENT_ID = d.DEPARTMENT_ID
LEFT JOIN staging.dbo.NS_CLASSES c ON tl.CLASS_ID = c.CLASS_ID
LEFT JOIN staging.dbo.NS_Accounting_Periods ap ON ap.Accounting_Period_ID = t.Accounting_Period_ID 
WHERE
--t.trandate between '01/01/2017' and '12/31/2017' and
tl.non_posting_line = 'No' 
--and a.type_name in ('Income','Other Income','Expense','Other Expense','Cost of Goods Sold')
group by
a.AccountNumber,
a.type_name,
a.name,
tl.SUBSIDIARY_ID,
t.trandate,
tl.DEPARTMENT_ID,
c.Name,
ap.ending

union all --Budget %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SELECT  
s.name EntityShortName,
 
case when d.Name = 'General Administrative' then 'Hospitality'
else d.Name
end as  DeptName,
c.Name Product,
a.AccountNumber,
a.type_name AccountType,
a.name AccountName,
0 balance,
b.amount budget,

ap.Ending trandate,
 coalesce(bc.Name,'Operating Budget') BudgetVersion,
NULL as SourceCategory

FROM staging.dbo.NS_Budget b
INNER JOIN staging.dbo.NS_accounts a ON a.account_id = b.account_id
INNER JOIN staging.dbo.NS_Accounting_Periods ap ON ap.Accounting_Period_ID = b.Accounting_Period_ID
LEFT JOIN  staging.dbo.NS_SUBSIDIARIES s ON b.SUBSIDIARY_ID =  s.SUBSIDIARY_ID 
LEFT JOIN staging.dbo.NS_DEPARTMENTS d ON b.DEPARTMENT_ID = d.DEPARTMENT_ID
LEFT JOIN staging.dbo.NS_CLASSES c ON b.CLASS_ID = c.CLASS_ID
left join staging.dbo.NS_Budget_Category bc on bc.budget_CATEGORY_ID = b.CATEGORY_ID
--select * from staging.dbo.NS_Budget_Category

UPDATE Fact_Financial SET budget = budget *-1 WHERE AccountType = 'Revenue'


UPDATE Fact_Financial set SourceCategory =
			case	when ( [DeptName]= 'marketing' and AccountName = 'Marketing: Direct Mail - Printing & Postage') then 'Direct Mail'
					when ( [DeptName]= 'marketing' and AccountName = 'Marketing: Direct Mail Sourcing') then 'Direct Mail'
					when ( [DeptName]= 'marketing' and AccountName = 'Marketing: Directories') then 'Directory'
					when ( [DeptName]= 'marketing' and AccountName = 'Marketing: Internet & Website') then 'Internet'
					when ( [DeptName]= 'marketing' and AccountName = 'Marketing: Magazine') then 'Magazine Advertising'
					when ( [DeptName]= 'marketing' and AccountName = 'Marketing: Newspaper') then 'Newspaper Advertising'
					when ( [DeptName]= 'marketing' and AccountName = 'Marketing: Public Relations') then 'Public Relations'
					when ( [DeptName]= 'marketing' and AccountName = 'Marketing: Radio') then 'Radio Advertising'
					when ( [DeptName]= 'marketing' and AccountName = 'Marketing: Signage') then 'Drive-by/Signage'
					when ( [DeptName]= 'marketing' and AccountName = 'Marketing: TV') then 'Television Advertising'
					when ( [DeptName]= 'marketing' and AccountName = 'Outreach') then 'External/Offsite Events'
					when ( [DeptName]= 'marketing' and AccountName = 'Events') then 'Special Events'
					when ( [DeptName]= 'marketing' and AccountName = 'Food') then 'Special Events'
					when ( [DeptName]= 'marketing' and AccountName = 'Liquor') then 'Special Events'
					when ( [DeptName]= 'marketing' and AccountName = 'Sales Event Food') then 'Special Events'
				else 'blank'
				end
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% INSERT INTO Dim_COA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


BEGIN TRY;THROW 50000,'',1;END TRY BEGIN CATCH;insert into Staging.dbo.log_DW_Time (LineNumber,MinSinceLast) values (ERROR_LINE(),DATEDIFF(mi,@DtLast,getdate()));END CATCH
set @DtLast = getdate()


TRUNCATE TABLE Dim_COA
INSERT INTO Dim_COA
SELECT a.AccountNumber
,a.Name AccountName
,a.Full_Name AccountFullName
,a.Type_Name AccountType
,a.TYPE_SEQUENCE SortAccountType
,b.name HeaderName
,b.AccountNumber HeaderNumber
FROM staging.dbo.NS_accounts a
LEFT JOIN  staging.dbo.NS_accounts b ON b.Account_ID = a.Parent_ID
WHERE a.AccountNumber is not null 
and a.ACCOUNT_ID not in (
select min(s.ACCOUNT_ID) from staging.dbo.NS_accounts s group by AccountNumber having count(*) > 1) --and a.isinactive = 'No'
--and a.accountnumber = '100038'
--select * from Dim_COA
TRUNCATE TABLE Dim_FinancialGroup
INSERT INTO Dim_FinancialGroup
SELECT AccountType,SortAccountType,AccountNumber,1
FROM DIM_COA
group by AccountType,SortAccountType,AccountNumber
--SELECT * FROM Fact_Financial WHERE accountname = '625900'
INSERT INTO Dim_FinancialGroup SELECT distinct 'Net Operating Income',12.5,AccountNumber,-1  FROM Fact_Financial WHERE Accounttype in ('Revenue','Operating Expenses')
INSERT INTO Dim_FinancialGroup SELECT distinct 'Net Income',17,AccountNumber,1  FROM Fact_Financial WHERE Accounttype in ('Revenue','Operating Expenses','Other Expense')
--SELECT * FROM Dim_FinancialGroup order by sortaccounttype
INSERT INTO Dim_FinancialGroup SELECT distinct 'Total Current Assets',3.5,AccountNumber,1  FROM Fact_Financial WHERE Accounttype in ('Bank','Accounts Receivable','Other Current Asset')
INSERT INTO Dim_FinancialGroup SELECT distinct 'Total Assets',5.7,AccountNumber,1  FROM Fact_Financial WHERE Accounttype in ('Bank','Accounts Receivable','Other Current Asset','Fixed Asset','Other Asset')
INSERT INTO Dim_FinancialGroup SELECT distinct 'Total Current Liabilities',8.5,AccountNumber,-1  FROM Fact_Financial WHERE Accounttype in ('Accounts Payable','Other Current Liability')
UPDATE Dim_FinancialGroup SET sign = -1 WHERE Accounttype in ('Accounts Payable') 
UPDATE Dim_FinancialGroup SET sign = -1 WHERE Accounttype in ('Other Current Liability') 
UPDATE Dim_FinancialGroup SET sign = -1 WHERE Accounttype in ('Long Term Liability') 
UPDATE Dim_FinancialGroup SET sign = -1 WHERE Accounttype in ('Equity') 

UPDATE Dim_FinancialGroup SET sign = -1 WHERE Accounttype in ('Revenue') 
UPDATE Dim_FinancialGroup SET sign = -1 WHERE Accounttype in ('Net Income') 

--UPDATE Dim_FinancialGroup SET AccountType = 'Revenue' WHERE AccountType = 'Income'
--UPDATE Dim_FinancialGroup SET AccountType = 'Operating Expenses' WHERE AccountType = 'Cost of Goods Sold'

--UPDATE Dim_COA SET AccountType = 'Revenue' WHERE AccountType = 'Income'
--UPDATE Dim_COA SET AccountType = 'Operating Expenses' WHERE AccountType = 'Cost of Goods Sold'






--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Dayforce - Associate %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


BEGIN TRY;THROW 50000,'',1;END TRY BEGIN CATCH;insert into Staging.dbo.log_DW_Time (LineNumber,MinSinceLast) values (ERROR_LINE(),DATEDIFF(mi,@DtLast,getdate()));END CATCH
set @DtLast = getdate()


--delete from dim_associate  where exists(select * From staging.dbo.df_Associate df where df.dayforce_login_id =  dim_associate.dayforce_login_id)

delete from dim_associate  where exists(select * From staging.dbo.ADP_Associates df where [File Number] =  dim_associate.dayforce_login_id)
--RIGHT('00000'+ISNULL(,''),6)

insert into dim_associate 

([Dayforce_Login_Id], [First_Name], [Last_Name], [Id_and_Name], [Department], [Department_Reference_Code], [Job], [Status], [Status_Effective_Start], [Status_Reference_Code]
, [Location], [Base_Rate], [Base_Salary], [Hire_Date], [Termination_Date], [Pay_Type], [Status_Reason_Description], [shortname], [Reference_Code]
, [IsVoluntary], [Bday], [Email], [Phone], [PayClass], [Manager], [CMT], [Phone1],Preferred_Name,Email_Work)
select 
--RIGHT('00000'+ISNULL([File Number],''),6) as Dayforce_Login_Id
[File Number] as Dayforce_Login_Id
,[First Name] as 'First_Name'
,[Last Name] as 'Last_Name'
,RIGHT('00000'+ISNULL(RIGHT([File Number],6),''),6) + ' - ' + [First Name] + ' ' + [Last Name]
, replace([Home Department Description],'_','/')
, replace([Home Department Description],'_','/')
, [Job Title Description]
, [Position Status]
, convert(date,[Position Start Date])
, [Position Status]
, [Location Description]
, replace(replace([Regular Pay Rate Amount],',',''),'$','')
, replace(replace([Annual Salary],',',''),'$','')
, [Hire Date]
, coalesce(nullif([Termination Date],''),'1/1/3000')
, case when [FLSA Description] = 'Exempt' then 'Salaried(Exempt)'
when  [FLSA Description] = 'Non-exempt' then 'Hourly(Non-Exempt)' end as Pay_Type
, [Termination Reason Description]
, [Location Code]
,[Associate ID] as ADP_ID
,case when [Voluntary/Involuntary Termination Flag] = 'Voluntary' then 'Yes'
when [Voluntary/Involuntary Termination Flag] = 'Involuntary' then 'No' end
as IsVoluntary
,TRY_CAST([Birth Date] AS date) 
,coalesce(nullif([Work Contact: Work Email],''),nullif([Personal Contact: Personal Email],''))
,coalesce(nullif([Personal Contact: Personal Mobile],''),nullif([Personal Contact: Home Phone],''),nullif([Work Contact: Work Mobile],''),nullif([Work Contact: Work Phone],''))
,[Worker Category Description]
,(select top 1 [File Number] from staging.[dbo].ADP_Associates where [Position Status] = 'Active' and [Associate ID] =  a.[Reports To Associate ID])
,case when CMT = 'Yes' then 1 
when CMT = 'No' then 0 end as CMT  
,null
,[Preferred or Chosen First Name]
,[Work Contact: Work Email]
from staging.[dbo].[ADP_Associates] a 
where isnumeric([File Number]) = 1 and [File Number] <>''

;


--dedup
WITH Dups AS
(
SELECT *, ROW_NUMBER() OVER (PARTITION BY Dayforce_Login_Id ORDER BY [Termination_Date] desc) AS RowNum
FROM dim_associate
)
DELETE FROM Dups WHERE rownum > 1;


WITH Dups AS
(
SELECT *, ROW_NUMBER() OVER (PARTITION BY Reference_Code ORDER BY [Termination_Date] desc) AS RowNum
FROM dim_associate
)
DELETE FROM Dups WHERE rownum > 1;




--select * from staging.dbo.df_Associate where email = 'david.watkins@kiscosl.com'
--select min(shortName) shortName,Community from [dbo].[Dim_Community] group by Community order by Community
--select * from Dim_Community order by shortName
--select * from  staging.dbo.df_Associate where status_reason_description like 'Offer Declined%'
update dim_associate set Termination_Date = '1/1/3000' where Termination_Date < Hire_Date
update dim_associate set Termination_Date = Hire_Date where status = 'Terminated' and Termination_Date = '1/1/3000'
update dim_associate set Reference_Code = Dayforce_Login_Id where Reference_Code  is null
update dim_associate set location = rtrim(left(location, CHARINDEX('-', location) - 1)) where location like '%-%'
update dim_associate set location = 'BridgePoint at Los Altos' where location = 'BridgePoint Los Altos'
update dim_associate set location = 'Cardinal at North Hills HC' where location = 'The Cardinal at North Hills HC'
update dim_associate set location = 'Cardinal at North Hills' where location = 'The Cardinal at North Hills'
update dim_associate set location = 'Kisco Senior Living, LLC' where location = 'Kisco Senior Living'
update dim_associate set location = 'RHC' where location = 'Living Well At Home'
update dim_associate set location = 'The Elms at Abbotswood' where location = 'Abbotswood at Irving Park Expansion'
update dim_associate set location = 'La Posada Mallorca' where location = 'La Posada Expansion'
update dim_associate set location = 'Woodbridge Terrace' where location = 'Woodbridge'
update dim_associate set location = 'Woodbridge Terrace' where location = 'Woodbridge Terrace of Irvine'








/*
--Update balfour dept
update Dim_associate set department = 'Executive Administration' where department = 'Administration'  and len(Dayforce_Login_Id) > 6
update Dim_associate set department = 'Assisted Living' where department = 'Care Manager'  and len(Dayforce_Login_Id) > 6
update Dim_associate set department = 'Assisted Living' where department = 'Care Manager'  and len(Dayforce_Login_Id) > 6
update Dim_associate set department = 'Assisted Living' where department = 'Care Partner'  and len(Dayforce_Login_Id) > 6
update Dim_associate set department = 'Assisted Living' where department = 'CNAs/PCPs'  and len(Dayforce_Login_Id) > 6
update Dim_associate set department = 'Executive Administration' where department = 'Corporate Administration'  and len(Dayforce_Login_Id) > 6
update Dim_associate set department = 'Human Resources' where department = 'Corporate Human Resources'  and len(Dayforce_Login_Id) > 6
update Dim_associate set department = 'Operations' where department = 'Corporate Management'  and len(Dayforce_Login_Id) > 6
update Dim_associate set department = 'Dining' where department = 'Culinary Services'  and len(Dayforce_Login_Id) > 6
update Dim_associate set department = 'Dining' where department like '%Dining%'  and len(Dayforce_Login_Id) > 6
update Dim_associate set department = 'Dining' where department = 'Direct Care'  and len(Dayforce_Login_Id) > 6
update Dim_associate set department = 'Housekeeping/Laundry' where department = 'Housekeeping'  and len(Dayforce_Login_Id) > 6
update Dim_associate set department = 'Sales' where department = 'Leasing'  and len(Dayforce_Login_Id) > 6
update Dim_associate set department = 'Art of Living Well' where department = 'Life Enrichment'  and len(Dayforce_Login_Id) > 6
update Dim_associate set department = 'Assisted Living' where department = 'LPNs'  and len(Dayforce_Login_Id) > 6
update Dim_associate set department = 'Environmental Services' where department = 'Maintenance'  and len(Dayforce_Login_Id) > 6
update Dim_associate set department = 'Assisted Living' where department = 'Nursing Admin'  and len(Dayforce_Login_Id) > 6

update Dim_associate set department = 'Memory Care' where department = 'Nursing Admin'  and len(Dayforce_Login_Id) > 6
update Dim_associate set department = 'Assisted Living' where department = 'Nursing Admin'  and len(Dayforce_Login_Id) > 6
update Dim_associate set department = 'Assisted Living' where department = 'Professional Services'  and len(Dayforce_Login_Id) > 6
update Dim_associate set department = 'Assisted Living' where department = 'RNs'  and len(Dayforce_Login_Id) > 6

update Dim_associate set department = 'Executive Administration' where job = 'Associate Executive Director' and department = 'Administration' and len(Dayforce_Login_Id) > 6 
update Dim_associate set department = 'Executive Administration' where job = 'Concierge' and department = 'Administration' and len(Dayforce_Login_Id) > 6 
update Dim_associate set department = 'Executive Administration' where job = 'Continuing Care Case Manager' and department = 'Administration' and len(Dayforce_Login_Id) > 6 
update Dim_associate set department = 'Executive Administration' where job = 'Executive Director' and department = 'Administration' and len(Dayforce_Login_Id) > 6 
update Dim_associate set department = 'Executive Administration' where job = 'Front Desk Manager' and department = 'Administration' and len(Dayforce_Login_Id) > 6 
update Dim_associate set department = 'Executive Administration' where job = 'Hair Stylist' and department = 'Administration' and len(Dayforce_Login_Id) > 6 
update Dim_associate set department = 'Executive Administration' where job = 'Lead Concierge' and department = 'Administration' and len(Dayforce_Login_Id) > 6 
update Dim_associate set department = 'Executive Administration' where job = 'Resident & Family Services Manager' and department = 'Administration' and len(Dayforce_Login_Id) > 6 
update Dim_associate set department = 'Executive Administration' where job = 'Senior Executive Director' and department = 'Administration' and len(Dayforce_Login_Id) > 6 
update Dim_associate set department = 'Assisted Living' where job = 'Care Manager, LPN' and department = 'Care Manager' and len(Dayforce_Login_Id) > 6 
update Dim_associate set department = 'Assisted Living' where job = 'Care Manager, RN' and department = 'Care Manager' and len(Dayforce_Login_Id) > 6 
update Dim_associate set department = 'Memory Care' where job = 'Memory Care Manager' and department = 'Care Manager' and len(Dayforce_Login_Id) > 6 
update Dim_associate set department = 'Assisted Living' where job = 'Care Partner' and department = 'Care Partner' and len(Dayforce_Login_Id) > 6 
update Dim_associate set department = 'Assisted Living' where job = 'CNA' and department = 'Care Partner' and len(Dayforce_Login_Id) > 6 
update Dim_associate set department = 'Assisted Living' where job = 'Lead Care Partner' and department = 'Care Partner' and len(Dayforce_Login_Id) > 6 
update Dim_associate set department = 'Assisted Living' where job = 'QMAP' and department = 'Care Partner' and len(Dayforce_Login_Id) > 6 
update Dim_associate set department = 'Assisted Living' where job = 'Care Partner' and department = 'CNAs/PCPs' and len(Dayforce_Login_Id) > 6 
update Dim_associate set department = 'Assisted Living' where job = 'Certified Medication Aide' and department = 'CNAs/PCPs' and len(Dayforce_Login_Id) > 6 
update Dim_associate set department = 'Assisted Living' where job = 'CNA' and department = 'CNAs/PCPs' and len(Dayforce_Login_Id) > 6 
update Dim_associate set department = 'Assisted Living' where job = 'QMAP' and department = 'CNAs/PCPs' and len(Dayforce_Login_Id) > 6 
update Dim_associate set department = 'Skilled Nursing' where job = 'Skilled Nursing CNA' and department = 'CNAs/PCPs' and len(Dayforce_Login_Id) > 6 
update Dim_associate set department = 'Finance & Accounting' where job = 'Accounting Manager' and department = 'Corporate Administration' and len(Dayforce_Login_Id) > 6 
update Dim_associate set department = 'Finance & Accounting' where job = 'Accounts Receivable Specialist' and department = 'Corporate Administration' and len(Dayforce_Login_Id) > 6 
update Dim_associate set department = 'Finance & Accounting' where job = 'AP-AR Specialist' and department = 'Corporate Administration' and len(Dayforce_Login_Id) > 6 
update Dim_associate set department = 'Finance & Accounting' where job = 'Community Accountant' and department = 'Corporate Administration' and len(Dayforce_Login_Id) > 6 
update Dim_associate set department = 'Acquisition' where job = 'Director, Campus Facilities and Maintenance' and department = 'Corporate Administration' and len(Dayforce_Login_Id) > 6 
update Dim_associate set department = 'Sales' where job = 'Marketing & Communications Coordinator' and department = 'Corporate Administration' and len(Dayforce_Login_Id) > 6 
update Dim_associate set department = 'Operations' where job = 'Nurse Liaison' and department = 'Corporate Administration' and len(Dayforce_Login_Id) > 6 
update Dim_associate set department = 'Finance & Accounting' where job = 'Senior Accountant' and department = 'Corporate Administration' and len(Dayforce_Login_Id) > 6 
update Dim_associate set department = 'Acquisition' where job = 'Sr. Director, Facilities and Assessment Mgmt' and department = 'Corporate Administration' and len(Dayforce_Login_Id) > 6 
update Dim_associate set department = 'Finance & Accounting' where job = 'Vice President, Finance' and department = 'Corporate Administration' and len(Dayforce_Login_Id) > 6 
update Dim_associate set department = 'Operations' where job = 'Vice President, Operations' and department = 'Corporate Administration' and len(Dayforce_Login_Id) > 6 
update Dim_associate set department = 'Sales' where job = 'Vice President, Sales & Marketing' and department = 'Corporate Administration' and len(Dayforce_Login_Id) > 6 
update Dim_associate set department = 'Human Resources' where job = 'Human Resources Business Partner' and department = 'Corporate Human Resources' and len(Dayforce_Login_Id) > 6 
update Dim_associate set department = 'Human Resources' where job = 'Human Resources Onboarding Specialist' and department = 'Corporate Human Resources' and len(Dayforce_Login_Id) > 6 
update Dim_associate set department = 'Human Resources' where job = 'Manager, Total Rewards' and department = 'Corporate Human Resources' and len(Dayforce_Login_Id) > 6 
update Dim_associate set department = 'Human Resources' where job = 'Recruiter' and department = 'Corporate Human Resources' and len(Dayforce_Login_Id) > 6 
update Dim_associate set department = 'Human Resources' where job = 'Senior Director, Human Resources' and department = 'Corporate Human Resources' and len(Dayforce_Login_Id) > 6 
update Dim_associate set department = 'Human Resources' where job = 'Vice President, Human Resources' and department = 'Corporate Human Resources' and len(Dayforce_Login_Id) > 6 
update Dim_associate set department = 'Operations' where job = 'COO & Co-President' and department = 'Corporate Management' and len(Dayforce_Login_Id) > 6 
update Dim_associate set department = 'Sales' where job = 'Associate Director of Sales' and department = 'Leasing' and len(Dayforce_Login_Id) > 6 
update Dim_associate set department = 'Sales' where job = 'Leasing & Move-In Coordinator' and department = 'Leasing' and len(Dayforce_Login_Id) > 6 
update Dim_associate set department = 'Sales' where job = 'Leasing & Move-In Specialist' and department = 'Leasing' and len(Dayforce_Login_Id) > 6 
update Dim_associate set department = 'Sales' where job = 'Leasing Counselor' and department = 'Leasing' and len(Dayforce_Login_Id) > 6 
update Dim_associate set department = 'Sales' where job = 'Senior Director, Sales & Marketing' and department = 'Leasing' and len(Dayforce_Login_Id) > 6 
update Dim_associate set department = 'Art of Living Well' where job = 'Director, Community Life' and department = 'Life Enrichment' and len(Dayforce_Login_Id) > 6 
update Dim_associate set department = 'Art of Living Well' where job = 'Director, Life Enrichment' and department = 'Life Enrichment' and len(Dayforce_Login_Id) > 6 
update Dim_associate set department = 'Art of Living Well' where job = 'Fitness & Wellness Coordinator' and department = 'Life Enrichment' and len(Dayforce_Login_Id) > 6 
update Dim_associate set department = 'Art of Living Well' where job = 'Hair Stylist' and department = 'Life Enrichment' and len(Dayforce_Login_Id) > 6 
update Dim_associate set department = 'Art of Living Well' where job = 'Lead Life Enrichment Coordinator' and department = 'Life Enrichment' and len(Dayforce_Login_Id) > 6 
update Dim_associate set department = 'Art of Living Well' where job = 'Life Enrichment Manager' and department = 'Life Enrichment' and len(Dayforce_Login_Id) > 6 
update Dim_associate set department = 'Art of Living Well' where job = 'Life Enrichment Specialist' and department = 'Life Enrichment' and len(Dayforce_Login_Id) > 6 
update Dim_associate set department = 'Assisted Living' where job = 'Care Manager, LPN' and department = 'LPNs' and len(Dayforce_Login_Id) > 6 
update Dim_associate set department = 'Environmental Services' where job = 'Director, Maintenance' and department = 'Maintenance' and len(Dayforce_Login_Id) > 6 
update Dim_associate set department = 'Environmental Services' where job = 'Floor Technician' and department = 'Maintenance' and len(Dayforce_Login_Id) > 6 
update Dim_associate set department = 'Environmental Services' where job = 'Maintenance Manager' and department = 'Maintenance' and len(Dayforce_Login_Id) > 6 
update Dim_associate set department = 'Environmental Services' where job = 'Maintenance Technician' and department = 'Maintenance' and len(Dayforce_Login_Id) > 6 
update Dim_associate set department = 'Environmental Services' where job = 'Senior Director, Maintenance' and department = 'Maintenance' and len(Dayforce_Login_Id) > 6 
update Dim_associate set department = 'Assisted Living' where job = 'Central Supply, Lead CNA & Trainer' and department = 'Nursing Admin' and len(Dayforce_Login_Id) > 6 
update Dim_associate set department = 'Assisted Living' where job = 'Director, Health & Wellness' and department = 'Nursing Admin' and len(Dayforce_Login_Id) > 6 
update Dim_associate set department = 'Assisted Living' where job = 'Director, Nursing' and department = 'Nursing Admin' and len(Dayforce_Login_Id) > 6 
update Dim_associate set department = 'Memory Care' where job = 'Memory Care Manager' and department = 'Nursing Admin' and len(Dayforce_Login_Id) > 6 
update Dim_associate set department = 'Assisted Living' where job = 'Nursing Manager' and department = 'Nursing Admin' and len(Dayforce_Login_Id) > 6 
update Dim_associate set department = 'Assisted Living' where job = 'Scheduler' and department = 'Nursing Admin' and len(Dayforce_Login_Id) > 6 
update Dim_associate set department = 'Assisted Living' where department = 'Nursing Admin' and len(Dayforce_Login_Id) > 6 
update Dim_associate set department = 'Assisted Living' where job = 'Nursing Supervisor' and department = 'Professional Services' and len(Dayforce_Login_Id) > 6 
update Dim_associate set department = 'Assisted Living' where department = 'RNs' and len(Dayforce_Login_Id) > 6 

*/

update Dim_associate set department = 'Executive Administration' where department = 'Administration'  and len(Dayforce_Login_Id) > 6
update Dim_associate set department = 'Assisted Living' where department = 'BRC CNAs/PCPs'  and len(Dayforce_Login_Id) > 6
update Dim_associate set department = 'Assisted Living' where department = 'Care Manager'  and len(Dayforce_Login_Id) > 6
update Dim_associate set department = 'Assisted Living' where department = 'Care Partner'  and len(Dayforce_Login_Id) > 6
update Dim_associate set department = 'Assisted Living' where department = 'CNAs/PCPs'  and len(Dayforce_Login_Id) > 6
update Dim_associate set department = 'Strategic Services' where department = 'Corporate Administration'  and len(Dayforce_Login_Id) > 6
update Dim_associate set department = 'Development' where department = 'Corporate Development'  and len(Dayforce_Login_Id) > 6
update Dim_associate set department = 'Executive Administration' where department = 'Corporate Executive'  and len(Dayforce_Login_Id) > 6
update Dim_associate set department = 'Human Resources' where department = 'Corporate Human Resources'  and len(Dayforce_Login_Id) > 6
update Dim_associate set department = 'Development' where department = 'Corporate Interiors'  and len(Dayforce_Login_Id) > 6
update Dim_associate set department = 'Environmental Services' where department = 'Maintenance'  and len(Dayforce_Login_Id) > 6
update Dim_associate set department = 'Strategic Services' where department = 'Corporate Management'  and len(Dayforce_Login_Id) > 6
update Dim_associate set department = 'Marketing' where department = 'Corporate Marketing'  and len(Dayforce_Login_Id) > 6
update Dim_associate set department = 'Sales' where department = 'Corporate Sales and Leasing'  and len(Dayforce_Login_Id) > 6
UPDATE Dim_associate SET department = 'Culinary' WHERE department = 'Culinary Services' AND LEN(Dayforce_Login_Id) > 6;
UPDATE Dim_associate SET department = 'Culinary' WHERE department = 'Culinary Services, Dining' AND LEN(Dayforce_Login_Id) > 6;
UPDATE Dim_associate SET department = 'Development' WHERE department = 'Dev Administration' AND LEN(Dayforce_Login_Id) > 6;
UPDATE Dim_associate SET department = 'Assisted Living' WHERE department = 'Direct Care' AND LEN(Dayforce_Login_Id) > 6;
UPDATE Dim_associate SET department = 'Housekeeping/Laundry' WHERE department = 'Housekeeping' AND LEN(Dayforce_Login_Id) > 6;
UPDATE Dim_associate SET department = 'Housekeeping/Laundry' WHERE department = 'Housekeeping_Laundry' AND LEN(Dayforce_Login_Id) > 6;
UPDATE Dim_associate SET department = 'Development' WHERE department = 'Interiors Administration' AND LEN(Dayforce_Login_Id) > 6;
UPDATE Dim_associate SET department = 'Sales' WHERE department = 'Leasing' AND LEN(Dayforce_Login_Id) > 6;
UPDATE Dim_associate SET department = 'Life Enrichment' WHERE department = 'Life Enrichment' AND LEN(Dayforce_Login_Id) > 6;
UPDATE Dim_associate SET department = 'Skilled Nursing' WHERE department = 'LPNs' AND LEN(Dayforce_Login_Id) > 6;
UPDATE Dim_associate SET department = 'Environmental Services' WHERE department = 'Maintenance' AND LEN(Dayforce_Login_Id) > 6;
UPDATE Dim_associate SET department = 'Ancillaries' WHERE department = 'Medical Records' AND LEN(Dayforce_Login_Id) > 6;
UPDATE Dim_associate SET department = 'Skilled Nursing' WHERE department = 'Nursing Admin' AND LEN(Dayforce_Login_Id) > 6;
UPDATE Dim_associate SET department = 'Professional Services' WHERE department = 'Professional Services' AND LEN(Dayforce_Login_Id) > 6;
UPDATE Dim_associate SET department = 'Skilled Nursing' WHERE department = 'RNs' AND LEN(Dayforce_Login_Id) > 6;
UPDATE Dim_associate SET department = 'Life Enrichment' WHERE department = 'Social Services' AND LEN(Dayforce_Login_Id) > 6;
UPDATE Dim_associate SET department = 'Life Enrichment' WHERE department = 'Wellness' AND LEN(Dayforce_Login_Id) > 6;

--Kisco
update dim_associate set department = 'Culinary' where department = 'Dining Services'
update dim_associate set department = 'Culinary' where department = 'Dining Services IL'
update dim_associate set department = 'Culinary' where department = 'Dining Services SNF'
update dim_associate set department = 'Culinary' where department = 'Dining Services AL'
update dim_associate set department = 'Culinary' where department = 'Dining Services MC'
update dim_associate set department = 'Housekeeping/Laundry' where department = 'Laundry'
update dim_associate set department = 'Skilled Nursing' where department = 'Medical Records'
update dim_associate set department = 'Skilled Nursing' where department = 'Nursing Administration'
update dim_associate set department = 'Wellness' where department = 'Wellness Services'
update dim_associate set department = 'Environmental Services' where department = 'Facilities Services'
update dim_associate set department = 'Skilled Nursing' where department = 'Nursing Administration'
update dim_associate set department = 'Hospitality' where department = 'Medical Records'
update dim_associate set department = 'Hospitality' where department = 'Social Services'
update dim_associate set department = 'Hospitality' where department = 'Admissions'
--select distinct department from dim_associate where last_name = 'Ritschel'
update dim_associate set department = 'Finance & Accounting' where department = 'Accounting Services'
update dim_associate set department = 'Acquisition' where department = 'Acquisitions and Investments'
update dim_associate set department = 'Acquisition' where department = 'Development Services'
update dim_associate set department = 'Operations Services' where department = 'Operations'
update dim_associate set department = 'Risk Services' where department = 'Risk'
update dim_associate set department = 'Sales & Marketing Services' where department = 'Sales and Marketing Services'
update dim_associate set department = 'Human Resources' where department = 'People Services'
update dim_associate set department = 'Hospitality' where department = 'General Administrative'
update dim_associate set department = 'Operations' where department = 'Operations Services'
update dim_associate set department = 'Life Enrichment' where department = 'Wellness'
update dim_associate set department = 'Culinary' where department = 'Dining'
update dim_associate set department = 'Life Enrichment' where department = 'Art of Living Well'
update dim_associate set department = 'Hospitality' where department = 'Resident Relations'








update Dim_associate set shortname = 'CWD' where shortname = 'BCV'
update Dim_associate set shortname = 'LSV' where shortname = 'BLF'
update Dim_associate set shortname = 'BMC' where shortname = 'BSC'
update Dim_associate set shortname = 'RIV' where shortname = 'DVR'
update Dim_associate set shortname = 'LSV' where shortname = 'LDG'
update Dim_associate set shortname = 'LGT' where shortname = 'LGM'
update Dim_associate set shortname = 'LSV' where shortname = 'RES'
update Dim_associate set shortname = 'BCP' where shortname = 'STU'





--select * from dim_community
delete from dim_associate  where status_reason_description = 'Offer Declined -Candidate never worked'
delete dim_associate where [Status_Reason_Description] in ('Term - Candidate Never Worked','Term - Offer Declined Candidate Never Workedd','Term Candidate Never Worked')

--update d set d.shortName = x.shortName
--from dim_associate d left join (select min(shortName) shortName,Community from [dbo].[Dim_Community] group by Community) x 
--on location collate SQL_Latin1_General_CP1_CI_AS  = Community
update dim_associate set shortName = 'CNH.HC' where shortName = 'CNHHC'
--voluntary

delete from Dim_Associate where Status =  'Active'
and Dayforce_Login_Id not in (
select [File Number] from Staging..[ADP_Associates] where [Position Status] = 'Active'
) and 

(
select count(*) from Dim_Associate a where a.Status =  'Active'
and a.Dayforce_Login_Id not in (
select [File Number] from Staging..[ADP_Associates] where [Position Status] = 'Active'
)) <100


/*
update dim_associate set IsVoluntary = 'Yes' where (Status_Reason_Description <> '8500 Other - Deceased' and Status_Reason_Description <> 'Death' 
and Status_Reason_Description <> 'Performance' and Status_Reason_Description <> 'Illness/Injury')
and not Status_Reason_Description  like '%involuntary%'
*/

--update dim_associate set IsVoluntary = 'No' where IsVoluntary is null

update DataWarehouse..dim_associate set Phone = right(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(Phone, '(', ''), ')', ''), '-', ''), ' ', ''), '+', ''), '.', ''), '/', ''), ',', ''),10)


  delete  from DataWarehouse..dim_associate where isnumeric(Dayforce_Login_Id) = 0
  insert into DataWarehouse..dim_associate ([Dayforce_Login_Id], [First_Name], [Last_Name], [Id_and_Name], [Department], [Department_Reference_Code], [Job], [Status], [Status_Effective_Start]
  , [Status_Reference_Code]) 
  select Department+ ' - ' + Job, 'Temp', 'Labor', Department+ ' - ' + Job, Department, Department, Job, 'Terminated', '1/1/2000', 'Terminated'
  from DataWarehouse..dim_associate 
  where Job in ('Cook',
'Housekeeper',
'Laundry Aide',
'Lead Housekeeper',
'Lead Server',
'Medication Technician',
'Memory Care Coordinator',
'Prep Cook',
'Resident Assistant',
'Resident Care Coordinator',
'Resident Care Supervisor',
'Server',
'Utility Worker'
)
  group by Department,Job









delete staging.dbo.adp_punch where isnumeric([Location Code]) = 1
--select * from dim_associate
delete from fact_punch where exists(select * From staging.dbo.adp_punch adp where convert(date,adp.[Employee Pay Date]) =  convert(date,fact_punch.Employee_Pay_Summary_Pay_Date) 
and isnumeric(Employee_Reference_Code) = 1 and len(adp.[File Number])=7 and len(fact_punch.Employee_Reference_Code) = 7)

delete from fact_punch where exists(select * From staging.dbo.adp_punch adp where convert(date,adp.[Employee Pay Date]) =  convert(date,fact_punch.Employee_Pay_Summary_Pay_Date) 
and isnumeric(Employee_Reference_Code) = 1 and len(adp.[File Number])=6 and len(fact_punch.Employee_Reference_Code) = 6)



insert into fact_punch 
select 
case 
when Pay_Category_Reference_Code = 'CA Meal Premium' then 'PREM'
when Pay_Category_Reference_Code = 'Double Time' then 'OT 2.0'
when Pay_Category_Reference_Code = 'Overtime' then 'OT 1.5'
when Pay_Category_Reference_Code = 'Vacation' then 'HOL 1.0'
when Pay_Category_Reference_Code = 'Holiday Worked OT' then 'OT 2.0'
when Pay_Category_Reference_Code = 'Holiday' then 'HOL 1.0'

else 'REG' end
, [File Number]
, [Location Description]
, [Department Description]
, convert(int,ROUND([Minute Duration],0))/60.0
, [Employee Pay Date]
, [Actual Pay Rate]
, case when [Pay_Category_Reference_Code] = 'Overtime' then 'Work'
when [Pay_Category_Reference_Code] = 'CA Meal Premium' then 'Missed Meal Period'
when [Pay_Category_Reference_Code] = 'CA Split Shift' then 'CA Split Shift'
when [Pay_Category_Reference_Code] = 'Regular' then 'Work'
when [Pay_Category_Reference_Code] = 'Unpaid Vacation' then 'Vacation'
when [Pay_Category_Reference_Code] = 'Vacation' then 'Vacation'
when [Pay_Category_Reference_Code] = 'Double Time' then 'Work'
when [Pay_Category_Reference_Code] = 'Training' then 'Work'
when [Pay_Category_Reference_Code] = 'Holiday Worked' then 'Work'
when [Pay_Category_Reference_Code] = 'Holiday Worked OT' then 'Work'

when [Pay_Category_Reference_Code] = 'Cert Trainer' then 'Work'
when [Pay_Category_Reference_Code] = 'Training Hours' then 'Work'

--when [Pay_Category_Reference_Code] = 'Cert Trainer' then 'Work'
else [Pay_Category_Reference_Code] end
, convert(int,ROUND([Minute Duration],0))
, [Actual Pay Rate]
, [Location Code]
,Null
,[Job Title Description]
from staging.dbo.adp_punch 

--HOL 1.0
--HOL 1.5
--OT 1.5
--OT 2.0
--PREM
--REG

--Floating Holiday
--Holiday
--Missed Meal Period
--NOT IN USE - Training
--Sick
--Training
--Vacation
--Work

/*
Sick Pay
Overtime
Cert Trainer 
Paid Not Worked
Jury Duty
Called In
CA Meal Premium
CA Split Shift
Unpaid Sick
--Regular
Sup In Charge 1.00
Bereavement
Unpaid Vacation
Vacation
Please Select Below
Unpaid Leave
Double Time
COVID Time
Float
Training 
Shift Diff - 2.00
Shift Diff - 1.00
On-Call Pay
Pay Code Edit
*/

update fact_punch set shortName = 'CNH.HC' where shortName = 'CNHHC'
--update fact_punch set shortName = 'CNHEX' where shortName = 'TCT'



update fact_punch set shortname = 'CWD' where shortname = 'BCV'
update fact_punch set shortname = 'LSV' where shortname = 'BLF'
update fact_punch set shortname = 'BMC' where shortname = 'BSC' 
update fact_punch set shortname = 'RIV' where shortname = 'DVR'
update fact_punch set shortname = 'LSV' where shortname = 'LDG'
update fact_punch set shortname = 'LGT' where shortname = 'LGM'
update fact_punch set shortname = 'LSV' where shortname = 'RES'
update fact_punch set shortname = 'BCP' where shortname = 'STU'
/*
--BAA

BCV
BLF
BRC
BSC
DVR
LDG
LGM
LIT
RES
RHC
STU

Dim_Community
BAA
BCP
BRC
CWD
LGT
LIT
LNGM
LSV
RIV

*/



--select * from staging.dbo.df_schedule
--select * from fact_schedule 9
delete from fact_schedule where convert(date,fact_schedule.BusinessDate) >= convert(date,getdate()-9) and isnumeric(Employee_Reference_Code) = 1

--exists(select * From staging.dbo.df_schedule df where convert(date,df.BusinessDate) =  convert(date,fact_schedule.BusinessDate) and convert(date,df.BusinessDate) >= convert(date,getdate()-9))
insert into fact_schedule 
select 
[Employee_Schedule_Net_Hours]
, [Department_Description]
, [Location_Name]
, [Employee_Reference_Code]
, [Job_Name]
, [ks_Net_Hours]/60.0
, [BusinessDate]
, [Employee_Punch_Net_Hours]
, [ks_Punch_Net_Hours]/60.0
, [Employee_Schedule_Date_Start]
, [Employee_Schedule_Is_Deleted]
, [Employee_Schedule_Status_Code]
,[Location_Name]
from staging.dbo.df_schedule
where (Employee_Reference_Code in (select dayforce_login_id from Dim_Associate where status = 'Active') or Employee_Reference_Code is null)
and convert(date,BusinessDate) >= convert(date,getdate()-9)
and [Location_Name] <> ''




update fact_schedule set Location_Name = 'CNHEX' where shortName = 'TCT'
update fact_schedule set shortName = 'CNHEX' where shortName = 'TCT'




update fact_schedule set department_description = 'Housekeeping/Laundry' where department_description = 'Housekeeping_Laundry'

update fact_schedule set department_description = 'Culinary' where department_description = 'Dining Services'
update fact_schedule set department_description = 'Culinary' where department_description = 'Dining Services IL'
update fact_schedule set department_description = 'Culinary' where department_description = 'Dining Services SNF'

update fact_schedule set department_description = 'Culinary' where department_description = 'Dining Services AL'
update fact_schedule set department_description = 'Culinary' where department_description = 'Dining Services MC'

update fact_schedule set department_description = 'Housekeeping/Laundry' where department_description = 'Laundry'
update fact_schedule set department_description = 'Skilled Nursing' where department_description = 'Medical Records'
update fact_schedule set department_description = 'Skilled Nursing' where department_description = 'Nursing Administration'
update fact_schedule set department_description = 'Wellness' where department_description = 'Wellness Services'
update fact_schedule set department_description = 'Environmental Services' where department_description = 'Facilities Services'
update fact_schedule set department_description = 'Skilled Nursing' where department_description = 'Nursing Administration'
update fact_schedule set department_description = 'Hospitality' where department_description = 'Medical Records'
update fact_schedule set department_description = 'Hospitality' where department_description = 'Social Services'
update fact_schedule set department_description = 'Hospitality' where department_description = 'Admissions'
--Clean Community
update fact_schedule set department_description = 'Finance & Accounting' where department_description = 'Accounting Services'
update fact_schedule set department_description = 'Acquisition' where department_description = 'Acquisitions and Investments'
update fact_schedule set department_description = 'Acquisition' where department_description = 'Development Services'
update fact_schedule set department_description = 'Operations Services' where department_description = 'Operations'
update fact_schedule set department_description = 'Risk Services' where department_description = 'Risk'
update fact_schedule set department_description = 'Sales & Marketing Services' where department_description = 'Sales and Marketing Services'
update fact_schedule set department_description = 'Human Resources' where department_description = 'People Services'
update fact_schedule set department_description = 'Hospitality' where department_description = 'General Administrative'
update fact_schedule set department_description = 'Ancillaries' where department_description = 'Ancillaries AL'
update fact_schedule set department_description = 'Operations' where department_description = 'Operations Services'

update fact_schedule set location_name = rtrim(left(location_name, CHARINDEX('-', location_name) - 1)) where location_name like '%-%'
update fact_schedule set location_name = 'BridgePoint at Los Altos' where location_name = 'BridgePoint Los Altos'
update fact_schedule set location_name = 'Cardinal at North Hills HC' where location_name = 'The Cardinal at North Hills HC'
update fact_schedule set location_name = 'Cardinal at North Hills' where location_name = 'The Cardinal at North Hills'
update fact_schedule set location_name = 'Kisco Senior Living, LLC' where location_name = 'Kisco Senior Living'
update fact_schedule set location_name = 'RHC' where location_name = 'Living Well At Home'
update fact_schedule set location_name = 'The Elms at Abbotswood' where location_name = 'Abbotswood at Irving Park Expansion'
update fact_schedule set location_name = 'La Posada Mallorca' where location_name = 'La Posada Expansion'
update fact_schedule set location_name = 'Woodbridge Terrace' where location_name = 'Woodbridge'

--update d set d.shortName = x.shortName
--from fact_schedule d left join (select min(shortName) shortName,Community from [dbo].[Dim_Community] group by Community) x 
--on location_name collate SQL_Latin1_General_CP1_CI_AS  = Community



--select * from Dim_Associate where not exists(select * from Dim_Department where department = name)
--Clean Department TODO-create department associate

UPDATE fact_punch SET department_description = 'Executive Administration' WHERE department_description = 'BRP Administration';
UPDATE fact_punch SET department_description = 'Assisted Living' WHERE department_description = 'BRP Care Manager';
UPDATE fact_punch SET department_description = 'Assisted Living' WHERE department_description = 'BRP Care Partner';
UPDATE fact_punch SET department_description = 'Culinary' WHERE department_description = 'BRP Culinary Services';
UPDATE fact_punch SET department_description = 'Culinary' WHERE department_description = 'BRP Culinary Services Dining';
UPDATE fact_punch SET department_description = 'Housekeeping/Laundry' WHERE department_description = 'BRP Housekeeping';
UPDATE fact_punch SET department_description = 'Sales & Marketing Services' WHERE department_description = 'BRP Leasing';
UPDATE fact_punch SET department_description = 'Life Enrichment' WHERE department_description = 'BRP Life Enrichment';
UPDATE fact_punch SET department_description = 'Environmental Services' WHERE department_description = 'BRP Maintenance';
UPDATE fact_punch SET department_description = 'Skilled Nursing' WHERE department_description = 'BRP Nursing Admin';
UPDATE fact_punch SET department_description = 'Transportation' WHERE department_description = 'BRP Transportation';

UPDATE fact_punch SET department_description = replace(department_description,'BRP ','') where department_description like 'BRP %';


update fact_punch set department_description = 'Executive Administration' where department_description = 'Administration'  and len(Employee_Reference_Code) > 6
update fact_punch set department_description = 'Assisted Living' where department_description = 'BRC CNAs/PCPs'  and len(Employee_Reference_Code) > 6
update fact_punch set department_description = 'Assisted Living' where department_description = 'Care Manager'  and len(Employee_Reference_Code) > 6
update fact_punch set department_description = 'Assisted Living' where department_description = 'Care Partner'  and len(Employee_Reference_Code) > 6
update fact_punch set department_description = 'Assisted Living' where department_description = 'CNAs/PCPs'  and len(Employee_Reference_Code) > 6
update fact_punch set department_description = 'Strategic Services' where department_description = 'Corporate Administration'  and len(Employee_Reference_Code) > 6
update fact_punch set department_description = 'Development' where department_description = 'Corporate Development'  and len(Employee_Reference_Code) > 6
update fact_punch set department_description = 'Executive Administration' where department_description = 'Corporate Executive'  and len(Employee_Reference_Code) > 6
update fact_punch set department_description = 'Human Resources' where department_description = 'Corporate Human Resources'  and len(Employee_Reference_Code) > 6
update fact_punch set department_description = 'Development' where department_description = 'Corporate Interiors'  and len(Employee_Reference_Code) > 6
update fact_punch set department_description = 'Environmental Services' where department_description = 'Maintenance'  and len(Employee_Reference_Code) > 6
update fact_punch set department_description = 'Strategic Services' where department_description = 'Corporate Management'  and len(Employee_Reference_Code) > 6
update fact_punch set department_description = 'Marketing' where department_description = 'Corporate Marketing'  and len(Employee_Reference_Code) > 6
update fact_punch set department_description = 'Sales' where department_description = 'Corporate Sales and Leasing'  and len(Employee_Reference_Code) > 6
UPDATE fact_punch SET department_description = 'Culinary' WHERE department_description = 'Culinary Services' AND len(Employee_Reference_Code) > 6;
UPDATE fact_punch SET department_description = 'Culinary' WHERE department_description = 'Culinary Services, Dining' AND len(Employee_Reference_Code) > 6;
UPDATE fact_punch SET department_description = 'Development' WHERE department_description = 'Dev Administration' AND len(Employee_Reference_Code) > 6;
UPDATE fact_punch SET department_description = 'Assisted Living' WHERE department_description = 'Direct Care' AND len(Employee_Reference_Code) > 6;
UPDATE fact_punch SET department_description = 'Housekeeping/Laundry' WHERE department_description = 'Housekeeping' AND len(Employee_Reference_Code) > 6;
UPDATE fact_punch SET department_description = 'Housekeeping/Laundry' WHERE department_description = 'Housekeeping_Laundry' AND len(Employee_Reference_Code) > 6;
UPDATE fact_punch SET department_description = 'Development' WHERE department_description = 'Interiors Administration' AND len(Employee_Reference_Code) > 6;
UPDATE fact_punch SET department_description = 'Sales' WHERE department_description = 'Leasing' AND len(Employee_Reference_Code) > 6;
UPDATE fact_punch SET department_description = 'Life Enrichment' WHERE department_description = 'Life Enrichment' AND len(Employee_Reference_Code) > 6;
UPDATE fact_punch SET department_description = 'Skilled Nursing' WHERE department_description = 'LPNs' AND len(Employee_Reference_Code) > 6;
UPDATE fact_punch SET department_description = 'Environmental Services' WHERE department_description = 'Maintenance' AND len(Employee_Reference_Code) > 6;
UPDATE fact_punch SET department_description = 'Ancillaries' WHERE department_description = 'Medical Records' AND len(Employee_Reference_Code) > 6;
UPDATE fact_punch SET department_description = 'Skilled Nursing' WHERE department_description = 'Nursing Admin' AND len(Employee_Reference_Code) > 6;
UPDATE fact_punch SET department_description = 'Professional Services' WHERE department_description = 'Professional Services' AND len(Employee_Reference_Code) > 6;
UPDATE fact_punch SET department_description = 'Skilled Nursing' WHERE department_description = 'RNs' AND len(Employee_Reference_Code) > 6;
UPDATE fact_punch SET department_description = 'Life Enrichment' WHERE department_description = 'Social Services' AND len(Employee_Reference_Code) > 6;
UPDATE fact_punch SET department_description = 'Life Enrichment' WHERE department_description = 'Wellness' AND len(Employee_Reference_Code) > 6;

--Kisco


update fact_punch set department_description = 'Housekeeping/Laundry' where department_description = 'Housekeeping_Laundry'
update fact_punch set department_description = 'Culinary' where department_description = 'Dining Services'
update fact_punch set department_description = 'Culinary' where department_description = 'Dining Services IL'
update fact_punch set department_description = 'Culinary' where department_description = 'Dining Services SNF'
update fact_punch set department_description = 'Culinary' where department_description = 'Dining Services AL'
update fact_punch set department_description = 'Culinary' where department_description = 'Dining Services MC'
update fact_punch set department_description = 'Housekeeping/Laundry' where department_description = 'Laundry'
update fact_punch set department_description = 'Skilled Nursing' where department_description = 'Medical Records'
update fact_punch set department_description = 'Skilled Nursing' where department_description = 'Nursing Administration'
update fact_punch set department_description = 'Wellness' where department_description = 'Wellness Services'
update fact_punch set department_description = 'Environmental Services' where department_description = 'Facilities Services'
update fact_punch set department_description = 'Skilled Nursing' where department_description = 'Nursing Administration'
update fact_punch set department_description = 'Hospitality' where department_description = 'Medical Records'
update fact_punch set department_description = 'Hospitality' where department_description = 'Social Services'
update fact_punch set department_description = 'Hospitality' where department_description = 'Admissions'
--Clean Community
update fact_punch set department_description = 'Finance & Accounting' where department_description = 'Accounting Services'
update fact_punch set department_description = 'Acquisition' where department_description = 'Acquisitions and Investments'
update fact_punch set department_description = 'Acquisition' where department_description = 'Development Services'
update fact_punch set department_description = 'Operations Services' where department_description = 'Operations'
update fact_punch set department_description = 'Risk Services' where department_description = 'Risk'
update fact_punch set department_description = 'Sales & Marketing Services' where department_description = 'Sales and Marketing Services'
update fact_punch set department_description = 'Human Resources' where department_description = 'People Services'
update fact_punch set department_description = 'Hospitality' where department_description = 'General Administrative'
update fact_punch set department_description = 'Ancillaries' where department_description = 'Ancillaries AL'
update fact_punch set department_description = 'Operations' where department_description = 'Operations Services'

update fact_punch set department_description = 'Life Enrichment' where department_description = 'Wellness'
update fact_punch set department_description = 'Life Enrichment' where department_description = 'Art of Living Well'


-- Update statements to map old department names to new ones





--update d set d.shortName = x.shortName
--from fact_punch d left join (select min(shortName) shortName,Community from [dbo].[Dim_Community] group by Community) x 
--on location_name collate SQL_Latin1_General_CP1_CI_AS  = Community


--Create Fact Associate select * from fact_punch where location_name = 'La Posada Expansion'
truncate table Fact_Associate
insert into Fact_Associate
select 
Dayforce_Login_Id
,Department
,Shortname
,Base_Rate
,Base_Salary
,Termination_Date
from dim_associate WITH (NOLOCK) 


/*
update fact_punch set Manager_Authorized = null

update Fact_Punch set Manager_Authorized = case when a.Manager_Authorized = 1 then 'True' else 'False' End
from Fact_Punch inner join staging.dbo.df_punch_approval a
on Fact_Punch.employee_reference_code = a.employee_reference_code
and Fact_Punch.[Employee_Pay_Summary_Pay_Date] = a.[Employee_Pay_Summary_Pay_Date]
where a.[Manager_Authorized] = 1
*/

--19 - Mobile
--18 - Home
--24 - peronsal Email
--32 - business email


--Create History
insert into Dim_Associate_History ([Dayforce_Login_Id], [First_Name], [Last_Name], [Id_and_Name], [Department], [Department_Reference_Code], [Job], [Status], [Status_Effective_Start], [Status_Reference_Code], [Location], [Base_Rate], [Base_Salary], [Hire_Date], [Termination_Date], [Pay_Type], [Status_Reason_Description], [shortname], [Reference_Code], [IsVoluntary], [Bday], [Email], [Phone], [PayClass], [Manager], [CMT], [Phone1],Preferred_Name)
select [Dayforce_Login_Id], [First_Name], [Last_Name], [Id_and_Name], [Department], [Department_Reference_Code], [Job], [Status], [Status_Effective_Start], [Status_Reference_Code], [Location], [Base_Rate], [Base_Salary], [Hire_Date], [Termination_Date], [Pay_Type], [Status_Reason_Description], [shortname], [Reference_Code], [IsVoluntary], [Bday], [Email], [Phone], [PayClass], [Manager], [CMT], [Phone1],Preferred_Name
from 
 dim_associate WITH (NOLOCK) where not exists( select * from Dim_Associate_History WITH (NOLOCK) where dt = convert(date,getdate()))


Print 'Dayforce:' + convert(varchar(50),getdate());






--Popluate Work Orders&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
/*truncate table Fact_WorkOrder
select convert(datetime,CreatedDate),* from Staging.dbo.worxhub_stage order by convert(datetime,CreatedDate)
select * from Fact_WorkOrder 
where exists(select * from Staging.dbo.worxhub_stage 
where convert(datetime,Fact_WorkOrder.CreatedDate) = convert(datetime,worxhub_stage.CreatedDate))

WITH cte AS (
    SELECT 
*,
        ROW_NUMBER() OVER (
            PARTITION BY 
                CreatedDate, 
                WONumber
            ORDER BY 
                 CreatedDate, 
                WONumber
        ) row_num
     FROM 
        Staging.dbo.worxhub_stage
)
--select * from cte
DELETE FROM cte
WHERE row_num > 1;

*/

--select * from Staging.dbo.worxhub_stage order by dt desc
--select * from Fact_WorkOrder


BEGIN TRY;THROW 50000,'',1;END TRY BEGIN CATCH;insert into Staging.dbo.log_DW_Time (LineNumber,MinSinceLast) values (ERROR_LINE(),DATEDIFF(mi,@DtLast,getdate()));END CATCH
set @DtLast = getdate()



delete from Staging.dbo.worxhub_stage where WONumber  = 'undefined'
update Staging.dbo.worxhub_stage set CompletedDate = null where CompletedDate = 'undefined'
update Staging.dbo.worxhub_stage set DueDate = null where DueDate = 'undefined'
update Staging.dbo.worxhub_stage set LaborTimeInMinutes = null where LaborTimeInMinutes = 'undefined'
update Staging.dbo.worxhub_stage set CreatedDate = convert(datetime,CreatedDate), StartDate = convert(date,StartDate),DueDate = convert(date,DueDate)
,CompletedDate = convert(date,CompletedDate) 

delete from Fact_WorkOrder where exists(select * from Staging.dbo.worxhub_stage where Fact_WorkOrder.WONumber = worxhub_stage.WONumber and Fact_WorkOrder.CreatedDate = worxhub_stage.CreatedDate)
insert into Fact_WorkOrder
select [WONumber]
      ,[Status]
      ,[Department]
      ,[Description]
      ,[CreatedDate]
      ,[CreatedByUserName]
      ,[StartDate]
      ,[DueDate]
      ,[Location]
      ,[Priority]
      ,[Category]
      ,[SubCategory]
      ,[SourceOfWork]
      ,[Billable]
      ,[BillAmount]
      ,[WorkerList]
      ,[Site]
      ,[LaborTimeInMinutes]
      ,[RequestorPhoneNumber]
,case when site = 'bridgepoint.theworxhub.com' then 'BLA'
when site = 'byronpark.theworxhub.com' then 'BP'
when site = 'cedarwood.theworxhub.com' then 'CW'
when site = 'cypresscourt.theworxhub.com' then 'CC'
when site = 'draketerrace.theworxhub.com' then 'DT'
when site = 'emeraldcourt.theworxhub.com' then 'EC'
when site = 'firstcolonialinn.theworxhub.com' then 'FCI'
when site = 'heritagegreens.theworxhub.com' then 'HG'
when site = 'ilimaatleihano.theworxhub.com' then 'IAL'
when site = 'irvingpark.theworxhub.com' then 'AIP'
when site = 'laposada.theworxhub.com' then 'LP'
when site = 'magnoliaglen.theworxhub.com' then 'MG'
when site = 'parkplaza.theworxhub.com' then 'PP'
when site = 'parkterrace.theworxhub.com' then 'PT'
when site = 'sagewoodatdaybreak.theworxhub.com' then 'SW'
when site = 'stonehenge.theworxhub.com' then 'ASH'
when site = 'thecardinal.theworxhub.com' then 'CNH'
when site = 'thefountains.theworxhub.com' then 'TF'
when site = 'thekensington.theworxhub.com' then 'TK'
when site = 'valenciaterrace.theworxhub.com' then 'VT'
when site = 'woodlandterrace.theworxhub.com' then 'WT'
when site = 'woodbridge.theworxhub.com' then 'WB'
when site = 'thenewbury.theworxhub.com' then 'NWB'


end as shortname
,convert(datetime,CompletedDate) CompletedDate
,[IsComplianceRelated]
, case when [IsComplianceRelated] = 'true' and convert(date,DueDate) >= convert(date,CompletedDate) then 'true' else 'false' end  [IsComplianceOnTime]
from Staging.dbo.worxhub_stage


--Populate Training%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


BEGIN TRY;THROW 50000,'',1;END TRY BEGIN CATCH;insert into Staging.dbo.log_DW_Time (LineNumber,MinSinceLast) values (ERROR_LINE(),DATEDIFF(mi,@DtLast,getdate()));END CATCH
set @DtLast = getdate()



--select * from [staging].[dbo].[Relias_Users]

update [staging].[dbo].[Relias_Users] set Hierarchy = 'Kisco Senior Living: The Kensington at Walnut Creek' where Hierarchy = 'Kisco Senior Living: The Kensington'

  truncate table Fact_Training
 insert into Fact_Training
  SELECT (select  distinct top 1 GroupedShortName from DataWarehouse.[dbo].[Dim_Community] where (IsActiveCommunity = 'Yes'  or ShortName in ('KSL', 'CAR', 'FTZ', 'NWB'))  and 
  (
  CHARINDEX(
    replace(Community,' at North Hills','')
  
  , hierarchy COLLATE DATABASE_DEFAULT) > 0
  
  
			or replace(hierarchy,'Home Office: Home Office - Kisco Senior Living','Kisco Senior Living, LLC') = Community
		  or replace(hierarchy,'Kisco Senior Living: Living Well at Home','Abbotswood at Irving Park') = Community
		  or replace(hierarchy,'Kisco Senior Living: Newbury of Brookline','The Newbury of Brookline') = Community
		  or replace(hierarchy,'Kisco Senior Living: Fitzgerald of Palisades','The Fitzgerald') = Community
		  or replace(hierarchy,'Kisco Senior Living: Balfour at Littleton','Balfour Littleton Well') = Community
		  or replace(hierarchy,'Kisco Senior Living: Balfour at Louisville','Balfour Louisville') = Community
		  or replace(hierarchy,'Kisco Senior Living: Balfour at Longmont','Balfour Longmont') = Community
		  or replace(hierarchy,'Kisco Senior Living: Balfour at Cherrywood Village','Balfour Cherrywood Village') = Community
		  or replace(hierarchy,'Kisco Senior Living: Balfour at Central Park','Balfour Central Park') = Community
		  or replace(hierarchy,'Kisco Senior Living: Balfour at Riverfront Park','Balfour Riverfront Park') = Community

		  
		  		   
  )
  ) as shortname
  ,coalesce(
  (select 'KLC6' from [staging].[dbo].[Relias_CoursePlan] cp where cp.curriculumID = 75539 and cp.courseid = p.courseid) --!All Associate Annual Training (KLC 6)
  ,(select top 1 'HP3' from [staging].[dbo].[Relias_Courses] rc where rc.CourseID = p.CourseID and rc.CourseCode in ('Kisco-HP3Annual','Kisco-HP3-90Day'))
  )
  as 'Type'
  , (select top 1 Fact_Associate.Department from DataWarehouse.[dbo].Fact_Associate where u.username = Fact_Associate.Dayforce_Login_Id) as 'Dept'
  ,u.*
  ,p.[StudentID],p.[Completed],p.[RequiredByDate],p.[CourseCode],p.[Course]
   
  FROM [staging].[dbo].[Relias_Users] u inner join [staging].[dbo].[Relias_Courses] p on u.userid = p.studentid
  where u.active = 1 and p.deleted = 0 and p.Active = 1
  and exists(select * from Dim_Associate a WITH (NOLOCK) where u.username = a.Dayforce_Login_Id and a.Status = 'Active')


  insert INTO Fact_Training_History 
   SELECT * , getdate() FROM Fact_Training where not exists(select * FROM Fact_Training_History where dt = convert(date,getdate()))



BEGIN TRY;THROW 50000,'',1;END TRY BEGIN CATCH;insert into Staging.dbo.log_DW_Time (LineNumber,MinSinceLast) values (ERROR_LINE(),DATEDIFF(mi,@DtLast,getdate()));END CATCH
set @DtLast = getdate()


--Add this Current Rent and Market rent to Daily Fact+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--select * from [staging].[dbo].NS_Rent_Role_History order by dtimported desc
--select * from [dbo].[Fact_Unit] where ksl_apartmentid = 'B7495E73-882A-E511-99C6-0050568B753A' order by dt desc
--select * from dim_Community 
 --If this section needs to be run on it's own, uncomment the below
					/*
						
						SET @AsOfDt = GETDATE()

						DECLARE @dt_start date
						DECLARE @dt_end date
						DECLARE @dt_startx date

						SET @dt_start = @AsOfDt - 90
						SET @dt_end = @AsOfDt			-- @AsOfDt = GETDATE()
				  
				  DECLARE @AsOfDt datetime
				  SET @AsOfDt = GETDATE()
				  DECLARE @dt_start date
					DECLARE @dt_end date
					DECLARE @dt_startx date
					
				  SET @dt_start = @AsOfDt - 90
				  SET @dt_end = @AsOfDt
				  */
			-- Run below from 90 days ago up through today
					SET @dt_startx = @dt_start				-- = GETDATE() - 90
							WHILE @dt_startx <= @dt_end
					BEGIN

			
				
					UPDATE f SET f.Rent_Amt = x.Rent_Amt, f.Sec_Occ_Amt = x.Sec_Occ_Amt, f.Care_Amt = x.Care_Amt, f.Mkt_Rate = x.Mkt_Rate, f.Prev_Rent_Amt = 
					(select top 1 r.RENT_Amt from Staging.dbo.NS_Rent_Role_History r inner join Dim_Apartment apt on r.ksl_apartmentnumber collate SQL_Latin1_General_CP1_CI_AS = apt.Apt_Number 
	inner join Dim_Community c on c.ksl_communityId = apt.ksl_CommunityId and r.GroupedShortName = c.ShortName where r.RENT_Amt <> 0 and
	  r.Resident_Number <> x.Resident_Number  and apt.ksl_apartmentId = f.ksl_ApartmentId order by r.dtImported desc)
						
					FROM Fact_Unit f INNER JOIN
					(
					select sum(Rent_Amt) Rent_Amt,Sum(Sec_Occ_Amt) Sec_Occ_Amt,sum(Care_Amt) Care_Amt,max(Mkt_Rate) Mkt_Rate ,h.shortname,x.ksl_apartmentId,convert(date,max(dtImported)) dt  
					,max(Resident_Number) as Resident_Number

					from [staging].[dbo].NS_Rent_Role_History h
					--inner join dim_Community c on NS_Rent_Role_History.shortname collate SQL_Latin1_General_CP1_CI_AS = c.ShortName
					--inner join Dim_Apartment a on a.Apt_Number = ksl_apartmentnumber collate SQL_Latin1_General_CP1_CI_AS and a.ksl_CommunityId = c.Groupedksl_communityId collate SQL_Latin1_General_CP1_CI_AS
					inner join (select a.*,c1.ShortName from [staging].[dbo].ksl_apartment a inner join dim_Community c1 on c1.ksl_communityId = a.ksl_communityid) x
					on x.ksl_apartmentnumber = h.ksl_apartmentnumber collate SQL_Latin1_General_CP1_CI_AS 
					 and coalesce(nullif(nullif(x.ksl_legalentity collate SQL_Latin1_General_CP1_CI_AS,''),'.'),x.shortname) = h.ShortName collate SQL_Latin1_General_CP1_CI_AS

					where dtImported = (select max(dtImported) from [staging].[dbo].NS_Rent_Role_History where convert(date,dtImported) between convert(date,DATEADD(dd,-5,@dt_startx)) and convert(date,@dt_startx))
									GROUP BY h.shortname ,x.ksl_apartmentId
					) AS x 

						ON f.ksl_ApartmentId = convert(varchar(100),x.ksl_ApartmentId)
						WHERE f.dt = @dt_startx 

						SET @dt_startx = DATEADD(dd,1,@dt_startx)
	
				END


--Update Fact_Survey***********************************************************************************************************************************

BEGIN TRY;THROW 50000,'',1;END TRY BEGIN CATCH;insert into Staging.dbo.log_DW_Time (LineNumber,MinSinceLast) values (ERROR_LINE(),DATEDIFF(mi,@DtLast,getdate()));END CATCH
set @DtLast = getdate()


--The Cardinal at North Hills select * from Dim_Community
--select distinct community  from [Staging].[dbo].Q_Survey

update [Staging].[dbo].Q_Survey set Community = 'Cardinal at North Hills' where Community = 'The Cardinal at North Hills'
update [Staging].[dbo].Q_Survey set Community = 'Cardinal at North Hills' where Community = 'Cardinal at North Hills EX (Do Not Use)'
update [Staging].[dbo].Q_Survey set Community = 'Kisco Senior Living, LLC' where Community = 'Kisco Senior Living'
update [Staging].[dbo].Q_Survey set Community = 'Woodbridge Terrace' where Community = 'Woodbridge'
update [Staging].[dbo].Q_Survey set Community = 'The Kensington at Walnut Creek' where Community = 'The Kensington'


update [Staging].[dbo].Q_Survey set department = 'Life Enrichment' where department = 'Wellness' 
update [Staging].[dbo].Q_Survey set department = 'Life Enrichment' where department = 'Transportation' 




update [Staging].[dbo].[Q_Questions] set question = [Staging].dbo.udf_StripHTML(question)
update [Staging].[dbo].[Q_Questions] set question = replace(question,'${e://Field/Community}','the community') where question like '%${e://Field/Community}%'
--update [Staging].[dbo].[Q_Questions] set question = replace(question,'&nbsp;','Community') where question like '%&nbsp;%'


update [Staging].[dbo].[Q_Questions] set Grouping = 'Resident Loyalty' where id = 'QID7' and surveyid = 'Resident_Survey'
update [Staging].[dbo].[Q_Questions] set Grouping = 'Associate Loyalty' where id = 'QID7' and surveyid = 'Associate_Survey'

update [Staging].[dbo].[Q_Questions] set Grouping = 'Associate Engagement' where id = 'QID8_5' and surveyid = 'Associate_Survey'
update [Staging].[dbo].[Q_Questions] set Grouping = 'Associate Engagement' where id = 'QID8_3' and surveyid = 'Associate_Survey'
update [Staging].[dbo].[Q_Questions] set Grouping = 'Associate Engagement' where id = 'QID5_4' and surveyid = 'Associate_Survey'
update [Staging].[dbo].[Q_Questions] set Grouping = 'Associate Engagement' where id = 'QID5_5' and surveyid = 'Associate_Survey'
update [Staging].[dbo].[Q_Questions] set Grouping = 'Associate Engagement' where id = 'QID8_4' and surveyid = 'Associate_Survey'
update [Staging].[dbo].[Q_Questions] set Grouping = 'Associate Engagement' where id = 'QID6_17' and surveyid = 'Associate_Survey'
update [Staging].[dbo].[Q_Questions] set Grouping = 'Associate Engagement' where id = 'QID6_15' and surveyid = 'Associate_Survey'
update [Staging].[dbo].[Q_Questions] set Grouping = 'Associate Engagement' where id = 'QID8_2' and surveyid = 'Associate_Survey'
update [Staging].[dbo].[Q_Questions] set Grouping = 'Associate Engagement' where id = 'QID6_5' and surveyid = 'Associate_Survey'
update [Staging].[dbo].[Q_Questions] set Grouping = 'Associate Engagement' where id = 'QID6_16' and surveyid = 'Associate_Survey'
update [Staging].[dbo].[Q_Questions] set Grouping = 'Associate Engagement' where id = 'QID6_4' and surveyid = 'Associate_Survey'

update [Staging].[dbo].[Q_Questions] set Grouping = 'Associate Other' where id = 'QID1_10' and surveyid = 'Associate_Survey'
update [Staging].[dbo].[Q_Questions] set Grouping = 'Associate Other' where id = 'QID1_11' and surveyid = 'Associate_Survey'
update [Staging].[dbo].[Q_Questions] set Grouping = 'Associate Other' where id = 'QID4_1' and surveyid = 'Associate_Survey'
update [Staging].[dbo].[Q_Questions] set Grouping = 'Associate Other' where id = 'QID4_4' and surveyid = 'Associate_Survey'
update [Staging].[dbo].[Q_Questions] set Grouping = 'Associate Other' where id = 'QID4_5' and surveyid = 'Associate_Survey'

update [Staging].[dbo].[Q_Questions] set Grouping = 'How often did you meet with your manager?' where id = 'QID43' and surveyid = 'Asoc_Survey_exit'
update [Staging].[dbo].[Q_Questions] set Grouping = 'Associate Exit' where id = 'QID40' and surveyid = 'Asoc_Survey_exit'
update [Staging].[dbo].[Q_Questions] set Grouping = 'Associate Exit' where id = 'QID51' and surveyid = 'Asoc_Survey_exit'
update [Staging].[dbo].[Q_Questions] set Grouping = 'Associate Exit' where id = 'QID7' and surveyid = 'Asoc_Survey_exit'
update [Staging].[dbo].[Q_Questions] set Grouping = 'Associate Exit Loyalty' where id = 'QID10' and surveyid = 'Asoc_Survey_exit'

update [Staging].[dbo].[Q_Questions] set Grouping = 'Passion for Excellence' where id = 'QID6_4' and surveyid = 'Resident_Survey'
update [Staging].[dbo].[Q_Questions] set Grouping = 'Passion for Excellence' where id = 'QID6_5' and surveyid = 'Resident_Survey'
update [Staging].[dbo].[Q_Questions] set Grouping = 'Passion for Excellence' where id = 'QID6_15' and surveyid = 'Resident_Survey'
update [Staging].[dbo].[Q_Questions] set Grouping = 'Passion for Excellence' where id = 'QID6_16' and surveyid = 'Resident_Survey'
update [Staging].[dbo].[Q_Questions] set Grouping = 'Passion for Excellence' where id = 'QID6_17' and surveyid = 'Resident_Survey'

update [Staging].[dbo].[Q_Questions] set Grouping = 'Resident Other' where id = 'QID1_10' and surveyid = 'Resident_Survey'
update [Staging].[dbo].[Q_Questions] set Grouping = 'Resident Other' where id = 'QID1_11' and surveyid = 'Resident_Survey'
update [Staging].[dbo].[Q_Questions] set Grouping = 'Resident Other' where id = 'QID1_19' and surveyid = 'Resident_Survey'
update [Staging].[dbo].[Q_Questions] set Grouping = 'Resident Other' where id = 'QID1_20' and surveyid = 'Resident_Survey'
update [Staging].[dbo].[Q_Questions] set Grouping = 'Resident Other' where id = 'QID1_21' and surveyid = 'Resident_Survey'
update [Staging].[dbo].[Q_Questions] set Grouping = 'Resident Other' where id = 'QID16_1' and surveyid = 'Resident_Survey'
update [Staging].[dbo].[Q_Questions] set Grouping = 'Resident Other' where id = 'QID16_4' and surveyid = 'Resident_Survey'
update [Staging].[dbo].[Q_Questions] set Grouping = 'Resident Other' where id = 'QID16_5' and surveyid = 'Resident_Survey'
update [Staging].[dbo].[Q_Questions] set Grouping = 'Resident Other' where id = 'QID4_1' and surveyid = 'Resident_Survey'
update [Staging].[dbo].[Q_Questions] set Grouping = 'Resident Other' where id = 'QID4_15' and surveyid = 'Resident_Survey'
update [Staging].[dbo].[Q_Questions] set Grouping = 'Resident Other' where id = 'QID4_4' and surveyid = 'Resident_Survey'
update [Staging].[dbo].[Q_Questions] set Grouping = 'Resident Other' where id = 'QID4_5' and surveyid = 'Resident_Survey'
update [Staging].[dbo].[Q_Questions] set Grouping = 'Resident Other' where id = 'QID8_2' and surveyid = 'Resident_Survey'
update [Staging].[dbo].[Q_Questions] set Grouping = 'Resident Other' where id = 'QID8_2' and surveyid = 'Resident_Survey'
update [Staging].[dbo].[Q_Questions] set Grouping = 'Resident Other' where id = 'QID8_3' and surveyid = 'Resident_Survey'
update [Staging].[dbo].[Q_Questions] set Grouping = 'Resident Other' where id = 'QID8_4' and surveyid = 'Resident_Survey'
update [Staging].[dbo].[Q_Questions] set Grouping = 'Resident Other' where id = 'QID8_5' and surveyid = 'Resident_Survey'
update [Staging].[dbo].[Q_Questions] set Grouping = 'Resident Other' where id = 'QID8_6' and surveyid = 'Resident_Survey'

update [Staging].[dbo].[Q_Questions] set Grouping = 'Resident Other' where id = 'QID8_7' and surveyid = 'Resident_Survey'


update [Staging].[dbo].[Q_Questions] set Grouping = 'Resident COVID' where id = 'QID19_1' and surveyid = 'Resident_Survey'
update [Staging].[dbo].[Q_Questions] set Grouping = 'Resident COVID' where id = 'QID19_2' and surveyid = 'Resident_Survey'
update [Staging].[dbo].[Q_Questions] set Grouping = 'Resident COVID' where id = 'QID19_3' and surveyid = 'Resident_Survey'

update [Staging].[dbo].[Q_Questions] set Grouping = 'Family Overall' where  surveyid = 'Resident_Family_Survey'


update [Staging].[dbo].[Q_Questions] set Grouping = 'Family COVID' where id = 'QID19_1' and surveyid = 'Resident_Family_Survey'
update [Staging].[dbo].[Q_Questions] set Grouping = 'Family COVID' where id = 'QID19_2' and surveyid = 'Resident_Family_Survey'
update [Staging].[dbo].[Q_Questions] set Grouping = 'Family COVID' where id = 'QID19_3' and surveyid = 'Resident_Family_Survey'
update [Staging].[dbo].[Q_Questions] set Grouping = 'Family COVID' where id = 'QID19_6' and surveyid = 'Resident_Family_Survey'
update [Staging].[dbo].[Q_Questions] set Grouping = 'Family NPS' where id = 'QID7' and surveyid = 'Resident_Family_Survey'



update [Staging].[dbo].[Q_Questions] set Grouping = 'Overall HO' where id like 'QID14%' and surveyid = 'Asoc_Survey_CMT_HO'
update [Staging].[dbo].[Q_Questions] set Grouping = 'Department HO' where id like 'QID21%' and surveyid = 'Asoc_Survey_CMT_HO'
update [Staging].[dbo].[Q_Questions] set Grouping = 'Department HO' where id like 'QID22%' and surveyid = 'Asoc_Survey_CMT_HO'
update [Staging].[dbo].[Q_Questions] set Grouping = 'Department HO' where id like 'QID18%' and surveyid = 'Asoc_Survey_CMT_HO'
update [Staging].[dbo].[Q_Questions] set Grouping = 'Department HO' where id like 'QID25%' and surveyid = 'Asoc_Survey_CMT_HO'
update [Staging].[dbo].[Q_Questions] set Grouping = 'Department HO' where id like 'QID28%' and surveyid = 'Asoc_Survey_CMT_HO'
update [Staging].[dbo].[Q_Questions] set Grouping = 'Department HO' where id like 'QID24%' and surveyid = 'Asoc_Survey_CMT_HO'
update [Staging].[dbo].[Q_Questions] set Grouping = 'Department HO' where id like 'QID26%' and surveyid = 'Asoc_Survey_CMT_HO'

--Rename Tell us why you feel this way.	 questions to be more descriptive for reporting
-- Asoc_NewDay1_Survey
UPDATE [Staging].[dbo].[Q_Questions] SET question = 'Tell us why not: (I received everything I needed for my first day of work.)' WHERE id LIKE 'QID18' AND surveyid = 'Asoc_NewDay1_Survey';
UPDATE [Staging].[dbo].[Q_Questions] SET question = 'Tell us why not: (I felt welcomed on my first day.)' WHERE id LIKE 'QID30' AND surveyid = 'Asoc_NewDay1_Survey';

-- Asoc_NewDay14_Survey
UPDATE [Staging].[dbo].[Q_Questions] SET question = 'Tell us why not: (The training I have received is preparing me for this work.)' WHERE id LIKE 'QID18' AND surveyid = 'Asoc_NewDay14_Survey';
UPDATE [Staging].[dbo].[Q_Questions] SET question = 'Tell us why not: (I feel welcomed by my team.)' WHERE id LIKE 'QID26' AND surveyid = 'Asoc_NewDay14_Survey';
UPDATE [Staging].[dbo].[Q_Questions] SET question = 'Tell us why not: (I feel appreciated by my supervisor.)' WHERE id LIKE 'QID28' AND surveyid = 'Asoc_NewDay14_Survey';
UPDATE [Staging].[dbo].[Q_Questions] SET question = 'Tell us why not: (I am happy about my decision to work here.)' WHERE id LIKE 'QID30' AND surveyid = 'Asoc_NewDay14_Survey';

-- Asoc_NewDay30_Survey
UPDATE [Staging].[dbo].[Q_Questions] SET question = 'Tell us why not: (I like working here.)' WHERE id LIKE 'QID18' AND surveyid = 'Asoc_NewDay30_Survey';
UPDATE [Staging].[dbo].[Q_Questions] SET question = 'Tell us why not: (My supervisor is a fair manager.)' WHERE id LIKE 'QID22' AND surveyid = 'Asoc_NewDay30_Survey';
UPDATE [Staging].[dbo].[Q_Questions] SET question = 'Tell us why not: (The training I received prepared me for my job.)' WHERE id LIKE 'QID26' AND surveyid = 'Asoc_NewDay30_Survey';

-- Asoc_NewDay6_Survey
UPDATE [Staging].[dbo].[Q_Questions] SET question = 'Tell us why not: (I am looking forward to coming back next week.)' WHERE id LIKE 'QID30' AND surveyid = 'Asoc_NewDay6_Survey';

-- Asoc_NewDay60_Survey
UPDATE [Staging].[dbo].[Q_Questions] SET question = 'Tell us why not: (I like working here.)' WHERE id LIKE 'QID18' AND surveyid = 'Asoc_NewDay60_Survey';
UPDATE [Staging].[dbo].[Q_Questions] SET question = 'Tell us why not: (I would recommend a friend to work here. [Reminder: We pay you for referrals!])' WHERE id LIKE 'QID26' AND surveyid = 'Asoc_NewDay60_Survey';

-- Asoc_NewDay90_Survey
UPDATE [Staging].[dbo].[Q_Questions] SET question = 'Tell us why not: (I like working for my supervisor.)' WHERE id LIKE 'QID18' AND surveyid = 'Asoc_NewDay90_Survey';
UPDATE [Staging].[dbo].[Q_Questions] SET question = 'Tell us why not: (I can see myself working here at least 2 years.' WHERE id LIKE 'QID22' AND surveyid = 'Asoc_NewDay90_Survey';
UPDATE [Staging].[dbo].[Q_Questions] SET question = 'Tell us why not: (I would recommend a friend to work here.)' WHERE id LIKE 'QID26' AND surveyid = 'Asoc_NewDay90_Survey';







delete from Fact_Survey where exists (select * from [Staging].[dbo].[Q_Survey] where Fact_Survey.responseid = Q_Survey.responseid)


insert into  Fact_Survey
SELECT  
[Survey]
,[responseId]
,convert(date,[startDate]) as startDate
,(select top 1 ShortName from Dim_Community 
where CASE 
    WHEN s.Community LIKE '%Irving Park' AND s.Community NOT LIKE '%at Irving Park' 
        THEN REPLACE(s.Community, ' Irving Park', ' at Irving Park')
    WHEN s.Community LIKE '%Stonehenge' AND s.Community NOT LIKE '%at Stonehenge' 
        THEN REPLACE(s.Community, ' Stonehenge', ' at Stonehenge')
    WHEN s.Community LIKE '%North Hills' AND s.Community NOT LIKE '%at North Hills' 
        THEN REPLACE(s.Community, ' North Hills', ' at North Hills')
    WHEN s.Community LIKE '%Los Altos' AND s.Community NOT LIKE '%at Los Altos' 
        THEN REPLACE(s.Community, ' Los Altos', ' at Los Altos')
    WHEN s.Community LIKE '%Sandy' AND s.Community NOT LIKE '%at Sandy' 
        THEN REPLACE(s.Community, ' Sandy', ' at Sandy')
    WHEN s.Community LIKE '%Leihano' AND s.Community NOT LIKE '%at Leihano' 
        THEN REPLACE(s.Community, ' Leihano', ' at Leihano')
    WHEN s.Community LIKE '%Daybreak' AND s.Community NOT LIKE '%at Daybreak' 
        THEN REPLACE(s.Community, ' Daybreak', ' at Daybreak')
    WHEN s.Community LIKE '%Washingtonian Center' AND s.Community NOT LIKE '%at Washingtonian Center' 
        THEN REPLACE(s.Community, ' Washingtonian Center', ' at Washingtonian Center')
    WHEN s.Community LIKE '%Walnut Creek' AND s.Community NOT LIKE '%at Walnut Creek' 
        THEN REPLACE(s.Community, ' Walnut Creek', ' at Walnut Creek')
    ELSE s.Community 
END = Dim_Community.Community 
and (Groupedksl_communityId is not null or ShortName = 'KSL') 
and ShortName not in ('BP_PRU', 'BP_Old')) as  Community
,[LevelOfLiving]
,[AptNum]
,[Department]
,[Job]
,[source]
,[SurveyWave]
,[MoveInDate]
,[BirthDate]
,[Tenure]
,[HoursWorked]
,[OTHours]
,[Occupancy]
,[ManagerName]
,[Name]
,[Value]
,coalesce(q.question,q1.question) as Question
,try_convert(int, left(value,3)) as ValueNumeric
,q.Grouping
  FROM [Staging].[dbo].[Q_Survey] s
  left join [Staging].[dbo].[Q_Questions] q   on  s.Name = q.id  and s.Survey = q.surveyid
  left join [Staging].[dbo].[Q_Questions] q1   on  s.Name = q1.id + '_TEXT' and s.Survey = q1.surveyid
  where coalesce(q.question,q1.question) is not null
  --and convert(date,[startDate]) <= getdate()-1

   update Fact_Survey set Department = 'Operations' where  Department = 'Operations Services'
   update Fact_Survey set Department = 'Sales' where  Department = 'Sales and Marketing'
   update Fact_Survey set LevelOfLiving = 'CT' where  LevelOfLiving = 'COT'
   update Fact_Survey set LevelOfLiving = 'SNF' where  LevelOfLiving = 'SN'



-- %%% Make meeting with manager question DW friendly 

    update [DataWarehouse].[dbo].[Fact_Survey]
	SET [Question] =CASE WHEN value = 2 THEN 'A Least Once a Week' 
						WHEN value = 3 THEN 'A few times a month' 
						WHEN value = 4 THEN 'Once a Month' 
						WHEN value = 5 THEN 'Less than Once a Month' 
						WHEN value = 6 THEN 'Never' 
				  END
	  where Name = 'QID43'
	  and Survey = 'Asoc_Survey_exit'


-- %%% Make individual rows of the Influence to leave questions %%%

  Declare @data TABLE (
	[Survey] [nvarchar](250) NULL,
	[responseId] [nvarchar](250) NULL,
	[startDate] [datetime] NULL,
	[Community] [nvarchar](250) NULL,
	[LevelOfLiving] [nvarchar](250) NULL,
	[AptNum] [nvarchar](250) NULL,
	[Department] [nvarchar](250) NULL,
	[Job] [nvarchar](250) NULL,
	[source] [nvarchar](250) NULL,
	[SurveyWave] [nvarchar](250) NULL,
	[MoveInDate] [nvarchar](250) NULL,
	[BirthDate] [nvarchar](250) NULL,
	[Tenure] [nvarchar](250) NULL,
	[HoursWorked] [nvarchar](250) NULL,
	[OTHours] [nvarchar](250) NULL,
	[Occupancy] [nvarchar](250) NULL,
	[ManagerName] [nvarchar](250) NULL,
	[Name] [nvarchar](250) NULL,
	[Value]  [nvarchar](max) NULL,
	answers [nvarchar](max) NULL,
	[Question] [nvarchar](500) NULL,
	[ValueNumeric] [int] NULL,
	[Grouping] [nvarchar](250) NULL
) 


--select *
--from 
----update
--[DataWarehouse].[dbo].[Fact_Survey]
----set Community = 'KSL'
--where Survey = 'Asoc_Survey_exit'
--and Community is null 


INSERT   into @data
 SELECT [Survey]
			  ,[responseId]
			  ,[startDate]
			  ,[Community]
			  ,[LevelOfLiving]
			  ,[AptNum]
			  ,[Department]
			  ,[Job]
			  ,[source]
			  ,[SurveyWave]
			  ,[MoveInDate]
			  ,[BirthDate]
			  ,[Tenure]
			  ,[HoursWorked]
			  ,[OTHours]
			  ,[Occupancy]
			  ,[ManagerName]
			  ,[Name]
			   ,[Value]
			  ,replace(replace(replace(replace(replace(replace(replace( [Value],'"',''),'[',''),']',''),Char(10),'' ),Char(13),'' ),Char(9),'' ),Char(32),'' ) answers
			  ,[Question]
			  ,[ValueNumeric]
			  ,[Grouping]
	
		  FROM [DataWarehouse].[dbo].[Fact_Survey]
			where Survey = 'Asoc_Survey_exit'
			and Name = 'QID2'





--SELECT 'original data', * FROM @data
--where responseId = 'R_1nPIcKKM8SKAX6G'




;with tmp ([Survey]
			  ,[responseId]
			  ,[startDate]
			  ,[Community]
			  ,[LevelOfLiving]
			  ,[AptNum]
			  ,[Department]
			  ,[Job]
			  ,[source]
			  ,[SurveyWave]
			  ,[MoveInDate]
			  ,[BirthDate]
			  ,[Tenure]
			  ,[HoursWorked]
			  ,[OTHours]
			  ,[Occupancy]
			  ,[ManagerName]
			  ,[Name]
			  ,[Question]
			  ,[ValueNumeric]
			  ,[Grouping]
			  ,dataitem
			  ,answers
			  )  as (
SELECT [Survey]
			  ,[responseId]
			  ,[startDate]
			  ,[Community]
			  ,[LevelOfLiving]
			  ,[AptNum]
			  ,[Department]
			  ,[Job]
			  ,[source]
			  ,[SurveyWave]
			  ,[MoveInDate]
			  ,[BirthDate]
			  ,[Tenure]
			  ,[HoursWorked]
			  ,[OTHours]
			  ,[Occupancy]
			  ,[ManagerName]
			  ,[Name]
			  ,[Question]
			  ,[ValueNumeric]
			  ,[Grouping]
			 
        ,CAST(LEFT(answers, CHARINDEX(',', answers + ',') - 1) AS VARCHAR(250)),
        CAST(STUFF(answers, 1, CHARINDEX(',', answers + ','), '') AS VARCHAR(250))
		  FROM @data
UNION ALL

SELECT [Survey]
			  ,[responseId]
			  ,[startDate]
			  ,[Community]
			  ,[LevelOfLiving]
			  ,[AptNum]
			  ,[Department]
			  ,[Job]
			  ,[source]
			  ,[SurveyWave]
			  ,[MoveInDate]
			  ,[BirthDate]
			  ,[Tenure]
			  ,[HoursWorked]
			  ,[OTHours]
			  ,[Occupancy]
			  ,[ManagerName]
			  ,[Name]
			  ,[Question]
			  ,[ValueNumeric]
			  ,[Grouping]

       , CAST(LEFT(answers, CHARINDEX(',', answers + ',') - 1) AS VARCHAR(250)),
        CAST(STUFF(answers, 1, CHARINDEX(',', answers + ','), '') AS VARCHAR(250))
		  FROM tmp
		  where answers > ''
) 

insert into  [DataWarehouse].[dbo].[Fact_Survey]
select [Survey]
			  ,[responseId]
			  ,[startDate]
			  ,[Community]
			  ,[LevelOfLiving]
			  ,[AptNum]
			  ,[Department]
			  ,[Job]
			  ,[source]
			  ,[SurveyWave]
			  ,[MoveInDate]
			  ,[BirthDate]
			  ,[Tenure]
			  ,[HoursWorked]
			  ,[OTHours]
			  ,[Occupancy]
			  ,[ManagerName]
			  ,[Name]+'1I' as Name
			  ,dataitem as Value
			  ,CASE   WHEN dataitem = 1 THEN 'Higher pay in new role'
					 WHEN dataitem = 2 THEN 'Better benefits in new role (less cost or better coverage)'
					 WHEN dataitem = 3 THEN 'New role is a promotion'
					 WHEN dataitem = 4 THEN 'I moved out of the area'
					 WHEN dataitem = 5 THEN 'Career change'
					 WHEN dataitem = 6 THEN 'Going back to school - I plan to return to work here'
					 WHEN dataitem = 7 THEN 'Going back to school - I do not plan to return to work here'
					 WHEN dataitem = 8 THEN 'Better Commute'
					 WHEN dataitem = 9 THEN 'Conflict with manager'
					 WHEN dataitem = 10 THEN 'Conflict with a co-worker or the team'
					 WHEN dataitem = 11 THEN 'Other (specify)'

																	END [Question]
			  ,4 as [ValueNumeric]
			  ,'Influence to Leave' [Grouping] 
			  

from tmp
where dataitem > 1
and CONCAT(responseid,[Name],'1I',dataitem) not in ( select CONCAT(responseid,name,value) from [DataWarehouse].[dbo].[Fact_Survey])
order by [responseId]
OPTION (maxrecursion 0)


update Fact_Survey set [Survey] = 'Asoc_NewDay1_Survey_1' where  [Survey] = 'Asoc_NewDay1_Survey'
update Fact_Survey set [Survey] = 'Asoc_NewDay14_Survey_3' where  [Survey] = 'Asoc_NewDay14_Survey'
update Fact_Survey set [Survey] = 'Asoc_NewDay30_Survey_4' where  [Survey] = 'Asoc_NewDay30_Survey'
update Fact_Survey set [Survey] = 'Asoc_NewDay7_Survey_2' where  [Survey] = 'Asoc_NewDay6_Survey'
update Fact_Survey set [Survey] = 'Asoc_NewDay60_Survey_5' where  [Survey] = 'Asoc_NewDay60_Survey'
update Fact_Survey set [Survey] = 'Asoc_NewDay90_Survey_6' where  [Survey] = 'Asoc_NewDay90_Survey'



delete from Fact_Survey where SurveyWave = '2024Q3'
delete from Fact_Survey where SurveyWave = '2024Q4' and Community = 'CAR'


--&&&&&&&&&&&&&&&&&&&&Coronavirus Temp

BEGIN TRY;THROW 50000,'',1;END TRY BEGIN CATCH;insert into Staging.dbo.log_DW_Time (LineNumber,MinSinceLast) values (ERROR_LINE(),DATEDIFF(mi,@DtLast,getdate()));END CATCH
set @DtLast = getdate()

/*

delete from staging.dbo.Covid_Account where convert(date,dt) = convert(date,@AsOfDt)
insert into staging.dbo.Covid_Account (ksl_communityidname,ksl_objectionstoovercome_displayname,statuscode_displayname,dt)  
Select ksl_communityidname,ksl_objectionstoovercome_displayname,statuscode_displayname,@AsOfDt from kslcloud_mscrm.dbo.Account WITH (NOLOCK)
*/
--select * from staging.dbo.Covid_Account



--select * from Fact_Unit where FinOccupancy = 0 and Prev_Rent_Amt is not null
--select * from dim_community where ksl_communityid = 'CD0187B1-532A-45C2-B26D-F6D63011C83A'

--select * from Fact_Unit where ksl_apartmentid = '83e0b602-da7f-e311-986a-0050568b37ac' order by dt
--SELECT distinct location FROM dim_associate order by location
--SELECT * FROM fact_punch  order by department_description
--SELECT * FROM staging.dbo.NS_DEPARTMENTS order by name
--SELECT distinct deptName 
  --FROM [DataWarehouse].[dbo].[Fact_Financial] order by deptName
  --SELECT * FROM dim_associate

  --SELECT distinct community FROM [dbo].[Dim_Community] order by community
--TODO:
--INSERT INTO Dim_FinancialGroup SELECT distinct 'Net Ordinary Income',17,AccountNumber,1  FROM Fact_Financial WHERE Accounttype in ('Income','Cost of Goods Sold','Other Expense')
--SELECT * FROM staging.dbo.NS_accounts
--SELECT * FROM Fact_Financial WHERE AccountType like '%other%'
--SELECT * FROM Dim_FinancialGroup



--select distinct Department  from [dbo].[Budgets] 




--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% INSERT INTO Fact_Care_Assessment %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

--ADDED 12/10/2020 BY JSHARP

BEGIN TRY;THROW 50000,'',1;END TRY BEGIN CATCH;insert into Staging.dbo.log_DW_Time (LineNumber,MinSinceLast) values (ERROR_LINE(),DATEDIFF(mi,@DtLast,getdate()));END CATCH
set @DtLast = getdate()

--declare @AsOfDt as date
--set @AsOfDt = getdate()
TRUNCATE TABLE  [dbo].[Fact_Care_Assessment] 

INSERT INTO [dbo].[Fact_Care_Assessment]
SELECT 	*,  
		(SELECT top 1 LevelNumber FROM [KiscoCustom].dbo.CAR_CareLevel cl WHERE cl.CareLevelCategory = x.CareLevelCategory and x.Points >= cl.LevelStart   and x.Points <= cl.LevelEnd) 
				as LevelofCare	
				


							
		FROM (
							SELECT
					a.CareStartDate,
					iif (a.LastDayofCare is null, '01/01/2030',a.LastDayofCare )  as LastDayofCare,
					--left(tas.CareLevelCategory,2) CareLevelCategory,
					tas.CareLevelCategory,
					DATEADD(DD,t.DaysValid,a.CareStartDate) as ExpiresOn,
					u.USR_ID,
					(select coalesce(sum(ta.Points),0) from [KiscoCustom].dbo.[CAR_Answer] an inner join [KiscoCustom].dbo.[CAR_TemplateAnswer] ta on an.TemplateAnswerID = ta.TemplateAnswerID 
					and ta.Version = a.Version where an.AssessmentID = a.AssessmentID) as Points
					,CASE WHEN ((@AsOfDt between CareStartDate and LastDayofCare) or LastDayofCare is null)  THEN 
						
						CASE WHEN OOC = 'OOC' then 'No' else 'Yes' end 
						
						ELSE 'No' END isActive
					--,CASE WHEN ((@AsOfDt between CareStartDate and LastDayofCare) or LastDayofCare is null) and exists(select * from ROH_CurrentRes r where r.ksl_contactid = ROH.ksl_contactid) THEN 'Yes' ELSE 'No' END isActive

					,a.ResidentID
					,ROH.[ksl_apartmentid]
					,ac.ksl_communityid
								,coalesce(cl1.ksl_amount + coalesce(((select sum(ta.Points) 
								from [kiscocustom].[dbo].[CAR_Answer] an inner join [kiscocustom].[dbo].[CAR_TemplateAnswer] ta on an.TemplateAnswerID = ta.TemplateAnswerID 
								and ta.Version = a.Version where an.AssessmentID = a.AssessmentID
								)-(cl.LevelStart-1))*cl1.ksl_customcareamountperpoint,0),0) as CareAmount

				FROM
					[KiscoCustom].dbo.CAR_Assessment a
					inner join [KiscoCustom].dbo.CAR_TemplateAssessment tas on a.TemplateAssessmentID = tas.TemplateAssessmentID and tas.Version = a.Version
					inner join [KSLCLOUD_MSCRM].dbo.contact c on c.contactid = a.ResidentID
					INNER JOIN [KSLCLOUD_MSCRM].dbo.Account ac on c.parentcustomerid = ac.accountid
					LEFT JOIN [KiscoCustom].dbo.CAR_AssessmentType t on a.AssessmentTypeID = t.AssessmentTypeID
					LEFT JOIN [KiscoCustom].dbo.Associate u  on u.USR_ID = a.CompletedBy
					outer apply (select top 1 * from [KSLCLOUD_MSCRM].dbo.ksl_residentoccupancyhistory h where a.ResidentID = [ksl_contactid] order by h.ksl_begindate desc) ROH 


					left join [kiscocustom].[dbo].CAR_CareLevel cl on cl.CareLevelCategory = tas.CareLevelCategory and (select sum(ta.Points) 
					from [kiscocustom].[dbo].[CAR_Answer] an inner join [kiscocustom].[dbo].[CAR_TemplateAnswer] ta on an.TemplateAnswerID = ta.TemplateAnswerID 
					and ta.Version = a.Version where an.AssessmentID = a.AssessmentID) 
					between cl.LevelStart and cl.LevelEnd

					outer apply (select top 1 * from [KSLCLOUD_MSCRM].dbo.ksl_carelevel cal where cal.statecode =0 
					and convert(date,cal.ksl_begindate) <= convert(date,getdate()) and coalesce(convert(date,cal.ksl_enddate),'1/1/2050') >= convert(date,getdate())
					and tas.CareLevelCategory + convert(varchar(50),cl.LevelNumber) =  ksl_carelevelcode and cal.ksl_communityid = ROH.[ksl_communityid] order by cal.ksl_begindate desc) cl1 
                     
					 outer apply (select top 1 'OOC' as OOC from [KiscoCustom]..[CAR_OutOfCommunity] o
where  (OOCLastFullDayOut is NULL or convert(date,OOCLastFullDayOut) >= convert(date,getdate()))
and OOCFirstFullDayOut <= convert(date,getdate()) and isActive = 1 and o.ResidentID = a.ResidentID) as OOC
     
				WHERE a.Status = 'Completed'
						--and a.ResidentID ='59887781-60F0-E511-81D5-0050568B37AC'
						and tas.TemplateAssessmentCategory = 'Assessment'
) x


update a set LastDayofCare = roh.ksl_enddate
--select roh.ksl_endtxntype_displayname,roh.ksl_enddate,LastDayofCare,* 
from Fact_Care_Assessment a
outer apply (select top 1 * from [KSLCLOUD_MSCRM].dbo.ksl_residentoccupancyhistory h where a.ResidentID = convert(varchar(100),ksl_contactid) order by h.ksl_begindate desc) ROH
where roh.ksl_endtxntype_displayname = 'Actual move out' and a.LastDayofCare = '01/01/2030' 


delete  [dbo].[Fact_Care_Assessment_History]  where DateImported = convert(date,@AsOfDt)

INSERT INTO [dbo].[Fact_Care_Assessment_History]
SELECT 	*,  
		(SELECT top 1 LevelNumber FROM [KiscoCustom].dbo.CAR_CareLevel cl WHERE cl.CareLevelCategory = x.CareLevelCategory and x.Points >= cl.LevelStart   and x.Points <= cl.LevelEnd) 
				as LevelofCare	
				,convert(date,@AsOfDt) as dt
		FROM (
				SELECT
					a.CareStartDate,
					iif (a.LastDayofCare is null, '01/01/2030',a.LastDayofCare )  as LastDayofCare,
					--left(tas.CareLevelCategory,2) CareLevelCategory,
					tas.CareLevelCategory,
					DATEADD(DD,t.DaysValid,a.CareStartDate) as ExpiresOn,
					u.USR_ID,
					(select coalesce(sum(ta.Points),0) from [KiscoCustom].dbo.[CAR_Answer] an inner join [KiscoCustom].dbo.[CAR_TemplateAnswer] ta on an.TemplateAnswerID = ta.TemplateAnswerID 
					and ta.Version = a.Version where an.AssessmentID = a.AssessmentID) as Points
					,CASE WHEN (@AsOfDt between CareStartDate and LastDayofCare) or LastDayofCare is null THEN 'Yes' ELSE 'No' END isActive
					,a.ResidentID
					,ROH.[ksl_apartmentid]
					,ac.ksl_communityid
					
				FROM
					[KiscoCustom].dbo.CAR_Assessment a
					inner join [KiscoCustom].dbo.CAR_TemplateAssessment tas on a.TemplateAssessmentID = tas.TemplateAssessmentID and tas.Version = a.Version
					inner join [KSLCLOUD_MSCRM].dbo.contact c on c.contactid = a.ResidentID
					INNER JOIN [KSLCLOUD_MSCRM].dbo.Account ac on c.parentcustomerid = ac.accountid
					LEFT JOIN [KiscoCustom].dbo.CAR_AssessmentType t on a.AssessmentTypeID = t.AssessmentTypeID
					LEFT JOIN [KiscoCustom].dbo.Associate u on u.USR_ID = a.CompletedBy
					outer apply (select top 1 * from [KSLCLOUD_MSCRM].[dbo].[ksl_residentoccupancyhistory] where a.ResidentID = [ksl_contactid]) ROH  

                     
     

				WHERE a.Status = 'Completed'
						--and a.ResidentID ='59887781-60F0-E511-81D5-0050568B37AC'
						and tas.TemplateAssessmentCategory = 'Assessment'
						
			) x










--Predict History%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

BEGIN TRY;THROW 50000,'',1;END TRY BEGIN CATCH;insert into Staging.dbo.log_DW_Time (LineNumber,MinSinceLast) values (ERROR_LINE(),DATEDIFF(mi,@DtLast,getdate()));END CATCH
set @DtLast = getdate()


insert into Staging.dbo.PREDICT_History
select date as ds,
(select nullif(count(*),0) 
from [KSLCLOUD_MSCRM].dbo.ksl_apartmentfinancialhistory afh inner join Dim_Apartment a on convert(varchar(100),afh.ksl_ApartmentId) = a.ksl_apartmentId 
where ksl_begintransactiontype_displayname = 'Scheduled Move in' and statuscode_displayname = 'active'
and year(Dim_Date.Date) = year(afh.ksl_begindate) and month(Dim_Date.Date) = month(afh.ksl_begindate)
and  convert(date,afh.createdon) <= convert(date,Dim_Date.Date) 
and afh.ksl_communityid in (select ksl_communityid from Dim_community where IsActiveCommunity = 'Yes' and IsStabilized <> 'Lease-Up')
and (afh.ksl_enddate is null or convert(date,afh.ksl_enddate) > convert(date,Dim_Date.Date))--Filter if moved in
and convert(date,Dim_Date.Date) <= convert(date,getdate()) --and ksl_leveloflivingidname <> 'Skilled Nursing'
and ((a.ksl_communityid = '39C35920-B2DE-E211-9163-0050568B37AC' AND a.level_of_living_short = 'IL')
or (a.ksl_communityidname = 'La Posada' AND a.level_of_living_short = 'IL')
or (a.ksl_communityid <> '39C35920-B2DE-E211-9163-0050568B37AC' and a.ksl_communityidname <> 'La Posada'))
) as Scheduled
,
(select nullif(count(*),0)  from
[KSLCLOUD_MSCRM].dbo.ksl_apartmentfinancialhistory afh inner join Dim_Apartment a on convert(varchar(100),afh.ksl_ApartmentId) = a.ksl_apartmentId 
where ksl_begintransactiontype_displayname = 'Actual Move in'
and year(Dim_Date.Date) = year(ksl_begindate) and month(Dim_Date.Date) = month(ksl_begindate)
and  convert(date,ksl_begindate) <= convert(date,Dim_Date.Date) and convert(date,Dim_Date.Date) <= convert(date,getdate())
and afh.ksl_communityid in (select ksl_communityid from Dim_community where IsActiveCommunity = 'Yes' and IsStabilized <> 'Lease-Up')
and statecode_displayname = 'Active' --and ksl_leveloflivingidname <> 'Skilled Nursing'
and ((a.ksl_communityid = '39C35920-B2DE-E211-9163-0050568B37AC' AND a.level_of_living_short = 'IL')
or (a.ksl_communityidname = 'La Posada' AND a.level_of_living_short = 'IL')
or (a.ksl_communityid <> '39C35920-B2DE-E211-9163-0050568B37AC' and a.ksl_communityidname <> 'La Posada'))
) as ActualMoveIn


,(select yhat from Staging.dbo.Predict_MoveIns) as Forecast


from Dim_Date where  Dim_Date.Date between convert(date,getdate()-6) and convert(date,getdate()-1) and not exists(select * from Staging.dbo.PREDICT_History where dt = Dim_Date.Date)








--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% INSERT INTO Fact_CompetitorRates %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

BEGIN TRY;THROW 50000,'',1;END TRY BEGIN CATCH;insert into Staging.dbo.log_DW_Time (LineNumber,MinSinceLast) values (ERROR_LINE(),DATEDIFF(mi,@DtLast,getdate()));END CATCH
set @DtLast = getdate()

truncate table  [Staging].[dbo].[Competitor_Rates];


with apt as ( 	
	select 
		(select top 1 [Square_Ft] FROM [DataWarehouse].[dbo].[Fact_Unit] fu where a.[ksl_apartmentId] = fu.[ksl_apartmentId] and dt>= dateadd(d,-2,getdate())) [Square_Ft]
		,a.* 
	from [DataWarehouse].[dbo].[Dim_Apartment] a

	) , comp as (
	
SELECT 

	[ksl_floorname]      
      ,[statecode]
      ,[statecode_displayname]      
      ,[ksl_competitorrateslookupid]
	  ,[ksl_noofunits]    
      ,CASE WHEN [ksl_leveloflivingname] like 'Assisted Living' THEN 'AL'
			WHEN [ksl_leveloflivingname] like 'Independent Living' THEN 'IL'
			WHEN [ksl_leveloflivingname] like 'Memory Care' THEN 'MC'
			WHEN [ksl_leveloflivingname] like 'Skilled Nursing' THEN 'SNF'
			WHEN [ksl_leveloflivingname] like 'Cottages' THEN 'CT'
			ELSE [ksl_leveloflivingname]
			END as [ksl_leveloflivingname]
      ,[ksl_rentdiscounts]
      ,[ksl_competitorrateslookupidname]
      ,[ksl_name]      
      ,[ksl_apartmenttypename]
	  ,[ksl_comparablefloorplanname]    
      ,[ksl_comparablefloorplan]
      ,[ksl_baserent]
      --,[ksl_competitorrateslookupidyominame]
      ,[ksl_baserent_base]     
      ,[ksl_competitorratesid]      
      ,[ksl_percentoccupied]
      ,[ksl_rentdiscounts_base]      
      ,[ksl_apartmenttype]	
      ,[ksl_levelofliving]    
      ,[statuscode]
      ,[statuscode_displayname]    
      ,[ksl_sqft]    
	  ,modifiedon

	    FROM [KSLCLOUD_MSCRM].[dbo].[ksl_competitorrates] cr WITH (NOLOCK) 
		where statuscode = 1
		) 
		
	 Insert into [Staging].[dbo].[Competitor_Rates]
	  SELECT 
	  [ksl_communityid]
	  ,name
      ,[ksl_communityidname]
	  ,[ksl_competitortype]
      ,[ksl_competitortype_displayname]
	  ,cr.modifiedon  as CompletedDate
	  ,ksl_communitytype
	  ,[competitorid]
	  ,[ksl_topcompetitor]
	  ,[ksl_floorname]      
      ,[statuscode]            
      
	  ,[ksl_noofunits]    
      ,[ksl_leveloflivingname]
      ,[ksl_rentdiscounts]
      ,[ksl_competitorrateslookupidname]
      ,[ksl_competitorrateslookupid]
      ,[ksl_name]      
      ,[ksl_apartmenttypename]
	  ,[ksl_comparablefloorplanname]    
      ,[ksl_comparablefloorplan]
      ,[ksl_baserent]

      
      ,[ksl_competitorratesid]      
      ,[ksl_percentoccupied]
        
      ,[ksl_apartmenttype]	
      ,[ksl_levelofliving]    
      ,[ksl_sqft]    

	  --Find the most closely related Kisco apartment that has the same LoL and Kisco floor plan, sorted by most similar square footage.
	  ,(select top 1 [ksl_apartmentId] from (
										SELECT TOP 2 * FROM  APT a WHERE (a.[ksl_UnitFloorPlanId] = cr.[ksl_comparablefloorplan] OR a.[Unit_Type] = cr.ksl_name COLLATE Latin1_General_CI_AS ) 
																	AND ([Square_Ft] > [ksl_sqft] OR [Square_Ft] IS NULL ) 
																	AND [ksl_leveloflivingname] = [Level_of_Living_Short]
																ORDER BY [Square_Ft] ASC 
										UNION ALL 

										SELECT TOP 2 * FROM  APT a WHERE (a.[ksl_UnitFloorPlanId] = cr.[ksl_comparablefloorplan] OR a.[Unit_Type] = cr.ksl_name COLLATE Latin1_General_CI_AS ) 
																	AND ([Square_Ft] < [ksl_sqft] OR [Square_Ft] IS NULL ) 
																	AND [ksl_leveloflivingname] = [Level_of_Living_Short]

																ORDER BY [Square_Ft] DESC 
																					
										) X ORDER BY ABS([Square_Ft]-[ksl_sqft])
											
				) AS [ksl_apartmentId]

  
  FROM comp cr
  inner join [KSLCLOUD_MSCRM].[dbo].[competitor] c on c.competitorid = cr.[ksl_competitorrateslookupid]
  



    -- truncate table [DataWarehouse].[dbo].[Fact_CompetitorRates] 
 Delete  [DataWarehouse].[dbo].[Fact_CompetitorRates] 
 Where CompletedDate > getdate() -30
  --truncate table  [Staging].[dbo].[Competitor_Rates_temp]

  ;with mostrecent as (

		 select
					ksl_competitorratesid 
					,max(CompletedDate) maxdate
			FROM [Staging].[dbo].[Competitor_Rates]
			group by ksl_competitorratesid
	)

  --Insert into [Staging].[dbo].[Competitor_Rates_temp]
  Insert into  [DataWarehouse].[dbo].[Fact_CompetitorRates]

	  SELECT cr.* 
		, CASE WHEN cr.ksl_competitorratesid = mr.ksl_competitorratesid and cr.CompletedDate = mr.maxdate THEN 1 ELSE 0 end as Flag

	from  [Staging].[dbo].[Competitor_Rates] cr
	 OUTER APPLY (select top 1 *  from  mostrecent m where  cr.ksl_competitorratesid = m.ksl_competitorratesid ) mr
	 Where CompletedDate > getdate() -30
	 order by cr.ksl_competitorratesid, CompletedDate
 


BEGIN TRY;THROW 50000,'',1;END TRY BEGIN CATCH;insert into Staging.dbo.log_DW_Time (LineNumber,MinSinceLast) values (ERROR_LINE(),DATEDIFF(mi,@DtLast,getdate()));END CATCH
set @DtLast = getdate()



--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% INSERT INTO Fact_Jobs = iCIMS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%





--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% INSERT INTO Fact_Jobs_History = iCIMS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



delete from Fact_Jobs_History where convert(date,dt) = convert(date,getdate())
insert into Fact_Jobs_History ([Job_Folder], [Job_Posting_Title], [Internal_Job_Title], [System_ID], [Job_Code], [Category], [Recruiter_System_ID], [Recruiter_Full_Name_First_Last], [Job_Ad_Text_Only]
, [Type], [Hire_Type], [Location_Name_Linked], [Department], [Hiring_Manager_System_ID], [Hiring_Manager_Full_Name_First_Last], [Days_To_Fill], [Time_to_Fill], [of_Openings], [of_Openings_Remaining]
, [Currently_in_Status_Interviewing_Community_Interview], [Currently_in_Status_Offer_Offer_Accepted], [of_Days_Since_First_Approved], [Date_First_Placed_in_Approved], [Date_First_Placed_in_Not_Approved]
, [Date_Last_Placed_in_Approved], [Date_Last_Placed_in_Not_Approved], [Created_Date], [Updated_Date]) select * from Fact_Jobs



--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% INSERT INTO Fact_Jobs_Workflow = iCIMS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%







 --%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% INSERT INTO Dim_WebDevice %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
BEGIN TRY;THROW 50000,'',1;END TRY BEGIN CATCH;insert into Staging.dbo.log_DW_Time (LineNumber,MinSinceLast) values (ERROR_LINE(),DATEDIFF(mi,@DtLast,getdate()));END CATCH
set @DtLast = getdate()

insert into datawarehouse..Dim_WebDevice

SELECT distinct UPPER( Device ) Device

FROM  (
  select distinct deviceCategory  Device
from   [Staging].[dbo].[GA4_metrics]
union all 

  select distinct Device 
from   [Staging].[dbo].[GAds_ClickData]
union all 
  select distinct Device 
from   [Staging].[dbo].[GAds_ConversionData]

) d
where Device not in ( select Device from datawarehouse..Dim_WebDevice)


--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% INSERT INTO Dim_Campaign %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
BEGIN TRY;THROW 50000,'',1;END TRY BEGIN CATCH;insert into Staging.dbo.log_DW_Time (LineNumber,MinSinceLast) values (ERROR_LINE(),DATEDIFF(mi,@DtLast,getdate()));END CATCH
set @DtLast = getdate()

delete datawarehouse..Dim_WebCampaign
where campaign_id in (

							SELECT distinct campaign_id
							FROM  (
							SELECT distinct   [AdvertisingChannelType]
								  ,[CampaignName]
								  ,[CampaignStatus]
								  ,[BiddingStrategyType]
								  , CASE 
										WHEN CHARINDEX('/campaigns/', [CampaignIdName]) > 0 
										THEN SUBSTRING(
											[CampaignIdName],
											CHARINDEX('/campaigns/', [CampaignIdName]) + LEN('/campaigns/'),
											LEN([CampaignIdName]) - CHARINDEX('/campaigns/', [CampaignIdName]) - LEN('/campaigns/') + 1
										)
										ELSE NULL
									END AS campaign_id
							FROM [Staging].[dbo].[GAds_ClickData]

							union all 

							SELECT distinct [AdvertisingChannelType]
								  ,[CampaignName]
								  ,[CampaignStatus]
								  ,[BiddingStrategyType]
	  								  , CASE 
										WHEN CHARINDEX('/campaigns/', [CampaignIdName]) > 0 
										THEN SUBSTRING(
											[CampaignIdName],
											CHARINDEX('/campaigns/', [CampaignIdName]) + LEN('/campaigns/'),
											LEN([CampaignIdName]) - CHARINDEX('/campaigns/', [CampaignIdName]) - LEN('/campaigns/') + 1
										)
										ELSE NULL
									END AS campaign_id
							FROM [Staging].[dbo].[GAds_ConversionData]
							) o 
				)


--Union all campaign data from both staging conversions and clicks tables
--and insert
INSERT INTO datawarehouse..Dim_WebCampaign
SELECT distinct  [AdvertisingChannelType] 
		, [CampaignName]
      ,[CampaignStatus]
      ,[BiddingStrategyType]
	  , campaign_id

FROM  (
SELECT distinct   [AdvertisingChannelType]
      ,[CampaignName]
      ,[CampaignStatus]
      ,[BiddingStrategyType]
	  , CASE 
            WHEN CHARINDEX('/campaigns/', [CampaignIdName]) > 0 
            THEN SUBSTRING(
                [CampaignIdName],
                CHARINDEX('/campaigns/', [CampaignIdName]) + LEN('/campaigns/'),
                LEN([CampaignIdName]) - CHARINDEX('/campaigns/', [CampaignIdName]) - LEN('/campaigns/') + 1
            )
            ELSE NULL
        END AS campaign_id
FROM [Staging].[dbo].[GAds_ClickData]

union all 

SELECT distinct [AdvertisingChannelType]
      ,[CampaignName]
      ,[CampaignStatus]
      ,[BiddingStrategyType]
	  	  , CASE 
            WHEN CHARINDEX('/campaigns/', [CampaignIdName]) > 0 
            THEN SUBSTRING(
                [CampaignIdName],
                CHARINDEX('/campaigns/', [CampaignIdName]) + LEN('/campaigns/'),
                LEN([CampaignIdName]) - CHARINDEX('/campaigns/', [CampaignIdName]) - LEN('/campaigns/') + 1
            )
            ELSE NULL
        END AS campaign_id
FROM [Staging].[dbo].[GAds_ConversionData]
) o 




--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% INSERT INTO Fact_WebConversions %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
BEGIN TRY;THROW 50000,'',1;END TRY BEGIN CATCH;insert into Staging.dbo.log_DW_Time (LineNumber,MinSinceLast) values (ERROR_LINE(),DATEDIFF(mi,@DtLast,getdate()));END CATCH
set @DtLast = getdate()

delete datawarehouse..Fact_WebConversions
where [Date] in (SELECT [Date]  FROM [Staging].[dbo].[GAds_ConversionData] )
--and campaign_id in (SELECT CASE 
--									WHEN CHARINDEX('/campaigns/', [CampaignIdName]) > 0 
--									THEN SUBSTRING(
--										[CampaignIdName],
--										CHARINDEX('/campaigns/', [CampaignIdName]) + LEN('/campaigns/'),
--										LEN([CampaignIdName]) - CHARINDEX('/campaigns/', [CampaignIdName]) - LEN('/campaigns/') + 1
--									)
--									ELSE NULL
--						END AS campaign_id  
--					FROM [Staging].[dbo].[GAds_ConversionData] )


insert into datawarehouse..Fact_WebConversions
SELECT 
      [Date]
	  ,CASE 
            WHEN CHARINDEX('/campaigns/', [CampaignIdName]) > 0 
            THEN SUBSTRING(
                [CampaignIdName],
                CHARINDEX('/campaigns/', [CampaignIdName]) + LEN('/campaigns/'),
                LEN([CampaignIdName]) - CHARINDEX('/campaigns/', [CampaignIdName]) - LEN('/campaigns/') + 1
            )
            ELSE NULL
        END AS campaign_id
	  ,[Community]
      , NULLIF([LevelofLiving], '') [LevelofLiving]
      ,[Device]

	  ,[ConversionActionName]
      
      ,[AllConversions]
      ,[Conversions]
      ,[ConversionsByConversionDate]
      ,[ConversionsValue]
      --,[CampaignIdName]
 --into datawarehouse..Fact_WebConversions
  FROM [Staging].[dbo].[GAds_ConversionData]





--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% INSERT INTO Fact_WebTraffic %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
BEGIN TRY;THROW 50000,'',1;END TRY BEGIN CATCH;insert into Staging.dbo.log_DW_Time (LineNumber,MinSinceLast) values (ERROR_LINE(),DATEDIFF(mi,@DtLast,getdate()));END CATCH
set @DtLast = getdate()


IF OBJECT_ID('tempdb..#gtemp') IS NOT NULL
    DROP TABLE #gtemp;

IF OBJECT_ID('tempdb..#GAds') IS NOT NULL
DROP TABLE #GAds;

IF OBJECT_ID('tempdb..#GA4') IS NOT NULL
DROP TABLE #GA4;


-- Prep Ads data  -  Pull out campaign id

SELECT 
      [Date]
      ,[Device]
      ,[Impressions]
      ,[Clicks]
      ,[CostMicros]
      ,[AbsoluteTopImpressionPercentage]
      ,[CrossDeviceConversions]
      ,[TopImpressionPercentage]
      ,CASE 
            WHEN CHARINDEX('/campaigns/', [CampaignIdName]) > 0 
            THEN SUBSTRING(
                [CampaignIdName],
                CHARINDEX('/campaigns/', [CampaignIdName]) + LEN('/campaigns/'),
                LEN([CampaignIdName]) - CHARINDEX('/campaigns/', [CampaignIdName]) - LEN('/campaigns/') + 1
            )
            ELSE NULL
        END AS campaign_id
      ,[Community]
      ,[LevelofLiving]
into #GAds
  FROM [Staging].[dbo].[GAds_ClickData]


  -- Prep GA4 data - group and sum data to prevent duplication when joining with Ads data later on 
  SELECT  [date]    
	  ,coalesce ( [ksl_shortname], community) [ksl_shortname] 
      ,[deviceCategory]
      ,[sessionCampaignId]
      ,[sessionDefaultChannelGrouping]
      
	  	  ,1 - (  sum([engagedSessions])*1.0 /sum( [sessions]) *1.0 )  [bounceRate]
	   
      ,sum([engagedSessions]) [engagedSessions]
	  , (  sum([engagedSessions])*1.0 /sum( [sessions]) *1.0 ) [engagementRate]

      ,sum([eventCount]) [eventCount]
      ,sum([eventsPerSession]) [eventsPerSession]
      ,sum([newUsers]) [newUsers]
      ,sum([sessions]) [sessions]
      ,sum([totalUsers])  [totalUsers]
into #GA4
  FROM 
    [Staging].[dbo].[GA4_metrics] g
LEFT JOIN 
    [KSLCLOUD_MSCRM].[dbo].[ksl_community] c
ON 
    CHARINDEX(g.community_URL, c.ksl_url) > 0
    OR CHARINDEX(c.ksl_url, g.community_URL) > 0
  
left join (SELECT distinct campaign_id , Community FROM  #GAds ) ad on g.[sessionCampaignId] = ad.campaign_id


GROUP BY  [date]    
	  ,coalesce ( [ksl_shortname], community)
      ,[deviceCategory]
      ,[sessionCampaignId]
      ,[sessionDefaultChannelGrouping]


--Join GA4 and Ads Data

SELECT *
into #gtemp
FROM  ( 
SELECT 

    g.[date],

	ad.LevelofLiving,

    coalesce ( [ksl_shortname], community) [ksl_shortname],
	community,
    g.[deviceCategory],

    g.[sessionCampaignId],
    g.[sessionDefaultChannelGrouping],
    g.[bounceRate],
    g.[engagedSessions],
    g.[engagementRate],
    g.[eventCount],
    g.[eventsPerSession],
    g.[newUsers],
    g.[sessions],
    g.[totalUsers],

	 ad.[Impressions] AS Ad_Impressions,
    ad.[Clicks] AS Ad_Clicks,
    ad.[CostMicros] AS Ad_CostMicros,
    ad.[AbsoluteTopImpressionPercentage] AS Ad_AbsoluteTopImpressionPercentage,
    ad.[CrossDeviceConversions] AS Ad_CrossDeviceConversions,
    ad.[TopImpressionPercentage] AS Ad_TopImpressionPercentage
FROM 
    #GA4 g

left join #GAds ad on ad.campaign_id = g.sessionCampaignId
				and ad.Date = g.date
				and ad.Device = g.deviceCategory

) e 



-- Delete existing data before loading new data for data range
delete datawarehouse..Fact_WebTraffic
where [Date] in (SELECT [Date]  FROM #GA4 )


-- Insert combined GA4 and Ads data
insert into datawarehouse..Fact_WebTraffic
select 
		date
		--,landingPage		
		,ksl_shortname
		,LevelofLiving
		,deviceCategory

		,sessionCampaignId CampaignId
		,sessionDefaultChannelGrouping Channel
		,bounceRate
		,engagedSessions
		,engagementRate
		,eventCount
		,eventsPerSession
		,newUsers
		,sessions
		,totalUsers
		,Ad_Impressions
		,Ad_Clicks
		,Ad_CostMicros
		,Ad_AbsoluteTopImpressionPercentage
		,Ad_CrossDeviceConversions
		,Ad_TopImpressionPercentage
		
from #gtemp
where ksl_shortname is not null  
and ( ksl_shortname = Community or community is null )   

	

-- Insert just Ads data where GA4 and Ads community data don't match 
insert into datawarehouse..Fact_WebTraffic
(date	
		, ksl_shortname
		,deviceCategory		
		,levelofLiving
		,CampaignId
		,Channel		
		,Ad_Impressions
		,Ad_Clicks
		,Ad_CostMicros
		,Ad_AbsoluteTopImpressionPercentage
		,Ad_CrossDeviceConversions
		,Ad_TopImpressionPercentage )
select 
		date	
		,community ksl_shortname
		,deviceCategory		
		,levelofLiving
		,sessionCampaignId
		,sessionDefaultChannelGrouping		
		,Ad_Impressions
		,Ad_Clicks
		,Ad_CostMicros
		,Ad_AbsoluteTopImpressionPercentage
		,Ad_CrossDeviceConversions
		,Ad_TopImpressionPercentage
from #gtemp
where ksl_shortname is not null  
and ( ksl_shortname <> Community  )  



-- Insert all Ads data that doesn't join with GA4
insert into datawarehouse..Fact_WebTraffic
(date	
		, ksl_shortname
		,deviceCategory		
		,levelofLiving
		,CampaignId			
		,Ad_Impressions
		,Ad_Clicks
		,Ad_CostMicros
		,Ad_AbsoluteTopImpressionPercentage
		,Ad_CrossDeviceConversions
		,Ad_TopImpressionPercentage )
SELECT 
		ad.date	
		,ad.community ksl_shortname
		,ad.Device				
		,levelofLiving
		,campaign_id
		,Impressions
		,Clicks
		,CostMicros
		,AbsoluteTopImpressionPercentage
		,CrossDeviceConversions
		,TopImpressionPercentage -- Add fields you need from GAds
FROM 
    #GAds ad
LEFT JOIN 
    #GA4 g
ON 
    ad.campaign_id = g.sessionCampaignId
    AND ad.Date = g.date
    AND ad.Device = g.deviceCategory

WHERE 
    g.date IS NULL -- This ensures only unmatched records are selected
    AND g.sessionCampaignId IS NULL
    AND g.deviceCategory IS NULL;


-- Refresh Pricing App Stats (Results in 50% Pricing App Performance Gain)
BEGIN TRY
    UPDATE STATISTICS KiscoCustom.dbo.PRC_FloorPlan        WITH FULLSCAN;
    UPDATE STATISTICS KiscoCustom.dbo.PRC_Apt_Attribute    WITH FULLSCAN;
    UPDATE STATISTICS KiscoCustom.dbo.PRC_Attribute        WITH FULLSCAN;

    UPDATE STATISTICS KSLCLOUD_MSCRM.dbo.ksl_unitfloorplan WITH FULLSCAN;
    UPDATE STATISTICS KSLCLOUD_MSCRM.dbo.ksl_community     WITH FULLSCAN;
    UPDATE STATISTICS KSLCLOUD_MSCRM.dbo.ksl_apartment     WITH FULLSCAN;
    UPDATE STATISTICS KSLCLOUD_MSCRM.dbo.ksl_levelofliving WITH FULLSCAN;
END TRY
BEGIN CATCH
    PRINT 'Warning: Failed to update statistics.';
END CATCH

 END
GO



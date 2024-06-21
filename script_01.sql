create procedure IAP.TestPerformance
AS
BEGIN
	
	DECLARE @DelayLength1 char(8)= '00:00:10'  
	DECLARE @DelayLength2 char(8)= '00:00:05'  

	SELECT 'EXECUTION STEP 1'

	SELECT * FROM [IAP].[IWA_Promo_Code]	
	
	SELECT 'EXECUTION STEP 2'		

	WAITFOR DELAY @DelayLength1  

	SELECT 'EXECUTION STEP 4'

	SELECT * FROM [IAP].[IWA_Config]

	WAITFOR DELAY @DelayLength2

	SELECT 'EXECUTION STEP 5'

END

/*

    drop procedure sp_EnableTrace

*/

create procedure sp_EnableTrace
@databaseName nvarchar(256),
@storedProcedureName nvarchar(256),
@traceFileName  nvarchar(256),
@duration bigint
AS
BEGIN

-- Declare variables
DECLARE @rc INT
DECLARE @TraceID INT
DECLARE @maxFileSize bigint
DECLARE @fileName NVARCHAR(128)
DECLARE @likeSPName  nvarchar(256)
DECLARE @likeDBName  nvarchar(256)
DECLARE @on bit

-- Set values
SET @maxFileSize = 5
SET @fileName = N'C:\Users\Public\work_sql_trace\' + @traceFileName
SET @on = 1

-- Create trace
EXEC @rc = sp_trace_create @TraceID output, 0, @fileName, @maxFileSize, NULL 

-- If error end process
IF (@rc != 0) GOTO error

-- Set the events and data to collect

EXEC sp_trace_setevent @TraceID, 40,  1, @on
EXEC sp_trace_setevent @TraceID, 40,  5, @on
EXEC sp_trace_setevent @TraceID, 40, 12, @on
EXEC sp_trace_setevent @TraceID, 40, 13, @on
EXEC sp_trace_setevent @TraceID, 40, 14, @on
EXEC sp_trace_setevent @TraceID, 40, 15, @on
EXEC sp_trace_setevent @TraceID, 40, 16, @on
EXEC sp_trace_setevent @TraceID, 40, 17, @on

EXEC sp_trace_setevent @TraceID, 41,  1, @on
EXEC sp_trace_setevent @TraceID, 41,  5, @on
EXEC sp_trace_setevent @TraceID, 41, 12, @on
EXEC sp_trace_setevent @TraceID, 41, 13, @on
EXEC sp_trace_setevent @TraceID, 41, 14, @on
EXEC sp_trace_setevent @TraceID, 41, 15, @on
EXEC sp_trace_setevent @TraceID, 41, 16, @on
EXEC sp_trace_setevent @TraceID, 41, 17, @on

EXEC sp_trace_setevent @TraceID, 44,  1, @on
EXEC sp_trace_setevent @TraceID, 44,  5, @on
EXEC sp_trace_setevent @TraceID, 44, 12, @on
EXEC sp_trace_setevent @TraceID, 44, 13, @on
EXEC sp_trace_setevent @TraceID, 44, 14, @on
EXEC sp_trace_setevent @TraceID, 44, 15, @on
EXEC sp_trace_setevent @TraceID, 44, 16, @on
EXEC sp_trace_setevent @TraceID, 44, 17, @on

EXEC sp_trace_setevent @TraceID, 45,  1, @on
EXEC sp_trace_setevent @TraceID, 45,  5, @on
EXEC sp_trace_setevent @TraceID, 45, 12, @on
EXEC sp_trace_setevent @TraceID, 45, 13, @on
EXEC sp_trace_setevent @TraceID, 45, 14, @on
EXEC sp_trace_setevent @TraceID, 45, 15, @on
EXEC sp_trace_setevent @TraceID, 45, 16, @on
EXEC sp_trace_setevent @TraceID, 45, 17, @on

-- Set Filters
-- filter1 include databaseId = 6
--EXEC sp_trace_setfilter @TraceID, 3, 1, 0, 6


SET @likeDBName = '%' + LTRIM(RTRIM(@databaseName)) + '%'

--filter2 include databaseName = 6
EXEC sp_trace_setfilter @TraceID, 35, 0, 6, @likeDBName

SET @likeSPName = '%' + LTRIM(RTRIM(@storedProcedureName)) + '%'


EXEC sp_trace_setfilter @TraceID, 1, 1, 6, @likeSPName

EXEC sp_trace_setfilter @TraceID, 13, 1, 2, @duration

-- filter2 exclude application SQL Profiler
EXEC sp_trace_setfilter @TraceID, 10, 0, 7, N'SQL Profiler'

-- Start the trace
EXEC sp_trace_setstatus @TraceID, 1
 
-- display trace id for future references 
SELECT TraceID=@TraceID 
GOTO finish 

-- error trap
error: 
SELECT ErrorCode=@rc 

-- exit
finish: 

END

GO

/*
	drop procedure sp_StopTrace
*/

CREATE PROCEDURE sp_StopTrace
@processID INT,
@storedProcedureName nvarchar(256),
@traceFileName nvarchar(256),
@spID int = null
AS
BEGIN

	DECLARE @likeSPName  nvarchar(256)
	SET @likeSPName = '%execute ' + LTRIM(RTRIM(@storedProcedureName)) + '%'

	IF @spID IS NULL 
	BEGIN	
		EXEC sp_trace_setstatus @processID, 0
		EXEC sp_trace_setstatus @processID, 2 
	END

	DECLARE @fileName NVARCHAR(128)
	SET @fileName = N'C:\Users\Public\work_sql_trace\' + LTRIM(RTRIM(@traceFileName)) + '.trc'

	delete sqlTableToLoad

	--Load into an existing table
	INSERT INTO sqlTableToLoad
	SELECT * FROM ::fn_trace_gettable(@fileName, DEFAULT)

	IF @spID IS NULL 

	BEGIN		

		SET @spID = (SELECT DISTINCT SPID FROM sqlTableToLoad WHERE TextData Like @likeSPName)

	END
	
	SELECT datediff(second, StartTime,EndTime) as ElapsedTime, Duration as Duration, 
		* FROM sqlTableToLoad 
		where EndTime IS NOT NULL
		AND SPID = @spID
		AND EventClass = 45 OR (EventClass = 41)
		AND TextData NOT LIKE '%SELECT @@SPID%'
		AND TextData NOT LIKE '%sp_Enable%'	
		order by LineNumber desc 

END
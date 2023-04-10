DECLARE @filepath NVARCHAR(260)

SELECT @filepath = SLC.PATH
FROM sys.dm_os_server_diagnostics_log_configurations AS SLC;

SELECT @filepath = @filepath + N'system_health_*.xel'
 
DROP TABLE IF EXISTS  #DeadLockTable

SELECT 
	CONVERT(XML, event_data) AS SessionData
	INTO #DeadLockTable 
 FROM sys.fn_xe_file_target_read_file(@filepath, NULL, NULL, NULL)
WHERE object_name = 'xml_deadlock_report'

SELECT 
	SessionData.value('(event/@timestamp)[1]', 'datetime2(7)') AS UTCDeadLockOccuredAt, 
    CONVERT(DATETIME, SWITCHOFFSET(CONVERT(DATETIMEOFFSET, 
    SessionData.value('(event/@timestamp)[1]', 'VARCHAR(50)')), DATENAME(TzOffset, SYSDATETIMEOFFSET()))) AS SystemTime, 
    SessionData.query('event/data/value/deadlock') AS XMLReport
FROM #DeadLockTable
ORDER BY UTCDeadLockOccuredAt DESC;
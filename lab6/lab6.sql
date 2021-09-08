/* Task ¹ 1 */
/* Create a stored function that receives the reader's ID as input 
and returns a list of book IDs that he has already read and returned to 
the library. */

CREATE FUNCTION BOOKS_FROM_SUBSCRIBER(@id_suscriber INT)
RETURNS NVARCHAR(max)
AS
BEGIN
	DECLARE @book NVARCHAR(max);
	SET @book = (SELECT
				  STRING_AGG([sb_book], ', ') WITHIN GROUP 
				  (ORDER BY [sb_book] ASC)
				  --AS [books_that_not_active]
				  FROM [subscriptions]
				  WHERE [sb_is_active] = 'N' AND [sb_subscriber] = @id_suscriber
				  GROUP BY [sb_subscriber])
	IF (@book IS NULL)
	SET @book = 'This reader did not take or return books.'
	RETURN @book
END;
GO

SELECT dbo.BOOKS_FROM_SUBSCRIBER(5);
SELECT dbo.BOOKS_FROM_SUBSCRIBER(1);



/* Task ¹ 2 */
/* Create a stored function that returns a list of the first range 
of free values ??of auto-incrementing primary keys in the specified table 
(for example, if the table has primary keys 1, 4, 8, then the first free 
range is values ??2 and 3). */

CREATE FUNCTION GET_INTERVAL_IN_SUBSCRIPTIONS()
RETURNS @intervals TABLE
	(
	[start] INT,
	[stop] INT
	)
AS
BEGIN
	INSERT @intervals
	SELECT TOP 1 [start],
		   [stop]
	FROM (SELECT [min_t].[sb_id] + 1 AS [start],
		 (SELECT MIN([sb_id]) - 1
		  FROM [subscriptions] AS [x]
		  WHERE [x].[sb_id] > [min_t].[sb_id]) AS [stop]
		  FROM [subscriptions] AS [min_t]
	UNION
	SELECT 1 AS [start],
	(SELECT MIN([sb_id]) - 1
	FROM [subscriptions] AS [x]
	WHERE [sb_id] > 0) AS [stop]
	) AS [data]
	WHERE [stop] >= [start]
	ORDER BY [start],
			 [stop]
	RETURN
END;
GO

SELECT * FROM GET_INTERVAL_IN_SUBSCRIPTIONS()




/* Task ¹ 3 */
/* Create a stored function that receives the reader's ID as input and 
returns 1 if the reader currently has less than ten books, and 0 otherwise. */

CREATE FUNCTION AMOUNT_SUBSCRIBER_BOOKS(@id_suscriber INT)
RETURNS NVARCHAR(150)
AS
BEGIN
	DECLARE @books INT;
	DECLARE @result INT;
	DECLARE @message NVARCHAR(150);
	
	SET @books = (SELECT 
				  COUNT(CASE WHEN [sb_is_active] = 'Y' THEN 1 ELSE NULL 
				  END)
				  FROM [subscriptions] 
				  WHERE @id_suscriber = [sb_subscriber]
				  GROUP BY [sb_subscriber]) 
	SET @message =
		CASE 
		WHEN (@books<10) THEN ': Less than 10.'
		WHEN (@books>=10) THEN ': More than 10.'
		ELSE 'No such subscriptions'
		END;
	SET @result =
		CASE 
		WHEN (@books<10) THEN 1
		WHEN (@books>=10) THEN 0
		END;
	RETURN CONCAT(@result, @message);
END;
GO

SELECT dbo.AMOUNT_SUBSCRIBER_BOOKS(5);




/* Task ¹ 4 */
/* Create a stored function that takes the year of publication of the book 
as input and returns 1 if the book was published less than a hundred years 
ago, and 0 otherwise. */

CREATE FUNCTION YEAR_VERIFY_HUNDRED(@publish_date DATE)
RETURNS NVARCHAR(150)
AS
BEGIN
	DECLARE @result INT;
	DECLARE @message NVARCHAR(150);
	
	SET @message =
		CASE 
		WHEN (DATEDIFF(y, @publish_date, GETDATE())<100) THEN ': Less than 100 years.'
		ELSE ': More than 100 years.'
		END;
	SET @result =
		CASE 
		WHEN (DATEDIFF(y, @publish_date, GETDATE())<100) THEN 1
		ELSE 0
		END;
	RETURN CONCAT(@result, @message);
END;
GO

SELECT dbo.YEAR_VERIFY_HUNDRED('2021-06-21');
SELECT dbo.YEAR_VERIFY_HUNDRED('1921-06-21');




/* Task ¹ 6 */
/* Create a stored procedure that generates a list of 
tables and their foreign keys that depend on the table function specified 
in the parameter. */

CREATE PROCEDURE SHOW_TABLE_OBJECTS
@table_name NVARCHAR(150)
WITH EXECUTE AS OWNER
AS 
	DECLARE @query_text NVARCHAR(1000) = '';
	SET @query_text =
		'SELECT SO_P.name as [parent table],
				SC_P.name as [parent column],
				''is a foreign key of'' AS [direction],
				SO_R.name as [referenced table],
				SC_R.name as [referenced column]
		 FROM sys.foreign_key_columns FKC
		 INNER JOIN sys.objects SO_P 
		 ON SO_P.object_id = FKC.parent_object_id
	     INNER JOIN sys.columns SC_P 
		 ON (SC_P.object_id = FKC.parent_object_id) 
			 AND (SC_P.column_id = FKC.parent_column_id)
		 INNER JOIN sys.objects SO_R 
		 ON SO_R.object_id = FKC.referenced_object_id
		 INNER JOIN sys.columns SC_R 
		 ON (SC_R.object_id = FKC.referenced_object_id) 
			 AND (SC_R.column_id = FKC.referenced_column_id)
		 WHERE
		 ((SO_R.name = ''_FP_TABLE_NAME_PLACEHOLDER_'') 
		 AND (SO_R.type = ''U''))';
	SET @query_text = REPLACE(@query_text, '_FP_TABLE_NAME_PLACEHOLDER_',
	@table_name);
	EXECUTE sp_executesql @query_text;
GO

EXECUTE SHOW_TABLE_OBJECTS 'subscribers';
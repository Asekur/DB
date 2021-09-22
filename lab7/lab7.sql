/* Task 1 */
/* Create a stored procedure that:
	a. adds two random genres to each book;
	b. cancels the performed actions if in the process of work at least 
	one insert operation failed due to duplicate value of the primary key 
	of the table "m2m_books_genres" (ie, such a book already had such 
	a genre). */

CREATE PROCEDURE ADD_GENRES_RANDOM
AS
BEGIN
	DECLARE @b_value INT
	DECLARE @g_value INT
	-- Declare cursors - logic T-SQL in cycle
	DECLARE cursor_of_books CURSOR LOCAL FAST_FORWARD FOR
		SELECT [b_id] FROM [books]
	DECLARE cursor_of_genres CURSOR LOCAL FAST_FORWARD FOR
		SELECT TOP 1 [g_id] FROM [genres]
		ORDER BY NEWID()
	DECLARE @fetch_books_cursor INT
	DECLARE @fetch_genres_cursor INT

	BEGIN TRANSACTION
		BEGIN TRY
			OPEN cursor_of_books
			FETCH NEXT FROM  cursor_of_books INTO @b_id_value
			SET @fetch_books_cursor = @@FETCH_STATUS
			WHILE @fetch_books_cursor = 0
			BEGIN
				OPEN cursor_of_genres
				FETCH NEXT FROM cursor_of_genres INTO @g_id_value
				SET @fetch_genres_cursor = @@FETCH_STATUS
				WHILE @fetch_genres_cursor = 0
				BEGIN
					INSERT INTO [m2m_books_genres] ([b_id], [g_id])
					VALUES (@b_value, @g_value)
					FETCH NEXT FROM cursor_of_genres INTO @g_id_value
					SET @fetch_genres_cursor = @@FETCH_STATUS
				END
				CLOSE cursor_of_genres
				FETCH NEXT FROM cursor_of_books INTO @b_id_value
				SET @fetch_books_cursor = @@FETCH_STATUS
			END
			CLOSE cursor_of_books
			DEALLOCATE cursor_of_books
			DEALLOCATE cursor_of_genres
			COMMIT TRANSACTION
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION
		END CATCH
END
GO

EXECUTE ADD_GENRES_RANDOM;



/* Task 2 */
/* Create a stored procedure that:
	a. doubles the value of the "b_quantity" field for all books;
	b. cancels the performed action if, as a result of the operation, 
	the average number of book copies exceeds 50. */

CREATE PROCEDURE INCREASE_QUANTITY
AS
BEGIN
	DECLARE @average_read FLOAT
	BEGIN TRANSACTION
		UPDATE [books]
		SET [b_quantity] = [b_quantity] * 2
		SET @average_read = 
			(SELECT AVG( CAST([b_quantity] AS FLOAT)) 
			FROM [books])
		IF (@average_read > 50) 
		BEGIN
			ROLLBACK TRANSACTION
		END
		ELSE 
		BEGIN
			COMMIT TRANSACTION
		END
END
GO

EXECUTE INCREASE_QUANTITY



/* Task 6 */
/* Create a trigger on the "subscriptions" table that determines the 
transaction isolation level in which the update operation is currently 
taking place, and undo the operation if the transaction isolation level 
is other than REPEATABLE READ. */

CREATE TRIGGER [isolation_level] 
ON [subscriptions] 
AFTER INSERT, UPDATE 
AS
	DECLARE @msg NVARCHAR(max)
	IF (SELECT [transaction_isolation_level] 
		FROM sys.dm_exec_sessions 
		WHERE [session_id] = @@SPID) != 3
	BEGIN
		SET @msg = 'Error';
		RAISERROR (@msg, 16, 1);
		ROLLBACK TRANSACTION;
		RETURN
	END;
GO



/* Task 7 */
/* Create a stored function that throws an exception if both conditions 
are met (hint: this task has a solution only for MS SQL Server):
	a. the auto-confirmation mode of transactions is disabled;
	b. the function is started from a nested transaction. */

CREATE PROCEDURE THROW_EXCEPTION 
AS
	IF (@@TRANCOUNT != 0) AND (@@OPTIONS & 2 = 0)
	RAISERROR ('ERROR', 16, 1);
GO

EXECUTE THROW_EXCEPTION




/* Task 8 */
/* Create a stored procedure that counts the number of records in the 
specified table in such a way that it returns the most correct data, even 
if you have to sacrifice performance to achieve this result */

CREATE PROCEDURE COUNTS_RECORDS 
@table_name NVARCHAR(150)
AS
	DECLARE @query nvarchar(max)
	SET @query = 'SELECT COUNT(*) 
				  FROM PLACEHOLDER'
	SET @query = REPLACE(@query, 'PLACEHOLDER', @table_name)
	SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
	BEGIN TRANSACTION
		EXECUTE sp_executesql @query
		COMMIT TRANSACTION
GO

EXECUTE COUNTS_RECORDS 'subscribers';
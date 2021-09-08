/* Task № 1 */
/* Create a view that allows you to get a list of readers with 
the number of books each reader has on hand, but displays only those 
readers for whom there are debts, ie. the reader has at least one book 
on hand that he should have returned before the current date. */

CREATE VIEW [readers_indebtedness] AS
SELECT [s_name],
	   COUNT(CASE 
			 WHEN [sb_is_active] = 'Y' THEN [sb_book] 
			 ELSE NULL 
			 END) AS [books_indebtedness]
FROM [subscribers]
LEFT OUTER JOIN [subscriptions]
ON [s_id] = [sb_subscriber]
GROUP BY [s_id], [s_name]
HAVING COUNT(CASE
	WHEN [sb_is_active] = 'Y' AND [sb_finish] < GETDATE() THEN [sb_is_active]
	ELSE NULL
	END) > 0

SELECT * FROM [readers_indebtedness] 


/* Task № 5 */
/* Create a view that returns all information from the subscriptions table, 
converting the dates from the sb_start and sb_finish fields to the format 
"YYYY-MM-DD NN", where "NN" is the day of the week as its full name. */

CREATE VIEW [subscriptions_datename]
WITH SCHEMABINDING
AS
	SELECT [sb_id],
		[sb_subscriber],
		[sb_book],
		CONCAT([sb_start], ' ', DATENAME(dw, [sb_start])) AS [sb_start],
		CONCAT([sb_start], ' ', DATENAME(dw, [sb_finish])) AS [sb_finish],
		[sb_is_active]
	FROM [dbo].[subscriptions]

SELECT * FROM [subscriptions_datename]


/* Task № 12 */
/* Modify the database schema so that the table "subscribers" stores 
information about how many times the reader has taken books from the 
library (this counter must be incremented every time the reader is given a 
book; decreasing the value of this counter is not provided). */

-- Модификация таблицы:
ALTER TABLE [subscribers] 
ADD [s_books] INT NOT NULL DEFAULT 0;

-- Инициализация данных:
UPDATE [subscribers]
SET [s_books] = [s_hand_books]
FROM [subscribers]
JOIN (SELECT [sb_subscriber],
	  COUNT([sb_id]) AS [s_hand_books]
	  FROM [subscriptions]
	  GROUP BY [sb_subscriber]) AS [prepared_data]
ON [s_id] = [sb_subscriber];

-- Реакция на добавление выдачи книги:
CREATE TRIGGER [s_add_books_on_subscriptions]
ON [subscriptions]
AFTER INSERT
AS
	UPDATE [subscribers]
	SET [s_books] = [s_books] + [s_new_books]
	FROM [subscribers]
	JOIN (SELECT [sb_subscriber],
				 COUNT([sb_id]) AS [s_new_books]
		  FROM [inserted]
		  GROUP BY [sb_subscriber]) AS [prepared_data]
	ON [s_id] = [sb_subscriber];
GO

-- Реакция на обновление выдачи книги:
CREATE TRIGGER [s_upd_books_on_subscriptions]
ON [subscriptions]
AFTER UPDATE
AS
	UPDATE [subscribers]
	SET [s_books] = [s_books] + [s_new_books]
	FROM [subscribers]
	JOIN (SELECT [sb_subscriber],
				 COUNT([sb_id]) AS [s_new_books]
		  FROM [inserted]
		  GROUP BY [sb_subscriber]) AS [prepared_data]
	ON [s_id] = [sb_subscriber];
GO



/* Task № 13 */
/* Create a trigger that does not allow adding information about the issue of a 
book to the database if at least one of the following conditions is met:
• date of issue or return falls on Sunday;
• the reader has borrowed more than 100 books over the past six months;
• the time interval between the dates of issue and return is less than 
three days. */

CREATE TRIGGER [subscriptions_control]
ON [subscriptions]
AFTER INSERT, UPDATE
AS
	-- Переменные для хранения списка "плохих записей" и сообщения об ошибке.
	DECLARE @bad_records NVARCHAR(max);
	DECLARE @msg NVARCHAR(max);

	-- Блокировка выдач книг с днем выдачи или возврата воскресенья.
	SELECT @bad_records = STUFF((SELECT ', ' + CAST([sb_id] AS NVARCHAR) +
			' (start: ' + CAST([sb_start] AS NVARCHAR) + ', finish: ' +
			CAST([sb_finish] AS NVARCHAR) + ')'
	FROM [inserted]
	WHERE DATENAME(dw, [sb_start]) = 'Sunday' OR DATENAME(dw, [sb_finish]) = 'Sunday'
	ORDER BY [sb_id]
	FOR XML PATH(''), TYPE).value('.', 'nvarchar(max)'),
	1, 2, '');
	IF LEN(@bad_records) > 0
	BEGIN
		SET @msg =
		CONCAT('The following subscriptions'' start or finish date are
		in the Sunday: ', @bad_records);
		RAISERROR (@msg, 16, 1);
		ROLLBACK TRANSACTION;
		RETURN 
	END;

	-- Блокировка выдач книг, где читатель брал более 100 книг за последние полгода.
	SELECT @bad_records = STUFF((SELECT ', ' + [list]
	FROM (SELECT CONCAT('(id=', [s_id], ', ',
				 [s_name], ', books=',
				 COUNT([sb_book]), ')') AS [list]
		  FROM [subscribers]
		  JOIN [subscriptions]
		  ON [s_id] = [sb_subscriber]
		  WHERE DATEDIFF(mm, [sb_start], GETDATE()) <= 6
		  AND [sb_subscriber] IN (SELECT [sb_subscriber]
								  FROM [inserted])
								  GROUP BY [s_id], [s_name]
								  HAVING COUNT([sb_book]) > 100)
	AS [prepared_data]
	FOR XML PATH(''), TYPE).value('.', 'nvarchar(max)'),
	1, 2, '');
	IF (LEN(@bad_records) > 0)
	BEGIN
		SET @msg = CONCAT('The following readers have more books
		than allowed (100 allowed) for last half year: ', @bad_records);
		RAISERROR (@msg, 16, 1);
		ROLLBACK TRANSACTION;
		RETURN;
	END;

	-- Блокировка выдач книг c промежутком времени между датами выдачи и возврата менее трёх дней.
	SELECT @bad_records = STUFF((SELECT ', ' + CAST([sb_id] AS NVARCHAR) +
			' (start: ' + CAST([sb_start] AS NVARCHAR) + ', finish: ' +
			CAST([sb_finish] AS NVARCHAR) + ')'
	FROM [inserted]
	WHERE DATEDIFF (dd, [sb_start], [sb_finish]) < 3
	ORDER BY [sb_id]
	FOR XML PATH(''), TYPE).value('.', 'nvarchar(max)'),
	1, 2, '');
	IF LEN(@bad_records) > 0
	BEGIN
		SET @msg =
		CONCAT('The following subscriptions'' the interval between 
		finish and start dates is less then three days: ', @bad_records); 
		RAISERROR (@msg, 16, 1);
		ROLLBACK TRANSACTION;
		RETURN 
	END;




/* Task № 17 */
/* Create a trigger, change the date of the current 
books, if specified in the IN-SERT- or UPDATE-query the date 
of the current books to change the current period and more. */

-- Необходимо отключить каскадное обновление FK для таблицы subdcriptions

CREATE TRIGGER [subscriptions_date_correct_insert]
ON [subscriptions]
INSTEAD OF INSERT
AS
	DECLARE @bad_records NVARCHAR(max);
	DECLARE @msg NVARCHAR(max);
	SELECT @bad_records =
		STUFF((SELECT ', ' + '[' + CAST([sb_start] AS NVARCHAR) +
		'] -> [' + FORMAT(GETDATE(),'yyyy-MM-dd') + ']'
	FROM [inserted]
	WHERE DATEDIFF(mm, [sb_start], GETDATE()) >= 6
	FOR XML PATH(''), TYPE).value('.', 'nvarchar(max)'),
	1, 2, '');
	IF (LEN(@bad_records) > 0)
	BEGIN
		SET @msg = CONCAT('Some values were changed: ', @bad_records);
		PRINT @msg;
		RAISERROR (@msg, 16, 0);
	END;

SET IDENTITY_INSERT [subscriptions] ON;
INSERT INTO [subscriptions]
			([sb_id],
			[sb_subscriber],
			[sb_book],
			[sb_start],
			[sb_finish],
			[sb_is_active])
SELECT ( CASE
		WHEN [sb_id] IS NULL
		OR [sb_id] = 0 THEN IDENT_CURRENT('subscriptions')
		+ IDENT_INCR('subscriptions')
		+ ROW_NUMBER() OVER (ORDER BY
		(SELECT 1)) - 1
		ELSE [sb_id]
		END ) AS [sb_id],
				 [sb_subscriber],
				 [sb_book],
				( CASE
					WHEN (DATEDIFF(mm, [sb_start], GETDATE()) >= 6)
					THEN GETDATE()
					ELSE [sb_start]
					END ) AS [sb_start],
				[sb_finish],
				[sb_is_active]
				FROM [inserted];

SET IDENTITY_INSERT [subscriptions] OFF;
GO

CREATE TRIGGER [subscriptions_date_correct_update]
ON [subscriptions]
INSTEAD OF UPDATE
AS
	DECLARE @bad_records NVARCHAR(max);
	DECLARE @msg NVARCHAR(max);
	
	IF (UPDATE([sb_id]))
	BEGIN
		RAISERROR ('Please, do NOT update surrogate PK
		on table [subscriptions]!', 16, 1);
		ROLLBACK TRANSACTION;
		RETURN;
	END;
	SELECT @bad_records =
		STUFF((SELECT ', ' + '[' + CAST([sb_start] AS NVARCHAR) +
		'] -> [' + FORMAT(GETDATE(), 'yyyy-MM-dd') + ']'
	FROM [inserted]
	WHERE DATEDIFF(mm, [sb_start], GETDATE()) >= 6
	FOR XML PATH(''), TYPE).value('.', 'nvarchar(max)'),
	1, 2, '');
	IF (LEN(@bad_records) > 0)
	BEGIN
		SET @msg = CONCAT('Some values were changed: ', @bad_records);
		PRINT @msg;
		RAISERROR (@msg, 16, 0);
	END;

	UPDATE [subscriptions]
	SET [subscriptions].[sb_subscriber] = [inserted].[sb_subscriber],
	[subscriptions].[sb_book] = [inserted].[sb_book],
	[subscriptions].[sb_start] =
		( CASE
		WHEN (DATEDIFF(mm, [inserted].[sb_start], GETDATE()) >= 6)
		THEN GETDATE()
		ELSE [inserted].[sb_start]
		END ),
	[subscriptions].[sb_finish] = [inserted].[sb_finish],
	[subscriptions].[sb_is_active] = [inserted].[sb_is_active]
	FROM [subscriptions]
	JOIN [inserted]
	ON [subscriptions].[sb_id] = [inserted].[sb_id];
GO

/* Task 1 */
/* Add information about three new readers to the database: 
"Orlov O.O.", "Sokolov S.S.", "Berkutov B.B.". */

INSERT INTO [subscribers] ([s_name])
VALUES
	(N'Orlov O.O.'),
	(N'Sokolov S.S.'),
	(N'Berkutov B.B.');
/* OR */
SET IDENTITY_INSERT [subscribers] ON;
INSERT INTO [subscribers] ([s_id], [s_name])
VALUES
	(5, N'Orlov O.O.'),	
	(6, N'Sokolov S.S.'),
	(7, N'Berkutov B.B.');
SET IDENTITY_INSERT [subscribers] OFF;


/* Task 7 */
/* Delete information about all issuances to readers of the book with ID = 1. */

UPDATE [subscriptions]
SET [sb_is_active] = N'N'
WHERE [sb_id] <= 50
SELECT * FROM [subscriptions]


/* Task 8 */
/* Delete information about all issuances to readers of the book with ID = 1. */

DELETE FROM [subscriptions]
WHERE [sb_book] = 1
SELECT * FROM [subscriptions]


/* Task 9 */
/* Delete information about all book loans made after the 
20th day of any month of any year. */

DELETE FROM [subscriptions]
WHERE DAY([sb_start]) > 20


/* Task 13 */
/* Update all the names of the authors, I added the names "[+]" to the 
branch if there is a sick book by this author in the library, or added 
the names "[-]" to the branch in the opposite case */

WITH [prepared_data]
AS (SELECT [a_id], COUNT([b_id]) AS [book_count]
    FROM [m2m_books_authors]
    GROUP BY [a_id])
UPDATE [authors]
SET [a_name] =
	(SELECT
		CASE
		WHEN [book_count] > 3
		THEN (SELECT CONCAT([a_name], ' [+] '))
		ELSE (SELECT CONCAT([a_name], ' [-] '))
		END
	FROM [prepared_data]
	WHERE [authors].[a_id] = [prepared_data].[a_id])
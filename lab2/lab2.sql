/* Task 2 */
/* Select all information about genres*/

SELECT * 
FROM [genres]


/* Task 3 */
/* Show ids (without dublication) of the books that were taken by the readers. */

SELECT DISTINCT [sb_book]
FROM [subscriptions]


/* Task 12 */
/* Show id of one (any) reader who has borrowed the most books from the library. */

SELECT TOP 1 [sb_subscriber]
FROM [subscriptions]
GROUP BY [sb_subscriber]
ORDER BY COUNT(*) DESC


/* Task 16 */
/* Show in days how many, on average, readers have 
already been registered in the library. */

SELECT AVG(DATEDIFF(day, [sb_start], GETDATE())) AS [avg_days_register]
FROM [subscriptions] AS [outer]
WHERE [sb_id] = (SELECT TOP 1 [sb_id]
	FROM [subscriptions] AS [inner]
	WHERE [outer].[sb_subscriber] = [inner].[sb_subscriber]
	ORDER BY [sb_start] ASC) 



/* Task 17 */
/* Show how many books were returned and not returned to the library. */

SELECT (CASE
	WHEN [sb_is_active] = 'Y'
	THEN 'Not returned'
	ELSE 'Returned'
	END) AS [status],
	COUNT([sb_id]) AS [amount_books]
FROM [subscriptions]
GROUP BY (CASE
	WHEN [sb_is_active] = 'Y'
	THEN 'Not returned'
	ELSE 'Returned'
	END)
ORDER BY [status] DESC
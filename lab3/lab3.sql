/* Task 3 */
/* Show all books with their genres (duplicate book titles are not allowed). */

SELECT [b_name]
	AS [book],
	STRING_AGG([g_name], ', ') WITHIN GROUP (ORDER BY [g_name] ASC)
	AS [genre(s)]
FROM [books]
	JOIN [m2m_books_genres]
	ON [books].[b_id] = [m2m_books_genres].[b_id]
	JOIN [genres]
	ON [m2m_books_genres].[g_id] = [genres].[g_id]
GROUP BY [books].[b_id], [books].[b_name]
ORDER BY [books].[b_name]


/* Task 5 */
/* Show a list of books that have ever been taken by readers. */

SELECT DISTINCT [b_id],
		[b_name],
		[b_year]
FROM [books]
	JOIN [subscriptions]
	ON [b_id] = [sb_book]
/* OR */
SELECT [b_id],
       [b_name],
       [b_year]
FROM [books]
WHERE [b_id] IN (SELECT DISTINCT [sb_book]
FROM [subscriptions])



/* Task 17 */
/* Show the readability of genres, i.e. all genres and the number 
of times that books of these genres have been taken by readers. */

SELECT [genres].[g_id],
       [genres].[g_name],
       COUNT([sb_book]) AS [amount_books_taken]
FROM [genres]
	JOIN [m2m_books_genres]
	ON [genres].[g_id] = [m2m_books_genres].[g_id]
	LEFT OUTER JOIN [subscriptions]
	ON [m2m_books_genres].[b_id] = [sb_book]
GROUP BY [genres].[g_id],
	 [genres].[g_name]
ORDER BY COUNT([sb_book]) DESC


/* Task 18 */
/* Show the most read genre, i.e. genre (or genres, if there are several), 
related to which the readers took the book most often. */

WITH [prepared_data]
AS (SELECT [genres].[g_id],
	   [genres].[g_name],
	   COUNT([sb_book]) AS [amount_books],
    	RANK()
	OVER (ORDER BY COUNT([sb_book]) DESC) AS [rank]
	FROM [genres]
	JOIN [m2m_books_genres]
	ON [genres].[g_id] = [m2m_books_genres].[g_id]
	LEFT OUTER JOIN [subscriptions]
	ON [m2m_books_genres].[b_id] = [sb_book]
	GROUP BY [genres].[g_id],
		 [genres].[g_name])
SELECT [g_id],
       [g_name], 
       [amount_books]
FROM [prepared_data]
WHERE [rank] = 1


/* Task 23 */
/* Show the reader who was the last to take a book from the library. */

SELECT TOP 1 [sb_start],
	     [s_name]
FROM [subscriptions]
JOIN [subscribers]
ON [sb_subscriber] = [s_id]
ORDER BY [sb_start] DESC

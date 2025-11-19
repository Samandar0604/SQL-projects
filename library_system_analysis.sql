-- Library system analysis

-- creating a new book record
INSERT INTO books
VALUES('978-1-60129-456-2', 
		'To Kill a Mockingbird', 
		'Classic', 
		6.00, 
		'yes', 
		'Harper Lee', 
		'J.B. Lippincott & Co.');
SELECT * FROM books
WHERE isbn = '978-1-60129-456-2';

-- Updating an Existing member's address
UPDATE members 
SET member_address = '125 Oak St'
WHERE member_id = 'C103';
select * from members;

-- Delete a Record from the Issued Status Table 
-- Objective: Delete the record with issued_id = 'IS121' from the issued_status table.
DELETE FROM issue_status WHERE issued_id = 'IS121';

-- Retrieve All Books Issued by a Specific Employee 
-- Objective: Select all books issued by the employee with emp_id = 'E101'.
SELECT issued_book_name 
FROM issue_status
WHERE issued_emp_id = 'E101';

-- List Members Who Have Issued More Than One Book
SELECT issued_member_id, COUNT(*) AS number_book
FROM issue_status
GROUP by issued_member_id
HAVING COUNT(*)>1;

-- Create Summary Tables: 
-- Used CTAS to generate new tables based on query results - each book and total book_issued_cnt
CREATE TABLE book_issued_cnt AS
SELECT  b.isbn, b.book_title, 
		COUNT(i.issued_id) AS issued_count
FROM books b
	 	JOIN issue_status i
		 ON i.issued_book_isbn = b.isbn
GROUP BY b.isbn;
SELECT * FROM book_issued_cnt;

-- Retrieve All Books in a Specific Category
SELECT book_title 
FROM books 
WHERE category = 'Classic';

-- Find Total Rental Income by Category
SELECT b.category, 
		SUM(b.rental_price)*COUNT(ist.issued_id) as total_price
FROM books b
	JOIN issue_status ist
	ON b.isbn = ist.issued_book_isbn
GROUP BY b.category;

-- List Members Who Registered in the Last 600 Days
SELECT member_id, member_name 
FROM members
WHERE reg_date >= CURRENT_DATE - INTERVAL '600 days'; 

-- List Employees with Their Branch Manager's Name and their branch details
SELECT e.emp_id,
		e.emp_name,
		e.position,
		e.branch_id,
		br.*,
		e2.emp_name AS manager
FROM employees e
		LEFT JOIN branch br
		ON e.branch_id = br.branch_id
		JOIN employees e2
		ON e2.emp_id = br.manager_id;

-- Create a Table of Books with Rental Price Above a Certain Threshold
 CREATE TABLE expensive_books AS
 SELECT * FROM books
 WHERE rental_price > 7.00;

-- Retrieve the List of Books Not Yet Returned
SELECT ist.issued_book_name FROM issue_status ist
		LEFT JOIN return_status rst
		ON ist.issued_id = rst.issued_id
WHERE rst.return_id IS NULL;

-- Identify Members with Overdue Books
-- Write a query to identify members who have overdue books (assume a 30-day return period). 
-- Display the member's_id, member's name, book title, issue date, and days overdue.
SELECT m.member_id, 
	   m.member_name,
	   b.book_title,
	   ist.issued_date,
	   DATE('2024-05-01') - ist.issued_date AS days_overdue
FROM issue_status ist
		JOIN members m
		ON ist.issued_member_id = m.member_id
		JOIN books b
		ON b.isbn = ist.issued_book_isbn
		LEFT JOIN return_status rst
		ON ist.issued_id = rst.issued_id
WHERE rst.return_id IS NULL 
	  AND (DATE('2024-05-01') - ist.issued_date)>30
ORDER BY 1;

-- Update Book Status on Return
-- Write a query to update the status of books in the books table to "Yes" 
-- when they are returned (based on entries in the return_status table).
CREATE OR REPLACE PROCEDURE add_return_records(p_return_id VARCHAR(10), p_issued_id VARCHAR(10), p_book_quality VARCHAR(10))
LANGUAGE plpgsql
AS $$

DECLARE
    v_isbn VARCHAR(50);
    v_book_name VARCHAR(80);
    
BEGIN
    -- all your logic and code
    -- inserting into returns based on users input
    INSERT INTO return_status(return_id, issued_id, return_date, book_quality)
    VALUES
    (p_return_id, p_issued_id, CURRENT_DATE, p_book_quality);

    SELECT 
        issued_book_isbn,
        issued_book_name
        INTO
        v_isbn,
        v_book_name
    FROM issue_status
    WHERE issued_id = p_issued_id;

    UPDATE books
    SET status = 'yes'
    WHERE isbn = v_isbn;

    RAISE NOTICE 'Thank you for returning the book: %', v_book_name;
    
END;
$$


-- Testing FUNCTION add_return_records

SELECT * FROM books
WHERE isbn = '978-0-307-58837-1';

SELECT * FROM issue_status
WHERE issued_book_isbn = '978-0-307-58837-1';

SELECT * FROM return_status
WHERE issued_id = 'IS135';

ALTER TABLE return_status
ADD COLUMN book_quality VARCHAR(15);

-- calling function 
CALL add_return_records('RS138', 'IS135', 'Good');

-- calling function 
CALL add_return_records('RS148', 'IS140', 'Good');

-- Branch Performance Report
-- Create a query that generates a performance report for each branch, showing the number of books issued, 
-- the number of books returned, and the total revenue generated from book rentals.
SELECT b.branch_id,
	   COUNT(ist.issued_id) AS issued_book_number,
	   COUNT(rst.return_id) AS returned_book_number,
	   SUM(bk.rental_price) AS total_revenue
FROM issue_status ist
	JOIN employees e 
		ON ist.issued_emp_id=e.emp_id
	JOIN branch b 
		ON e.branch_id = b.branch_id
	LEFT JOIN return_status rst 
		ON ist.issued_id = rst.issued_id
	JOIN books bk 
		ON ist.issued_book_isbn = bk.isbn
GROUP BY b.branch_id
ORDER BY 1;

-- Create a Table of Active Members
-- Use the CREATE TABLE AS (CTAS) statement to create a new table active_members containing members 
-- who have issued at least one book in the last 2 months
CREATE TABLE active_members 
AS
SELECT * 
FROM members 
WHERE member_id in (SELECT DISTINCT issued_member_id 
					FROM issue_status
					WHERE issued_date >= DATE('2024-05-01') - INTERVAL '2 month');
SELECT * FROM active_members;

-- Find Employees with the Most Book Issues Processed
-- Write a query to find the top 3 employees who have processed the most book issues. 
-- Display the employee name, number of books processed, and their branch.

SELECT e.emp_name, 
		B.*, 
		COUNT(ist.issued_id) AS issued_book_number
FROM issue_status ist
		JOIN employees E 
			ON ist.issued_emp_id = e.emp_id
		JOIN branch b
			ON e.branch_id = b.branch_id
GROUP BY 1,2
ORDER BY 3 DESC
LIMIT 3;

-- Stored Procedure Objective: Create a stored procedure to manage the status of books in a library system. 
-- Description: Write a stored procedure that updates the status of a book in the library based on its issuance. 
-- The procedure should function as follows: The stored procedure should take the book_id as an input parameter. 
-- The procedure should first check if the book is available (status = 'yes'). 
-- If the book is available, it should be issued, and the status in the books table should be updated to 'no'. 
-- If the book is not available (status = 'no'), the procedure should return an error message indicating that 
-- the book is currently not available.
CREATE OR REPLACE PROCEDURE issue_book(p_issued_id VARCHAR(10), p_issued_member_id VARCHAR(30), p_issued_book_isbn VARCHAR(30), p_issued_emp_id VARCHAR(10))
LANGUAGE plpgsql
AS $$

DECLARE
-- all the variabable
    v_status VARCHAR(10);

BEGIN
-- all the code
    -- checking if book is available 'yes'
    SELECT 
        status 
        INTO
        v_status
    FROM books
    WHERE isbn = p_issued_book_isbn;

    IF v_status = 'yes' THEN

        INSERT INTO issue_status(issued_id, issued_member_id, issued_date, issued_book_isbn, issued_emp_id)
        VALUES
        (p_issued_id, p_issued_member_id, CURRENT_DATE, p_issued_book_isbn, p_issued_emp_id);

        UPDATE books
            SET status = 'no'
        WHERE isbn = p_issued_book_isbn;

        RAISE NOTICE 'Book records added successfully for book isbn : %', p_issued_book_isbn;


    ELSE
        RAISE NOTICE 'Sorry to inform you the book you have requested is unavailable book_isbn: %', p_issued_book_isbn;
    END IF;
END;
$$

-- Testing The function
SELECT * FROM books;
-- "978-0-553-29698-2" -- yes
-- "978-0-375-41398-8" -- no
SELECT * FROM issued_status;

CALL issue_book('IS155', 'C108', '978-0-553-29698-2', 'E104');
CALL issue_book('IS156', 'C108', '978-0-375-41398-8', 'E104');

SELECT * FROM books
WHERE isbn = '978-0-375-41398-8';

-- Objective: Create a CTAS (Create Table As Select) query to identify overdue books and calculate fines.
-- Description: Write a CTAS query to create a new table that lists each member and the books they have issued 
-- but not returned within 30 days. The table should include: The number of overdue books. 
-- The total fines, with each day's fine calculated at $0.50. The number of books issued by each member. 
-- The resulting table should show: Member ID Number of overdue books Total fines.

SELECT m.member_id, 
	   m.member_name,
	   COUNT(ist.issued_id) AS overdue_book_number, 
	   SUM(DATE('2024-05-01')-ist.issued_date)*0.5 AS total_fine 
FROM issue_status ist
		LEFT JOIN return_status rst 
				ON ist.issued_id = rst.issued_id
		JOIN members m 
				ON ist.issued_member_id = m.member_id
WHERE rst.return_id IS NULL 
		AND ist.issued_date >= DATE('2024-05-01') - INTERVAL '30 days'
GROUP BY m.member_id, m.member_name;

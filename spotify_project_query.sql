-- Sql project on Spotify

-- artist table
alter table artist
add constraint pk_artist_id primary key (artist_id);

-- album table
alter table album
add constraint pk_album_id primary key (album_id);

alter table album
add constraint fk_artist_id foreign key (artist_id) references artist (artist_id);

-- genre table 
alter table genre
add constraint pk_genre_id primary key (genre_id);

-- media_type table
alter table media_type 
add constraint pk_media_type_id primary key (media_type_id);

-- invoice table 
alter table invoice 
add constraint pk_invoice_id primary key (invoice_id);

-- invoice_line table
alter table invoice_line 
add constraint pk_invoice_line_id primary key (invoice_line_id);

-- track table
alter table track
add constraint pk_track_id primary key(track_id);

alter table track 
add constraint fk_album_id foreign key(album_id) references album(album_id);

alter table track
add constraint fk_media_type_id foreign key(media_type_id) references media_type (media_type_id); 

alter table track 
add constraint fk_genre_id foreign key (genre_id) references genre (genre_id);  

-- employee table
alter table employee 
add constraint pk_employee_id primary key (employee_id);

-- customer table
alter table customer 
add constraint pk_customer_id primary key (customer_id);

-- Self-Referencing Foreign Key for Employee (reports_to)
ALTER TABLE employee
ADD CONSTRAINT FK_employee_reports_to 
FOREIGN KEY (reports_to) REFERENCES employee(employee_id);

-- Adding foreign key to customer table from employee table
ALTER TABLE customer
ADD CONSTRAINT FK_customer_support_rep 
FOREIGN KEY (support_rep_id) REFERENCES employee(employee_id);
-- -----------------------------------------------------------

-- table desccription
desc artist;
desc album;
desc genre;
desc media_type;
desc track;
desc customer;
desc employee;
desc invoice;
desc invoice_line;
desc playlist;
desc playlist_track;
-- --------------------

-- Easy Level Questions

# 1. Who is the senior most employee based on job title?
	SELECT 
		CONCAT(first_name, ' ',last_name) AS employee_name ,title
	FROM employee
	ORDER BY title DESC, hire_date ASC
	LIMIT 1;

# 2. Which countries have the most Invoices?
		SELECT 
			billing_country,
            COUNT(*) AS Total_Invoices
        FROM invoice 
        GROUP BY billing_country
        ORDER BY Total_Invoices DESC;
        
# 3. What are top 3 values of total invoice?
	SELECT 
		DISTINCT total as total_invoices,billing_country
	FROM invoice
	ORDER BY total_invoices DESC
	limit 3;
        
# 4. Which city has the best customers? We would like to throw a promotional Music.
		SELECT
			billing_city,
            SUM(total) AS total_invoIce
        FROM invoice
        GROUP BY billing_city
        ORDER BY total_invoice DESC
        LIMIT 5; 
        					
# 5. Who is the best customer? The customer who has spent the most money will be declared the best  customer.
      -- Write a query that returns the person who has spent the most money
      SELECT 
		c.customer_id, 
        c.first_name ,
        c.last_name,
        SUM(inv.total) Total_Expenditure
      FROM customer c
      JOIN invoice inv
      ON c.customer_id = inv.customer_id
      GROUP BY c.customer_id, c.first_name,  c.last_name
      ORDER BY  Total_Expenditure DESC
      LIMIT 1;
-- --------------------------------------------------------------------------------------------------------------
-- Moderate Level Questions:

/* 1. Write query to return the email, first name, last name, & Genre of all Rock Music listeners.
     Return your list ordered alphabetically by email starting with A.    */
	
	    SELECT 
			DISTINCT c.first_name, c.last_name,c.email, g.name AS genre	 
        FROM customer c
			JOIN invoice AS invo ON c.customer_id = invo.customer_id
			JOIN invoice_line AS inline ON inline.invoice_id = invo.invoice_id
			JOIN track AS t ON t.track_id = inline.track_id
			JOIN genre AS g ON g.genre_id = t.genre_id 
		WHERE g.name = 'Rock'
        ORDER BY c.email;

/* 2. Let's invite the artists who have written the most rock music in our dataset. Write a query that
      returns the Artist name and total track count of the top 10 rock bands.  */
		
        SELECT 
			a.artist_id,  
            a.name,
            COUNT(t.track_id) AS track_count,
            g.name AS genre
        FROM artist AS a
        JOIN album AS al ON a.artist_id = al.artist_id
        JOIN track AS t ON t.album_id = al.album_id
        JOIN genre AS g ON g.genre_id = t.genre_id
        WHERE g.name = 'Rock'
        GROUP BY a.artist_id, a.name
        ORDER BY track_count DESC
        LIMIT 10
        ;
            
/* 3. Return all the track names that have a song length longer than the average song length. 
   Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first.      */
      
		SELECT 
			t.name AS track_name,
            t.milliseconds AS track_length,
            (SELECT AVG(milliseconds)  FROM track) ' avg(track lenth) '
		FROM track t
        WHERE t.milliseconds > (SELECT AVG(milliseconds) AS average_lenth FROM track)
        ORDER BY track_length DESC
        ;

-- -----------------------------------------------------------------------------------
-- Advance Level Questions:

/* 1. Find how much amount spent by each customer on artists? Write a query to return customer name, artist name and total spent. */
		
        SELECT
			CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
			ar.name AS artist_name,
            SUM(il.unit_price * il.quantity) AS total_spent
        FROM customer c
        JOIN invoice inv     ON c.customer_id = inv.customer_id
        JOIN invoice_line il ON il.invoice_id = inv.invoice_id
        JOIN track t         ON t.track_id = il.track_id
        JOIN album al        ON al.album_id = t.album_id 
        JOIN artist ar       ON ar.artist_id = al.artist_id 
        GROUP BY customer_name, ar.name
        ORDER BY total_spent DESC;
             
/* 2. We want to find out the most popular music Genre for each country. 
	We determine the most popular genre as the genre with the highest amount of purchases. 
    Write a query that returns each country along with the top Genre. For countries where the maximum number of purchases is shared return all Genres.  */       
     
        WITH popular_genre AS
        (
			SELECT
				inv.billing_country AS country,
                g.name AS genre,
                COUNT(il.quantity) AS total_purchase,
                ROW_NUMBER() OVER (PARTITION BY inv.billing_country ORDER BY COUNT(il.quantity) DESC ) AS rn
            FROM invoice inv
            JOIN invoice_line il ON il.invoice_id = inv.invoice_id
            JOIN track t 	ON t.track_id = il.track_id
            JOIN genre g    ON g.genre_id = t.genre_id
            GROUP BY inv.billing_country,g.name 
            )
        SELECT 
				country,  genre
        FROM popular_genre
        WHERE rn = 1;
        

/* 3. Write a query that determines the customer that has spent the most on music for each country.
	  Write a query that returns the country along with the top customer and how much they spent.
      For countries where the top amount spent is shared, provide all customers who spent this amount.        */
	
	  WITH customer_total_spending AS
	     ( SELECT 
				CONCAT(c.first_name,  ' ',  c.last_name) AS customer, 
                i.billing_country,
                ROUND(SUM(i.total),2) AS total_spent,
				ROW_NUMBER() OVER (PARTITION BY i.billing_country ORDER BY SUM(i.total) DESC) AS rn
           FROM customer c
           JOIN invoice i ON c.customer_id = i.customer_id
           GROUP BY  customer, i.billing_country
          )
		SELECT billing_country, customer, total_spent
		FROM customer_total_spending
		WHERE rn = 1;

use film_rental;
#q1
USE INFORMATION_SCHEMA;
SELECT TABLE_NAME,
       COLUMN_NAME,
       CONSTRAINT_NAME,
       REFERENCED_TABLE_NAME,
       REFERENCED_COLUMN_NAME
FROM information_schema.key_column_usage
WHERE TABLE_SCHEMA = "film_rental" 
      AND TABLE_NAME = "rental" 
      AND REFERENCED_COLUMN_NAME IS NOT NULL;
      
      #q2What are the top 5 categories by average film length, and how do their average lengths compare to the overall average length of films in the database?
       
       select cat.name , avg(f.length) as average_length, avg(f.length)- (select avg(length)from film) as length_difference
       from film f 
       join film_category fc on f.film_id=fc.film_id
       join category cat on cat.category_id= fc.category_id
       group by cat.name 
       order by average_length desc
       limit 5;
     #q3 Which customers have rented films from all categories in the database?  
SELECT c.customer_id, c.first_name, c.last_name
FROM customer c
WHERE NOT EXISTS (
    SELECT DISTINCT cat.category_id
    FROM category cat
    LEFT JOIN (
        SELECT DISTINCT fc.category_id
        FROM film_category fc
        JOIN film f ON fc.film_id = f.film_id
        JOIN inventory i ON f.film_id = i.film_id
        JOIN rental r ON i.inventory_id = r.inventory_id
        WHERE r.customer_id = c.customer_id
    ) AS rented_categories
    ON cat.category_id = rented_categories.category_id
    WHERE rented_categories.category_id IS NULL
);

#q4 What is the average rental duration for films that have been rented by more than 5 customers?
select avg(f.rental_duration) as avg_rental_duration
from film f
join inventory i on f.film_id=i.film_id
join rental r on i.inventory_id = r.inventory_id
join customer c on r.customer_id= c.customer_id
having count(r.customer_id)>5;
#What are the top 3 films in terms of the number of rentals in each store?
(select f.title, f.film_id , s.store_id, count(r.rental_id) as number_of_rentals
from film f
join inventory i on f.film_id=i.film_id
join rental r on i.inventory_id = r.inventory_id
join staff s on r.staff_id= s.staff_id
join store st on st.store_id=s.store_id
group by  s.store_id,  f.film_id
having s.store_id=1
order by number_of_rentals desc
limit 3)
union
(select f.title, f.film_id , s.store_id, count(r.rental_id) as number_of_rentals
from film f
join inventory i on f.film_id=i.film_id
join rental r on i.inventory_id = r.inventory_id
join staff s on r.staff_id= s.staff_id
join store st on st.store_id=s.store_id
group by  s.store_id,  f.film_id
having s.store_id=2
order by number_of_rentals desc
limit 3 );
#6 Which actors have appeared in at least one film from each category?
SELECT a.actor_id, a.first_name, a.last_name
FROM actor a
WHERE NOT EXISTS (
    SELECT DISTINCT c.category_id
    FROM category c
    LEFT JOIN (
        SELECT DISTINCT fc.category_id
        FROM film_category fc
        JOIN film f ON fc.film_id = f.film_id
        JOIN film_actor fa ON f.film_id = fa.film_id
        WHERE fa.actor_id = a.actor_id
    ) AS actor_categories
    ON c.category_id = actor_categories.category_id
    WHERE actor_categories.category_id IS NULL
);
#What are the top 3 countries by the total number of films rented by customers living in those countries?
select c.country, COUNT(r.rental_id) AS number_of_rentals
from country c join city cy ON c.country_id=cy.country_id
join address a on cy.city_id= a.city_id
join customer cu on a.address_id = cu.address_id
join rental r on cu.customer_id = r.customer_id
GROUP by c.country
Order by number_of_rentals desc
limit 3;
#8 What is the total revenue generated from rentals by customers living in cities that start with the letter "S"?
select sum(p.amount) as total_revenue
from payment p
join customer c on p.customer_id = c.customer_id
join address a on c.address_id= a.address_id
join city cy on a.city_id= cy.city_id
where (cy.city like 's%');
#9 What is the percentage of customers who have rented the same film more than once?
select count(g.customer_id)*100/(Select count(distinct customer_id)
from rental) as percentage
from (select r.customer_id, (count(i.film_id)-count(distinct i.film_id)) as watch_frequency
from rental r left join inventory i 
on i.inventory_id = r.inventory_id 
group by r.customer_id)g
where g.watch_frequency>0;
#10 What are the top 5 categories by total revenue, and how do their average revenues compare to the overall average revenue of films in the database? 
select avg(p.amount) as avg_revenue, fc.category_id , avg(p.amount)-(select avg(amount) from payment) as difference
from payment p
join rental r on p. rental_id = r.rental_id
join inventory i on r.inventory_id= i.inventory_id
join film f on i.film_id=f.film_id
join film_category fc on f.film_id=fc.film_id
group by fc.category_id
order by avg_revenue desc
limit 5;
#11 What is the percentage of revenue generated from films in the top 10% of the rental rate range?









#12 What is the total revenue generated from rentals of films broken down by category?
select sum(p.amount) as tot_revenue, fc.category_id 
from payment p
join rental r on p. rental_id = r.rental_id
join inventory i on r.inventory_id= i.inventory_id
join film f on i.film_id=f.film_id
join film_category fc on f.film_id=fc.film_id
group by fc.category_id;

#13 How many distinct customers have rented films with a rental rate higher than the overall average rental rate in the "Sci-Fi" category?
select count(distinct customer_id) from rental r
join inventory i on r.inventory_id= i.inventory_id
join film f on i.film_id=f.film_id
join film_category fc on f.film_id= fc.film_id
join category c on fc.category_id= c.category_id
where rental_rate > (select avg(rental_rate) 
from rental r 
join inventory i on r.inventory_id= i.inventory_id
join film f on i.film_id=f.film_id
join film_category fc on f.film_id= fc.film_id
join category c on fc.category_id= c.category_id
where c.name= "Sci-Fi");

#14 What is the average rental rate of the top 3 most popular films in terms of the number of rentals, broken down by category and language?
 SELECT 
    AVG(f.rental_rate) AS avg_rental_rate,
    COUNT(r.rental_id) AS number_of_rentals,
    fc.category_id,
    f.language_id,
    f.title,
    f.film_id
FROM
    rental r
        JOIN
    inventory i ON r.inventory_id = i.inventory_id
        JOIN
    film f ON i.film_id = f.film_id
        JOIN
    film_category fc ON f.film_id = fc.film_id
GROUP BY fc.category_id , f.film_id
ORDER BY number_of_rentals DESC
LIMIT 3;
#15 Which category has the highest average rental rate for films with a duration longer 
# than the overall average duration of films in that category? Here duration means the length of the film.
SELECT
    cat.name AS category,
    AVG(f.rental_rate) AS avg_rental_rate
FROM film f
JOIN film_category fc ON f.film_id = fc.film_id
JOIN category cat ON fc.category_id = cat.category_id
WHERE f.length > (
    SELECT AVG(length)
    FROM film
    WHERE fc.category_id = cat.category_id
)
GROUP BY cat.category_id
ORDER BY avg_rental_rate DESC
LIMIT 1;
#16 What is the total amount of late fees paid by customers who have rented more than 10 films in the database?
select sum((datediff(return_date, rental_date) - rental_duration) * rental_rate) as a
from rental r left join inventory i 
on i.inventory_id = r.inventory_id left join film f
on f.film_id = i.film_id
where r.customer_id in (select customer_id
        from rental
        group by customer_id
        having count(rental_id) > 10) and 
        datediff(return_date, rental_date) > f.rental_duration ;
#17 Create a View for the total revenue generated by each staff member, broken down by store city with the country name?
select r.customer_id, count(f.film_id)
from film f inner join inventory i 
on f.film_id = i.film_id
inner join rental r
on i.inventory_id = r.inventory_id
group by r.customer_id having count(f.film_id) > 10 
order by count(f.film_id);
create view T_R as
select p.staff_id, sum(p.amount) as tot_revenue, c.city, co.country
from payment p left join staff s 
on p.staff_id = s.staff_id
left join address a 
on s.address_id = a.address_id
left join city c 
on a.city_id = c.city_id 
left join country co
on c.country_id = co.country_id
group by p.staff_id;
select * from T_R;

#19 Display the customers who paid 50% of their total rental costs within one day
Select
    c.first_name,
    c.last_name,
    (p.amount / (DATEDIFF(r.return_date, r.rental_date) * f.rental_rate)) * 100 as amount
FROM
    customer c left join payment p
on p.customer_id = c.customer_id left join rental r
on p.rental_id = r.rental_id left join inventory i
on i.inventory_id = r.inventory_id left join film f
on f.film_id = i.film_id
where
    DATEDIFF(r.return_date, p.payment_date) > 0
    and (p.amount / (DATEDIFF(r.return_date, r.rental_date) * f.rental_rate)) * 100 = 50.0
limit 2;

#11
SELECT
    ROUND(
        (SUM(p.amount) / (SELECT SUM(amount) FROM payment)) * 100,
        2
    ) AS percentage_revenue
FROM payment p
JOIN rental r ON p.rental_id = r.rental_id
JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN film f ON i.film_id = f.film_id
WHERE f.rental_rate >= (
    SELECT rental_rate
    FROM (
        SELECT rental_rate, ROW_NUMBER() OVER (ORDER BY rental_rate DESC) AS row_num
        FROM film
    ) AS ranked_films
    WHERE row_num = FLOOR(0.1 * (SELECT COUNT(*) FROM film))
);


#18 Create a view based on rental information consisting of visiting_day, customer_name, title of film, no_of_rental_days, amount paid by the customer along with percentage of customer spending. Here “percentage of customer spending” means: Cumulative distribution of the customer payment amount(history)
CREATE VIEW rental_summary AS
SELECT
    DATE(r.rental_date) AS visiting_day,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    f.title AS film_title,
    DATEDIFF(r.return_date, r.rental_date) AS no_of_rental_days,
    p.amount AS amount_paid,
    ROUND(
        (SUM(p.amount) OVER (PARTITION BY c.customer_id ORDER BY p.payment_date ASC) / 
         SUM(p.amount) OVER (PARTITION BY c.customer_id) * 100),
        2
    ) AS percentage_of_spending
FROM rental r
JOIN customer c ON r.customer_id = c.customer_id
JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN film f ON i.film_id = f.film_id
LEFT JOIN payment p ON r.rental_id = p.rental_id;
select * from rental_summary 

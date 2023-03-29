CREATE SCHEMA IF NOT EXISTS reporting;

CREATE OR REPLACE VIEW reporting.flight AS
SELECT *,
    CASE
           WHEN flight.dep_delay_new > 0 THEN 1
           ELSE 0
       END AS is_delayed
	
FROM
    flight
WHERE
    flight.cancelled = 0;

CREATE OR REPLACE VIEW reporting.top_reliability_roads
 AS
 SELECT f.origin_airport_id,
    al1.name AS origin_airport_name,
    f.dest_airport_id,
    al2.name AS dest_airport_name,
    f.year,
    count(*) AS cnt,
    round(avg(
        CASE
            WHEN f.dep_delay_new > 0::double precision THEN 1
            ELSE 0
        END), 2) AS reliability,
    rank() OVER (ORDER BY (avg(
        CASE
            WHEN f.dep_delay_new > 0::double precision THEN 1
            ELSE 0
        END)) DESC) AS nb
   FROM flight f
     JOIN airport_list al1 ON f.origin_airport_id = al1.origin_airport_id
     JOIN airport_list al2 ON f.dest_airport_id = al2.origin_airport_id
  GROUP BY f.origin_airport_id, al1.name, f.dest_airport_id, al2.name, f.year
 HAVING count(*) > 10000
  ORDER BY (count(*)) DESC;
CREATE OR REPLACE VIEW reporting.year_to_year_comparision AS
select 
year,
month,
count(*) as flights_amount,
round(avg(
        CASE
            WHEN dep_delay_new > 0::double precision THEN 1
            ELSE 0
        END), 2) AS reliability
from flight 
group by year,month
ORDER BY year,month;
CREATE OR REPLACE VIEW reporting.day_to_day_comparision AS
select 
year, 
day_of_week,
count(*) as flights_amount
from flight
group by year, day_of_week 
order by year, day_of_week;

CREATE OR REPLACE VIEW reporting.day_by_day_reliability AS
SELECT
    TO_DATE(CONCAT(year, '-', month, '-', day_of_month), 'YYYY-MM-DD') AS date,
    ROUND(AVG(CASE WHEN dep_delay_new > 0 THEN 1 ELSE 0 END)::NUMERIC, 2) AS reliability
FROM flight AS f
GROUP BY year, month, day_of_month
ORDER BY date
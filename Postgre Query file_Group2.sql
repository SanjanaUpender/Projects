-- 1
SELECT EXTRACT(YEAR FROM e.start_date) AS event_year,MAX(e.total_cost) AS max_total_cost
FROM event_details e
GROUP BY event_year
HAVING EXTRACT(YEAR FROM e.start_date) > 2017
ORDER BY event_year;

--2
WITH event_time_buckets AS
  (SELECT event_id, total_cost,
   CASE
   WHEN start_date < '2020-03-01' THEN 'pre-covid'
   WHEN start_date >= '2020-04-01' AND start_date <= '2022-04-30' THEN 'during-covid'        
   WHEN start_date > '2022-05-01' THEN 'post-covid'
   ELSE NULL
   END AS time_bucket
FROM event_details) 
SELECT time_bucket, COUNT(event_id) AS event_count,
ROUND(SUM(CAST(total_cost AS numeric)), 2) AS total_cost_in_bucket FROM event_time_buckets 
WHERE time_bucket IS NOT NULL 
GROUP BY time_bucket
ORDER BY time_bucket;  

--3 
SELECT ed.event_description, ad.employee_attendees 
FROM event_details ed 
JOIN attendees_details ad ON ed.event_id = ad.event_id 
WHERE ed.start_date < CURRENT_DATE 
GROUP BY ed.event_description, ad.employee_attendees 
HAVING SUM(ad.employee_attendees) > 400;

--4
SELECT EXTRACT(YEAR FROM start_date) AS event_year,    
CASE
WHEN EXTRACT(MONTH FROM start_date) BETWEEN 1 AND 3 THEN 'Q1'         
WHEN EXTRACT(MONTH FROM start_date) BETWEEN 4 AND 6 THEN 'Q2'         
WHEN EXTRACT(MONTH FROM start_date) BETWEEN 7 AND 9 THEN 'Q3'         
WHEN EXTRACT(MONTH FROM start_date) BETWEEN 10 AND 12 THEN 'Q4'     
END AS event_quarter,    
COUNT(event_id) AS num_events, 
ROUND(SUM(CAST(total_cost AS numeric)), 2) AS total_cost
FROM public.event_details
WHERE EXTRACT(YEAR FROM start_date) IN (2016, 2022) 
GROUP BY event_year, event_quarter 
ORDER BY     event_year, event_quarter; 
 
--5
WITH CTE AS (
SELECT event_location,
(CASE WHEN total_cost BETWEEN 1 AND 4999 THEN 'low'
      WHEN total_cost BETWEEN 5000 AND 9999 THEN 'medium'
      WHEN total_cost BETWEEN 10000 AND 14999 THEN 'high'
      WHEN total_cost BETWEEN 15000 AND 20000 THEN 'very high'
      End)  as cost_category 
 FROM event_details)
SELECT event_location, cost_category
FROM CTE
WHERE cost_category LIKE '%high'
ORDER BY cost_category DESC;

--6
SELECT ed.event_id, ed.total_cost, ad.event_officer_name, round (avg (ad.guest_attendees))as gst_attd,
round (avg (ad.employee_attendees))as emp_attd
FROM public.event_details ed
JOIN public.attendees_details ad ON ed.event_id = ad.event_id
WHERE  ad.guest_attendees = 0 and ad.employee_attendees = 0 and ed.total_cost > 50
group by  ed.event_id, ad.event_officer_name;

--7
SELECT disclosure_id, disclosure_group, event_count, round (total_cost),
RANK() OVER (ORDER BY total_cost DESC) AS cost_rank
FROM 
(SELECT dg.disclosure_id, dg.disclosure_group, COUNT(ed.event_id) AS event_count, SUM(ed.total_cost) AS total_cost
FROM public.disclosure_group_details dg
LEFT JOIN public.event_details ed ON dg.disclosure_id = ed.disclosure_id
GROUP BY dg.disclosure_id, dg.disclosure_group) AS grouped_data;

--8
SELECT ed.event_id, ed.event_description, ed.start_date, ed.end_date
FROM public.event_details ed
JOIN public.org_owner oo ON ed.disclosure_id = oo.disclosure_id
WHERE oo.owner_org = 'atssc scdata' 
AND ed.start_date >= CURRENT_DATE - INTERVAL '6 months'
AND ed.start_date <= CURRENT_DATE;

--9
SELECT event_id,event_location,total_cost,disclosure_id,officer_title
FROM public.event_details
WHERE total_cost >= (SELECT 15 * AVG(total_cost)
FROM public.event_details);

--10
WITH OfficerAttendeeTotals AS (
    SELECT event_officer_name, SUM(employee_attendees) + SUM(guest_attendees) AS total_attendees
    FROM attendees_details
    GROUP BY event_officer_name
	HAVING SUM(employee_attendees) + SUM(guest_attendees) > 500)
SELECT event_officer_name, total_attendees 
FROM OfficerAttendeeTotals;


Drop database if exists wind_scada_project;

CREATE DATABASE wind_scada_project;

USE wind_scada_project;

drop table if exists wind_scada_raw;

CREATE TABLE wind_scada_raw(
	timestamp_text varchar(100),
	actual_power_kw double,
	wind_speed double,
	theoretical_power_kw double,
	wind_direction double
	);

show tables;

Select *
FROM wind_scada_raw
LIMIT 10;

CREATE or REPLACE VIEW wind_scada_cleaned AS
SELECT 
	STR_TO_DATE(timestamp_text, '%d %m %Y %H:%i ') AS reading_timestamp,
	CAST(actual_power_kw AS DECIMAL(12,2)) AS actual_power_kw,
	CAST(wind_speed AS DECIMAL(12,2)) AS wind_speed,
	CAST(theoretical_power_kw AS DECIMAL(12,2)) AS theoretical_power_kw,
	CAST(wind_direction AS DECIMAL(10,2)) AS wind_direction
FROM wind_scada_raw;	

SELECT *
FROM wind_scada_cleaned;

CREATE OR REPLACE VIEW wind_scada_analysis AS
SELECT
	reading_timestamp,
	DATE(reading_timestamp) AS reading_date,
	MONTH(reading_timestamp) AS reading_month,
	YEAR(reading_timestamp) AS reading_year,
	HOUR(reading_timestamp) AS reading_hour,
	DAYNAME(reading_timestamp) AS day_name,
	MONTHNAME(reading_timestamp) AS month_name,
	actual_power_kw,
	wind_speed,
	theoretical_power_kw,
	wind_direction,
	
	theoretical_power_kw - actual_power_kw AS power_loss_kw,
	
	ROUND(
	CASE
		WHEN theoretical_power_kw = 0 THEN NULL
		ELSE actual_power_kw / theoretical_power_kw * 100
	END,
	2
	) AS effeciency_percentage,
	
	CASE
		WHEN wind_speed < 3 THEN 'Low Wind'
		WHEN wind_speed >= 3 AND wind_speed < 12 THEN 'Optimal Wind'
		ELSE 'High Wind'
	END AS wind_category,
	
	CASE
		WHEN actual_power_kw < theoretical_power_kw * 0.7 AND wind_speed > 3 
		THEN 'Underperforming'
		ELSE 'Normal'
	END AS performance_status,
	
	CASE 
		WHEN wind_speed < 3 THEN '0-3'
		WHEN wind_speed < 6 THEN '3-6'
		WHEN wind_speed < 9 THEN '6-9'
		WHEN wind_speed < 12 THEN '9-12'
		WHEN wind_speed < 15 THEN '12-15'
		ELSE '15+'
	END AS wind_speed_bin
	
FROM wind_scada_cleaned
WHERE reading_timestamp IS NOT NULL 
AND actual_power_kw >= 0
AND wind_speed >=0
AND theoretical_power_kw >=0;


SELECT * 
FROM wind_scada_analysis;

CREATE OR REPLACE VIEW wind_scada_monthly_performance AS
SELECT
	reading_month,
	month_name,
	reading_year,
	SUM(actual_power_kw) AS total_actual_power,
	SUM(theoretical_power_kw) AS total_theoretical_power,
	SUM(power_loss_kw) AS total_power_loss,
	AVG(wind_speed) AS average_wind_speed,
	AVG(effeciency_percentage) AS average_effeciency
FROM wind_scada_analysis
GROUP BY reading_year, reading_month, month_name;


SELECT *
FROM wind_scada_monthly_performance;

CREATE OR REPLACE VIEW wind_category_summary AS
SELECT
	wind_category,
	COUNT(*) AS total_records,
	SUM(actual_power_kw) AS total_actual_power,
	SUM(theoretical_power_kw) AS total_theoretical_power,
	SUM(power_loss_kw) AS total_power_loss,
	AVG(effeciency_percentage) AS average_effeciency
FROM wind_scada_analysis
GROUP BY wind_category;

SELECT *
FROM wind_category_summary;

	
	
	
	




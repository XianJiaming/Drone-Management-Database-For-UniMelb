--5.3.1

WITH flight AS (
SELECT ST_SetSRID(ST_GeomFromText('LINESTRING Z (144.87103558763067 -37.67814707715162 120, 144.8667137848033 -37.67929871348155 118, 
								  144.8720120519403 -37.671311422147866 123, 144.87440408410174 -37.6748647958145 130, 
								  144.87103558763067 -37.67814707715162 120)'), 4326) AS geom
)
SELECT *
FROM group22.public_places AS p, flight AS f
WHERE ST_Intersects(p.geom, ST_transform(f.geom, 7855));

--5.3.2 

SELECT d.d_id,
B.b_id,
S.s_id,
 d.max_payload, 
 -- Two decimal places are retained to ensure accuracy
 ROUND((COALESCE(SUM(B.weight), 0) + COALESCE(SUM(S.weight), 
0))::numeric, 2) AS TotalWeight,
 -- Check that the total weight of the batteries and sensors does not exceed the maximum load of the drone
 CASE 
 WHEN d.max_payload >= (COALESCE(SUM(B.weight), 0) + 
COALESCE(SUM(S.weight), 0)) THEN 'Within Payload Limit' 
 ELSE 'Exceeds Payload Limit'
 END AS PayloadStatus
FROM group22.drone AS d
LEFT JOIN group22.battery AS B ON d.d_id = B.drone_id
LEFT JOIN group22.sensor AS S ON d.d_id = S.drone_id
WHERE d.max_payload IS NOT NULL --Ignore maximum loads with NULL values
GROUP BY d.d_id, d.max_payload,B.b_id,S.s_id
ORDER BY d.d_id;

-- 5.3.3

WITH flight AS (
SELECT ST_SetSRID(ST_GeomFromText('LINESTRING Z (144.87103558763067 -37.67814707715162 120, 144.8667137848033 -37.67929871348155 118, 
								  144.8720120519403 -37.671311422147866 123, 144.87440408410174 -37.6748647958145 130, 
								  144.87103558763067 -37.67814707715162 120)'), 4326) AS geom
)
SELECT b.power * 4.96 AS max_meters, ST_Length(ST_Transform(f.geom, 
7855)) AS flight_meters
FROM group22.battery AS b, flight AS f
WHERE b_id = 4;


-- 5.3.4

WITH flight AS (
SELECT ST_SetSRID(ST_GeomFromText('LINESTRING Z (144.87103558763067 -37.67814707715162 120, 144.8667137848033 -37.67929871348155 118, 
								  144.8720120519403 -37.671311422147866 123, 144.87440408410174 -37.6748647958145 130, 
								  144.87103558763067 -37.67814707715162 120)'), 4326) AS geom
)
, takeoff_point AS (
 SELECT ST_StartPoint(flight.geom) AS geom FROM flight
)
SELECT ST_DWithin(ST_Transform(p.geom, 7855), ST_Transform(f.geom, 
7855), 600) AS within_600m
FROM flight AS f, takeoff_point AS p;


-- 5.3.5

WITH flight AS (
SELECT ST_SetSRID(ST_GeomFromText('LINESTRING Z (144.87103558763067 -37.67814707715162 120, 144.8667137848033 -37.67929871348155 118, 
								  144.8720120519403 -37.671311422147866 123, 144.87440408410174 -37.6748647958145 130, 
								  144.87103558763067 -37.67814707715162 120)'), 4326) AS geom
), points AS (
 SELECT (ST_DumpPoints(f.geom)).geom AS point
 FROM flight AS f
), max_altitude AS (
SELECT ST_Z(p.point) - ST_Value(v.rast, ST_Transform(p.point, 7855)) 
AS max_above_ground_level_meters
FROM points AS p, spatial.victoria_dem_30m AS v
WHERE ST_Intersects(ST_Transform(p.point, 7855), v.rast)
ORDER BY ST_Z(p.point) DESC
LIMIT 1
), min_altitude AS (
SELECT ST_Z(p.point) - ST_Value(v.rast, ST_Transform(p.point, 7855)) 
AS min_above_ground_level_meters
FROM points AS p, spatial.victoria_dem_30m AS v
WHERE ST_Intersects(ST_Transform(p.point, 7855), v.rast)
ORDER BY ST_Z(p.point) ASC
LIMIT 1
)
SELECT min_altitude.min_above_ground_level_meters, 
max_altitude.max_above_ground_level_meters
FROM min_altitude, max_altitude;

--5.3.6

SELECT CASE
 WHEN latest_end_time.endtime < '2023-05-05 12:00:00' THEN 'Available'
 ELSE 'Not Available'
END AS Operator_is_available
FROM (
 SELECT endtime
 FROM group22.flight_history
 WHERE operator_id = 1
ORDER BY endtime DESC
 LIMIT 1
) AS latest_end_time;

--5.3.7

SELECT 
 f.fh_id,
 f.operator_id,
o.name,
 o.licence,
 CASE
 -- If the operator has a licence (licence_status = 'Y'), then the flight is always valid in anywhere
 WHEN o.licence = 'Y' THEN 'Valid Flight anywhere'
 -- If the operator does not have a licence but the flight path is within the Parkville campus, 
-- then the flight is valid but only on campus
 WHEN ST_Contains(uc.geom, ST_Transform(f.path, 7899)) THEN 'Valid Flight only on campus'
 --In all other cases, the flight is not valid
 ELSE 'Invalid Flight'
 END AS FlightStatus
FROM 
 group22.flight_history AS f,
 spatial.unimelb_campus AS uc,
 group22.operator AS o
WHERE 
f.operator_id = o.o_id AND
 uc.campus = 'Parkville'
group by 
f.fh_id,
f.operator_id,
o.name, 
o.licence, 
FlightStatus;


--5.3.8

select * from group22.operator;

--5.3.9

select * from group22.operator
WHERE licence = true and last_train_date <= NOW() - INTERVAL '1' Year and 
total_flight_time< INTERVAL '50' Hour ;


--5.3.10
--battery

select * from group22.battery
WHERE battery.manufacture_date <= NOW() - INTERVAL '2' Year;

--sensor

select * from group22.sensor
WHERE calibration_date <= NOW() - INTERVAL '1' Year;


--5.3.11

select * from group22.flight_history;


--5.3.12
--part 1

WITH flight AS (
 SELECT ST_SetSRID(ST_GeomFromText('LINESTRING 
Z(144.98241409006857 -37.76301660954355 130,
144.98204232805682 -37.76263934715726 130,
144.98269314028826 -37.76231143646494 130,
144.98324064707032 -37.76202450861073 130,
144.9837468670509 -37.761581769551164 130,
144.98449055789516 -37.76157366788137 130,
144.9849140311435 -37.761655723528946 130,
144.9849448891796 -37.76230354014615 130,
144.9852236245759 -37.763074389754344 130,
144.98526484393165 -37.7635746043922 130,
144.98515111864668 -37.764099400292274 130,
144.98430414516974 -37.76393528933462 130,
144.98342625935595 -37.763443161878804 130,
144.982889153999 -37.763369285034 130,
144.98241409006857 -37.76301660954355 130)'), 4326) 
AS geom
), start_point_on_road AS (
SELECT v.id
FROM spatial.victoria_roads2023_vertices_pgr AS v, flight AS f
ORDER BY ST_Transform(ST_StartPoint(f.geom), 7855) <-> 
ST_Transform(v.the_geom, 7855) ASC
LIMIT 1
), nearest_3_hotels AS (
SELECT h.name, h.geom
FROM group22.hotel AS h, flight AS f
ORDER BY ST_Transform(ST_StartPoint(f.geom), 7855) <-> h.geom 
ASC
LIMIT 3
) 
SELECT nearest_3_hotels.name, nearest_3_hotels.geom
FROM nearest_3_hotels;

-- Search the shortest paths to the three nearest hotels from the flight start point

WITH flight AS (
 SELECT ST_SetSRID(ST_GeomFromText('LINESTRING 
Z(144.98241409006857 -37.76301660954355 130,
144.98204232805682 -37.76263934715726 130,
144.98269314028826 -37.76231143646494 130,
144.98324064707032 -37.76202450861073 130,
144.9837468670509 -37.761581769551164 130,
144.98449055789516 -37.76157366788137 130,
144.9849140311435 -37.761655723528946 130,
144.9849448891796 -37.76230354014615 130,
144.9852236245759 -37.763074389754344 130,
144.98526484393165 -37.7635746043922 130,
144.98515111864668 -37.764099400292274 130,
144.98430414516974 -37.76393528933462 130,
144.98342625935595 -37.763443161878804 130,
144.982889153999 -37.763369285034 130,
144.98241409006857 -37.76301660954355 130)'), 4326) 
AS geom
), start_point_on_road AS (
SELECT v.id
FROM spatial.victoria_roads2023_vertices_pgr AS v, flight AS f
ORDER BY ST_Transform(ST_StartPoint(f.geom), 7855) <-> 
ST_Transform(v.the_geom, 7855) ASC
LIMIT 1
), nearest_3_hotels AS (
SELECT h.name, h.geom
FROM group22.hotel AS h, flight AS f
ORDER BY ST_Transform(ST_StartPoint(f.geom), 7855) <-> h.geom 
ASC
LIMIT 3
), hotel_points_on_road AS ( 
SELECT points.id AS id 
FROM nearest_3_hotels AS h 
CROSS JOIN LATERAL ( 
SELECT v.id, st_transform(v.the_geom, 7855) as geom 
FROM spatial.victoria_roads2023_vertices_pgr AS v 
ORDER BY h.geom <-> ST_Transform(v.the_geom, 7855) ASC
LIMIT 1) 
AS points 
), shortest_path AS ( 
SELECT * 
FROM pgr_dijkstra( 
'select "OBJECTID" as id, source, target, 
ST_length(st_transform(geom, 7855)) as cost from spatial.victoria_roads2023', 
(SELECT id FROM start_point_on_road), 
ARRAY(SELECT id FROM hotel_points_on_road),
false
) 
) 
SELECT r."OBJECTID" AS id, st_transform(r.geom, 7855) AS geom 
FROM spatial.victoria_roads2023 AS r, shortest_path AS p 
WHERE p.edge = r."OBJECTID";


--Part 2: Search the one nearest emergency from the flight start point

WITH flight AS (
 SELECT ST_SetSRID(ST_GeomFromText('LINESTRING 
Z(144.98241409006857 -37.76301660954355 130,
144.98204232805682 -37.76263934715726 130,
144.98269314028826 -37.76231143646494 130,
144.98324064707032 -37.76202450861073 130,
144.9837468670509 -37.761581769551164 130,
144.98449055789516 -37.76157366788137 130,
144.9849140311435 -37.761655723528946 130,
144.9849448891796 -37.76230354014615 130,
144.9852236245759 -37.763074389754344 130,
144.98526484393165 -37.7635746043922 130,
144.98515111864668 -37.764099400292274 130,
144.98430414516974 -37.76393528933462 130,
144.98342625935595 -37.763443161878804 130,
144.982889153999 -37.763369285034 130,
144.98241409006857 -37.76301660954355 130)'), 4326) 
AS geom
), start_point_on_road AS (
SELECT v.id
FROM spatial.victoria_roads2023_vertices_pgr AS v, flight AS f
ORDER BY ST_Transform(ST_StartPoint(f.geom), 7855) <-> 
ST_Transform(v.the_geom, 7855) ASC
LIMIT 1
), nearest_1_emergency AS (
SELECT e.name, e.geom
FROM group22.emergency AS e, flight AS f
ORDER BY ST_Transform(ST_StartPoint(f.geom), 7855) <-> e.geom 
ASC
LIMIT 1
)
SELECT nearest_1_emergency.name, nearest_1_emergency.geom
FROM nearest_1_emergency;


--Search the shortest paths to the one nearest emergency from the flight start point.

WITH flight AS (
 SELECT ST_SetSRID(ST_GeomFromText('LINESTRING 
Z(144.98241409006857 -37.76301660954355 130,
144.98204232805682 -37.76263934715726 130,
144.98269314028826 -37.76231143646494 130,
144.98324064707032 -37.76202450861073 130,
144.9837468670509 -37.761581769551164 130,
144.98449055789516 -37.76157366788137 130,
144.9849140311435 -37.761655723528946 130,
144.9849448891796 -37.76230354014615 130,
144.9852236245759 -37.763074389754344 130,
144.98526484393165 -37.7635746043922 130,
144.98515111864668 -37.764099400292274 130,
144.98430414516974 -37.76393528933462 130,
144.98342625935595 -37.763443161878804 130,
144.982889153999 -37.763369285034 130,
144.98241409006857 -37.76301660954355 130)'), 4326) 
AS geom
), start_point_on_road AS (
SELECT v.id
FROM spatial.victoria_roads2023_vertices_pgr AS v, flight AS f
ORDER BY ST_Transform(ST_StartPoint(f.geom), 7855) <-> 
ST_Transform(v.the_geom, 7855) ASC
LIMIT 1
), nearest_1_emergency AS (
SELECT e.name, e.geom
FROM group22.emergency AS e, flight AS f
ORDER BY ST_Transform(ST_StartPoint(f.geom), 7855) <-> e.geom 
ASC
LIMIT 1
), emergency_point_on_road AS ( 
SELECT points.id AS id 
FROM nearest_1_emergency AS e 
CROSS JOIN LATERAL ( 
SELECT v.id, st_transform(v.the_geom, 7855) as geom 
FROM spatial.victoria_roads2023_vertices_pgr AS v 
ORDER BY e.geom <-> ST_Transform(v.the_geom, 7855) ASC
LIMIT 1) 
AS points 
), shortest_path AS ( 
SELECT * 
FROM pgr_dijkstra( 
'select "OBJECTID" as id, source, target, 
ST_length(st_transform(geom, 7855)) as cost from spatial.victoria_roads2023', 
(SELECT id FROM start_point_on_road), 
ARRAY(SELECT id FROM emergency_point_on_road),
false
) 
) 
SELECT r."OBJECTID" AS id, st_transform(r.geom, 7855) AS geom 
FROM spatial.victoria_roads2023 AS r, shortest_path AS p 
WHERE p.edge = r."OBJECTID";


--5.3.13

WITH centralpoint AS (
SELECT ST_PointOnSurface(ST_Union(st_transform(geom,7855))) AS geom 
FROM spatial.unimelb_campus 
WHERE campus = 'Parkville'
), central_nearest_point_on_road as (
SELECT v.id as id, st_transform(v.the_geom,7855) as geom
FROM centralpoint AS c, spatial.victoria_roads2023_vertices_pgr AS v
ORDER BY ST_Distance(c.geom, st_transform(v.the_geom,7855))
LIMIT 1
), flight_start_point as (
select st_startpoint(geom) as geom from group22.demo_flight_path
), nearest_point_on_road as (
select v.id as id, st_transform(v.the_geom, 7855) as geom
from flight_start_point as p, spatial.victoria_roads2023_vertices_pgr as v
order by st_distance(p.geom, st_transform(v.the_geom, 7855))
limit 1
), paths as (
select * from pgr_dijkstra(
'select "OBJECTID" as id, source, target, st_length(st_transform(geom,7855)) as 
cost from spatial.victoria_roads2023',
(SELECT id FROM central_nearest_point_on_road),
(SELECT id FROM nearest_point_on_road),
false
)
)
select st_transform(r.geom, 7855) as geom
from spatial.victoria_roads2023 as r, paths as p
WHERE p.edge = r."OBJECTID";

--5.3.14

select * from group22.sensor;
Select * from group22.drone;
select * from group22.battery;


--5.3.15

SELECT
 CASE
 -- Assuming that the drone can fly during daylight hours of 6:00 to 17:00
 WHEN EXTRACT(HOUR FROM NOW()) BETWEEN 6 AND 17 THEN 'Can Fly'
 ELSE 'Cannot Fly'
 END AS CanFlyStatus;
 

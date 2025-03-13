-- 01 СТРУКТУРА БАЗЫ ДАННЫХ
-- Получить схемы и таблицы
SELECT schemaname, tablename, tableowner
FROM pg_catalog.pg_tables
WHERE
    schemaname != 'pg_catalog' AND
    schemaname != 'information_schema';

-- 02 ПОДЗАПРОСЫ
-- Выбрать номера билетов стоимость которых выше среднего
SELECT AVG(amount)
FROM ticket_flights tf;

-- 03
-- Применим фильтрацию по среднему значению
SELECT *
FROM ticket_flights tf
WHERE amount > (
    SELECT AVG(amount)
    FROM ticket_flights tf
)
LIMIT 10;

-- 04 EXISTS
-- Выведем бронирования и их даты если стоимость бронирования более 100,000
SELECT b.book_ref, b.book_date
FROM bookings b
WHERE EXISTS (
	SELECT *
	FROM tickets t
	WHERE b.book_ref = t.book_ref AND b.total_amount > 100000
)
ORDER BY b.book_ref
LIMIT 10;

-- 05
-- То же через join
SELECT DISTINCT b.*
FROM bookings b
    INNER JOIN tickets t
      ON b.book_ref = t.book_ref
WHERE b.total_amount > 100000
ORDER BY b.book_ref
LIMIT 10;

-- 06
-- Найти рейсы на которых были билеты бизнес-класса
SELECT DISTINCT aircraft_code
FROM seats s
WHERE fare_conditions = 'Business';

-- 07
-- Объединим с таблицей полетов
SELECT flight_no, aircraft_code
FROM flights f
WHERE aircraft_code IN (
    SELECT DISTINCT aircraft_code
    FROM seats s
    WHERE fare_conditions = 'Business'
);

-- 08
-- Выборка мест на Boeing
SELECT *
FROM seats s
WHERE aircraft_code IN (
    SELECT aircraft_code
    FROM aircrafts a
    WHERE model LIKE 'Boeing%'
)
ORDER BY aircraft_code
LIMIT 10;

-- 09 JOIN
-- Получить номера билетов, которые были проданы пассажиру Vladimir с 1 по 6 июня 2017 года
SELECT t.ticket_no, t.passenger_name, b.book_date
FROM tickets t
    JOIN bookings b
        ON t.book_ref = b.book_ref
        AND b.book_date >= '2017-06-01'
        AND b.book_date <= '2017-06-07'
        AND t.passenger_name LIKE '%VLADIMIR%'
ORDER BY b.book_date
LIMIT 10;

-- 10
-- Получить посадочные места, проданные Vladimir'у в бизнес-класс на рейсы из Москвы в период с 1 по 5 июня 2017 года
SELECT *
FROM airports
LIMIT 10;

-- 11 JSON
-- Получим коды московских аэропортов
SELECT ad.airport_code, *
FROM airports ad
WHERE ad.city @> '{"en": "Moscow"}'  -- распаковка json
LIMIT 10;

-- 12
-- Альтернативный способ распаковки JSON
SELECT ad.airport_code, *
FROM airports_data ad
WHERE ad.city ->> 'en'='Moscow'  -- распаковка json
LIMIT 10;

SELECT t.contact_data
FROM tickets t
LIMIT 10;

-- 13
-- Получить города
SELECT a.city
FROM airports a;

-- 14
-- Получим все рейсы вылетающие из Москвы
SELECT DISTINCT f.flight_no, f.departure_airport AS airport_code
FROM flights f
    JOIN airports_data ad
      ON f.departure_airport = ad.airport_code
WHERE f.departure_airport IN (
    SELECT ad.airport_code
    FROM airports_data ad
    WHERE ad.city @> '{"en": "Moscow"}' -- распаковка json
)
ORDER BY f.flight_no
LIMIT 10;

-- 15
-- Альтернативный способ получения рейсов из Москвы
SELECT DISTINCT f.flight_no, f.departure_airport AS airport_code
FROM flights f
    INNER JOIN airports a
        ON f.departure_airport = a.airport_code
        AND a.city = 'Moscow'
ORDER BY f.flight_no
LIMIT 10;

-- 16
-- Получим все рейсы из Москвы с бизнес-классом
SELECT DISTINCT f.flight_no, f.status, tf.fare_conditions
FROM flights f
    JOIN airports_data ad
        ON f.departure_airport = ad.airport_code
    JOIN ticket_flights tf
        ON f.flight_id = tf.flight_id
WHERE f.departure_airport IN (
    SELECT ad.airport_code
    FROM airports_data ad
    WHERE ad.city @> '{"en": "Moscow"}'
)
AND tf.fare_conditions = 'Business'
LIMIT 10;

-- 17
-- Итоговая конструкция с несколькими JOIN
SELECT
    bp.seat_no,
	tf.fare_conditions,
	t.passenger_name,
	f.scheduled_departure,
	f.departure_airport,
	f.arrival_airport
FROM boarding_passes bp
    JOIN ticket_flights tf
        ON bp.ticket_no = tf.ticket_no
    JOIN tickets t
        ON tf.ticket_no = t.ticket_no
    JOIN flights f
        ON tf.flight_id = f.flight_id
WHERE tf.fare_conditions = 'Business'
	AND t.passenger_name LIKE '%VLADIMIR%'
	AND f.scheduled_departure >= '2017-06-01'
	AND f.scheduled_departure <= '2017-06-06'
	AND f.departure_airport IN (
        SELECT ad.airport_code
        FROM airports_data ad
        WHERE ad.city @> '{"en": "Moscow"}'
    )
ORDER BY f.scheduled_departure;

-- 18
-- Посчитаем количество рейсов с определенными номерами
SELECT flight_no, COUNT(flight_no)
FROM flights f
GROUP BY flight_no
LIMIT 10;

-- 19 GROUP BY с фильтрацией
-- Добавим фильтрацию по номерам рейсов
SELECT flight_no, COUNT(flight_no)
FROM flights f
GROUP BY flight_no
HAVING flight_no IN ('PG0001', 'PG0002', 'PG0003')
LIMIT 10;

-- 20 UNION
-- Объединение таблиц оператором UNION для несвязанных таблиц со схожей структурой
-- Выбрать номера рейсов, которые вылетали из Москвы
SELECT
    flight_no,
    departure_airport AS airport_code,
    'departure' AS depart_or_arrive
FROM flights f
    INNER JOIN airports a
        ON f.departure_airport = a.airport_code and a.city = 'Moscow'
LIMIT 10;

-- 21
-- Выбрать номера рейсов, которые прилетали в Москву
SELECT
    flight_no,
    arrival_airport AS airport_code,
    'arrival' AS depart_or_arrive
FROM flights f
    INNER JOIN airports a
        ON f.arrival_airport = a.airport_code and a.city = 'Moscow'
LIMIT 10;

-- 22
-- Объединение вылетов и прилетов через UNION
SELECT flight_no, departure_airport AS airport_code, 'departure' AS depart_or_arrive
FROM flights f
    INNER JOIN airports a
        ON f.departure_airport = a.airport_code and a.city = 'Moscow'
UNION
SELECT flight_no, arrival_airport AS airport_code, 'arrival' AS depart_or_arrive
FROM flights f
    INNER JOIN airports a
        ON f.arrival_airport = a.airport_code and a.city = 'Moscow';

-- 23 HAVING and WHERE
-- Выведем все рейсы с количеством полетов более 20
SELECT flight_no, COUNT(flight_no)
FROM flights f
GROUP BY flight_no
HAVING COUNT(flight_no) > 20
ORDER BY flight_no;

-- 24
-- Выведем номера рейсов, которые вылетели по расписанию более 20 раз
SELECT flight_no, COUNT(flight_no)
FROM flights f
WHERE f.status = 'Scheduled'
GROUP BY flight_no
HAVING COUNT(flight_no) > 20
ORDER BY flight_no
LIMIT 30;

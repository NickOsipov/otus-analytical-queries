-- ОКОННЫЕ ФУНКЦИИ 2 - Самостоятельная работа

-- 01 ПРОСТОЙ ПРИМЕР ОКОННОЙ ФУНКЦИИ
-- Получаем общую сумму стоимости билетов и среднюю стоимость в таблице ticket_flights
SELECT 
    ticket_no,
    flight_id,
    fare_conditions,
    amount,
    SUM(amount) OVER() AS total_amount,
    AVG(amount) OVER() AS avg_amount
FROM 
    ticket_flights
LIMIT 10;

-- 02 ОКНА С РАЗДЕЛЕНИЕМ (PARTITION BY)
-- Получаем суммы и средние стоимости билетов для каждого класса обслуживания
SELECT 
    ticket_no,
    flight_id,
    fare_conditions,
    amount,
    SUM(amount) OVER(PARTITION BY fare_conditions) AS class_total,
    AVG(amount) OVER(PARTITION BY fare_conditions) AS class_avg
FROM 
    ticket_flights
LIMIT 20;

-- 03 ДОБАВЛЕНИЕ СОРТИРОВКИ ВНУТРИ ОКНА (ORDER BY)
-- Нарастающий итог стоимости билетов по возрастанию для каждого класса обслуживания
SELECT 
    ticket_no,
    flight_id,
    fare_conditions,
    amount,
    SUM(amount) OVER(PARTITION BY fare_conditions ORDER BY amount) AS running_total
FROM 
    ticket_flights
LIMIT 20;

-- 04 ROW_NUMBER - НУМЕРАЦИЯ СТРОК В ОКНЕ
-- Пронумеруем билеты в каждом классе обслуживания по возрастанию стоимости
SELECT 
    ticket_no,
    flight_id,
    fare_conditions,
    amount,
    ROW_NUMBER() OVER(PARTITION BY fare_conditions ORDER BY amount) AS row_num
FROM 
    ticket_flights
LIMIT 30;

-- 05 RANK и DENSE_RANK - РАНЖИРОВАНИЕ СТРОК
-- RANK оставляет "пробелы" в нумерации при одинаковых значениях,
-- DENSE_RANK не оставляет пробелов
SELECT 
    ticket_no,
    flight_id,
    fare_conditions,
    amount,
    ROW_NUMBER() OVER(PARTITION BY fare_conditions ORDER BY amount) AS row_num,
    RANK() OVER(PARTITION BY fare_conditions ORDER BY amount) AS rank_num,
    DENSE_RANK() OVER(PARTITION BY fare_conditions ORDER BY amount) AS dense_rank_num
FROM 
    ticket_flights
LIMIT 30;

-- 06 LAG и LEAD - ДОСТУП К ПРЕДЫДУЩЕЙ И СЛЕДУЮЩЕЙ СТРОКЕ
-- Сравним стоимость текущего билета с предыдущим и следующим в том же классе
SELECT 
    ticket_no,
    flight_id,
    fare_conditions,
    amount,
    LAG(amount) OVER(PARTITION BY fare_conditions ORDER BY amount) AS prev_amount,
    LEAD(amount) OVER(PARTITION BY fare_conditions ORDER BY amount) AS next_amount,
    amount - LAG(amount) OVER(PARTITION BY fare_conditions ORDER BY amount) AS diff_with_prev
FROM 
    ticket_flights
LIMIT 20;

-- 07 FIRST_VALUE и LAST_VALUE - ПЕРВОЕ И ПОСЛЕДНЕЕ ЗНАЧЕНИЕ В ОКНЕ
-- Найдем минимальную и максимальную стоимость билета в каждом классе
SELECT 
    ticket_no,
    flight_id,
    fare_conditions,
    amount,
    FIRST_VALUE(amount) OVER(PARTITION BY fare_conditions ORDER BY amount) AS min_amount,
    LAST_VALUE(amount) OVER(
        PARTITION BY fare_conditions 
        ORDER BY amount 
        RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS max_amount
FROM 
    ticket_flights
LIMIT 20;

-- 08 ПРАКТИЧЕСКИЙ ПРИМЕР 1: АНАЛИЗ БРОНИРОВАНИЙ ПО МЕСЯЦАМ
-- Рассчитаем месячные суммы бронирований и сравним их с предыдущим месяцем
SELECT 
    date_trunc('month', book_date) AS month,
    SUM(total_amount) AS month_total,
    LAG(SUM(total_amount)) OVER(ORDER BY date_trunc('month', book_date)) AS prev_month_total,
    SUM(total_amount) - LAG(SUM(total_amount)) OVER(ORDER BY date_trunc('month', book_date)) AS month_diff,
    CASE 
        WHEN LAG(SUM(total_amount)) OVER(ORDER BY date_trunc('month', book_date)) > 0 
        THEN ROUND((SUM(total_amount) - LAG(SUM(total_amount)) OVER(ORDER BY date_trunc('month', book_date))) 
                / LAG(SUM(total_amount)) OVER(ORDER BY date_trunc('month', book_date)) * 100, 2)
        ELSE NULL
    END AS growth_percent
FROM 
    bookings
GROUP BY 
    date_trunc('month', book_date)
ORDER BY 
    month;

-- 09 ПРАКТИЧЕСКИЙ ПРИМЕР 2: НАХОЖДЕНИЕ САМЫХ ДОРОГИХ БИЛЕТОВ ПО НАПРАВЛЕНИЯМ
-- Найдем топ-3 самых дорогих билета для каждого рейса
WITH ranked_tickets AS (
    SELECT 
        tf.flight_id,
        f.flight_no,
        f.departure_airport,
        f.arrival_airport,
        tf.fare_conditions,
        tf.amount,
        ROW_NUMBER() OVER(PARTITION BY tf.flight_id ORDER BY tf.amount DESC) AS price_rank
    FROM 
        ticket_flights tf
        JOIN flights f ON tf.flight_id = f.flight_id
)
SELECT 
    flight_id,
    flight_no,
    departure_airport,
    arrival_airport,
    fare_conditions,
    amount
FROM 
    ranked_tickets
WHERE 
    price_rank <= 3
ORDER BY 
    flight_id, price_rank
LIMIT 30;

-- 10 ПРАКТИЧЕСКИЙ ПРИМЕР 3: РАСЧЕТ ДВИЖУЩЕГОСЯ СРЕДНЕГО
-- Рассчитаем скользящее среднее для бронирований по 3-дневным интервалам
SELECT 
    book_date,
    SUM(total_amount) AS daily_total,
    AVG(SUM(total_amount)) OVER(
        ORDER BY book_date 
        ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
    ) AS moving_avg_3days
FROM 
    bookings
GROUP BY 
    book_date
ORDER BY 
    book_date
LIMIT 30;

-- 11 ПРАКТИЧЕСКИЙ ПРИМЕР 4: ОПРЕДЕЛЕНИЕ ПЕРЦЕНТИЛЕЙ
-- Определим перцентили стоимости билетов для различных классов обслуживания
SELECT 
    fare_conditions,
    PERCENTILE_CONT(0.25) WITHIN GROUP(ORDER BY amount) AS percentile_25,
    PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY amount) AS median,
    PERCENTILE_CONT(0.75) WITHIN GROUP(ORDER BY amount) AS percentile_75,
    PERCENTILE_CONT(0.9) WITHIN GROUP(ORDER BY amount) AS percentile_90
FROM 
    ticket_flights
GROUP BY 
    fare_conditions;

-- 12 ПРАКТИЧЕСКИЙ ПРИМЕР 5: РАСЧЕТ ДОЛИ ОТ ОБЩЕГО
-- Рассчитаем долю каждого класса обслуживания в общей выручке
SELECT 
    fare_conditions,
    SUM(amount) AS class_total,
    SUM(SUM(amount)) OVER() AS grand_total,
    ROUND(SUM(amount) * 100.0 / SUM(SUM(amount)) OVER(), 2) AS percentage
FROM 
    ticket_flights
GROUP BY 
    fare_conditions;

-- 13 ПРАКТИЧЕСКИЙ ПРИМЕР 6: РАЗБИЕНИЕ НА ГРУППЫ
-- Разбиваем аэропорты на группы по количеству рейсов
WITH airport_flights AS (
    SELECT 
        departure_airport AS airport_code,
        COUNT(*) AS flight_count
    FROM 
        flights
    GROUP BY 
        departure_airport
    UNION ALL
    SELECT 
        arrival_airport AS airport_code,
        COUNT(*) AS flight_count
    FROM 
        flights
    GROUP BY 
        arrival_airport
), airport_stats AS (
    SELECT 
        airport_code,
        SUM(flight_count) AS total_flights,
        NTILE(4) OVER(ORDER BY SUM(flight_count) DESC) AS quartile
    FROM 
        airport_flights
    GROUP BY 
        airport_code
)
SELECT 
    quartile,
    MIN(total_flights) AS min_flights,
    MAX(total_flights) AS max_flights,
    COUNT(*) AS airport_count
FROM 
    airport_stats
GROUP BY 
    quartile
ORDER BY 
    quartile;

-- 14 ПРАКТИЧЕСКИЙ ПРИМЕР 7: АНАЛИЗ ЗАГРУЖЕННОСТИ РЕЙСОВ
-- Определим самые загруженные дни недели для каждого рейса
SELECT 
    flight_no,
    EXTRACT(DOW FROM scheduled_departure) AS day_of_week,
    COUNT(*) AS flights_count,
    ROW_NUMBER() OVER(PARTITION BY flight_no ORDER BY COUNT(*) DESC) AS day_rank
FROM 
    flights
GROUP BY 
    flight_no, EXTRACT(DOW FROM scheduled_departure)
HAVING 
    COUNT(*) > 10
ORDER BY 
    flight_no, day_rank
LIMIT 30;

-- 15 ПРАКТИЧЕСКИЙ ПРИМЕР 8: СРАВНЕНИЕ МЕЖДУ ПЕРИОДАМИ
-- Сравним средние продажи за текущий и предыдущий месяц для каждого аэропорта
WITH monthly_sales AS (
    SELECT 
        date_trunc('month', f.scheduled_departure) AS month,
        f.departure_airport,
        AVG(tf.amount) AS avg_ticket_price,
        COUNT(tf.ticket_no) AS tickets_sold
    FROM 
        flights f
        JOIN ticket_flights tf ON f.flight_id = tf.flight_id
    GROUP BY 
        date_trunc('month', f.scheduled_departure), 
        f.departure_airport
)
SELECT 
    month,
    departure_airport,
    avg_ticket_price,
    tickets_sold,
    LAG(avg_ticket_price) OVER(PARTITION BY departure_airport ORDER BY month) AS prev_month_avg_price,
    ROUND((avg_ticket_price - LAG(avg_ticket_price) OVER(PARTITION BY departure_airport ORDER BY month)) / 
        NULLIF(LAG(avg_ticket_price) OVER(PARTITION BY departure_airport ORDER BY month), 0) * 100, 2) AS price_change_percent,
    tickets_sold - LAG(tickets_sold) OVER(PARTITION BY departure_airport ORDER BY month) AS tickets_change
FROM 
    monthly_sales
ORDER BY 
    departure_airport, month
LIMIT 30;
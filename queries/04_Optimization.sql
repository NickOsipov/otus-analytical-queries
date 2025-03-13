-- Active: 1741805086317@@127.0.0.1@5432@demo@bookings
-- ОПТИМИЗАЦИЯ SQL-ЗАПРОСОВ
-- Примеры использования EXPLAIN, индексов, подсказок и других методов оптимизации в PostgreSQL

-- 01 ИСПОЛЬЗОВАНИЕ EXPLAIN
-- Базовый синтаксис для анализа плана выполнения запроса
EXPLAIN SELECT * FROM tickets WHERE passenger_name LIKE '%IVAN%';

-- 02 EXPLAIN ANALYZE
-- Не только показывает план, но и выполняет запрос, предоставляя реальное время выполнения
EXPLAIN ANALYZE SELECT * FROM tickets WHERE passenger_name LIKE '%IVAN%';

-- 03 ФОРМАТИРОВАНИЕ ВЫВОДА EXPLAIN
-- Получить вывод в различных форматах (TEXT, XML, JSON, YAML)
EXPLAIN (FORMAT JSON) SELECT * FROM tickets WHERE passenger_name LIKE '%IVAN%';

-- 04 АНАЛИЗ ПРОБЛЕМЫ СКАНИРОВАНИЯ ТАБЛИЦЫ
-- Сначала посмотрим на план выполнения запроса без оптимизации
EXPLAIN ANALYZE
SELECT * FROM tickets
WHERE passenger_name = 'IVAN PETROV';

-- 05 СОЗДАНИЕ ИНДЕКСА ДЛЯ ОПТИМИЗАЦИИ ЗАПРОСОВ
-- Создаем индекс для часто используемого столбца
CREATE INDEX idx_tickets_passenger_name ON tickets(passenger_name);
DROP INDEX idx_tickets_passenger_name;

-- 06 АНАЛИЗ ЗАПРОСА ПОСЛЕ СОЗДАНИЯ ИНДЕКСА
-- Смотрим, как изменился план выполнения после создания индекса
EXPLAIN ANALYZE
SELECT * FROM tickets
WHERE passenger_name = 'IVAN PETROV';

-- Bitmap Index Scan:
-- Сначала PostgreSQL сканирует индекс idx_tickets_passenger_name
-- Находит все указатели на строки, где passenger_name = 'IVAN PETROV'
-- Создаёт битовую карту (bitmap) в памяти, где каждый бит соответствует определённой странице таблицы
-- Если на странице есть нужная строка, соответствующий бит устанавливается в 1

-- Bitmap Heap Scan:
-- Далее PostgreSQL использует созданную битовую карту
-- Последовательно читает только те страницы таблицы, которые отмечены в битовой карте
-- Проверяет каждую строку в этих страницах на соответствие условию passenger_name = 'IVAN PETROV'
-- Возвращает строки, удовлетворяющие условию

-- 07 СРАВНЕНИЕ ТИПОВ ИНДЕКСОВ
-- Для поиска по подстроке B-Tree индекс не эффективен
EXPLAIN ANALYZE
SELECT * FROM tickets
WHERE passenger_name LIKE '%IVAN%';

-- 08 СОЗДАНИЕ СПЕЦИАЛИЗИРОВАННОГО ИНДЕКСА ДЛЯ ПОИСКА ПО ПОДСТРОКЕ
-- Для поиска по подстроке используем GIN индекс с триграммами
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX idx_tickets_passenger_name_trgm ON tickets USING gin (passenger_name gin_trgm_ops);
DROP INDEX idx_tickets_passenger_name_trgm;

-- 09 АНАЛИЗ ЗАПРОСА С ИСПОЛЬЗОВАНИЕМ СПЕЦИАЛИЗИРОВАННОГО ИНДЕКСА
EXPLAIN ANALYZE
SELECT * FROM tickets
WHERE passenger_name LIKE '%IVAN%';

-- Триграммный индекс (GIN индекс с операторами триграмм) - это специальный тип индекса, 
-- который разбивает текст на триграммы (последовательности из трех символов) 
-- и строит индекс на основе этих триграмм. 
-- Это позволяет эффективно выполнять поиск по шаблону, даже если шаблон начинается с символа подстановки '%'.

-- 10 СОСТАВНЫЕ ИНДЕКСЫ
-- Создаем составной индекс для оптимизации запросов с несколькими условиями
CREATE INDEX idx_bookings_date_amount ON bookings(book_date, total_amount);

-- 11 АНАЛИЗ ЗАПРОСА С СОСТАВНЫМ ИНДЕКСОМ
EXPLAIN ANALYZE
SELECT * FROM bookings
WHERE book_date BETWEEN '2016-07-01' AND '2016-07-31'
AND total_amount > 50000
ORDER BY book_date;

-- 12 ЧАСТИЧНЫЕ ИНДЕКСЫ
-- Создаем индекс только для части данных, что уменьшает его размер
CREATE INDEX idx_flights_status_scheduled ON flights(scheduled_departure)
WHERE status = 'Scheduled';

-- 13 АНАЛИЗ ЗАПРОСА С ЧАСТИЧНЫМ ИНДЕКСОМ
EXPLAIN ANALYZE
SELECT * FROM flights
WHERE status = 'Scheduled'
AND scheduled_departure BETWEEN '2016-06-01' AND '2017-10-31';

-- 14 ИСПОЛЬЗОВАНИЕ ПОДСКАЗОК (HINTS)
-- Принудительно используем индекс
SELECT /*+ INDEX(t idx_tickets_passenger_name) */
    *
FROM 
    tickets t
WHERE 
    passenger_name = 'IVAN PETROV';

-- 15 МАТЕРИАЛИЗОВАННЫЕ ПРЕДСТАВЛЕНИЯ
-- Создаем материализованное представление для часто используемых данных
CREATE MATERIALIZED VIEW monthly_booking_stats AS
SELECT 
    date_trunc('month', book_date) AS month,
    COUNT(*) AS bookings_count,
    SUM(total_amount) AS total_revenue,
    AVG(total_amount) AS avg_booking_amount
FROM 
    bookings
GROUP BY 
    date_trunc('month', book_date)
WITH DATA;

SELECT * FROM pg_matviews;

-- 16 СОЗДАНИЕ ИНДЕКСА ДЛЯ МАТЕРИАЛИЗОВАННОГО ПРЕДСТАВЛЕНИЯ
CREATE INDEX idx_monthly_booking_stats_month ON monthly_booking_stats(month);

-- 17 ИСПОЛЬЗОВАНИЕ МАТЕРИАЛИЗОВАННОГО ПРЕДСТАВЛЕНИЯ
EXPLAIN ANALYZE
SELECT * FROM monthly_booking_stats
WHERE month BETWEEN '2016-06-01' AND '2016-10-31'
ORDER BY month;


-- 18 ОБНОВЛЕНИЕ МАТЕРИАЛИЗОВАННОГО ПРЕДСТАВЛЕНИЯ
REFRESH MATERIALIZED VIEW monthly_booking_stats;

-- 19 ПАРТИЦИОНИРОВАНИЕ ТАБЛИЦ
-- Создание партиционированной таблицы (пример для PostgreSQL 12)
CREATE TABLE IF NOT EXISTS bookings_partitioned (
    book_ref character(6) NOT NULL,
    book_date timestamp NOT NULL,
    total_amount numeric(10,2) NOT NULL
) PARTITION BY RANGE (book_date);

-- Наполнение партиционированной таблицы данными из оригинальной таблицы
INSERT INTO bookings_partitioned
SELECT 
    book_ref,
    book_date,
    total_amount
FROM 
    bookings
WHERE 
    book_date >= '2016-01-01' AND book_date < '2017-01-01';

-- 20 СОЗДАНИЕ ОТДЕЛЬНЫХ ПАРТИЦИЙ
CREATE TABLE bookings_2016_q1 PARTITION OF bookings_partitioned
    FOR VALUES FROM ('2016-01-01') TO ('2016-04-01');
    
CREATE TABLE bookings_2016_q2 PARTITION OF bookings_partitioned
    FOR VALUES FROM ('2016-04-01') TO ('2016-07-01');
    
CREATE TABLE bookings_2016_q3 PARTITION OF bookings_partitioned
    FOR VALUES FROM ('2016-07-01') TO ('2016-10-01');
    
CREATE TABLE bookings_2016_q4 PARTITION OF bookings_partitioned
    FOR VALUES FROM ('2016-10-01') TO ('2017-01-01');

-- 21 АНАЛИЗ ЗАПРОСОВ НА ПАРТИЦИОНИРОВАННОЙ ТАБЛИЦЕ
EXPLAIN ANALYZE
SELECT * FROM bookings_partitioned
WHERE book_date BETWEEN '2016-06-01' AND '2016-06-30';

SELECT * FROM bookings_partitioned
WHERE book_date BETWEEN '2016-06-01' AND '2016-06-30';

DROP TABLE bookings_partitioned CASCADE;

-- 22 ОПТИМИЗАЦИЯ СЛОЖНЫХ ЗАПРОСОВ С JOIN
-- Сначала анализируем план выполнения
EXPLAIN ANALYZE
SELECT 
    t.passenger_name,
    f.flight_no,
    f.scheduled_departure,
    bp.seat_no
FROM 
    tickets t
    JOIN ticket_flights tf ON t.ticket_no = tf.ticket_no
    JOIN flights f ON tf.flight_id = f.flight_id
    JOIN boarding_passes bp ON tf.ticket_no = bp.ticket_no AND tf.flight_id = bp.flight_id
WHERE 
    f.departure_airport = 'SVO'
    AND f.scheduled_departure BETWEEN '2016-09-01' AND '2016-09-30';

-- 23 СОЗДАНИЕ ИНДЕКСОВ ДЛЯ ОПТИМИЗАЦИИ JOIN
CREATE INDEX idx_flights_departure_airport ON flights(departure_airport, scheduled_departure);
CREATE INDEX idx_ticket_flights_flight_id ON ticket_flights(flight_id);
CREATE INDEX idx_boarding_passes_flight_id ON boarding_passes(flight_id);

-- 24 АНАЛИЗ ЗАПРОСА ПОСЛЕ СОЗДАНИЯ ИНДЕКСОВ
EXPLAIN ANALYZE
SELECT 
    t.passenger_name,
    f.flight_no,
    f.scheduled_departure,
    bp.seat_no
FROM 
    tickets t
    JOIN ticket_flights tf ON t.ticket_no = tf.ticket_no
    JOIN flights f ON tf.flight_id = f.flight_id
    JOIN boarding_passes bp ON tf.ticket_no = bp.ticket_no AND tf.flight_id = bp.flight_id
WHERE 
    f.departure_airport = 'SVO'
    AND f.scheduled_departure BETWEEN '2017-09-01' AND '2017-09-30';

-- 25 ОПТИМИЗАЦИЯ ПОДЗАПРОСОВ
-- Часто подзапросы можно заменить JOIN для оптимизации
-- Неоптимальный вариант с подзапросом
EXPLAIN ANALYZE
SELECT 
    flight_no,
    scheduled_departure,
    departure_airport,
    arrival_airport
FROM 
    flights f
WHERE 
    f.flight_id IN (
        SELECT flight_id
        FROM ticket_flights
        GROUP BY flight_id
        HAVING COUNT(*) > 50
    );

-- 26 ОПТИМИЗИРОВАННЫЙ ВАРИАНТ С JOIN
EXPLAIN ANALYZE
SELECT 
    f.flight_no,
    f.scheduled_departure,
    f.departure_airport,
    f.arrival_airport
FROM 
    flights f
    JOIN (
        SELECT flight_id
        FROM ticket_flights
        GROUP BY flight_id
        HAVING COUNT(*) > 50
    ) tf ON f.flight_id = tf.flight_id;

-- 27 ОПТИМИЗАЦИЯ ГРУППИРОВКИ С ИСПОЛЬЗОВАНИЕМ ИНДЕКСОВ
CREATE INDEX idx_ticket_flights_flight_id_amount ON ticket_flights(flight_id, amount);

-- 28 АНАЛИЗ ЗАПРОСА ПОСЛЕ СОЗДАНИЯ ИНДЕКСА ДЛЯ ГРУППИРОВКИ
EXPLAIN ANALYZE
SELECT 
    flight_id,
    SUM(amount) AS total_revenue,
    AVG(amount) AS avg_ticket_price,
    COUNT(*) AS tickets_sold
FROM 
    ticket_flights
GROUP BY 
    flight_id
ORDER BY 
    total_revenue DESC
LIMIT 10;

-- 29 ИСПОЛЬЗОВАНИЕ ФУНКЦИИ АВТОВАКУУМ ДЛЯ ПОДДЕРЖАНИЯ ПРОИЗВОДИТЕЛЬНОСТИ
-- Postgres управляет автовакуумом автоматически, но можно настроить его параметры
ALTER TABLE tickets SET (
    autovacuum_vacuum_scale_factor = 0.1,
    autovacuum_analyze_scale_factor = 0.05
);

-- 30 СТАТИСТИКА ДЛЯ ОПТИМИЗАТОРА
-- Обновление статистики для улучшения планов выполнения
ANALYZE tickets;
ANALYZE flights;
ANALYZE bookings;

-- 31 ОПРЕДЕЛЕНИЕ "ГОРЯЧИХ" ТАБЛИЦ И СТОЛБЦОВ
-- Запрос для определения наиболее часто используемых таблиц
SELECT 
    relname, 
    seq_scan, 
    idx_scan, 
    n_tup_ins, 
    n_tup_upd, 
    n_tup_del
FROM 
    pg_stat_user_tables
ORDER BY 
    seq_scan DESC;

-- 32 ПОИСК РЕДКО ИСПОЛЬЗУЕМЫХ ИНДЕКСОВ
-- Запрос для определения индексов, которые редко используются
SELECT 
    idstat.relname AS table_name, 
    idstat.indexrelname AS index_name, 
    idstat.idx_scan AS times_used, 
    idstat.idx_tup_read AS tuples_read, 
    idstat.idx_tup_fetch AS tuples_fetched
FROM 
    pg_stat_user_indexes idstat
JOIN 
    pg_stat_user_tables tabstat ON idstat.relname = tabstat.relname
ORDER BY 
    idstat.idx_scan ASC;

-- 33 ПАРАЛЛЕЛЬНАЯ ОБРАБОТКА ЗАПРОСОВ
-- Настройка параллелизма (для версий PostgreSQL 9.6+)
-- Включение параллельного сканирования
SET max_parallel_workers_per_gather = 4;

-- 34 АНАЛИЗ ЗАПРОСА С ПАРАЛЛЕЛЬНОЙ ОБРАБОТКОЙ
EXPLAIN ANALYZE
SELECT 
    f.departure_airport,
    COUNT(*) AS flights_count,
    AVG(b.total_amount) AS avg_booking_amount
FROM 
    flights f
    JOIN ticket_flights tf ON f.flight_id = tf.flight_id
    JOIN tickets t ON tf.ticket_no = t.ticket_no
    JOIN bookings b ON t.book_ref = b.book_ref
GROUP BY 
    f.departure_airport
ORDER BY 
    flights_count DESC;

-- 35 ИСПОЛЬЗОВАНИЕ КУРСОРОВ ДЛЯ БОЛЬШИХ НАБОРОВ ДАННЫХ
-- Для обработки очень больших наборов данных можно использовать курсоры
BEGIN;
DECLARE large_result_cursor CURSOR FOR
SELECT 
    t.passenger_name,
    f.flight_no,
    f.scheduled_departure
FROM 
    tickets t
    JOIN ticket_flights tf ON t.ticket_no = tf.ticket_no
    JOIN flights f ON tf.flight_id = f.flight_id;

-- Получаем первые 100 записей
FETCH 100 FROM large_result_cursor;
-- Получаем следующие 100 записей
FETCH 100 FROM large_result_cursor;
CLOSE large_result_cursor;
COMMIT;
-- Active: 1741805086317@@127.0.0.1@5432@demo@bookings
-- 01 СТРУКТУРА БАЗЫ ДАННЫХ
-- Получить все доступные нам схемы данных
SELECT schemaname, tablename, tableowner
FROM pg_catalog.pg_tables
WHERE schemaname != 'pg_catalog' AND
    schemaname != 'information_schema';

-- 02
-- Получить имена таблиц для схемы 'bookings'
SELECT tablename
FROM pg_catalog.pg_tables
WHERE schemaname = 'bookings';

-- 03
-- Получить все поля определенной таблицы в виде списка
SELECT column_name
FROM information_schema.columns
WHERE
    table_schema = 'bookings'
    AND
    table_name   = 'flights';

-- 04
-- Получить все поля определенной таблицы в виде таблицы
SELECT *
FROM flights f
LIMIT 1;

-- 05 ВЫБОРКА ДАННЫХ
-- Получить все данные из таблицы
-- Внимание, вы пока не знаете, сколько там данных
-- и это может "подвесить" вашу сессию работы
SELECT *
FROM flights f
LIMIT 100;

-- 06
-- Давайте узнаем, сколько строк содержит наша таблица
SELECT COUNT(*)
FROM flights f;

-- 07 АЛИАСЫ
-- Переименуем столбец результата.
-- Дальше это нам понадобится, чтобы выводить
-- осмысленные результаты
SELECT COUNT(*) AS "number_of_notes"
FROM flights f;

-- 08
-- Обратите внимание, в отличие от Python'a
-- SQL требует от нас двойные кавычки
-- такой код вызовет ошибку
SELECT COUNT(*) AS 'number of notes'
FROM flights f;

-- 09 LIMIT и ORDER
-- Выберем 100 полетов и их аэропорты вылета
SELECT flight_no, departure_airport AS depart
FROM flights f
LIMIT 100;

-- 10
-- Получим первые 100 записей из seats
SELECT *
FROM seats
LIMIT 100;

-- 11
-- Получим последние 100 записей из seats
SELECT *
FROM seats s
ORDER BY aircraft_code DESC
LIMIT 100;

-- 12
-- А по какому критерию они "последние"?
-- Например, по коду рейса
SELECT *
FROM seats s
ORDER BY aircraft_code DESC
LIMIT 100;

-- 13 УНИКАЛЬНЫЕ ЗНАЧЕНИЯ
-- Получить коды рейсов
SELECT aircraft_code
FROM seats s;

-- 14
-- Получить только УНИКАЛЬНЫЕ коды рейсов без повторов
SELECT DISTINCT aircraft_code
FROM seats s;

-- 15
-- Давайте отсортируем и сделаем по возрастанию
SELECT DISTINCT aircraft_code
FROM seats s
ORDER BY aircraft_code;

-- 16 ФИЛЬТРАЦИЯ
-- Выберем только места, которые обслуживают бизнес-класс
SELECT DISTINCT seat_no
FROM seats s
WHERE fare_conditions = 'Business'
ORDER BY seat_no
LIMIT 100;

-- 17
-- Выберем рейсы и выведем их номера, где были билеты бизнес-класса
SELECT DISTINCT aircraft_code
FROM seats s
WHERE fare_conditions = 'Business'
ORDER BY aircraft_code
LIMIT 100;

-- 18 ГРУППИРОВКА
-- Выберем рейсы, на которых ТОЛЬКО билеты эконом-класса
-- Так просто это сделать не удастся
-- Оператор WHERE фильтрует строки до группировки,
-- а для решения этой задачи требуется анализировать
-- данные на уровне групп (по каждому номеру рейса)
-- Приведу пример - а обсудим его на следующем семинаре
SELECT DISTINCT aircraft_code
FROM seats
GROUP BY aircraft_code
HAVING
    SUM(CASE WHEN fare_conditions = 'Economy' THEN 1 ELSE 0 END) > 0
    AND
    SUM(CASE WHEN fare_conditions IN ('Business', 'Comfort') THEN 1 ELSE 0 END) = 0;

-- 19 ПОИСК ПО ПОДСТРОКЕ
-- Фильтрация по подстроке
SELECT *
FROM tickets t
WHERE passenger_name LIKE '%SERGEEVA'
LIMIT 100;

-- 20
-- Количество отфильтрованных строк по подстроке
SELECT COUNT(*)
FROM tickets t
WHERE passenger_name LIKE '%SERGEEVA'
LIMIT 100;

-- 21
-- Фильтрация по подстроке
-- Не забывайте про LIMIT,
-- потому что результат может быть неожиданным
-- Например, в этой таблице Елен - более 25 тысяч
SELECT COUNT(*)
FROM tickets t
WHERE passenger_name LIKE '%ELENA%'
LIMIT 100;

-- 22 СЛОЖНЫЕ УСЛОВИЯ
-- Аэропорты, которые содержат слово International и находятся в Европе
-- Отсортировать по городу по возрастанию и потом по коду по убыванию
SELECT *
FROM airports a
WHERE airport_name LIKE '%International%'
	AND timezone LIKE 'Europe%'
ORDER BY city ASC, airport_code DESC
LIMIT 100;

-- 23 АГРЕГАЦИЯ
-- Посчитать, сколько аэропортов находится в городах
SELECT city, COUNT(airport_name) AS num
FROM airports a
GROUP BY city;

-- 24
-- И вывести только те, где больше 1
SELECT city, COUNT(airport_name) AS num
FROM airports a
GROUP BY city
HAVING COUNT(airport_name) > 1;

-- 25
-- Количество строк в bookings
SELECT COUNT(*)
FROM bookings b
LIMIT 100;

-- 26
-- Посчитать, сколько было бронирований билетов суммарно по датам
-- и вывести 20 наиболее "продавшихся"
SELECT book_date, SUM(total_amount) AS SUMma
FROM bookings b
GROUP BY book_date
ORDER BY SUM(total_amount) DESC
LIMIT 20;

-- 27 РАБОТА С ДАТАМИ
-- Посчитать, сколько было бронирований по месяцам
-- В PostgreSQL можно воспользоваться функцией date_trunc.
-- Эта функция позволяет усечь дату до указанного компонента,
-- такого как месяц, год и т.д.
SELECT
  date_trunc('month', book_date) AS month,
	SUM(total_amount) AS total_sales
FROM bookings
GROUP BY date_trunc('month', book_date)
ORDER BY month
LIMIT 100;

-- 28
-- Посчитать, сколько было бронирований по часам
SELECT
    date_trunc('hour', book_date) AS hour,
    SUM(total_amount) AS total_sales
FROM bookings
GROUP BY date_trunc('hour', book_date)
ORDER BY hour
LIMIT 100;

-- 29
-- Посчитать, сколько было бронирований по часам без указания суток
SELECT
    EXTRACT('hour' FROM book_date) AS hour,
    SUM(total_amount) AS total_sales
FROM bookings
GROUP BY EXTRACT('hour' FROM book_date)
ORDER BY hour
LIMIT 100;

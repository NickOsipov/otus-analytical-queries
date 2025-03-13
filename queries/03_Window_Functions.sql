-- Active: 1741805086317@@127.0.0.1@5432@postgres@public

-- ОКОННЫЕ ФУНКЦИИ 1
-- Оконные функции позволяют выполнять агрегатные функции над группами строк

-- 01 СОЗДАНИЕ ТАБЛИЦ В БД
CREATE TABLE IF NOT EXISTS employees (
    id  INTEGER PRIMARY KEY,
    name  TEXT NOT NULL,
    city  TEXT NOT NULL,
    department  TEXT NOT NULL,
    salary  INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS expenses (
    year  INTEGER NOT NULL,
    month INTEGER NOT NULL,
    income INTEGER NOT NULL,
    expense INTEGER NOT NULL
);

-- 02 НАПОЛНЕНИЕ ДАННЫМИ
-- Заполняем таблицу employees
INSERT INTO employees (id, name, city, department, salary)
VALUES
    (11,'Дарья','Самара','hr',70),
    (12,'Борис','Самара','hr',78),
    (21,'Елена','Самара','it',84),
    (22,'Ксения','Москва','it',90),
    (23,'Леонид','Самара','it',104),
    (24,'Марина','Москва','it',104),
    (25,'Иван','Москва','it',120),
    (31,'Вероника','Москва','sales',96),
    (32,'Григорий','Самара','sales',96),
    (33,'Анна','Москва','sales',100);

-- 03
-- Заполняем таблицу expenses
INSERT INTO expenses (year, month, income, expense)
VALUES
    (2020, 1, 94, 82),
    (2020, 2, 94, 75),
    (2020, 3, 94, 104),
    (2020, 4, 100, 94),
    (2020, 5, 100, 99),
    (2020, 6, 100, 105),
    (2020, 7, 100, 95),
    (2020, 8, 100, 110),
    (2020, 9, 104, 104);

-- 04 РАНЖИРОВАНИЕ
-- Отсортируем таблицу по зарплате и создадим ранг
-- window — ключевое слово, показывающее определение окна
-- w — название окна
-- (order by salary desc) — описание окна
SELECT
    DENSE_RANK() OVER w AS rank,
    name, 
    department, 
    salary
FROM employees
WINDOW w AS (ORDER BY salary DESC)
ORDER BY rank;

SELECT *
FROM employees
ORDER BY salary DESC;

-- 05
-- Сравнение RANK и DENSE_RANK
SELECT
    RANK() OVER w AS rank,
    DENSE_RANK() OVER w AS dense_rank,
    name, 
    department, 
    salary
FROM employees
WINDOW w AS (ORDER BY salary DESC)
ORDER BY rank;

-- 06 ПАРТИЦИИ
-- Рейтинг зарплат по департаментам
-- partition by department разбивает окно на секции
SELECT
    RANK() OVER w AS rank,
    DENSE_RANK() OVER w AS dense_rank,
    name, 
    department, 
    salary
FROM employees
WINDOW w AS (
    PARTITION BY department
    ORDER BY salary DESC
)
ORDER BY department, rank;

-- 07
-- Нумерация сотрудников внутри отделов
SELECT
    ROW_NUMBER() OVER w AS rank,
    name, 
    department, 
    salary
FROM employees
WINDOW w AS (
    PARTITION BY department
    ORDER BY salary DESC
)
ORDER BY department, rank;

-- 08 ГРУППИРОВКА NTILE
-- Разбиение на группы по зарплате
-- ntile(n) разбивает записи на n групп
SELECT
  ntile(3) OVER w AS tile,
  name, 
  department, 
  salary
FROM employees
WINDOW w AS (ORDER BY salary DESC)
ORDER BY salary DESC;

-- 09 LAG И LEAD
-- Разница зарплаты с предыдущим значением
SELECT
    name, 
    department, 
    salary,
    round(
        (salary - lag(salary, 1) over w)*100.0 / salary
    ) || '%' AS diff
FROM employees
WINDOW w AS (ORDER BY salary)
ORDER BY salary;

-- 10 FIRST_VALUE И LAST_VALUE
-- Диапазон зарплат в департаменте
SELECT
    name, 
    department, 
    salary,
    first_value(salary) OVER w AS low,
    last_value(salary) OVER w AS high
FROM employees
WINDOW w AS (
    PARTITION BY department
    ORDER BY salary
    ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
)
ORDER BY department, salary;

-- 11 АГРЕГАЦИЯ
-- Процент зарплаты от фонда департамента
SELECT
    name, 
    department, 
    salary,
    sum(salary) OVER w AS fund,
    round(salary * 100.0 / sum(salary) OVER w) || ' %' AS perc
FROM employees
WINDOW w AS (PARTITION BY department)
ORDER BY department, salary;

-- 12 MULTIPLE WINDOWS
-- Сравнение со средней зарплатой и общим фондом
SELECT
    name, 
    department, 
    salary,
    round(avg(salary) OVER w) AS avg_sal,
    round((salary - avg(salary) OVER w)*100.0 / round(avg(salary) OVER w)) AS diff,
    round(salary * 100 / sum(salary) OVER t) || '%' AS perc_total
FROM employees
WINDOW
    w AS (PARTITION BY department),
    t AS ()
ORDER BY department, salary;

-- 13 СКОЛЬЗЯЩИЕ АГРЕГАТЫ
-- Скользящее среднее расходов
SELECT
    year, 
    month, 
    expense,
    round(avg(expense) OVER w) AS roll_avg
FROM expenses
WINDOW w AS (
    ORDER BY year, month
    ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
)
ORDER BY year, month;

-- 14 КУМУЛЯТИВНЫЕ ИТОГИ
-- Нарастающие итоги по доходам и расходам
SELECT
    year, month, income, expense,
    sum(income) OVER w AS cum_income,
    sum(expense) OVER w AS cum_expense,
    (sum(income) OVER w) - (sum(expense) OVER w) AS cum_profit,
    round(avg(income) OVER w) AS cum_avg
FROM expenses
WINDOW w AS (
    ORDER BY year, month
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
)
ORDER BY year, month;

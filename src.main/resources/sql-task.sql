-- Вывести к каждому самолету класс обслуживания и количество мест этого класса
SELECT model, fare_conditions, count(fare_conditions) AS seats_qty
FROM aircrafts_data a
         LEFT JOIN seats s ON a.aircraft_code = s.aircraft_code
GROUP BY fare_conditions, model
ORDER BY model;

-- Найти 3 самых вместительных самолета (модель + кол-во мест)
SELECT model, count(model) AS seats_qty
FROM aircrafts_data a
         JOIN seats s ON a.aircraft_code = s.aircraft_code
GROUP BY model
ORDER BY seats_qty
        DESC
LIMIT 3;

-- Вывести код,модель самолета и места не эконом класса для самолета 'Аэробус A321-200' с сортировкой по местам
SELECT a.aircraft_code, model, seat_no
FROM aircrafts_data a
         LEFT JOIN seats s ON a.aircraft_code = s.aircraft_code
WHERE model @> '{"ru": "Аэробус A321-200"}'
  AND fare_conditions != 'Economy'
ORDER BY seat_no;

-- Вывести города в которых больше 1 аэропорта ( код аэропорта, аэропорт, город)
SELECT airport_code, airport_name, city
FROM airports_data
WHERE city IN (SELECT city
               FROM airports_data
               GROUP BY city
               HAVING count(airport_code) > 1);

-- Найти ближайший вылетающий рейс из Екатеринбурга в Москву, на который еще не завершилась регистрация
SELECT flight_id, flight_no, scheduled_departure, scheduled_arrival, departure_airport, arrival_airport, status,
       aircraft_code, actual_departure, actual_arrival
FROM flights
WHERE status NOT IN ('Departed', 'Arrived', 'Canceled')
  AND scheduled_departure > bookings.now()
  AND departure_airport IN (SELECT airport_code FROM airports_data WHERE city @> '{"ru": "Екатеринбург"}')
  AND arrival_airport IN (SELECT airport_code FROM airports_data WHERE city @> '{"ru": "Москва"}')
ORDER BY scheduled_departure
LIMIT 1;

-- Вывести самый дешевый и дорогой билет и стоимость ( в одном результирующем ответе)
(SELECT ticket_no, flight_id, fare_conditions, amount
 FROM ticket_flights
 WHERE amount IN (SELECT max(amount)
                  FROM ticket_flights)
 LIMIT 1)
UNION
(SELECT ticket_no, flight_id, fare_conditions, amount
 FROM ticket_flights
 WHERE amount IN (SELECT min(amount)
                  FROM ticket_flights)
 LIMIT 1);

-- Написать DDL таблицы Customers , должны быть поля id , firstName, LastName, email , phone. Добавить ограничения на поля ( constraints) .
CREATE SEQUENCE IF NOT EXISTS customers_id_seq;

ALTER SEQUENCE customers_id_seq OWNER TO postgres;

CREATE TABLE IF NOT EXISTS customers
(
    id         BIGINT DEFAULT nextval('bookings.customers_id_seq'::regclass)
        CONSTRAINT customers_pk
            PRIMARY KEY,
    first_name VARCHAR(30) NOT NULL,
    last_name  VARCHAR(30) NOT NULL,
    email      VARCHAR(30) NOT NULL,
    phone      VARCHAR(20) NOT NULL
);

ALTER TABLE customers
    OWNER TO postgres;

CREATE UNIQUE INDEX IF NOT EXISTS customers_email_uindex
    ON customers (email);

CREATE UNIQUE INDEX IF NOT EXISTS customers_id_uindex
    ON customers (id);

CREATE UNIQUE INDEX IF NOT EXISTS customers_phone_uindex
    ON customers (phone);

-- Написать DDL таблицы Orders , должен быть id, customerId,	quantity. Должен быть внешний ключ на таблицу customers + ограничения
CREATE SEQUENCE IF NOT EXISTS orders_id_seq;

ALTER SEQUENCE orders_id_seq OWNER TO postgres;

CREATE TABLE IF NOT EXISTS orders
(
    id          BIGINT DEFAULT nextval('bookings.orders_id_seq'::regclass)
        CONSTRAINT orders_pk
            PRIMARY KEY,
    customer_id BIGINT  NOT NULL
        CONSTRAINT orders_customers_id_fk
            REFERENCES customers
            ON UPDATE CASCADE ON DELETE CASCADE,
    quantity    INTEGER NOT NULL
);

ALTER TABLE orders
    OWNER TO postgres;

CREATE UNIQUE INDEX IF NOT EXISTS orders_customer_id_uindex
    ON orders (customer_id);

CREATE UNIQUE INDEX IF NOT EXISTS orders_id_uindex
    ON orders (id);

-- Написать 5 insert в эти таблицы
INSERT INTO customers
    (first_name, last_name, email, phone)
VALUES ('Adrian', 'Smith', 'a_smith@ironmaiden.com', '442012345678'),
       ('Dave', 'Murray', 'd_murray@ironmaiden.com', '442012345679'),
       ('Nicko', 'McBrain', 'n_mcbrain@ironmaiden.com', '442012345680'),
       ('Steve', 'Harris', 's_harris@ironmaiden.com', '442012345681'),
       ('Bruce', 'Dickinson', 'b_dickinson@ironmaiden.com', '442012345682');

INSERT INTO orders
    (customer_id, quantity)
VALUES (1, 2),
       (2, 3),
       (3, 2),
       (4, 3),
       (5, 2);

-- удалить таблицы
DROP TABLE customers, orders;

-- Написать свой кастомный запрос ( rus + sql)
/*Вывести инфо (номер рейса, даты фактического вылета и прибытия, аэропорт прибытия, имя и контакты пассажира) по
  пассажирам, вылетевшим в течение последних суток из Москвы, фамилия которых начинается на "Popov" (Popov, Popova,
  Popovitch и т.д.) в хронологическом порядке по времени вылета */

SELECT f.flight_id, actual_departure, airport_name, actual_arrival, passenger_name, contact_data
FROM flights f
         JOIN airports_data ad ON f.arrival_airport = ad.airport_code
         JOIN ticket_flights tf on f.flight_id = tf.flight_id
         JOIN tickets t on tf.ticket_no = t.ticket_no
WHERE status = 'Departed'
  AND actual_departure BETWEEN (bookings.now() - INTERVAL '1 day') AND bookings.now()
  AND departure_airport IN (SELECT airport_code FROM airports_data WHERE city @> '{"ru": "Москва"}')
  AND passenger_name LIKE '% POPOV%'
ORDER BY actual_departure;

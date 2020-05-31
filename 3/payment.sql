-- 1. INSERT
--  1. Без указания списка полей
        INSERT INTO house VALUES (1, 'Rome', 2, '1977-02-02');
        INSERT INTO owner VALUES (1, 'Mark', '78923232323');
        INSERT INTO apartment VALUES (1, 2, 1, 1, 1, 1);
        INSERT INTO utility_fee VALUES (1, 'water', 50);
        INSERT INTO payment VALUES (1, 2000, 1, '2020-02-02', true, 1);

--  2. С указанием списка полей
        INSERT INTO house (house_id, address, floor_count, construction_date) VALUES (2, 'Crimea', 2, '12-12-1999');
        INSERT INTO owner (owner_id, name, phone) VALUES (2, 'Seneka', '738892323434');
        INSERT INTO apartment (apartment_id, room_count, floor_space, resident_count, owner_id, house_id) VALUES (2, 2, 50, 3, 2, 2);
        INSERT INTO utility_fee (utility_fee_id, name, price_per_unit) VALUES (2, 'water', 30);
        INSERT INTO payment (payment_id, amount, utility_fee_id, date, is_paid, apartment_id) VALUES (2, 1000, 2, '2020-02-02', false, 2);

--  3. С чтением значения из другой таблицы
        INSERT INTO utility_fee (price_per_unit)  SELECT (amount) FROM payment;

-- 2. DELETE
-- 	1. Всех записей
        DELETE FROM payment;

-- 	2. По условию
		DELETE FROM house
		 WHERE address = 'Crimea';
		DELETE FROM owner
		 WHERE name = 'Mark';

-- 	3. Очистить таблицу
		TRUNCATE TABLE payment CASCADE;

-- 3. UPDATE
-- 	1. Всех записей
        UPDATE owner
        SET name = 'Plutarch';

-- 	2. По условию обновляя один атрибут
		UPDATE owner
		SET name = 'Ovid'
		 WHERE name = 'Plutarch';

-- 	3. По условию обновляя несколько атрибутов
		UPDATE owner
		SET name = 'Cicero', phone = '32232323232'
		 WHERE name = 'Eduard';

-- 4. SELECT
--  1. С определенным набором извлекаемых атрибутов (SELECT atr1, atr2 FROM...)
        SELECT name FROM owner;

-- 	2. Со всеми атрибутами (SELECT * FROM...)
        SELECT * FROM owner;

-- 	3. С условием по атрибуту (SELECT * FROM ... WHERE atr1 = "")
        SELECT name
          FROM owner
         WHERE name = 'Seneka';

-- 5. SELECT ORDER BY + TOP (LIMIT)
--  1. С сортировкой по возрастанию ASC + ограничение вывода количества записей
        SELECT *
          FROM apartment
        ORDER BY floor_space
        LIMIT 2;

--  2. С сортировкой по убыванию DESC
        SELECT *
          FROM apartment
        ORDER BY floor_space DESC
        LIMIT 1;

--  3. С сортировкой по двум атрибутам + ограничение вывода количества записей
        SELECT *
          FROM apartment
        ORDER BY floor_space, resident_count
        LIMIT 2;

--  4. С сортировкой по первому атрибуту, из списка извлекаемых
        SELECT *
          FROM apartment
        ORDER BY apartment_id;

-- 6. Работа с датами. Необходимо, чтобы одна из таблиц содержала атрибут с типом DATETIME.
--     Например, таблица авторов может содержать дату рождения автора.
--     1. WHERE по дате
        SELECT *
          FROM payment
         WHERE date = '2020-02-02';

--     2. Извлечь из таблицы не всю дату, а только год. Например, год рождения автора.
--        Для этого используется функция YEAR
--        https://docs.microsoft.com/en-us/sql/t-sql/functions/year-transact-sql?view=sql-server-2017
        SELECT EXTRACT(YEAR FROM date)
         FROM payment;

-- 7. SELECT GROUP BY с функциями агрегации
--     1. MIN
        SELECT MIN(floor_space)
         FROM apartment
        GROUP BY room_count;

--     2. MAX
        SELECT MAX(floor_space)
         FROM apartment
        GROUP BY room_count;

--     3. AVG
        SELECT AVG(floor_space)
         FROM apartment
        GROUP BY room_count;

--     4. SUM
        SELECT SUM(amount)
         FROM payment
        GROUP BY amount;

--     5. COUNT
        SELECT COUNT(address)
         FROM house
        WHERE address = 'Rome';

-- 8. SELECT GROUP BY + HAVING
--     1. Написать 3 разных запроса с использованием GROUP BY + HAVING
        SELECT AVG(floor_count)
          FROM house
        GROUP BY address
        HAVING AVG(floor_count) < 20;

        SELECT o.name,
               AVG(floor_space)
          FROM payment
            LEFT JOIN apartment a
              ON payment.apartment_id = a.apartment_id
            LEFT JOIN owner o
              ON a.owner_id = o.owner_id
        GROUP BY o.name
        HAVING AVG(floor_space) > 30;

        SELECT SUM(DISTINCT apartment_id) AS apartment_count,
               h.address
          FROM apartment
            LEFT JOIN house h ON apartment.house_id = h.house_id
        GROUP BY h.address
        HAVING SUM(DISTINCT apartment_id) >= 2;

-- 9. SELECT JOIN
--     1. LEFT JOIN двух таблиц и WHERE по одному из атрибутов
        SELECT
          apartment_id, payment.utility_fee_id, amount
          FROM
              payment
          LEFT JOIN
              utility_fee
                  ON
                    utility_fee.utility_fee_id = payment.utility_fee_id
         WHERE
             utility_fee.price_per_unit > 40::money;

--     2. RIGHT JOIN. Получить такую же выборку, как и в 5.1
        SELECT
          apartment.apartment_id,apartment.room_count,apartment.floor_space,apartment.resident_count,apartment.house_id
          FROM
              apartment
          RIGHT JOIN
              owner
                  ON
                    owner.owner_id = apartment.owner_id
         WHERE
             floor_space = 50
        ORDER BY
            resident_count
        LIMIT 2;

--     3. LEFT JOIN трех таблиц + WHERE по атрибуту из каждой таблицы
        SELECT owner.owner_id, owner.name, owner.phone
          FROM
              owner
          LEFT JOIN
              apartment
            ON
               apartment.owner_id = owner.owner_id
          LEFT JOIN
              house
            ON
              house.house_id = apartment.house_id
         WHERE
             house.construction_date > '1980-02-12'
         AND
             apartment.room_count = 2
         AND
             owner.name != 'Ovid';

--     4. FULL OUTER JOIN двух таблиц
        SELECT
          apartment.apartment_id,apartment.resident_count,apartment.floor_space
          FROM
              apartment
          FULL OUTER JOIN
              house
            ON
              house.house_id = apartment.house_id
        ORDER BY floor_space;
--
-- 10. Подзапросы
--     1. Написать запрос с WHERE IN (подзапрос)
        SELECT owner_id, name
          FROM owner
         WHERE name IN (SELECT name
                          FROM owner
                          LEFT JOIN apartment a ON a.owner_id = owner.owner_id
                         WHERE room_count = 2);

--     2. Написать запрос SELECT atr1, atr2, (подзапрос) FROM ...
        SELECT owner_id,phone,
            (SELECT apartment_id
              FROM apartment
             WHERE owner.owner_id = apartment.apartment_id)
          AS apartment_id
          FROM owner;

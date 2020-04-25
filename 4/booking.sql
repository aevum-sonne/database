-- 1. Добавить внешние ключи
    ALTER TABLE booking
        ADD CONSTRAINT booking_client_id_client_fk
            FOREIGN KEY (id_client)
             REFERENCES client;

    ALTER TABLE room
        ADD CONSTRAINT room_room_category_id_room_category_fk
            FOREIGN KEY (id_room_category)
             REFERENCES room_category;

    ALTER TABLE room
        ADD CONSTRAINT room_hotel_id_hotel_fk
            FOREIGN KEY (id_hotel)
             REFERENCES hotel;

    ALTER TABLE room_in_booking
        ADD CONSTRAINT room_in_booking_booking_id_booking_fk
            FOREIGN KEY (id_booking)
             REFERENCES booking;

    ALTER TABLE room_in_booking
        ADD CONSTRAINT room_in_booking_room_id_room_fk
            FOREIGN KEY (id_room)
             REFERENCES room;

-- 2. Выдать информацию о клиентах гостиницы “Космос”, проживающих в номерах
-- категории “Люкс” на 1 апреля 2019г.
    SELECT client.name, client.phone
      FROM booking
        LEFT JOIN client ON client.id_client = booking.id_client
        LEFT JOIN room_in_booking ON room_in_booking.id_booking = booking.id_booking
        LEFT JOIN room ON room.id_room= room_in_booking.id_room
        LEFT JOIN hotel ON hotel.id_hotel = room.id_hotel
        LEFT JOIN room_category ON room_category.id_room_category = room.id_room_category
     WHERE hotel.name = 'Космос'
        AND room_category.name = 'Люкс'
        AND checkin_date <= '2019-04-01'::date
        AND checkout_date >= '2019-04-01'::date;

-- 3. Дать список свободных номеров всех гостиниц на 22 апреля.
    SELECT hotel.name, room_category.name, room.number, room.price
      FROM room_in_booking
        LEFT JOIN room ON room.id_room = room_in_booking.id_room
        LEFT JOIN hotel ON hotel.id_hotel = room.id_hotel
        LEFT JOIN room_category ON room_category.id_room_category = room.id_room_category
     WHERE checkin_date > '2019-04-22'::date
        OR checkout_date < '2019-04-22'::date;

-- 4. Дать количество проживающих в гостинице "Космос" на 23 марта по каждой категории номеров
    SELECT count(room_in_booking.id_room_in_booking), room_category.name
      FROM room_in_booking
        LEFT JOIN room ON room.id_room = room_in_booking.id_room
        LEFT JOIN hotel ON hotel.id_hotel = room.id_hotel
        LEFT JOIN room_category ON room_category.id_room_category = room.id_room_category
     WHERE checkin_date <= '2019-04-23'::date
        AND checkout_date > '2019-04-23'::date
    GROUP BY room_category.id_room_category;

-- 5. Дать список последних проживавших клиентов по всем комнатам гостиницы “Космос”,
-- выехавшим в апреле с указанием даты выезда.
    SELECT client.name, room.id_room, room_in_booking.checkout_date
      FROM room_in_booking
        LEFT JOIN room ON room.id_room = room_in_booking.id_room
        LEFT JOIN hotel ON hotel.id_hotel = room.id_hotel
        LEFT JOIN room_category ON room_category.id_room_category = room.id_room_category
        LEFT JOIN booking ON booking.id_booking = room_in_booking.id_booking
        LEFT JOIN client ON client.id_client = booking.id_client
    WHERE hotel.name = 'Космос'
        AND (checkout_date BETWEEN '2019-04-01'::date AND '2019-04-30'::date)
    GROUP BY room.id_room, client.name, room_in_booking.checkout_date;

-- 6. Продлить на 2 дня дату проживания в гостинице “Космос” всем клиентам
-- комнат категории “Бизнес”, которые заселились 10 мая.
    UPDATE room_in_booking
    SET checkout_date = checkout_date + INTERVAL '2 days'
    WHERE id_room_in_booking IN (
        SELECT room_in_booking.id_room_in_booking
        FROM room_in_booking
            LEFT JOIN room ON room.id_room = room_in_booking.id_room
            LEFT JOIN hotel ON hotel.id_hotel = room.id_hotel
            LEFT JOIN room_category ON room_category.id_room_category = room.id_room_category
            LEFT JOIN booking ON booking.id_booking = room_in_booking.id_booking
            LEFT JOIN client ON client.id_client = booking.id_client
     WHERE hotel.name = 'Космос'
        AND room_category.name = 'Бизнес'
        AND room_in_booking.checkin_date = '2019-05-10'
        );

-- 7. Найти все "пересекающиеся" варианты проживания. Правильное состояние: не может быть
-- забронирован один номер на одну дату несколько раз, т.к. нельзя заселиться нескольким
-- клиентам в один номер. Записи в таблице room_in_booking с id_room_in_booking = 5 и 2154
-- являются примером неправильного состояния, которые необходимо найти. Результирующий кортеж
-- выборки должен содержать информацию о двух конфликтующих номерах.
    SELECT *
      FROM room_in_booking booking1, room_in_booking booking2
    WHERE booking1.id_room = booking2.id_room
        AND booking1.id_room_in_booking != booking2.id_room_in_booking
        AND (booking1.checkin_date BETWEEN booking2.checkin_date AND booking2.checkout_date
            OR booking2.checkin_date BETWEEN booking1.checkin_date AND booking1.checkout_date)
    GROUP BY booking1.id_room_in_booking, booking2.id_room_in_booking;

-- 8. Создать бронирование в транзакции.
    BEGIN TRANSACTION;
        INSERT INTO booking
        VALUES(77, '2019-07-11');
    COMMIT;

-- 9. Добавить необходимые индексы для всех таблиц.
    CREATE INDEX booking_id_client_index
     ON booking (id_client);

    CREATE INDEX room_in_booking_checkin_date_checkout_date_index
     ON room_in_booking (checkin_date, checkout_date);

    CREATE INDEX hotel_name_index
     ON hotel (name);

    CREATE INDEX room_id_hotel_id_room_category_index
     ON room (id_hotel, id_room_category);

    CREATE INDEX room_category_name_id_room_category_index
     ON room_category (name);

    CREATE INDEX room_in_booking_id_room_id_booking_index
     ON room_in_booking (id_room, id_booking);
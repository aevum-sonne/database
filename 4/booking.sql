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
    SELECT all_rooms.id_room, all_rooms.number, all_rooms.price
      FROM room AS all_rooms
    EXCEPT
      SELECT room.id_room, room.number, room.price
        FROM room
          LEFT JOIN room_in_booking rib ON room.id_room = rib.id_room
       WHERE rib.checkin_date <= '2019-04-22'::date
          OR rib.checkout_date > '2019-04-22'::date
    ORDER BY id_room;

-- 4. Дать количество проживающих в гостинице "Космос" на 23 марта по каждой категории номеров
    SELECT COUNT(room_in_booking.id_room_in_booking), room_category.name
      FROM room_in_booking
        LEFT JOIN room ON room.id_room = room_in_booking.id_room
        LEFT JOIN hotel ON hotel.id_hotel = room.id_hotel
        LEFT JOIN room_category ON room_category.id_room_category = room.id_room_category
     WHERE checkin_date <= '2019-04-23'::date
        AND checkout_date > '2019-04-23'::date
    GROUP BY room_category.id_room_category;

-- 5. Дать список последних проживавших клиентов по всем комнатам гостиницы “Космос”,
-- выехавшим в апреле с указанием даты выезда.
    WITH last_dates AS (SELECT
      room_in_booking.id_room,
      MAX(room_in_booking.checkout_date) AS departure_date
      FROM room_in_booking
        LEFT JOIN room ON room.id_room = room_in_booking.id_room
        LEFT JOIN hotel h ON room.id_hotel = h.id_hotel
     WHERE h.name = 'Космос'
      AND checkout_date BETWEEN '2019-04-01' AND '2019-04-30'
    GROUP BY room_in_booking.id_room)

    SELECT last_dates.id_room, client.name, MAX(last_dates.departure_date) AS checkout_date
      FROM last_dates
        LEFT JOIN room_in_booking ON room_in_booking.id_room = last_dates.id_room AND room_in_booking.checkout_date = last_dates.departure_date
        LEFT JOIN booking ON room_in_booking.id_booking = booking.id_booking
        LEFT JOIN client ON booking.id_client = client.id_client
    GROUP BY client.name, last_dates.id_room
    ORDER BY id_room;

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
    SELECT booking1.id_booking, booking1.checkin_date, booking1.checkout_date, booking2.id_booking,
           booking2.checkin_date, booking2.checkout_date
      FROM room_in_booking booking1
        LEFT JOIN room_in_booking AS booking2 ON booking1.id_room = booking2.id_room
    WHERE booking1.id_room_in_booking != booking2.id_room_in_booking
        AND (booking1.checkin_date < booking2.checkin_date
               AND booking1.checkout_date > booking2.checkin_date);

-- 8. Создать бронирование в транзакции.
    BEGIN TRANSACTION;
      INSERT INTO client
        (id_client, name, phone)
      VALUES
        (NEXTVAL('client_id_client_seq'), 'Taylor Swift', '+18448444944');

      INSERT INTO booking
        (id_booking, id_client, booking_date)
      VALUES
        (NEXTVAL(booking_id_booking_seq), CURRVAL(client_id_client_seq), '1999-12-13');

      INSERT INTO room_in_booking
        (id_room_in_booking, id_booking, id_room, checkin_date, checkout_date)
      VALUES
        (NEXTVAL('room_in_booking_id_room_in_booking_seq'), CURRVAL('booking_id_booking_seq'), 23, '2019-04-04', '2019-04-12');
    COMMIT;

-- 9. Добавить необходимые индексы для всех таблиц.
    create index client_name_index
      on client (name);

    create index client_phone_index
      on client (phone);

    create index hotel_name_index
      on hotel (name);

    create index room_category_name_index
      on room_category (name);

    CREATE INDEX booking_id_client_index
      ON booking (id_client);

    CREATE INDEX booking_booking_date_index
      ON booking (booking_date);

    create index room_id_hotel_index
      on room (id_hotel);

    create index room_id_room_category_index
      on room (id_room_category);

    create index room_number_index
      on room (number);

    create index room_price_index
      on room (price);

    create index room_in_booking_checkin_date_index
      on room_in_booking (checkin_date);

    create index room_in_booking_checkout_date_index
      on room_in_booking (checkout_date);

    create index room_in_booking_id_booking_index
      on room_in_booking (id_booking);

    create index room_in_booking_id_room_index
      on room_in_booking (id_room);
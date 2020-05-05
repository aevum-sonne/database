-- 1. Добавить внешние ключи.
    ALTER TABLE dealer
      ADD CONSTRAINT dealer_company_id_company_fk
        FOREIGN KEY (id_company) REFERENCES company;

    ALTER TABLE production
      ADD CONSTRAINT production_company_id_company_fk
        FOREIGN KEY (id_company) REFERENCES company;

    ALTER TABLE production
      ADD CONSTRAINT production_medicine_id_medicine_fk
        FOREIGN KEY (id_medicine) REFERENCES medicine;

    ALTER TABLE "order"
      ADD CONSTRAINT order_dealer_id_dealer_fk
        FOREIGN KEY (id_dealer) REFERENCES dealer;

    ALTER TABLE "order"
      ADD CONSTRAINT order_pharmacy_id_pharmacy_fk
        FOREIGN KEY (id_pharmacy) REFERENCES pharmacy;

    ALTER TABLE "order"
      ADD CONSTRAINT order_production_id_production_fk
        FOREIGN KEY (id_production) REFERENCES production;

-- 2. Выдать информацию по всем заказам лекарства “Кордерон” компании “Аргус”
-- с указанием названий аптек, дат, объема заказов.
    CREATE VIEW order_view AS
    SELECT date, quantity, pharmacy.name AS pharmacy_name, medicine.name AS medicine_name,
           dealer.name as dealer_name, company.name AS company_name, production.rating,
           production.price
      FROM
        "order"
        LEFT JOIN pharmacy ON pharmacy.id_pharmacy = "order".id_pharmacy
        LEFT JOIN dealer ON dealer.id_dealer = "order".id_dealer
        LEFT JOIN production ON production.id_production = "order".id_production
        LEFT JOIN medicine ON medicine.id_medicine = production.id_medicine
        LEFT JOIN company ON company.id_company = production.id_company;

--     DROP VIEW IF EXISTS order_view;

    SELECT pharmacy_name, date, quantity
      FROM
        order_view
     WHERE medicine_name = 'Кордеон'
      AND company_name = 'Аргус';

-- 3. Дать список лекарств компании “Фарма”, на которые не были сделаны заказы
-- до 25 января.
    SELECT medicine_name
      FROM
        order_view
     WHERE company_name = 'Фарма'
      AND date > '2019-01-25';

-- 4. Дать минимальный и максимальный баллы лекарств каждой фирмы, которая
-- оформила не менее 120 заказов.
    SELECT company_name, MAX(rating), MIN(rating)
      FROM
        order_view
     WHERE quantity >= 120
    GROUP BY company_name;

-- 5. Дать списки сделавших заказы аптек по всем дилерам компании “AstraZeneca”.
-- Если у дилера нет заказов, в названии аптеки проставить NULL.
    SELECT dealer_name,
           pharmacy_name
      FROM
        order_view
     WHERE company_name = 'AstraZeneca'
    ORDER BY dealer_name;

-- 6. Уменьшить на 20% стоимость всех лекарств, если она превышает 3000, а
-- длительность лечения не более 7 дней.
    UPDATE production
    SET price = 0.8 * price
     WHERE production.id_production
      IN (
        SELECT production.id_production
          FROM production
          LEFT JOIN medicine ON production.id_medicine = medicine.id_medicine
          LEFT JOIN "order" ON "order".id_production = production.id_production
         WHERE production.price > 3000::money
          AND medicine.cure_duration <= 7
      );

-- 7. Добавить необходимые индексы.
    CREATE INDEX production_id_company_index
      ON production (id_company);
    
    CREATE INDEX production_id_medicine_index
      ON production (id_medicine);
    
    CREATE INDEX dealer_id_company_index
      ON dealer (id_company);
    
    CREATE INDEX order_id_dealer_index
      ON "order" (id_dealer);
    
    CREATE INDEX order_id_pharmacy_index
      ON "order" (id_pharmacy);
    
    CREATE INDEX order_id_production_index
      ON "order" (id_production);
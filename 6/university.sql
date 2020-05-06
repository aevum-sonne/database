-- 1. Добавить внешние ключи.
      ALTER TABLE student
        ADD CONSTRAINT student_group_id_group_fk
          FOREIGN KEY (id_group) REFERENCES "group";

      ALTER TABLE lesson
        ADD CONSTRAINT lesson_group_id_group_fk
          FOREIGN KEY (id_group) REFERENCES "group";

      ALTER TABLE lesson
        ADD CONSTRAINT lesson_subject_id_subject_fk
          FOREIGN KEY (id_subject) REFERENCES subject;

      ALTER TABLE lesson
        ADD CONSTRAINT lesson_teacher_id_teacher_fk
          FOREIGN KEY (id_teacher) REFERENCES teacher;

      ALTER TABLE mark
        ADD CONSTRAINT mark_lesson_id_lesson_fk
          FOREIGN KEY (id_lesson) REFERENCES lesson;

      ALTER TABLE mark
        ADD CONSTRAINT mark_student_id_student_fk
          FOREIGN KEY (id_student) REFERENCES student (id_student);

-- 2. Выдать оценки студентов по информатике если они обучаются данному предмету.
-- Оформить выдачу данных с использованием view.
      CREATE VIEW university_view AS
      SELECT mark.id_mark, l.id_lesson, student.id_student, g.id_group,
             mark.mark, student.name AS student_name, student.phone,
             l.date as lesson_date, s.name AS subject_name, g.name as group_name
        FROM mark
          LEFT JOIN student ON mark.id_student = student.id_student
          LEFT JOIN "group" g ON student.id_group = g.id_group
          LEFT JOIN lesson l ON g.id_group = l.id_group
          LEFT JOIN subject s ON l.id_subject = s.id_subject
          LEFT JOIN teacher t ON l.id_teacher = t.id_teacher
      ORDER BY
          id_mark;

      SELECT id_mark, student_name, mark
        FROM university_view
      WHERE
        subject_name = 'Информатика';

-- 3. Дать информацию о должниках с указанием фамилии студента и названия предмета.
-- Должниками считаются студенты, не имеющие оценки по предмету, который ведется в группе.
-- Оформить в виде процедуры, на входе идентификатор группы.
      CREATE FUNCTION PrintDebtors(groupId int)
      RETURNS TABLE (
                      student_name varchar(50),
                      subject_name varchar(100)
                    )
      LANGUAGE SQL
      AS
      $$
        SELECT std.name, sub.name
          FROM "group" AS g
            LEFT JOIN student std on g.id_group = std.id_group
            LEFT JOIN lesson l on g.id_group = l.id_group
            LEFT JOIN mark m on l.id_lesson = m.id_lesson
                                  AND std.id_student = m.id_student
            LEFT JOIN subject sub on l.id_subject = sub.id_subject
         WHERE g.id_group = groupId
        GROUP BY
          std.name, sub.name
        HAVING COUNT(mark) = 0
      $$;

--       DROP PROCEDURE PrintDebtors(groupId INT);

      SELECT * FROM  PrintDebtors(1);
      SELECT * FROM  PrintDebtors(2);
      SELECT * FROM  PrintDebtors(3);
      SELECT * FROM  PrintDebtors(4);

-- 4. Дать среднюю оценку студентов по каждому предмету для тех предметов, по которым
-- занимается не менее 35 студентов.
      SELECT DISTINCT ON (student_name) student_name, subject_name, AVG(mark)
        FROM university_view
      GROUP BY student_name, subject_name
      HAVING COUNT(id_student) >= 35;

-- 5. Дать оценки студентов специальности ВМ по всем проводимым предметам с
-- указанием группы, фамилии, предмета, даты. При отсутствии оценки заполнить
-- значениями NULL поля оценки.
      SELECT DISTINCT ON (id_student) id_student, student_name, group_name, subject_name, lesson_date
        FROM university_view
       WHERE group_name = 'ВМ'
      ORDER BY id_student;

-- 6. Всем студентам специальности ПС, получившим оценки меньшие 5 по предмету БД до 12.05,
-- повысить эти оценки на 1 балл.
      UPDATE mark
      SET mark = mark + 1
       WHERE mark.id_mark
        IN (
          SELECT mark.id_mark
            FROM mark
            LEFT JOIN student s ON mark.id_student = s.id_student
            LEFT JOIN "group" g ON s.id_group = g.id_group
            LEFT JOIN lesson l ON mark.id_lesson = l.id_lesson
            LEFT JOIN subject sub ON l.id_subject = sub.id_subject
           WHERE g.name = 'ПС'
            AND sub.name = 'БД'
            AND l.date < '12.05.2019'::DATE
        );

-- 7. Добавить необходимые индексы
          CREATE INDEX group_name_index
            ON "group" (name);
          
          CREATE INDEX subject_name_index
            ON subject (name);
          
          CREATE INDEX teacher_name_index
            ON teacher (name);
          
          CREATE INDEX teacher_phone_index
            ON teacher (phone);
          
          CREATE INDEX lesson_date_index
            ON lesson (date);
          
          CREATE INDEX student_name_index
            ON student (name);
          
          CREATE INDEX student_phone_index
            ON student (phone);
          
          CREATE INDEX mark_mark_index
            ON mark (mark);
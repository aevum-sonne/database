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
      CREATE VIEW informatics_mark AS
      SELECT student.name AS student_name,
             subject.name AS subject_name,
             mark.mark
        FROM mark
               LEFT JOIN student ON mark.id_student = student.id_student
               LEFT JOIN lesson ON mark.id_lesson = lesson.id_lesson
               LEFT JOIN subject ON lesson.id_subject = subject.id_subject
      WHERE subject.name = 'Информатика'
      ORDER BY student_name;

      SELECT * FROM informatics_mark;

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
            LEFT JOIN student std ON g.id_group = std.id_group
            LEFT JOIN lesson l ON g.id_group = l.id_group
            LEFT JOIN mark m ON l.id_lesson = m.id_lesson
                                  AND std.id_student = m.id_student
            LEFT JOIN subject sub ON l.id_subject = sub.id_subject
         WHERE g.id_group = groupId
        GROUP BY
          std.name, sub.name
        HAVING COUNT(mark) = 0
      $$;

--       DROP PROCEDURE PrintDebtors(groupId INT);

      SELECT * FROM PrintDebtors(1);
      SELECT * FROM PrintDebtors(2);
      SELECT * FROM PrintDebtors(3);
      SELECT * FROM PrintDebtors(4);

-- 4. Дать среднюю оценку студентов по каждому предмету для тех предметов, по которым
-- занимается не менее 35 студентов.
      CREATE VIEW average_mark AS
      SELECT s.name,
             AVG(m.mark) AS average_mark
        FROM student
          LEFT JOIN mark m ON student.id_student = m.id_student
          LEFT JOIN lesson l ON m.id_lesson = l.id_lesson
          LEFT JOIN subject s ON l.id_subject = s.id_subject
      GROUP BY s.name
      HAVING COUNT(DISTINCT student.id_student) >= 35;

      SELECT * FROM average_mark;

-- 5. Дать оценки студентов специальности ВМ по всем проводимым предметам с
-- указанием группы, фамилии, предмета, даты. При отсутствии оценки заполнить
-- значениями NULL поля оценки.
      CREATE VIEW vm_mark AS
      SELECT g.name AS "group",
             student.name AS student_name,
             subject.name AS subject_name,
             lesson.date AS date
        FROM student
          LEFT JOIN "group" g ON student.id_group = g.id_group
          LEFT JOIN lesson ON g.id_group = lesson.id_group
          LEFT JOIN subject ON lesson.id_subject = subject.id_subject
          LEFT JOIN mark ON lesson.id_lesson = mark.id_lesson AND student.id_student = mark.id_student
       WHERE g.name = 'ВМ'
      ORDER BY student.name;

      DROP VIEW vm_mark;

      SELECT * FROM vm_mark;

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

          CREATE INDEX lesson_id_subject_id_group_index
            ON lesson (id_subject, id_group);

          CREATE INDEX lesson_id_teacher_index
            ON lesson (id_teacher);

          CREATE INDEX lesson_date_index
            ON lesson (date);

          CREATE INDEX student_id_group_index
            ON student (id_group);

          CREATE INDEX student_name_index
            ON student (name);

          CREATE INDEX student_phone_index
            ON student (phone);

          CREATE INDEX mark_id_lesson_index
            ON mark (id_lesson);
          
          CREATE INDEX mark_id_student_index
            ON mark (id_student);

          CREATE INDEX mark_mark_index
            ON mark (mark);


--Таблица "заявка"
create table bid (
	id serial primary key, 
	product_type varchar(50),
	client_name varchar(100),
	is_company boolean,
	amount numeric(12,2)
);

insert into bid (product_type, client_name, is_company, amount) values
('credit', 'Petrov Petr Petrovich', false, 1000000),
('credit', 'Coca cola', true, 100000000),
('deposit', 'Soho bank', true, 12000000),
('deposit', 'Kaspi bank', true, 18000000),
('deposit', 'Miksumov Anar Raxogly', false, 500000),
('debit_card', 'Miksumov Anar Raxogly', false, 0),
('credit_card', 'Kipu Masa Masa', false, 5000),
('credit_card', 'Popova Yana Andreevna', false, 25000),
('credit_card', 'Miksumov Anar Raxogly', false, 30000),
('debit_card', 'Saronova Olga Olegovna', false, 0);


--Скрипт №1 - Распределение заявок по продуктовым таблицам
--Создать скрипт, который будет: 
--1. Создавать таблицы на основании таблицы bid:
--Имя таблицы должно быть основано на типе продукта + является ли он компанией
--Если такая таблица уже есть, скрипт не должен падать!
--Например:
--для записи где product_type = credit, is_company = false будет создана таблица:
--person_credit, с колонками: id (новый id), client_name, amount
--для записи где product_type = credit, is_company = true:
--company_credit, с колонками: id (новый id), client_name, amount

--2. Копировать заявки в соответствующие таблицы c помощью конструкции:
--2.1 Для вставки значений можно использовать конструкцию
--insert into (col1, col2)
--select col1, col2
--from [наименование таблицы]
--2.2 Для исполнения динамического запроса с параметрами можно использовать конструкцию
--execute '[текст запроса]' using [значение параметра №1], [значение параметра №2].
--Пример:
--execute 'select * from product where product_type = $1 and is_company = $2' using 'credit', false;

DO $$
	DECLARE
		result_row record;
		res_is_company varchar (50);
		test varchar;
		c_table_name varchar;
	BEGIN
		FOR result_row IN (SELECT DISTINCT ON (product_type) * FROM bid) LOOP
			IF result_row.is_company = false THEN res_is_company := 'person';
			ELSE res_is_company := 'company';
			END IF;
			c_table_name := res_is_company || '_' || result_row.product_type;
			EXECUTE 'CREATE TABLE ' || c_table_name || '(
									id serial primary key, 
									client_name varchar(100),
									amount numeric(12,2)
									)';
			EXECUTE 'INSERT INTO ' || c_table_name || '(client_name, amount) SELECT client_name, amount FROM bid';
		END LOOP;
	END;
$$


--Скрипт №2 - Начисление процентов по кредитам за день
--Создать скрипт, который:
--1. Создаст(если нет) таблицу credit_percent для начисления процентов по кредитам: имя клиента, сумма начисленных процентов
--2. Имеет переменную - базовая кредитная ставка со значением "0.1" 
--3. Возьмет значения из таблиц person_credit и company_credit и вставит их в credit_percent:
-- необходимо выбрать id клиента и (сумму кредита * базовую ставку) / 365 для компаний
-- необходимо выбрать id клиента и (сумму кредита * (базовую ставку + 0.05) / 365 для физ лиц
--4. Печатает на экран общую сумму начисленных процентов в таблице

--Скрипт №3 - Разделение ответственности. 
--Менеджеры компаний, должны видеть только заявки компаний.
--Создать view которая отображает только заявки компаний
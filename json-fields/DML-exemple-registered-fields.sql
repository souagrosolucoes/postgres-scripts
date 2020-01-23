--//creating a new table with a column "custom_fields" as type json
DROP TABLE IF EXISTS table_test;

CREATE TABLE table_test (
    "id" serial NOT NULL,
    "name" character varying(256) NULL,
    "email" character varying(256) NULL,
    "custom_fields" json NULL,
    CONSTRAINT "table_test_id" PRIMARY KEY ("id"),
    CONSTRAINT "table_test_validate" CHECK (
       name ~* '^[\d]*[a-z_][a-z\d_]*$' and
       email ~* '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$'
    )
);

--// add TRIGGER to the table that will validate the record custom fields in the "custom_fields" column
CREATE TRIGGER validate_custom_fields_table_test BEFORE INSERT OR UPDATE ON table_test
FOR EACH ROW EXECUTE FUNCTION validate_constraints();


--//insert a new values in "registered_fields" for table "table_test" (change the corrects ID's for column "metadata_fields_id" generate in your base)
INSERT INTO "registered_fields" ("metadata_fields_id", "slug", "label", "description", "table_name", "enable", "required")
VALUES 
    (1, 'cep_1',        'CEP',                  'CEP da cidade',                    'table_test', '1', '1'),
    (5, 'text_1',       'texto',                'texto aberto',                     'table_test', '1', '1'),
    (6, 'phone_br_1',   'telefone',             'telefone formato brasileiro',      'table_test', '1', '1'),
    (3, 'phone',        'telefone',             'telefone formato internacional',   'table_test', '1', '1'),
    (4, 'numeric_1',    'numeros',              'numeros',                          'table_test', '1', '1'),
    (7, 'email_1',      'email',                'email',                            'table_test', '1', '1'),
    (8, 'timestamp',    'data timestamp',       'data em timestamp',                'table_test', '1', '1'),
    (9, 'date_1',       'data - (yyyy/mm/dd)',  'data formato (yyyy/mm/dd)',        'table_test', '1', '1'),
    (2, 'date_2',       'data - (mm/dd/yyyy)',  'data formato (mm/dd/yyyy)',        'table_test', '1', '1'),
    (10,'url',          'url',                  'url',                              'table_test', '1', '1');


--//insert values in table:
INSERT INTO "table_test" ("name", "email", "custom_fields")
VALUES (
    'teste1',
    'vinicius@email.com', '{
        "cep_1":"47640-000",
        "text_1":"um texto qualquer",
        "phone_br_1":"(77)93483-4453",
        "phone":"+55(77)93483-4453",
        "numeric_1":12345,
        "email_1": "vnicius@email.com",
        "timestamp": "2020-01-25T03:14:07",
        "date_2":"05/15/2019",
        "date_1":"2019/05/15",
        "url":"https://www.postgresql.org/docs/9.1/sql-createtable.html"
    }');
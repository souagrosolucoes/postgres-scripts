CREATE OR REPLACE FUNCTION is_date(s varchar) 
RETURNS boolean AS $BODY$
BEGIN
    perform s::date;
    return true;
    RAISE EXCEPTION 'metadata is not a valid date';
END;
$BODY$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION validate_constraints()
RETURNS trigger AS $BODY$
DECLARE
    _field record;
    _metadata record;
    _registered_field record;
    _ct int;
    _tg_table_name text := quote_ident(TG_TABLE_NAME);
BEGIN

    FOR _registered_field IN
        SELECT * FROM registered_fields rf INNER JOIN metadata_fields mf ON rf.metadata_fields_id = mf.id
        WHERE rf.table_name = _tg_table_name and rf.enable = true and rf.required = true LOOP
        IF (new.custom_fields->_registered_field.slug IS NULL) THEN
            RAISE EXCEPTION 'metadata % is required', _registered_field.slug;
        END IF;
    END LOOP;

    IF new.custom_fields::jsonb is null THEN
        RETURN new;
    END IF;

    FOR _field IN SELECT * FROM json_each_text(new.custom_fields) LOOP
        EXECUTE format('SELECT * FROM registered_fields rf WHERE rf.table_name = ''%s'' and rf.enable = true and rf.slug = ''%s'' ', _tg_table_name, _field.key);
        GET DIAGNOSTICS _ct = ROW_COUNT;
        IF _ct = 0 THEN
            RAISE EXCEPTION 'metadata % custom fields not exist', _field.key;
        END IF;

        FOR _metadata IN
            SELECT * FROM registered_fields rf INNER JOIN metadata_fields mf ON rf.metadata_fields_id = mf.id 
            WHERE rf.table_name = _tg_table_name and rf.enable = true and rf.slug = _field.key LOOP

            IF _metadata.required = true and _field.value IS null THEN
                RAISE EXCEPTION 'custom_fields is required';
            END IF;
            
            IF _field.value !~ _metadata.constraints THEN
                RAISE EXCEPTION 'custom_fields value does not have a valid value (% for constraint: %)', _field.value, _metadata.constraints;
            END IF;

            CASE
                WHEN _metadata.type = 'numeric' THEN
                    new.custom_fields = jsonb_set(new.custom_fields::jsonb, ('{'||_field.key||'}')::text[], ('' || to_number(cast(_field.value as text), '99999999999999999999D9999999999')::numeric || '')::jsonb, true);
                WHEN _metadata.type = 'date' THEN
                    PERFORM is_date(_field.value);
                ELSE
            END CASE;

        END LOOP;
    END LOOP;

    RETURN new;
END;
$BODY$
LANGUAGE 'plpgsql';

CREATE TYPE metadata_fields_type AS ENUM ('numeric', 'date', 'text');

CREATE TABLE metadata_fields (
    "id" serial NOT NULL,
    "name" character varying(256) NOT NULL,
    "constraints" text NOT NULL,
    "type" metadata_fields_type DEFAULT 'text' NOT NULL,
    "locked" boolean DEFAULT true NOT NULL,
    "message" text,
    CONSTRAINT "metadata_fields_id" PRIMARY KEY ("id")
);

CREATE TABLE registered_fields (
    "id" serial NOT NULL,
    "metadata_fields_id" int NOT NULL,
    "slug" character varying(256) NOT NULL,
    "label" character varying(256) NOT NULL,
    "description" character varying(256),
    "table_name" character varying(256) NOT NULL,
    "enable" boolean DEFAULT true NOT NULL,
    "required" boolean DEFAULT false NOT NULL,
    "error_code" text,
    "error_message" text,
    CONSTRAINT "registered_fields_id" PRIMARY KEY ("id"),
    CONSTRAINT "registered_fields_slug" UNIQUE ("slug"),
    CONSTRAINT "registered_fields_foreign_metadata_fields" FOREIGN KEY ("metadata_fields_id") REFERENCES metadata_fields
);

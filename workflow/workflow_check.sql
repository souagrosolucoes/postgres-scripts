CREATE OR REPLACE FUNCTION workflow_check_change_step(d int, wf int, entity_id int, table_name varchar)
RETURNS boolean AS $BODY$
DECLARE
    _ct int := 0;
    _current_step int := null;
BEGIN

    EXECUTE format('SELECT (SELECT step_id FROM "%s" WHERE entity_id = ' || entity_id || ' and workflow_group_id = ' || wf || ') as current_step;', table_name) INTO _current_step;
    IF(_current_step == d) THEN
        return true;
    END IF;

    EXECUTE format('SELECT * FROM "next_setp" WHERE COALESCE(setp_id_src, -1) = COALESCE(' || _current_step || ', -1) AND setp_id_dst = ' || d);
    GET DIAGNOSTICS _ct = ROW_COUNT;
    IF _ct = 0 THEN
        return false;
    END IF;
    return true;
END;
$BODY$
LANGUAGE 'plpgsql';


CREATE OR REPLACE FUNCTION workflow_insert_historic()
RETURNS trigger AS $BODY$
DECLARE
    _historic_id int := 0;
    _historic_table_name varchar := quote_ident(TG_TABLE_NAME) || '_historic';
BEGIN
    IF (old.step_id = new.step_id) THEN
        RETURN new;
    END IF;

    IF (TG_OP = 'UPDATE') THEN    
        EXECUTE format('UPDATE ' || _historic_table_name || ' SET time_to = now() WHERE id = ' || new.historic_id);
        old.step_id = new.step_id;
        new = old;
    END IF;

    EXECUTE format('
        INSERT INTO ' || _historic_table_name || '(step_id, workflow_group_id, entity_id) 
        VALUES(' || new.step_id || ', ' || new.workflow_group_id || ', ' || new.entity_id || ') RETURNING id;' 
    ) INTO _historic_id;
    new.historic_id = _historic_id;
    RETURN new;
    
END;
$BODY$
LANGUAGE 'plpgsql';



CREATE TABLE "workflow_group" (
    "id" serial NOT NULL,
    "name" character varying(256) NOT NULL,
    "description" text,
    CONSTRAINT "workflow_group_id" PRIMARY KEY ("id")
);

CREATE TABLE "workflow_group_step" (
    "setp_id" serial NOT NULL,
    "workflow_group_id" integer NOT NULL,
    "name" character varying(256) NOT NULL,
    "position_order" integer NOT NULL,
    "description" text,
    CONSTRAINT "workflow_group_step_setp_id_workflow_group_id" PRIMARY KEY ("setp_id", "workflow_group_id"),
    CONSTRAINT "workflow_group_step_workflow_group_id_fkey" FOREIGN KEY (workflow_group_id) REFERENCES workflow_group(id)
);

CREATE TABLE "workflow_next_setp" (
    "id" serial NOT NULL,
    "setp_id_src" integer,
    "setp_id_dst" integer NOT NULL,
    "workflow_group_id" integer NOT NULL,
    CONSTRAINT "workflow_next_setp_id" PRIMARY KEY ("id"),
    CONSTRAINT "workflow_next_setp_setp_id_src_setp_id_dst" UNIQUE ("setp_id_src", "setp_id_dst"),
    CONSTRAINT "workflow_next_setp_setp_id_dst_workflow_group_id_fkey" FOREIGN KEY (setp_id_dst, workflow_group_id) REFERENCES workflow_group_step(setp_id, workflow_group_id),
    CONSTRAINT "workflow_next_setp_setp_id_src_workflow_group_id_fkey" FOREIGN KEY (setp_id_src, workflow_group_id) REFERENCES workflow_group_step(setp_id, workflow_group_id)
);

CREATE TABLE "workflow_next_steps_dependence" (
    "id" serial NOT NULL,
    "next_setp_id" integer NOT NULL,
    "setp_id" integer NOT NULL,
    "workflow_group_id" integer NOT NULL,
    CONSTRAINT "workflow_next_steps_dependence_id" PRIMARY KEY ("id"),
    CONSTRAINT "workflow_next_steps_dependence_next_setp_id_setp_id_workflow_gr" UNIQUE ("next_setp_id", "setp_id", "workflow_group_id"),
    CONSTRAINT "workflow_next_steps_dependence_next_setp_id_fkey" FOREIGN KEY (next_setp_id) REFERENCES workflow_next_setp(id),
    CONSTRAINT "workflow_next_steps_dependence_setp_id_workflow_group_id_fkey" FOREIGN KEY (setp_id, workflow_group_id) REFERENCES workflow_group_step(setp_id, workflow_group_id)
);

CREATE TABLE "table_test_workflow_step_historic" (
    "id" serial NOT NULL,
    "step_id" integer NOT NULL,
    "workflow_group_id" integer NOT NULL,
    "entity_id" integer NOT NULL,
    "time_from" timestamp DEFAULT now() NOT NULL,
    "time_to" timestamp,
    CONSTRAINT "table_test_workflow_step_historic_id" PRIMARY KEY ("id"),
    CONSTRAINT "table_test_workflow_step_histori_step_id_workflow_group_id_fkey" FOREIGN KEY (step_id, workflow_group_id) REFERENCES workflow_group_step(setp_id, workflow_group_id),
    CONSTRAINT "table_test_workflow_step_historic_entity_id_fkey" FOREIGN KEY (entity_id) REFERENCES table_test(id),
    CONSTRAINT "table_test_workflow_validate" CHECK (workflow_check_change_step(step_id, workflow_group_id, entity_id, 'table_test_workflow_step'))
);

CREATE TABLE "table_test_workflow_step" (
    "id" serial NOT NULL,
    "entity_id" integer NOT NULL,
    "workflow_group_id" integer NOT NULL,
    "step_id" integer NOT NULL,
    "historic_id" integer NOT NULL,
    CONSTRAINT "table_test_workflow_step_entity_id_workflow_group_id" UNIQUE ("entity_id", "workflow_group_id"),
    CONSTRAINT "table_test_workflow_step_id" PRIMARY KEY ("id"),
    CONSTRAINT "table_test_workflow_step_entity_id_fkey" FOREIGN KEY (entity_id) REFERENCES table_test(id),
    CONSTRAINT "table_test_workflow_step_historic_id_fkey" FOREIGN KEY (historic_id) REFERENCES table_test_workflow_step_historic(id)
);

CREATE TRIGGER table_test_workflow_step_insert_historic BEFORE INSERT OR UPDATE ON table_test_workflow_step
FOR EACH ROW EXECUTE FUNCTION workflow_insert_historic();

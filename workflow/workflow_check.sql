CREATE OR REPLACE FUNCTION workflow_check_change_step(d int, wf int, entity_id int, table_name varchar)
RETURNS boolean AS $BODY$
DECLARE
    _next_step_id int := null;
    _current_step int := null;
    _wf_current_step int := null;
    _count int := 0;
    _dependence record;
BEGIN

    EXECUTE format('SELECT (SELECT step_id FROM "%s" WHERE entity_id = ' || entity_id || ' and workflow_group_id = ' || wf || ') as current_step;', table_name) INTO _current_step;
    IF(_current_step = d) THEN
        RAISE EXCEPTION 'source is the same as the destination';
        return false;
    END IF;

    EXECUTE format('SELECT id FROM "workflow_next_step" WHERE COALESCE(step_id_src, -1) = COALESCE(' || _current_step || ', -1) AND step_id_dst = ' || d) INTO _next_step_id;
    IF _next_step_id = null THEN
        return false;
    END IF;

    FOR _dependence IN
        SELECT * FROM workflow_next_step_dependence where next_step_id = _next_step_id
    LOOP
        EXECUTE format('SELECT (SELECT step_id FROM "%s" WHERE entity_id = ' || entity_id || ' and workflow_group_id = ' || _dependence.workflow_group_id || ') as wf_current_step;', table_name) INTO _wf_current_step;
        EXECUTE format('SELECT count(*) FROM workflow_next_step_dependence_step where next_step_id =' || _next_step_id || ' AND workflow_group_id =' || _dependence.workflow_group_id || ' AND step_id =' || _wf_current_step) INTO _count;
        IF _count = 0 THEN
            return false;
        END IF;
    END LOOP;

    return true;
END;
$BODY$
LANGUAGE 'plpgsql';


CREATE OR REPLACE FUNCTION workflow_insert_historic()
RETURNS trigger AS $BODY$
DECLARE
    _historic_id int := 0;
    _ct int := 0;
    _table_name varchar := quote_ident(TG_TABLE_NAME);
    _historic_table_name varchar := quote_ident(TG_TABLE_NAME) || '_historic';
BEGIN
    EXECUTE format('SELECT count(id) FROM "workflow_entity" WHERE "workflow_group_id" = ' || new.workflow_group_id || ' AND "table_name" = ''' || _table_name ||  '''' ) INTO _ct;
    IF(_ct == 0) THEN
        RAISE EXCEPTION 'workflow not registered for this table';
    END IF;

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

CREATE TABLE "workflow_entity" (
    "id" serial NOT NULL,
    "workflow_group_id" integer NOT NULL,
    "table_name" text NOT NULL,
    CONSTRAINT "workflow_entity_id" PRIMARY KEY ("id"),
    CONSTRAINT "workflow_entity_workflow_group_id_fkey" FOREIGN KEY (workflow_group_id) REFERENCES workflow_group(id)
);

CREATE TABLE "workflow_group_step" (
    "step_id" serial NOT NULL,
    "workflow_group_id" integer NOT NULL,
    "name" character varying(256) NOT NULL,
    "position_order" integer NOT NULL,
    "description" text,
    CONSTRAINT "workflow_group_step_step_id_workflow_group_id" PRIMARY KEY ("step_id", "workflow_group_id"),
    CONSTRAINT "workflow_group_step_workflow_group_id_fkey" FOREIGN KEY (workflow_group_id) REFERENCES workflow_group(id)
);

CREATE TABLE "workflow_next_step" (
    "id" serial NOT NULL,
    "step_id_src" integer,
    "step_id_dst" integer NOT NULL,
    "workflow_group_id" integer NOT NULL,
    CONSTRAINT "workflow_next_step_id" PRIMARY KEY ("id"),
    CONSTRAINT "workflow_next_step_step_id_src_step_id_dst" UNIQUE ("step_id_src", "step_id_dst"),
    CONSTRAINT "workflow_next_step_step_id_dst_workflow_group_id_fkey" FOREIGN KEY (step_id_dst, workflow_group_id) REFERENCES workflow_group_step(step_id, workflow_group_id),
    CONSTRAINT "workflow_next_step_step_id_src_workflow_group_id_fkey" FOREIGN KEY (step_id_src, workflow_group_id) REFERENCES workflow_group_step(step_id, workflow_group_id)
);

CREATE TABLE "workflow_next_step_dependence" (
    "next_step_id" integer NOT NULL,
    "workflow_group_id" integer NOT NULL,
    CONSTRAINT "workflow_next_steps_dependence_id" PRIMARY KEY ("next_step_id", "workflow_group_id"),
    CONSTRAINT "workflow_next_steps_dependence_next_step_id_fkey" FOREIGN KEY (next_step_id) REFERENCES workflow_next_step(id),
    CONSTRAINT "workflow_next_steps_workflow_group_id_fkey" FOREIGN KEY (workflow_group_id) REFERENCES workflow_group(id)
);

CREATE TABLE "workflow_next_step_dependence_step" (
    "id" serial NOT NULL,
    "step_id" integer NOT NULL,
    "workflow_group_id" integer NOT NULL,
    "next_step_id" integer NOT NULL,
    CONSTRAINT "workflow_next_step_dependence_step_id" PRIMARY KEY ("id"),
    CONSTRAINT "workflow_next_step_dependence_step_id_workflow_group_id_fkey" FOREIGN KEY (step_id, workflow_group_id) REFERENCES workflow_group_step(step_id, workflow_group_id),
    CONSTRAINT "workflow_next_step_dependence_step_id_workflow_next_step_dependence_id_fkey" FOREIGN KEY (next_step_id, workflow_group_id) REFERENCES workflow_next_step_dependence(next_step_id, workflow_group_id)
);


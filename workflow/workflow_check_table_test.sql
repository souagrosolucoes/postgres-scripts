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

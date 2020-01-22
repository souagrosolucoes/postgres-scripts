INSERT INTO "workflow_group" ("id", "name", "description") VALUES
(1,	'wf_Fases',	'workflow fases'),
(2,	'wf_Status',	'workflow status');

INSERT INTO "workflow_group_step" ("step_id", "workflow_group_id", "name", "position_order", "description") VALUES
(1,	1,	'Fase-1',	1,	'Fase 1'),
(2,	1,	'Fase-2',	2,	'Fase 2'),
(3,	1,	'Fase-3',	3,	'Fase 3'),
(4,	1,	'Fase-4',	4,	'Fase 4'),
(5,	2,	'Status-1',	1,	'Status 1'),
(6,	2,	'Status-2',	2,	'Status 2'),
(7,	2,	'Status-3',	3,	'Status 3'),
(8,	2,	'Status-4',	4,	'Status 4'),
(9,	2,	'Status-5',	5,	'Status 5');

INSERT INTO "workflow_next_step" ("id", "step_id_src", "step_id_dst", "workflow_group_id") VALUES
(1,	NULL,	1,	1),
(2,	1,	2,	1),
(3,	2,	3,	1),
(4,	3,	4,	1),
(5,	NULL,	5,	2),
(6,	5,	6,	2),
(7,	6,	7,	2),
(8,	7,	8,	2),
(9,	8,	9,	2),
(10,	5,	7,	2),
(11,	5,	8,	2),
(12,	6,	8,	2);

INSERT INTO "workflow_next_step_dependence" ("next_step_id", "workflow_group_id") VALUES
(10,	1),
(8,	1),
(11,	1),
(12,	1),
(9,	1),
(9,	2);

INSERT INTO "workflow_next_step_dependence_step" ("id", "step_id", "workflow_group_id", "next_step_id") VALUES
(1,	2,	1,	10),
(2,	3,	1,	11),
(3,	3,	1,	8),
(4,	3,	1,	12),
(5,	3,	1,	9),
(6,	4,	1,	9),
(8,	8,	2,	9);

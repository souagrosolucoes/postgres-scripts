# Gerenciamento de WorkFlow (fluxo de trabalho)
:shipit:

O script [workflow_check.sql](workflow_check.sql)
 contém as tabelas e funções para criar a estrutura básica do gerenciamento de fluxos de trabalho de forma genérica, permitindo que o usuário possa criar e organizar de forma genérica os seus próprios fluxos.

De forma geral teremos as seguintes entidades

| Entidades                         	| Tipo   	| Descrição                                                                                   	|
|-----------------------------------	|--------	|---------------------------------------------------------------------------------------------	|
| workflow_group                    	| tabela 	| Registra os workflows que serão gerenciados.                                                	|
| workflow_entity                   	| tabela 	| Registra o nome das tabelas que mantêm o status<br>atual para cada workflow                 	|
| workflow_group_step               	| tabela 	| Registra cada uma dos passos presente em um <br>determinado workflows                       	|
| workflow_next_setp                	| tabela 	| Registra como será a interação entre os passos                                              	|
| workflow_next_step_dependence     	| tabela 	| Registra as dependencias de quais workflows um determinado <br> passo é depedente           	|
| workflow_next_step_dependence_step 	| tabela 	| Registra as dependencias para que uma interação <br>entre os passos possa acontecer         	|
| workflow_check_change_step        	| função 	| Função que verifica se uma alteração em um dos <br>passos sobre um registro é válida.       	|
| workflow_insert_historic          	| função 	| <br>Função que atualiza o histórico de alterações de <br><br>um workflows sobre um registro 	|

o modelo de relacionamento entre as entidade é definido como:

![modelo](_img/model.png "modelo de entidade")

## Exemplo de workflow
Os dois workflows mostrado na figura serão utilizado como referencia no exemplo:

![workflow](_img/workflows.png "exemplo de workflow")

### tabela: `workflow_group`

| id 	| name      	| description     	|
|----	|-----------	|-----------------	|
| 1  	| wf_Fases  	| workflow fases  	|
| 2  	| wf_Status 	| workflow status 	|


### tabela: `workflow_group_step`

| step_id 	| workflow_group_id 	| name     	| position_order 	| description 	|
|---------	|-------------------	|----------	|----------------	|-------------	|
| 1       	| 1                 	| Fase-1   	| 1              	| Fase 1      	|
| 2       	| 1                 	| Fase-2   	| 2              	| Fase 2      	|
| 3       	| 1                 	| Fase-3   	| 3              	| Fase 3      	|
| 4       	| 1                 	| Fase-4   	| 4              	| Fase 4      	|
| 5       	| 2                 	| Status-1 	| 1              	| Status 1    	|
| 6       	| 2                 	| Status-2 	| 2              	| Status 2    	|
| 7       	| 2                 	| Status-3 	| 3              	| Status 3    	|
| 8       	| 2                 	| Status-4 	| 4              	| Status 4    	|
| 9       	| 2                 	| Status-5 	| 5              	| Status 5    	|


### tabela: `workflow_next_step`

| id 	| step_id_src 	| step_id_dst 	| workflow_group_id 	|
|----	|-------------	|-------------	|-------------------	|
| 1  	| NULL        	| 1           	| 1                 	|
| 2  	| 1           	| 2           	| 1                 	|
| 3  	| 2           	| 3           	| 1                 	|
| 4  	| 3           	| 4           	| 1                 	|
| 5  	| NULL        	| 5           	| 2                 	|
| 6  	| 5           	| 6           	| 2                 	|
| 7  	| 6           	| 7           	| 2                 	|
| 8  	| 7           	| 8           	| 2                 	|
| 9  	| 8           	| 9           	| 2                 	|
| 10 	| 5           	| 7           	| 2                 	|
| 11 	| 5           	| 8           	| 2                 	|
| 12 	| 6           	| 8           	| 2                 	|


### tabela: `workflow_next_step_dependence`

| next_step_id 	| workflow_group_id 	|
|--------------	|-------------------	|
| 10           	| 1                 	|
| 8            	| 1                 	|
| 11           	| 1                 	|
| 12           	| 1                 	|
| 9            	| 1                 	|
| 9            	| 2                 	|


### tabela: `workflow_next_step_dependence_step`

| id 	| step_id 	| workflow_group_id 	| next_step_id 	|
|----	|---------	|-------------------	|--------------	|
| 1  	| 2       	| 1                 	| 10           	|
| 2  	| 3       	| 1                 	| 11           	|
| 3  	| 3       	| 1                 	| 8            	|
| 4  	| 3       	| 1                 	| 12           	|
| 5  	| 3       	| 1                 	| 9            	|
| 6  	| 4       	| 1                 	| 9            	|
| 7  	| 8       	| 2                 	| 9            	|

O arquivo [create-wf.sql](example/create-wf.sql) tem os insert para criar a estrutura dos workflows de exemplo.
> obs. os comando `INSERT` poder fazer com que a sequência de auto incremento fique inconsistente.

## Adicionando o workflow a uma entidade

Dada a entidade na qual se deseja adicionar o workflow:
```sql
CREATE TABLE "entidade" (
    "id" serial NOT NULL,
    "name" varchar(256)
);
```

Para utilizar o workflow à sua entidade devemos criar duas tabelas relacionadas ***entidade***_workflow_step e ***entidade***_workflow_step_historic

| Entidades                           	| Tipo   	| Descrição                                                                                   	|
|-------------------------------------	|--------	|---------------------------------------------------------------------------------------------	|
| ***entidade***                      	| tabela 	| Entidade da sua base na qual deseja associar um workflow.                                    	|
| ***entidade***_workflow_step         	| tabela 	| Registra o valor atual do workflow para os registro da sua entidade                          	|
| ***entidade***_workflow_step_historic	| tabela 	| Registra o histórico de todas as alterações dos workflows para a sua entidade                	|


### tabela: ***entidade***_workflow_step

A definicão dessa tabela deve seguir a seguinte estrutura (sempre mantenha o prefixo **_workflow_step_historic**):
> Atenção: Os **CONSTRAINT** devem ser atualizado para que reflita os nomes das entidades

```sql
CREATE TABLE "entidade_workflow_step_historic" (
    "id" serial NOT NULL,
    "step_id" integer NOT NULL,
    "workflow_group_id" integer NOT NULL,
    "entity_id" uuid NOT NULL,
    "time_from" timestamp DEFAULT now() NOT NULL,
    "time_to" timestamp,
    CONSTRAINT "entidade_workflow_step_historic_id" PRIMARY KEY ("id"),
    CONSTRAINT "entidade_workflow_step_histori_step_id_workflow_group_id_fkey" FOREIGN KEY (step_id, workflow_group_id) REFERENCES workflow_group_step(step_id, workflow_group_id),
    CONSTRAINT "entidade_workflow_step_historic_entity_id_fkey" FOREIGN KEY (entity_id) REFERENCES entidade(id),
    CONSTRAINT "entidade_workflow_validate" CHECK (workflow_check_change_step(step_id, workflow_group_id, entity_id, 'entidade_workflow_step'))
);
```

na linha:
```
CONSTRAINT "entidade_workflow_validate" CHECK (workflow_check_change_step(step_id, workflow_group_id, entity_id, 'entidade_workflow_step'))
```
É utilizado o CHECK para verificar se os dados incluídos são válidos

### tabela: ***entidade***_workflow_step

Para a ***entidade***_workflow_step deve se ter a estrutura (sempre mantenha o prefixo **_workflow_step**):

```sql
CREATE TABLE "entidade_workflow_step" (
    "id" serial NOT NULL,
    "entity_id" uuid NOT NULL,
    "workflow_group_id" integer NOT NULL,
    "step_id" integer NOT NULL,
    "historic_id" integer DEFAULT 0 NOT NULL,
    CONSTRAINT "entidade_workflow_step_entity_id_workflow_group_id" UNIQUE ("entity_id", "workflow_group_id"),
    CONSTRAINT "entidade_workflow_step_id" PRIMARY KEY ("id"),
    CONSTRAINT "entidade_workflow_step_entity_id_fkey" FOREIGN KEY (entity_id) REFERENCES entidade(id),
    CONSTRAINT "entidade_workflow_step_historic_id_fkey" FOREIGN KEY (historic_id) REFERENCES entidade_workflow_step_historic(id)
);

CREATE TRIGGER entidade_workflow_step_insert_historic BEFORE INSERT OR UPDATE ON entidade_workflow_step
FOR EACH ROW EXECUTE FUNCTION workflow_insert_historic();
```
Além do gatilho (TRIGGER) na ação de `insert` ou `update` que faz a chamada da função `workflow_insert_historic()`.

### tabela: `workflow_entity`

o nome da tabela `entidade_workflow_step` deve ser inserido na tabela **workflow_entity** para que os workflows sejam 
habilitados para a entidade

| id 	| workflow_group_id 	| table_name 	        |
|----	|-------------------	|-------------------	|
| 1  	| 1                 	| cargo_workflow_step |
| 2  	| 2                 	| cargo_workflow_step |


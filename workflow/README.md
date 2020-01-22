## Gerenciamento de WorkFlow (fluxo de trabalho)

O script [workflow_check.sql](workflow_check.sql)
 contém as tabelas e funções para criar a estrutura básica do gerenciamento de fluxos de trabalho de forma genérica, permitindo que o usuário possa criar e organizar de forma genérica os seus próprios fluxos.

De forma geral teremos as seguintes entidades

| Entidades                      	| Tipo   	| Descrição                                                                                   	|
|--------------------------------	|--------	|---------------------------------------------------------------------------------------------	|
| workflow_group                 	| tabela 	| Registra os workflows que serão gerenciados.                                                	|
| workflow_entity                	| tabela 	| Registra o nome das tabelas que mantêm o status<br>atual para cada workflow                 	|
| workflow_group_step            	| tabela 	| Registra cada uma dos passos presente em um <br>determinado workflows                       	|
| workflow_next_setp             	| tabela 	| Registra como será a interação entre os passos                                              	|
| workflow_next_steps_dependence 	| tabela 	| Registra a dependencias para que uma interação <br>entre os passos possa acontecer          	|
| workflow_check_change_step     	| função 	| Função que verifica se uma alteração em um dos <br>passos sobre um registro é válida.       	|
| workflow_insert_historic       	| função 	| <br>Função que atualiza o histórico de alterações de <br><br>um workflows sobre um registro 	|



![workflow](_img/workflows.png "exemplo de workflow")
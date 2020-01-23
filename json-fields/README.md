# validação de dados em coluna JSON - JSON column data format validation

O script [DDL.sql](DDL.sql) possue a estrutura basica para criar um validador de dados em uma coluna JSON no postgres.

serão criadas duas tabelas de controle:

### tabela: metadata_fields

nesta tabela você deve especificar os metadados para os tipos de dados que poderão serem inseridos no campo JSON.

* name -> nome do tipo a ser criado (por exemplo "Telefone")
* constraints -> RegExp para validar o tipo de dado
* type -> o typo de dado primitivo que será gravado na base, valores: `numeric`, `date` e `text`
* locked -> se o metadado está bloqueado 
* message -> mensagem informativa sobre o metadado

### tabela: registered_fields

nessa tabela você registra os campos que podem fazem parte da coluna JSON na sua entidade

* metadata_fields_id -> ID referente a qual metadado será utilizado para validar o dado do campo.
* slug -> Valor referente a `KEY` para identificar o dado no JSON.
* label -> Rotúlo utilizado pelo campo.
* description -> Descrição do campo.
* table_name -> Nome da tabela na qual o campo é utilizado
* enable -> Se é um campo ativo.
* required -> Se é um campo obrigátorio para esse tabela.
* error_code -> código de erro caso a validação falhe.
* error_message -> mensagem de erro caso a validação falhe.


## Ativando a validação

A validação pode ser incluida em quaqluer tabela, para isso basta adicionar a coluna:

```sql
"custom_fields" json NULL,
```
e adicionar o gatilho para as ações de `insert` e `update` da seu entidade:

```sql
CREATE TRIGGER validate_custom_fields_table_test BEFORE INSERT OR UPDATE ON table_test
FOR EACH ROW EXECUTE FUNCTION validate_constraints();
```

No arquivo [DML-sample.sql](DML-sample.sql) é exibido alguns exemplos de metadados e no arquivo [DML-exemple-registered-fields.sql](DML-exemple-registered-fields.sql) é mostrado a ativação do campo para a entidade ***table_test***, e o registro de alguns campos.

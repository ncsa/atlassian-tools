SET @var_DB = 'ncsa_wiki';

SELECT DEFAULT_CHARACTER_SET_NAME, DEFAULT_COLLATION_NAME FROM information_schema.SCHEMATA S
WHERE schema_name = @var_DB;

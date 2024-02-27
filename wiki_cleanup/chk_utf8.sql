SET @var_DB = 'ncsa_wiki';
SET @var_charset = 'utf8';
SET @var_collation = 'utf8_bin';


/* https://confluence.atlassian.com/confkb/mysql-collation-repair-database-level-changes-670958163.html */
SELECT '/* DB updates */';
SELECT DEFAULT_CHARACTER_SET_NAME, DEFAULT_COLLATION_NAME FROM information_schema.SCHEMATA S
WHERE schema_name = @var_DB
AND 
(
	DEFAULT_CHARACTER_SET_NAME != @var_charset
	OR
	DEFAULT_COLLATION_NAME != @var_collation
);


/* https://confluence.atlassian.com/confkb/mysql-collation-repair-table-level-changes-670958169.html */
SELECT '/* TABLE updates */';
SELECT CONCAT('ALTER TABLE `',  table_name, '` CHARACTER SET ', @var_charset, 'COLLATE ', @var_collation, ';')
FROM information_schema.TABLES AS T, information_schema.`COLLATION_CHARACTER_SET_APPLICABILITY` AS C
WHERE C.collation_name = T.table_collation
AND T.table_schema = @var_DB
AND 
(
	C.CHARACTER_SET_NAME != @var_charset
	OR
	C.COLLATION_NAME != @var_collation
);


SELECT 'SET FOREIGN_KEY_CHECKS=0;';


/* https://confluence.atlassian.com/confkb/mysql-collation-repair-column-level-changes-670958189.html */
SELECT '/* VARCHAR COLUMN updates */';
SELECT CONCAT('ALTER TABLE `', table_name, '` MODIFY `', column_name, '` ', DATA_TYPE, '(', CHARACTER_MAXIMUM_LENGTH, ') CHARACTER SET ', @var_charset, ' COLLATE ', @var_collation, (CASE WHEN IS_NULLABLE = 'NO' THEN ' NOT NULL' ELSE '' END), ';')
FROM information_schema.COLUMNS 
WHERE TABLE_SCHEMA = @var_DB
AND DATA_TYPE = 'varchar'
AND 
(
	CHARACTER_SET_NAME != @var_charset
	OR
	COLLATION_NAME != @var_collation
);

SELECT '/* non-VARCHAR COLUMN updates */';
SELECT CONCAT('ALTER TABLE `', table_name, '` MODIFY `', column_name, '` ', DATA_TYPE, ' CHARACTER SET ', @var_charset, 'COLLATE ', @var_collation, (CASE WHEN IS_NULLABLE = 'NO' THEN ' NOT NULL' ELSE '' END), ';')
FROM information_schema.COLUMNS 
WHERE TABLE_SCHEMA = '<yourDB>'
AND DATA_TYPE != 'varchar'
AND 
(
	CHARACTER_SET_NAME != @var_charset
	OR
	COLLATION_NAME != @var_collation
);

SELECT 'SET FOREIGN_KEY_CHECKS=1;';

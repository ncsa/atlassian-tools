-- This should be executed on the clone

UPDATE cwd_user SET
	  lower_user_name = 'aeakin'
	, user_name = 'aeakin'
WHERE lower_user_name = 'aeakin ';

UPDATE app_user SET
	  user_key = 'aeakin'
	, lower_user_name = 'aeakin'
WHERE lower_user_name = 'aeakin ';

UPDATE app_user SET
	  user_key = 'aysegul'
	, lower_user_name = 'aysegul'
WHERE lower_user_name = 'aysegul ';

UPDATE app_user SET
	user_key = 'pjiang6'
  , lower_user_name = 'pjiang6'
WHERE lower_user_name = 'pjiang6 ';

INSERT INTO cwd_user (
	  id
	, directory_id
	, user_name
	, lower_user_name
	, active
	, created_date
	, updated_date
)
SELECT
	newid.ID
  , 1
  , 'aysegul'
  , 'aysegul'
  , 0
  , NOW()
  , NOW()
FROM
	(SELECT MAX(ID)+1 AS ID FROM cwd_user) newid;

INSERT INTO cwd_user (
	  id
	, directory_id
	, user_name
	, lower_user_name
	, active
	, created_date
	, updated_date
)
SELECT
	newid.ID
  , 1
  , 'hlf'
  , 'hlf'
  , 0
  , NOW()
  , NOW()
FROM
	(SELECT MAX(ID)+1 AS ID FROM cwd_user) newid;

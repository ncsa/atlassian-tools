select 'missing display name'
  as Comment;
SELECT
	  lower_user_name
	, active 
	, lower_first_name
	, lower_last_name
	, display_name
	, lower_display_name
	, email_address
	, lower_email_address
FROM cwd_user
WHERE ID IN (53892, 53893);

select 'anyone with missing display name'
  as Comment;
SELECT
	  lower_user_name
	, active 
	, lower_first_name
	, lower_last_name
	, display_name
	, lower_display_name
	, email_address
	, lower_email_address
FROM cwd_user
WHERE
	COALESCE(TRIM(display_name),'') = '';

select 'missing email address'
  as Comment;
SELECT
	  lower_user_name
	, active 
	, lower_first_name
	, lower_last_name
	, display_name
	, lower_display_name
	, email_address
	, lower_email_address
FROM cwd_user
WHERE 
	id IN (10671, 11070, 11095,18659, 53892, 53893, 55269, 55273, 55857, 56299, 58329, 62244);

select 'anyone with missing email address'
  as Comment;
SELECT
	  lower_user_name
	, active 
	, lower_first_name
	, lower_last_name
	, display_name
	, lower_display_name
	, email_address
	, lower_email_address
FROM cwd_user
WHERE
	COALESCE(TRIM(email_address),'') = '';

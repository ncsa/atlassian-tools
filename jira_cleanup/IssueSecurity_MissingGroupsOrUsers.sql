-- Find users and groups in issue security that don't exist in
-- ldap or jira databases
/* Find tickets that reference non-existant users/groups. */
/* Useful when an org_* LDAP group goes out of existance but some tickets have a reference */
/* to the group. Those references need to be cleaned up before migration. */
/* Clean up looks like: */
/* 1. add the group manually */
/* 2. open each ticket and delete the reference (usually in "groups who can view" field) */
/* 3. delete the group manually */
SELECT 
	  grps_and_users.cust_field
	, grps_and_users.cust_value
	, grps_and_users.proj_key
	, grps_and_users.proj_name
	, grps_and_users.issue_key
FROM (
	SELECT
		cust_grps.cust_field
	  , cust_grps.cust_value
	  , p.pkey proj_key
	  , p.pname proj_name
	  , CONCAT(p.pkey,'-',ji.issuenum) issue_key
	FROM 
	(
		SELECT
			  cf.cfname cust_field
			, cfv.ISSUE issue
			, LOWER(cfv.STRINGVALUE) cust_value
		FROM customfield cf
		JOIN customfieldvalue cfv ON
			cf.ID = cfv.CUSTOMFIELD 
		WHERE cf.cfname = 'Groups who can view'
	) cust_grps
	LEFT OUTER JOIN cwd_group cg ON 
		cust_grps.cust_value = cg.lower_group_name 
	JOIN jiraissue ji ON
		cust_grps.issue = ji.ID AND
		COALESCE(cg.group_name,'') = ''
	JOIN project p ON
		ji.PROJECT = p.ID
	UNION 
	SELECT
		  cust_users.cust_field
		, cust_users.cust_value
		, p.pkey proj_key
		, p.pname proj_name
		, CONCAT(p.pkey,'-',ji.issuenum) AS issue_key
		FROM 
		(
			SELECT
			  	  cf.cfname cust_field
				, cfv.ISSUE issue
				, LOWER(cfv.STRINGVALUE) cust_value
	   		FROM customfield cf
	   		JOIN customfieldvalue cfv ON
		 		cf.ID = cfv.CUSTOMFIELD 
		   	WHERE cf.cfname = 'Users who can view'
	 	) cust_users 
		LEFT OUTER JOIN cwd_user cu ON 
			cust_users.cust_value = cu.lower_user_name
		LEFT OUTER JOIN app_user au ON
			cust_users.cust_value = LOWER(au.user_key)
		JOIN jiraissue ji ON
			cust_users.issue = ji.ID AND
		COALESCE(cu.lower_user_name,au.lower_user_name,'') = ''
		JOIN project p ON
			ji.PROJECT = p.ID 
	) grps_and_users
WHERE grps_and_users.proj_key IN -- projects staying in (new) Jira
	(	
		  'DELTA'
		, 'HYDRO'
		, 'IRC'
		, 'NUS'
		, 'CTA'
		, 'PFR'
		, 'MNIP'
		, 'NCSACC'
		, 'SECVAR'
		, 'C3AID'
		, 'CIL'
		, 'CTSC'
		, 'SECOPS'
		, 'SVCPLAN'
		, 'HELMAG'
		, 'TGI'
		, 'IDDS'
		, 'CFAI'
		, 'SVNA'
		, 'SVNRW'
		, 'IADDA'
	); 

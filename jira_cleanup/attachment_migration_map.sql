/* \pset fieldsep '\t' */
/* \pset recordsep '\n' */
\pset tuples_only on

SELECT
    cfv.stringvalue AS oldIssueKey,
	  CONCAT('SUP-',ji.issuenum) AS issue_key
FROM jiraissue ji
JOIN project p ON
	ji.project = p.id
JOIN customfield cf ON
	'oldIssueKey' = cf.cfname
JOIN customfieldvalue cfv ON
	cfv.issue = ji.id AND
	cf.id = cfv.customfield 
WHERE p.pkey = 'SUP'
ORDER BY ji.issuenum;

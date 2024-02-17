DELETE FROM customfieldvalue WHERE
id IN
(SELECT cfv.id
FROM customfieldvalue cfv
JOIN jiraissue ji ON
  cfv.issue = ji.id
JOIN project p ON
  ji.project = p.id
WHERE
  p.pkey = 'SVCPLAN' AND
  cfv.customfield = (SELECT ID FROM customfield WHERE customfieldtypekey LIKE '%com.pyxis.greenhopper.jira:gh-sprint%') AND
  cfv.stringvalue NOT IN (SELECT ID FROM AO_60DB71_SPRINT)
);

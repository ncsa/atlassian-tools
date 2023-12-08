DELETE FROM customfieldvalue 
WHERE customfield = (SELECT ID FROM customfield WHERE customfieldtypekey LIKE '%com.pyxis.greenhopper.jira:gh-sprint%')
AND stringvalue NOT IN (SELECT ID FROM AO_60DB71_SPRINT);

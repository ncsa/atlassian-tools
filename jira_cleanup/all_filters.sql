/* adapted from */
/* https://community.atlassian.com/t5/Jira-Software-questions/How-to-get-all-filter-in-jira-server/qaq-p/987166 */

/* describe searchrequest */

/* Field   Type    Null    Key     Default Extra */
/* ID      decimal(18,0)   NO      PRI     NULL */
/* filtername      varchar(255)    YES             NULL */
/* authorname      varchar(255)    YES     MUL     NULL */
/* DESCRIPTION     text    YES             NULL */
/* username        varchar(255)    YES             NULL */
/* groupname       varchar(255)    YES             NULL */
/* projectid       decimal(18,0)   YES             NULL */
/* reqcontent      longtext        YES             NULL */
/* FAV_COUNT       decimal(18,0)   YES             NULL */
/* filtername_lower        varchar(255)    YES     MUL     NULL */

SELECT s.ID, s.filtername, s.authorname, s.DESCRIPTION FROM searchrequest s
;
SELECT s.ID FROM searchrequest s
;

#!/usr/bin/python3

HEADER = f"""
/* https://confluence.atlassian.com/confkb/how-to-determine-the-number-of-attachments-in-my-confluence-instance-289276388.html */

/* FOR CONFLUENCE 5.7 AND ABOVE */
-- To get a count of current attachment versions only
select count(*) as "count of current attachment versions only"
from content where contenttype = 'ATTACHMENT' and prevver is null;

-- To get a count of all attachment versions
select count(*) as "count of all attachment versions"
from content where contenttype = 'ATTACHMENT';

-- To get the number of attachments in a space
"""

# print( HEADER )

with open('wiki_spaces.txt', 'r') as file:
    for rawline in file:
        line = rawline.strip().replace("'", "''")
        SQL = f"""
select count(*) as "number of attachments", SPACES.SPACENAME from CONTENT
join SPACES on CONTENT.SPACEID = SPACES.SPACEID
where contenttype='ATTACHMENT' and spacename='{line}'
and prevver is null
and content_status='current' 
group by SPACES.SPACENAME;
"""
        print(SQL)

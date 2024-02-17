select * 
INTO OUTFILE '/var/lib/mysql-files/os_propertyentry_10880091.csv'
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
from OS_PROPERTYENTRY where entity_id=10880091;

select * 
INTO OUTFILE '/var/lib/mysql-files/os_propertyentry_like_vote.csv'
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
from OS_PROPERTYENTRY where entity_key like '%vote.%';

/* \d CONTENT; */
/* \d SPACES; */
/* describe spaces; */
/* SELECT DISTINCT SPACETYPE from SPACES; */
/* select SPACENAME,SPACETYPE from SPACES; */
/* SELECT SPACENAME from SPACES where SPACETYPE="personal"; */
/* SELECT SPACEKEY,SPACENAME from SPACES where SPACETYPE="global"; */
select SPACENAME,SPACEKEY
from SPACES
;
/* INTO OUTFILE '/var/lib/mysql-files/SPACES.csv' */
/* FIELDS TERMINATED BY ',' */
/* ENCLOSED BY '"' */
/* LINES TERMINATED BY '\n'; */

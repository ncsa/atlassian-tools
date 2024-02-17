SELECT CONCAT("'", lower_username, "'") AS quoted_value
FROM user_mapping
WHERE lower_username REGEXP '\\s';

/* select * from user_mapping where lower_username like '%aeakin%'; */
/* select * from user_mapping where lower_username like '%ashoks%'; */
/* select * from user_mapping where lower_username like '%aysegul%'; */
/* select * from user_mapping where lower_username like '%hartungl%'; */
/* select * from user_mapping where lower_username like '%pjiang6%'; */

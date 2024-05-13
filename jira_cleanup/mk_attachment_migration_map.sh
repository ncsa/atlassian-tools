BASE=~/working/atlassian-tools
FN_SQL=attachment_migration_map.sql
FN_OUTPUT=attachment_migration_map.csv
SERVER=jira-dev-m1

# run SQL
$BASE/bin/pg_run_sql.sh "$SERVER" "$FN_SQL" \
| grep -v '^$' \
> "$FN_OUTPUT"

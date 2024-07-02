BASE=~/working/atlassian-tools
FN_SQL=issue_migration_map.sql
FN_OUTPUT=issue_migration_map.csv
SERVER=jira-dev-dr1

# run SQL
$BASE/bin/pg_run_sql.sh "$SERVER" "$FN_SQL" \
| grep -v '^$' \
> "$FN_OUTPUT"

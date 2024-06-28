import argparse
import json
import logging
import pprint
import sys
import csv
import pathlib
import textwrap

# Add /app to import path
sys.path.append( '/app' )

# Local imports
import libjira

# Setup logging
logfmt = '%(levelname)s:%(funcName)s[%(lineno)d] %(message)s'
loglvl = logging.INFO
loglvl = logging.DEBUG
logging.basicConfig( level=loglvl, format=logfmt )
logging.getLogger( 'libjira' ).setLevel( loglvl )


resources = {} #module level resources

def get_jira():
    key = 'jira_connection'
    try:
        j = resources[key]
    except KeyError:
        j = libjira.jira_login()
    return j


def get_args( params=None ):
    key = 'args'
    if key not in resources:
        constructor_args = {
            'formatter_class': argparse.ArgumentDefaultsHelpFormatter,
            'description': textwrap.dedent( '''\
                Create list of attachment directories for tickets provided.
                Add attachments from old Jira tickets to new JSM tickets.
                '''),
            'epilog': textwrap.dedent( '''\
                NETRC:
                    Jira login credentials should be stored in ~/.netrc.
                    Machine name should be hostname only.
                '''),
            }
        parser = argparse.ArgumentParser( **constructor_args )
        # parser.add_argument( '-d', '--debug', action='store_true' )
        # parser.add_argument( '-v', '--verbose', action='store_true' )
        parser.add_argument( '--mk_paths',
            dest='action', action='store_const', const='mk_paths' )
        parser.add_argument( '--migrate_attachments',
            dest='action', action='store_const', const='migrate_attachments' )
        parser.add_argument( '--attachments_dir', default='./attachments',
            help='Path to attachments dir' )
        args = parser.parse_args( params )
        if not args.action:
            raise UserWarning( "Exacly one of --mk_paths or --migrate_attachments must be specified." )
        resources[key] = args
    return resources[key]

# def get_all_fields():
#     j = get_jira()
#     key = 'all_fields'
#     if key not in resources:
#         resources[key] = { x['id']:x for x in j.fields() }
#     return resources[key]


# def get_issue_link_types():
#     j = get_jira()
#     key = 'issue_link_types'
#     if key not in resources:
#         resources[key] = { x.id:x for x in j.issue_link_types() }
#     return resources[key]


# def get_labels( issue ):
#     # return get_jira().issue( id ).fields.labels
#     return issue.fields.labels


def dump_issue( issue ):
    pprint.pprint( issue.raw )


#def get_linked_issues( issue ):
#    linked_issues = []
#    for link in issue.fields.issuelinks:
#        # l_type = link['type']
#        try:
#            remote_issue = link.inwardIssue
#            direction = 'inward'
#        except AttributeError:
#            remote_issue = link.outwardIssue
#            direction = 'outward'
#        linked_issues.append(
#            Linked_Issue(
#                remote_issue=remote_issue,
#                link_type=link.type,
#                direction=direction
#            )
#        )
#    return linked_issues


#def get_parent( issue ):
#    #issue = get_jira().issue( id )
#    try:
#        parent = issue.fields.parent
#    except AttributeError:
#        parent = None
#    return parent


#def get_all_subtasks():
#    jql = 'project = "Service Planning" and issuetype = Sub-task and resolution is EMPTY'
#    return get_jira().search_issues( jql, maxResults=9999 )


#def add_label( issue, new_label ):
#    issue.fields.labels.append( new_label )
#    issue.update( fields={"labels":issue.fields.labels}, notify=False )


#def add_childof_label( issue ):
#    p = get_parent( issue )
#    parent_label = f'childof{p}'
#    add_label( issue, parent_label )


#def link_to_parent( issue, parent=None ):
#    if parent is None:
#        parent = get_parent( issue )
#    if parent is None:
#        logging.warn( f"No parent for issue '{issue.key}'" )
#    logging.info( f'Parent={parent} Child={issue}' )
#    j = get_jira()
#    j.create_issue_link(
#        type='Ancestor',
#        inwardIssue=parent.key,
#        outwardIssue=issue.key
#        )


# def print_issue_summary( issue ):
#     print( f"{issue}" )
#     parent = get_parent( issue )
#     print( f"\tParent {parent}" )
#     labels = get_labels( issue )
#     print( f"\tLabels {labels}" )
#     links = get_linked_issues( issue )
#     for link in links:
#         if link.direction == 'inward':
#             link_text = link.link_type.inward
#         else:
#             link_text = link.link_type.outward
#         print( f"\t{link_text} {link.remote_issue.key}" )


def tsv_to_dict( path ):
    rv = {}
    with path.open() as fh:
        reader = csv.reader( fh, delimiter='\t' )
        rv = { row[0]:row[1] for row in reader }
    return rv


def slug_to_filepath( slug ):
    base = pathlib.Path( get_args().attachments_dir )
    prj, ident = slug.split('-')
    # convert ident into subdir name
    scalar = int(ident) // 10000
    subdir = 10000 + (scalar * 10000)
    return base / prj / str(subdir) / slug


if __name__ == '__main__':

    # TEST CONNECTION
    # print( json.dumps( get_jira().issue('SVCPLAN-398').raw ) )

    # # elems = [ f'SVCPLAN-{x}' for x in range( 289, 295 ) ]
    # elems = [ f'SVCPLAN-{x}' for x in range( 289, 292 ) ]
    # jql = f'id in ({",".join(elems)})'
    # issues = get_jira().search_issues( jql, maxResults=9999 )

    # # issues = get_all_subtasks()

    # for i in issues:
    # #     add_childof_label( i )
    #     # link_to_parent( i )
    #     print_issue_summary( i )

    # GET ISSUE MAP FROM CSV
    infile = pathlib.Path( 'issue_migration_map.csv' )
    issue_map = tsv_to_dict( infile )
    # pprint.pprint( issue_map )

    action = get_args().action
    if action == 'mk_paths':
        for k,v in issue_map.items():
            at_dir = slug_to_filepath( k )
            # print( f"{k} -> {at_dir}" )
            print( f"{at_dir}" )
    elif action == 'migrate_attachments':
        print( action )

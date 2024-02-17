import argparse
import json
import logging
import pprint
import sys
import csv
import pathlib
import textwrap
import jira

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

def get_jira( servername ):
    key = f'jira_connection_{servername}'
    try:
        j = resources[key]
    except KeyError:
        j = libjira.jira_login( jira_server=f'{servername}.ncsa.illinois.edu' )
    return j


def get_old_jira():
    return get_jira( 'jira-old' )


def get_jsm():
    return get_jira( 'jira' )


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


def get_issuemap():
    key = 'issuemap'
    if key not in resources:
        infile = pathlib.Path( 'attachment_migration_map.csv' )
        with infile.open() as fh:
            reader = csv.reader( fh, delimiter='|' )
            resources[key] = { row[0].strip():row[1].strip() for row in reader }
    return resources[key]


def debug( msg ):
    logging.info( msg )


def info( msg ):
    logging.info( msg )


def error( msg ):
    logging.error( msg )


def dump_issue( issue ):
    pprint.pprint( issue.raw )


def slug_to_filepath( slug ):
    base = pathlib.Path( get_args().attachments_dir )
    prj, ident = slug.split('-')
    # convert ident into subdir name
    scalar = int(ident) // 10000
    subdir = 10000 + (scalar * 10000)
    return base / prj / str(subdir) / slug


def mk_paths():
    for k,v in get_issuemap().items():
        at_dir = slug_to_filepath( k )
        print( f"{at_dir}" )



def migrate_attachments():
    oldjira = get_old_jira()
    newjira = get_jsm()
    # Walk filesystem for issues that have attachments
    # ... dir structure looks like:
    #     attachments_dir/TICKET-KEY/file
    attachments_dir = pathlib.Path( get_args().attachments_dir )
    for root, dirs, files in attachments_dir.walk():
        for d in dirs:
            # directory name will be the TICKET-KEY
            old_key = str(d)
            new_key = get_issuemap()[ old_key ]
            try:
                old_issue = oldjira.issue( old_key )
            except jira.exceptions.JIRAError as e:
                if 'Issue Does Not Exist' in e.text:
                    error( f'source issue not found: {old_key} -> {new_key}' )
                    continue
            try:
                new_issue = newjira.issue( new_key )
            except jira.exceptions.JIRAError as e:
                if 'Issue Does Not Exist' in e.text:
                    error( f'target issue not found: {old_key} -> {new_key}' )
                    continue

            # get filenames of any existing attachments in new issue
            existing_filenames = [ a.filename for a in new_issue.fields.attachment ]

            # get attachments from old_issue; add to new_issue
            for at in old_issue.fields.attachment:
                if at.filename in existing_filenames:
                    # don't re-add attachments with same filename
                    info( f"SKIP attachment '{at.filename}' already exists for ticket '{new_key}'" )
                    continue
                local_file = root / d / at.id
                if not local_file.exists():
                    error( f'file not found: {local_file}' )
                    continue
                info( f"ADD attachment '{at.filename}' to ticket '{new_key}'" )
                newjira.add_attachment(
                    issue = new_issue,
                    attachment = str(local_file),
                    filename = at.filename
                    )


if __name__ == '__main__':

    action = get_args().action
    if action == 'mk_paths':
        mk_paths()
    elif action == 'migrate_attachments':
        migrate_attachments()





# TEST CONNECTION
# issue = oldjira.issue('SVC-5118')
# print( json.dumps( issue.raw ) )

# VIEW ATTACHMENT INFO
# for at in issue.fields.attachment:
#     pprint.pprint( at )
# <JIRA Attachment:
#   filename='Scan_Report_NCSA___SET_mgmt_3003_ports___20211124___20211124_ncsa_cc_20211124.pdf',
#   id='50071',
#   mimeType='application/pdf'>

# ATTACHMENT JSON
# {'author': {'active': True,
#             'avatarUrls': {'16x16': 'https://jira.ncsa.illinois.edu/secure/useravatar?size=xsmall&avatarId=10122',
#                            '24x24': 'https://jira.ncsa.illinois.edu/secure/useravatar?size=small&avatarId=10122',
#                            '32x32': 'https://jira.ncsa.illinois.edu/secure/useravatar?size=medium&avatarId=10122',
#                            '48x48': 'https://jira.ncsa.illinois.edu/secure/useravatar?avatarId=10122'},
#             'displayName': 'Pallavi Jain',
#             'emailAddress': 'pjain15@illinois.edu',
#             'key': 'JIRAUSER36800',
#             'name': 'pjain15',
#             'self': 'https://jira.ncsa.illinois.edu/rest/api/2/user?username=pjain15',
#             'timeZone': 'America/Chicago'},
#  'content': 'https://jira.ncsa.illinois.edu/secure/attachment/62174/image-2023-03-03-14-50-55-959.png',
#  'created': '2023-03-03T14:50:56.000-0600',
#  'filename': 'image-2023-03-03-14-50-55-959.png',
#  'id': '62174',
#  'mimeType': 'image/png',
#  'self': 'https://jira.ncsa.illinois.edu/rest/api/2/attachment/62174',
#  'size': 105502,
#  'thumbnail': 'https://jira.ncsa.illinois.edu/secure/thumbnail/62174/_thumb_62174.png'}

import configparser
import json
import logging
import netrc
import os
import pathlib
import pprint
import re
import requests
import requests.exceptions
import time

from functools import wraps

logfmt = '%(levelname)s:%(funcName)s[%(lineno)d] %(message)s'
loglvl = logging.INFO
loglvl = logging.DEBUG
logging.basicConfig( level=loglvl, format=logfmt )
# logging.getLogger( 'libjira' ).setLevel( loglvl )
# logging.getLogger( 'jira.JIRA' ).setLevel( loglvl )

resources = {} # module level resources


def get_session():
    key = 'session'
    if key not in resources:
        resources[key] = requests.Session()
    return resources[key]


def get_config():
    key = 'cfg'
    if key not in resources:
        envvar = 'ATLASSIAN_TOOLS_CONFIG'
        try:
            conf_file = os.environ[ envvar ]
        except KeyError as e:
            logging.error( f"Env var '{envvar}' must be set" )
            raise SystemExit( 1 )
        cfg = configparser.ConfigParser( allow_no_value=True )
        cfg.read( conf_file )
        resources[key] = cfg
    return resources[key]


def get_server():
    key = 'server'
    config = get_config()
    if key not in resources:
        server = config['server']['server']
        resources[key] = server
    return resources[key]


def get_netrc():
    key = 'netrc'
    if key not in resources:
        n = netrc.netrc()
        server = get_server()
        (login, account, password) = n.authenticators( server )
        resources['login'] = login
        # resources['account'] = account
        resources['password'] = password
        resources[key] = n
    return resources[key]


def get_password():
    key = 'password'
    if key not in resources:
        get_netrc()
    return resources[key]


def get_warnings():
    key = 'errs'
    if key not in resources:
        resources[key] = []
    return resources[key]


def warn( msg ):
    ''' Log an warning to the screen and,
        Also save it in an array for later retrieval of all warnings.
    '''
    key = 'errs'
    if key not in resources:
        resources[key] = []
    resources[key].append( msg )
    logging.warning( msg )


def get_errors():
    key = 'errs'
    if key not in resources:
        resources[key] = []
    return resources[key]


def err( msg ):
    ''' Log an error to the screen and,
        Also save it in an array for later retrieval of all errors.
    '''
    key = 'errs'
    if key not in resources:
        resources[key] = []
    resources[key].append( msg )
    logging.error( msg )


# https://stackoverflow.com/questions/1622943/timeit-versus-timing-decorator#27737385
def timing( f ):
    @wraps( f )
    def wrap( *args, **kw ):
        starttime = time.time()
        result = f( *args, **kw )
        endtime = time.time()
        elapsed = endtime - starttime
        logging.info( f'func:{f.__name__} args:[{args}, {kw}] took: {elapsed} sec' )
        return result
    return wrap


def get_atl_token():
    s = get_session()
    return requests.utils.dict_from_cookiejar( s.cookies )['atlassian.xsrf.token']


def go_sudo_path( path ):
    ''' attempt to access a secure/admin page
        side effect: get's a valid atl_token that can be used for future calls
    '''
    s = get_session()
    url = f'https://{get_server()}{path}'
    r = s.get( url )
    logging.debug( f'RETURN CODE, GET, {path} .. {r}' )
    # If unauthorized, then go to login page instead
    validate_string = 'You have requested access to an administrative function in Jira and are required to validate your credentials below'
    if validate_string in r.text:
        logging.debug( 'SUDO login required' )
        # submit the admin login form with redirect to the same secure/admin page
        url = f'https://{get_server()}/secure/admin/WebSudoAuthenticate.jspa'
        post_data = {
            'webSudoPassword': get_password(),
            'atl_token': get_atl_token(),
            'webSudoIsPost': 'false',
            'webSudoDestination': path,
        }
        r = s.post( url, data = post_data )
        logging.debug( f'WebSudoAuthenticate .. {r}' )
    r.raise_for_status()
    return r


def post_sudo_path( path, data ):
    url = f'https://{get_server()}{path}'
    r = get_session().post( url, data=data )
    logging.debug( f'RETURN CODE, POST, {path} .. {r}' )
    r.raise_for_status()
    return r


def api_go( method, path, version='latest', **kw ):
    url = f'https://{get_server()}/rest/api/{version}/{path}'
    logging.debug( f'{method} {path}, {pprint.pformat(kw)}' )
    r = get_session().request( method, url, **kw )
    logging.debug( f'RETURN CODE .. {r}' )
    r.raise_for_status()
    return r


def api_get( path, params=None ):
    return api_go( 'GET', path, params=params )


def api_delete( path, data=None ):
    kwargs = { 'timeout': 1800 }
    if data:
        kwargs.update ( {
            'headers': { "Content-Type": "application/json" },
            'json': data,
        } )
    return api_go( 'DELETE', path, **kwargs )


def api_post( path, data):
    headers = { "Content-Type": "application/json" }
    return api_go( 'POST', path, json=data, headers=headers )


def api_put( path, data ):
    headers = { "Content-Type": "application/json" }
    return api_go( 'PUT', path, json=data, headers=headers )


def web_delete_by_id( id, path, addl_form_data={} ):
    form_data = {
        'id': id,
        'confirm': 'true',
        'Delete': 'Delete',
        'atl_token': get_atl_token(),
    }
    form_data.update( addl_form_data )
    logging.debug( f'{path} {id} ...' )
    r = post_sudo_path( path, form_data )
    time.sleep( 0.1 ) #attempt to avoid slamming the server
    return r


def get_projects_to_keep():
    return [ x.upper() for x in get_config().options( 'projects to keep' ) ]


def get_all_project_keys():
    return [ x['key'] for x in api_get( 'project' ).json() ]


def get_projects_to_purge():
    keep_projects = get_projects_to_keep()
    all_projects = get_all_project_keys()
    return set(all_projects) - set(keep_projects)


@timing
def delete_project( pid ):
    try:
        r = api_delete( f'project/{pid}' )
    except requests.exceptions.ReadTimeout as e:
        warn( f"Caught ReadTimeout waiting to delete project '{pid}'" )
    except requests.exceptions.HTTPError as e:
        if e.status_code == 400:
            err( f"Error trying to delete project '{pid}': {e}" )
        else:
            raise e
    else:
        logging.info( f"Deleted project '{pid}'" )


def del_projects():
    purge_list = get_projects_to_purge()
    start_time=time.time()
    for pid in purge_list:
        delete_project( pid )
    elapsed = time.time() - start_time
    logging.info( f"Deleted a total of '{len(purge_list)}' projects in {int(elapsed)} seconds" )


def verify_all_projects_deleted():
    ''' Report if any projects exist that are NOT on the keep list
    '''
    purge_list = get_projects_to_purge()
    if len(purge_list) > 0:
        err( f"Projects not deleted: '{purge_list}'" )


@timing
def del_issueTypeScreen_schemes():
    r = go_sudo_path( f'/secure/admin/ViewIssueTypeScreenSchemes.jspa' )
    ptrn = re.compile( r'href="ViewDeleteIssueTypeScreenScheme.jspa[^"]+id=([0-9]+)"' )
    del_ids = ptrn.findall( r.text )
    for id in del_ids:
        r = web_delete_by_id( id, '/secure/admin/DeleteIssueTypeScreenScheme.jspa' )
    logging.info( f'Deleted {len(del_ids)} Issue Type Screen Schemes' )


@timing
def del_issueType_schemes():
    r = go_sudo_path( f'/secure/admin/ManageIssueTypeSchemes!default.jspa' )
    del_ids = get_unused_issueType_schemes( r.text )
    for id in del_ids:
        r = api_delete( f'issuetypescheme/{id}' )
    logging.info( f'Deleted {len(del_ids)} issueTypeSchemes.' )


def get_unused_issueType_schemes( raw_html ):
    scheme_ids = []
    for m in re.finditer( r'<tr data-id=".+?</tr>', raw_html, re.DOTALL ):
        scheme = m.group()
        if re.search( r'No projects', scheme ):
            # no associated projects - safe to delete
            id = re.match( r'<tr data-id="([0-9]+)"', scheme ).group(1)
            scheme_ids.append( id )
    return scheme_ids


@timing
def del_fieldConfiguration_schemes():
    r = go_sudo_path( f'/secure/admin/ViewFieldLayoutSchemes.jspa' )
    ptrn = r'href="/secure/admin/DeleteFieldLayoutScheme[^"]+id=([0-9]+)"'
    for m in re.finditer( ptrn, r.text ):
        id = m.group(1)
        r = web_delete_by_id( id, '/secure/admin/DeleteFieldLayoutScheme.jspa' )


@timing
def del_field_configurations():
    r = go_sudo_path( f'/secure/admin/ViewFieldLayouts.jspa' )
    ptrn = r'href="/secure/admin/DeleteFieldLayout!default.jspa[^"]+id=([0-9]+)"'
    for m in re.finditer( ptrn, r.text ):
        id = m.group(1)
        r = web_delete_by_id( id, '/secure/admin/DeleteFieldLayout.jspa' )


@timing
def del_workflow_schemes():
    r = go_sudo_path( f'/secure/admin/ViewWorkflowSchemes.jspa' )
    ptrn = r'href="DeleteWorkflowScheme!default.jspa[^"]+schemeId=([0-9]+)"'
    num_deleted = 0
    for m in re.finditer( ptrn, r.text ):
        id = m.group(1)
        r = api_delete( f'workflowscheme/{id}' )
        num_deleted = num_deleted + 1
    logging.info( f'Deleted {num_deleted} workflow schemes.' )


@timing
def del_priority_schemes():
    r = go_sudo_path( f'/secure/admin/ViewPrioritySchemes.jspa' )
    del_ids = get_unused_priority_schemes( r.text )
    logging.debug( pprint.pformat( del_ids ) )
    for id in del_ids:
        r = api_delete( f'priorityschemes/{id}' )
    logging.info( f'Deleted {len(del_ids)} issueTypeSchemes.' )


def get_unused_priority_schemes( raw_html ):
    logging.debug( 'IN get_unused_priority_schemes' )
    scheme_ids = []
    for m in re.finditer( r'<tr data-id=".+?</tr>', raw_html, re.DOTALL ):
        scheme = m.group()
        if re.search( r'No projects', scheme ):
            # no associated projects - safe to delete
            id_ptrn = r'href="DeletePriorityScheme!default.jspa\?schemeId=([0-9]+)"'
            id = re.search( id_ptrn, scheme ).group(1)
            scheme_ids.append( id )
    return scheme_ids


@timing
def del_screen_schemes():
    r = go_sudo_path( f'/secure/admin/ViewFieldScreenSchemes.jspa' )
    ptrn = re.compile( r'href="ViewDeleteFieldScreenScheme.jspa\?id=([0-9]+)"' )
    counter = 0
    for m in ptrn.finditer( r.text ):
        id = m.group(1)
        r = web_delete_by_id( id, '/secure/admin/DeleteFieldScreenScheme.jspa' )
        counter = counter + 1
    logging.info( f'Deleted {counter} Screen schemes.' )


@timing
def del_permission_schemes():
    r = go_sudo_path( f'/secure/admin/ViewPermissionSchemes.jspa' )
    del_ids = get_unused_permission_schemes( r.text )
    for id in del_ids:
        r = api_delete( f'permissionscheme/{id}' )
    logging.info( f'Deleted {len(del_ids)} Permission schemes.' )


def get_unused_permission_schemes( raw_html ):
    scheme_ids = []
    for m in re.finditer( r'<tr>.+?</tr>', raw_html, re.DOTALL ):
        scheme = m.group()
        if re.search( r'href="/plugins/servlet/project-config', scheme ):
            # projects are associated - SKIP
            pass
        else:
            # no associated projects - safe to delete
            id_ptrn = r'href="DeletePermissionScheme!default.jspa\?schemeId=([0-9]+)"'
            m = re.search( id_ptrn, scheme )
            if m:
                id = m.group(1)
                scheme_ids.append( id )
    return scheme_ids


@timing
def del_notification_schemes():
    r = go_sudo_path( f'/secure/admin/ViewNotificationSchemes.jspa' )
    del_ids = get_unused_notification_schemes( r.text )
    for id in del_ids:
        r = web_delete_by_id(
            id,
            '/secure/admin/DeleteNotificationScheme.jspa',
            { 'schemeId': id, 'confirmed': 'true' }
            )
    logging.info( f'Deleted {len(del_ids)} notification schemes.' )


def get_unused_notification_schemes( raw_html ):
    scheme_ids = []
    for m in re.finditer( r'<tr>.+?</tr>', raw_html, re.DOTALL ):
        scheme = m.group()
        if re.search( r'href="/plugins/servlet/project-config', scheme ):
            # projects are associated - SKIP
            pass
        else:
            # no associated projects - safe to delete
            id_ptrn = r'href="DeleteNotificationScheme!default.jspa[^"]+schemeId=([0-9]+)"'
            m = re.search( id_ptrn, scheme )
            if m:
                id = m.group(1)
                scheme_ids.append( id )
    return scheme_ids


@timing
def del_issueSecurity_schemes():
    r = go_sudo_path( f'/secure/admin/ViewIssueSecuritySchemes.jspa' )
    ptrn = re.compile( r'href="DeleteIssueSecurityScheme[^"]+schemeId=([0-9]+)"' )
    counter = 0
    for m in ptrn.finditer( r.text ):
        id = m.group(1)
        r = web_delete_by_id(
            id,
            '/secure/admin/DeleteIssueSecurityScheme.jspa',
            { 'schemeId': id, 'confirmed': 'true' }
        )
        counter = counter + 1
    logging.info( f'Deleted {counter} issueSecurity schemes.' )


@timing
def del_workflows():
    r = go_sudo_path( f'/secure/admin/ListWorkflows.jspa' )
    ptrn = re.compile( r'id="del_([^"]+)" href="DeleteWorkflow.jspa' )
    counter = 0
    for m in ptrn.finditer( r.text ):
        name = m.group(1)
        r = web_delete_by_id(
            name,
            '/secure/admin/DeleteWorkflow.jspa',
            {
                'workflowName': name,
                'confirmedDelete': 'true',
                'workflowMode': 'live',
            }
        )
        counter = counter + 1
    logging.info( f'Deleted {counter} workflows.' )


@timing
def del_screens():
    r = api_get( 'screens?expand=deletable' )
    screens = r.json()
    # Returns a list of dicts formatted like so:
	# {
	#   "id": 10227,
	#   "name": "AD: Project Management Create Issue Screen",
	#   "description": "",
	#   "deletable": true,
	#   "expand": "fieldScreenSchemes,fieldScreenWorkflows,deletable"
	# },
    # print( json.dumps( r.json() ) )
    ###
    # load an admin page once before sending a delete POST
    # so the atl_token is valid for requests via the website
    go_sudo_path( f'/secure/admin/ViewFieldScreens.jspa' )
    deleted = 0
    for screen in screens:
        if screen[ 'deletable' ]:
            logging.debug( f"DELETE {screen['id']} {screen['name']}" )
            r = web_delete_by_id( screen['id'], '/secure/admin/DeleteFieldScreen.jspa' )
            deleted = deleted + 1
    logging.info( f'Deleted {deleted} screens.' )


@timing
def del_statuses():
    r = go_sudo_path( f'/secure/admin/ViewStatuses.jspa' )
    ptrn = re.compile( r'href="DeleteStatus[^"]+id=([0-9]+)"' )
    counter = 0
    for m in ptrn.finditer( r.text ):
        id = m.group(1)
        r = web_delete_by_id( id, '/secure/admin/DeleteStatus.jspa' )
        counter = counter + 1
    logging.info( f'Deleted {counter} Statuses.' )


def get_groups_to_add():
    return get_config().options( 'groups to add' )


@timing
def add_groups():
    for group in get_groups_to_add():
        add_group( group )


def add_group( groupname ):
    exists = True
    try:
        r = api_get( f'group/member?groupname={groupname}' )
    except requests.exceptions.HTTPError as e:
        if e.response.status_code == 404:
            exists = False
        else:
            raise e
    if not exists:
        data = { 'name': groupname }
        r = api_post( 'group', data )
        if r.status_code != 201:
            logging.warning( f'FAILED with status {r.status_code} .. {r.text}' )


def get_filters_to_delete():
    return get_config().options( 'filters to delete' )


@timing
def del_filters():
    ids = get_filters_to_delete()
    for id in ids:
        exists = True
        try:
            api_get( f'filter/{id}' )
        except requests.exceptions.HTTPError as e:
            if e.response.status_code == 400:
                # 400 means the filter doesn't exist
                exists = False
            else:
                raise e
        if exists:
            api_delete( f'filter/{id}' )


@timing
def update_filters():
    filters = get_config().items( 'filters to update' )
    for id, jql in filters:
        path = f'filter/{id}'
        data = { 'jql': jql }
        r = api_put( path, data )


@timing
def del_custom_fields_unused():
    r = api_get( 'customFields?maxResults=200' )
    custom_fields = r.json()['values']
    # print( f'Num custom fields: {len(custom_fields)}' )
    # print( json.dumps( custom_fields ) )
    # raise SystemExit( 'STOP' )

    # Custom fields look like:
    # {
    #   "id": "customfield_13831",
    #   "name": "ACHE CC subsystem",
    #   "description": "<p>This is the select field for ACHE systems</p>",
    #   "type": "Select List (single choice)",
    #   "searcherKey": "multiselectsearcher",
    #   "projectIds": [],
    #   "issueTypeIds": [],
    #   "self": "https://jira-test.ncsa.illinois.edu/rest/api/latest/customFields/customfield_13831",
    #   "numericId": 13831,
    #   "isLocked": false,
    #   "isManaged": false,
    #   "isAllProjects": true,
    #   "isTrusted": true,
    #   "projectsCount": 0,
    #   "screensCount": 4
    # }
    # A custom field is deletable IF:
    #   "projectsCount": 0,
    #   "screensCount": 0,
    #   "isLocked": false,
    # Not Always, so we need to specify a few to keep
    fields_to_keep = get_config().items( 'customfields to keep' )
    ids_to_keep = [ int(id) for (id,name) in fields_to_keep ]

    # Load a web page to get atl_token
    go_sudo_path( f'/secure/admin/ViewCustomFields.jspa' )
    deleted = 0
    for f in custom_fields:
        if f['numericId'] in ids_to_keep:
            logging.debug( f"KEEP {f['id']} {f['name']}" )
            continue
        not_locked = not f['isLocked']
        has_no_projects = f['projectsCount'] == 0
        has_no_screens = f['screensCount'] == 0
        if not_locked and has_no_projects and has_no_screens:
            logging.debug( f"DELETE {f['id']} {f['name']}" )
            r = web_delete_by_id( f['numericId'], '/secure/admin/DeleteCustomField.jspa' )
            deleted = deleted + 1
    logging.info( f'Deleted {deleted} custom_fields.' )


@timing
def del_custom_fields_specified():
    cfields = get_config().items( 'customfields to delete' )
    # Load a web page to get atl_token
    go_sudo_path( f'/secure/admin/ViewCustomFields.jspa' )
    for (id, name) in cfields:
        logging.info( f"DELETE customfield_{id} ({name})" )
        r = web_delete_by_id( id, '/secure/admin/DeleteCustomField.jspa' )


@timing
def update_sop_used():
    sop_options = get_config().items( 'SOP_Used Options' )
    # Load a web page to get atl_token
    go_sudo_path( f'/secure/admin/ViewCustomFields.jspa' )
    for (id, name) in sop_options:
        path = '/secure/admin/EditCustomFieldOptions!update.jspa'
        data = {
            'value': name,
            'fieldConfigId': '15244',
            'selectedValue': str(id),
            'Update': 'Update',
            'atl_token': get_atl_token(),
        }
        logging.info( f"UPDATE SOP_Used '{name}' ({id})" )
        r = post_sudo_path( path, data )
        time.sleep( 0.3 ) #attempt to avoid slamming the server



def run():
    starttime = time.time()

    del_projects()

    del_issueTypeScreen_schemes()

    del_issueType_schemes()

    del_fieldConfiguration_schemes()

    del_workflow_schemes()

    del_priority_schemes()

    del_screen_schemes()

    del_permission_schemes()

    del_field_configurations()

    del_notification_schemes()

    del_issueSecurity_schemes()

    del_workflows()

    del_statuses()

    del_screens()

    del_custom_fields_unused()

    del_filters()

    update_sop_used()

    # Groups are already updated on prod, or require manual coordination with LDAP
    # add_groups()

    # Not going to update filters, just deleting them
    # update_filters()

    # Skip since don't actually delete, even though they get a 200 return code
    # del_custom_fields_specified()

    verify_all_projects_deleted()

    elapsed = time.time() - starttime
    logging.info( f'Finished in {elapsed} seconds!' )

    # Print summary of errors and warnings
    for e in get_errors():
        logging.error( e )
    for w in get_warnings():
        logging.warning( w )


if __name__ == '__main__':
    run()

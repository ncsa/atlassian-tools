import requests
import pprint
import configparser
import pathlib
import netrc
import time

from functools import wraps

resources = {} # module level resources


def get_session():
    key = 'session'
    if key not in resources:
        resources[key] = requests.Session()
    return resources[key]


def get_config():
    key = 'cfg'
    if key not in resources:
        conf_file = pathlib.Path.home() / '.atlassian-tools-config.ini'
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


def get_login():
    key = 'login'
    if key not in resources:
        get_netrc()
    return resources[key]


# https://stackoverflow.com/questions/1622943/timeit-versus-timing-decorator#27737385
def timing( f ):
    @wraps( f )
    def wrap( *args, **kw ):
        starttime = time.time()
        result = f( *args, **kw )
        endtime = time.time()
        elapsed = endtime - starttime
        print( f'func:{f.__name__} args:[{args}, {kw}] took: {elapsed} sec' )
        return result
    return wrap


def get_atl_token():
    s = get_session()
    return requests.utils.dict_from_cookiejar( s.cookies )['atlassian.xsrf.token']


def get_html_page( url ):
    return get_session().get( url )


def go_sudo_path( path ):
    # attempt to access a secure/admin page
    url = f'https://{get_server()}{path}'
    r = get_html_page( url )
    print( f'RETURN CODE, GET, {path} .. {r}' )

    validate_string = 'You have requested access to an administrative function in Jira and are required to validate your credentials below'
    if validate_string in r.text:
        print( 'SUDO login required' )
        # submit the admin login form with redirect to the same secure/admin page
        s = get_session()
        url = f'https://{get_server()}/secure/admin/WebSudoAuthenticate.jspa'
        post_data = {
            'webSudoPassword': get_password(),
            'atl_token': get_atl_token(),
            'webSudoIsPost': 'false',
            'webSudoDestination': path,
        }
        r = s.post( url, data = post_data )
        print( f'WebSudoAuthenticate .. {r}' )
    return r


def post_sudo_path( path, data ):
    url = f'https://{get_server()}{path}'
    r = get_session().post( url, data=data )
    print( f'RETURN CODE, POST, {path} .. {r}' )
    return r


def api_go( method, path, version='latest', **kw ):
    url = f'https://{get_server()}/rest/api/{version}/{path}'
    print( f'{method} {path}, {pprint.pformat(kw)}' )
    r = get_session().request( method, url, **kw )
    print( f'RETURN CODE .. {r}' )
    r.raise_for_status()
    return r


def api_get( path ):
    return api_go( 'GET', path )


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
    print( f'{path} {id} ...' )
    r = post_sudo_path( path, form_data )
    time.sleep( 0.1 ) #attempt to avoid slamming the server
    return r


@timing
def add_groups():
    for group in get_config().options( 'groups to add' ):
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
            print( f'FAILED with status {r.status_code} .. {r.text}' )


### DO WORK
starttime = time.time()

add_groups()

elapsed = time.time() - starttime
print( f'Finished in {elapsed} seconds!' )

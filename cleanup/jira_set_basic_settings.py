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
        cfg.optionxform = str
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
    try:
        token = requests.utils.dict_from_cookiejar( s.cookies )['atlassian.xsrf.token']
    except KeyError as e:
        go_sudo_path( '/secure/admin/ViewApplicationProperties.jspa' )
        token = requests.utils.dict_from_cookiejar( s.cookies )['atlassian.xsrf.token']
    return token

assert_atl_token = get_atl_token


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
    assert_atl_token()
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
    logging.debug( f'{path} {id} ...' )
    r = post_sudo_path( path, form_data )
    time.sleep( 0.1 ) #attempt to avoid slamming the server
    return r


def set_banner():
    banner = get_config().get( 'server', 'banner' )
    path = '/secure/admin/EditAnnouncementBanner.jspa'
    data = {
        'announcement': banner,
        'bannerVisibility': 'private',
        'Set Banner': 'Set Banner',
        'atl_token': get_atl_token(),
    }
    r = post_sudo_path( path, data )
    logging.info( 'Banner set!' )


def set_general_config():
    data = { k:v for k,v in get_config().items( 'general config' ) }
    # cfg = get_config()
    # data = { k:cfg['general config'][k] for k in ( 'baseURL', 'title', 'useGzip' ) }
    # pprint.pprint( data )
    data.update( { 'atl_token': get_atl_token(), 'Update': 'Update' } )
    path = '/secure/admin/EditApplicationProperties.jspa'
    r = post_sudo_path( path, data )


def run():
    # starttime = time.time()

    set_banner()

    set_general_config()

    # elapsed = time.time() - starttime
    # logging.info( f'Finished in {elapsed} seconds!' )

    # Print summary of errors and warnings
    for e in get_errors():
        logging.error( e )
    for w in get_warnings():
        logging.warning( w )


if __name__ == '__main__':
    run()

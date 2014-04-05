from __future__ import unicode_literals

import logging
import json
import os

import cherrypy
import pykka
from ws4py.messaging import TextMessage
from ws4py.server.cherrypyserver import WebSocketPlugin, WebSocketTool

from mopidy import models, zeroconf
from mopidy.core import CoreListener
from . import ws

from configobj import ConfigObj, ConfigObjError
from validate import Validator
import jinja2

logger = logging.getLogger(__name__)

config_file = '/boot/config/settings.ini'
spec_file = '/opt/musicbox/settingsspec.ini'
template_file = '/opt/webclient/settings/index.html'
log_file = '/var/log/mopidy/mopidy.log'

class HttpFrontend(pykka.ThreadingActor, CoreListener):
    def __init__(self, config, core):
        super(HttpFrontend, self).__init__()
        self.config = config
        self.core = core

        self.hostname = config['http']['hostname']
        self.port = config['http']['port']
        self.zeroconf_name = config['http']['zeroconf']
        self.zeroconf_service = None

        self._setup_server()
        self._setup_websocket_plugin()
        app = self._create_app()
        self._setup_logging(app)

    def _setup_server(self):
        cherrypy.config.update({
            'engine.autoreload_on': False,
            'server.socket_host': self.hostname,
            'server.socket_port': self.port,
        })

    def _setup_websocket_plugin(self):
        WebSocketPlugin(cherrypy.engine).subscribe()
        cherrypy.tools.websocket = WebSocketTool()

    def _create_app(self):
        root = RootResource()
        root.mopidy = MopidyResource()
        root.mopidy.ws = ws.WebSocketResource(self.core)

        if self.config['http']['static_dir']:
            static_dir = self.config['http']['static_dir']
        else:
            static_dir = os.path.join(os.path.dirname(__file__), 'data')
        logger.debug('HTTP server will serve "%s" at /', static_dir)

        mopidy_dir = os.path.join(os.path.dirname(__file__), 'data')
        favicon = os.path.join(mopidy_dir, 'favicon.png')

        config = {
            b'/': {
                'tools.staticdir.on': True,
                'tools.staticdir.index': 'index.html',
                'tools.staticdir.dir': static_dir,
            },
            b'/favicon.ico': {
                'tools.staticfile.on': True,
                'tools.staticfile.filename': favicon,
            },
            b'/mopidy': {
                'tools.staticdir.on': True,
                'tools.staticdir.index': 'mopidy.html',
                'tools.staticdir.dir': mopidy_dir,
            },
            b'/mopidy/ws': {
                'tools.websocket.on': True,
                'tools.websocket.handler_cls': ws.WebSocketHandler,
            },
        }

        return cherrypy.tree.mount(root, '/', config)

    def _setup_logging(self, app):
        cherrypy.log.access_log.setLevel(logging.NOTSET)
        cherrypy.log.error_log.setLevel(logging.NOTSET)
        cherrypy.log.screen = False

        app.log.access_log.setLevel(logging.NOTSET)
        app.log.error_log.setLevel(logging.NOTSET)

    def on_start(self):
        logger.debug('Starting HTTP server')
        cherrypy.engine.start()
        logger.info('HTTP server running at %s', cherrypy.server.base())

        if self.zeroconf_name:
            self.zeroconf_service = zeroconf.Zeroconf(
                stype='_http._tcp', name=self.zeroconf_name,
                host=self.hostname, port=self.port)

            if self.zeroconf_service.publish():
                logger.debug(
                    'Registered HTTP with Zeroconf as "%s"',
                    self.zeroconf_service.name)
            else:
                logger.debug('Registering HTTP with Zeroconf failed.')

    def on_stop(self):
        if self.zeroconf_service:
            self.zeroconf_service.unpublish()

        logger.debug('Stopping HTTP server')
        cherrypy.engine.exit()
        logger.info('Stopped HTTP server')

    def on_event(self, name, **data):
        event = data
        event['event'] = name
        message = json.dumps(event, cls=models.ModelJSONEncoder)
        cherrypy.engine.publish('websocket-broadcast', TextMessage(message))


class RootResource(object):
    @cherrypy.expose
    @cherrypy.tools.allow(methods=['POST'])
    def updateSettings(self, **params):
        error = ''
        try:
            config = ConfigObj(config_file, configspec=spec_file, file_error=True)
        except (ConfigObjError, IOError), e:
            error = 'Could not load ini file!'
        print (params)
        validItems = ConfigObj(spec_file)
        templateVars = { 
            "error": error
        }
        #iterate over the items, so that only valid items are processed
        for item in validItems:
            for subitem in validItems[item]:
                itemName = item + '__' + subitem
                print itemName
                if itemName in params.keys():
                    config[item][subitem] = params[itemName]
                    print params[itemName]
        config.write()
        os.system("shutdown -r now")
#        os.system("su root -c /opt/musicbox/startup.sh")
        return "<html><body><h1>Settings Saved!</h1><script>toast('Applying changes (might need a rebbot)...', 10000);setTimeout(function(){window.location('/');}, 10000);</script><a href='/'>Back</a></body></html>"

    @cherrypy.expose
    def Settings(self, **params):
        templateLoader = jinja2.FileSystemLoader( searchpath = "/" )
        templateEnv = jinja2.Environment( loader=templateLoader )
        template = templateEnv.get_template(template_file)
        error = ''
        #read config file
        try:
            config = ConfigObj(config_file, configspec=spec_file, file_error=True)
        except (ConfigObjError, IOError), e:
            error = 'Could not load ini file!'
        print (error)
        #read values of valid items (in the spec-file)
        validItems = ConfigObj(spec_file)
        templateVars = { 
            "error": error
        }
        #iterate over the valid items to get them into the template
        for item in validItems:
            print(item)
            for subitem in validItems[item]:
                print('['+subitem)
                itemName = item + '__' + subitem
                try:
                    templateVars[itemName] = config[item][subitem]
                except:
                    pass
        print templateVars
        return template.render ( templateVars )

    @cherrypy.expose
    @cherrypy.tools.allow(methods=['POST'])
    def haltSystem(self, **params):
        os.system("shutdown -h now")

    @cherrypy.expose
    @cherrypy.tools.allow(methods=['POST'])
    def rebootSystem(self, **params):
        os.system("shutdown -r now")

    @cherrypy.expose
    def log(self, **params):
        page = '<html><body><h2>MusicBox/Mopidy Log (can take a while to load...)</h2><pre>'
        with open(log_file, 'r') as f:
            page += f.read()
            page += '</pre></body></html>'
        return page

class MopidyResource(object):
    pass

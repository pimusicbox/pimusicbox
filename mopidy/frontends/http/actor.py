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


logger = logging.getLogger(__name__)


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
                logger.info('Registered HTTP with Zeroconf as "%s"',
                            self.zeroconf_service.name)
            else:
                logger.info('Registering HTTP with Zeroconf failed.')

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
#    def updateSettings(self, **params):
#        #set the username & password
#        logger.info('Settings received %s', params)
#	for key, value in params.iteritems():
#		logger.info("%s %s", key, value)
#		sysstring = "sed -i -e \"/^\[MusicBox\]/,/^\[.*\]/ s|^\(%s[ \t]*=[ \t]*\).*$|\1'%s'\r|\" /boot/config/settingst.ini" % (key, value)
#		logger.info(sysstring)
#		subprocess.Popen(sysstring, shell=True)
#	subprocess.Popen("/opt/restartmopidy.sh", shell=True)

#    @cherrypy.expose
#    def settings(self, **params):
#        logger.info('Settings')
#	templatefile = open(os.path.join(settings_dir, 'index.html'), 'r')
#	for line in templatefile:
#            for src, target in replacements.iteritems():
#	        line = line.replace(src, target)
#	        page += line
#	return page

    @cherrypy.expose
    @cherrypy.tools.allow(methods=['POST'])
    def haltSystem(self, **params):
        logger.info('Halt received')
	os.system("shutdown -h now")

    @cherrypy.expose
    @cherrypy.tools.allow(methods=['POST'])
    def rebootSystem(self, **params):
        logger.info('Reboot received')
	os.system("shutdown -r now")

    @cherrypy.expose
    def log(self, **params):
#        logger.info('Show log')
	page = '<html><body>'
	with open('/var/log/mopidy.log', 'r') as f:
	    page = '<pre>%s</pre>' % f.read()
	page += '</body></html>'
	return page

class MopidyResource(object):
    pass
                                                                                                                                                                                                                              pass
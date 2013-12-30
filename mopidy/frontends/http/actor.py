from __future__ import unicode_literals

import logging
import json
import os
import subprocess

import cherrypy
import pykka
from ws4py.messaging import TextMessage
from ws4py.server.cherrypyserver import WebSocketPlugin, WebSocketTool

from mopidy import models
from mopidy.core import CoreListener
from . import ws


logger = logging.getLogger('mopidy.frontends.http')


class HttpFrontend(pykka.ThreadingActor, CoreListener):
    def __init__(self, config, core):
        super(HttpFrontend, self).__init__()
        self.config = config
        self.core = core
        self._setup_server()
        self._setup_websocket_plugin()
        app = self._create_app()
        self._setup_logging(app)

    def _setup_server(self):
        cherrypy.config.update({
            'engine.autoreload_on': False,
            'server.socket_host': self.config['http']['hostname'],
            'server.socket_port': self.config['http']['port'],
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

        settings_dir = os.path.join(static_dir, 'settings/static')
        settings_static_dir = os.path.join(settings_dir, 'static')

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
#            b'/settings/static': {
#                'tools.staticdir.on': True,
##                'tools.staticdir.index': 'index.html',
#                'tools.staticdir.dir': settings_static_dir,
#            },
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

    def on_stop(self):
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

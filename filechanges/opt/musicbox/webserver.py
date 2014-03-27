# Webserver for musicbox functions
# (c) Wouter van Wijk 2014
# GPL 3 License

import cherrypy
import os

config_file = '/boot/config/settings.ini'
template_file = '/opt/webclient/settings/index.html'
log_file = '/var/log/mopidy/mopidy.log'


class runServer(object):
    _cp_config = {'tools.staticdir.on' : True,
            'tools.staticdir.dir' : '/opt/defaultwebclient',
            'tools.staticdir.index' : 'index.html',
    }

    @cherrypy.expose
    @cherrypy.tools.allow(methods=['POST'])
    def updateSettings(self, **params):
        #set the username & password
        for key, value in params.iteritems():
            sysstring = "sed -i -e \"/^\[MusicBox\]/,/^\[.*\]/ s|^\(%s[ \t]*=[ \t]*\).*$|\1'%s'\r|\" /boot/config/settings.ini" % (key, value)
            subprocess.Popen(sysstring, shell=True)
        subprocess.Popen("/opt/restartmopidy.sh", shell=True)
    updateSettings._cp_config = {'tools.staticdir.on': False}

    @cherrypy.expose
    def settings(self, **params):
        templatefile = open(template_file, 'r')
        for line in templatefile:
            for src, target in replacements.iteritems():
                line = line.replace(src, target)
                page += line
        return page
    settings._cp_config = {'tools.staticdir.on': False}

    @cherrypy.expose
    @cherrypy.tools.allow(methods=['POST'])
    def haltSystem(self, **params):
        os.system("shutdown -h now")
    haltSystem._cp_config = {'tools.staticdir.on': False}

    @cherrypy.expose
    @cherrypy.tools.allow(methods=['POST'])
    def rebootSystem(self, **params):
        os.system("shutdown -r now")
    rebootSystem._cp_config = {'tools.staticdir.on': False}

    @cherrypy.expose
    def log(self, **params):
        page = '<html><body><h2>MusicBox/Mopidy Log (can take a while to load...)</h2>'
        with open(log_file, 'r') as f:
            page += '<pre>%s</pre>' % f.read()
            page += '</body></html>'
        return page
    log._cp_config = {'tools.staticdir.on': False}

cherrypy.config.update({'server.socket_host': '0.0.0.0', 'server.socket_port': 80 })
cherrypy.quickstart(runServer())

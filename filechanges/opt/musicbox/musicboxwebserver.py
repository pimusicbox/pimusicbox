#!/usr/bin/python
# Webserver for musicbox functions
# (c) Wouter van Wijk 2014
# GPL 3 License

import cherrypy
from configobj import ConfigObj, ConfigObjError
from validate import Validator
import os
import jinja2

config_file = '/boot/config/settings.ini'
spec_file = '/opt/musicbox/settingsspec.ini'
template_file = '/opt/webclient/settings/index.html'
log_file = '/var/log/mopidy/mopidy.log'

class runServer(object):
    #setup static files
    _cp_config = {'tools.staticdir.on' : True,
            'tools.staticdir.dir' : '/opt/defaultwebclient',
            'tools.staticdir.index' : 'index.html',
    }

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
        #os.system("shutdown -r now")
        return '<html><body><h1>Settings Saved!</h1>Rebooting MusicBox...<br/><a href="/">Back</a></body></html>'
        
    updateSettings._cp_config = {'tools.staticdir.on': False}

    @cherrypy.expose
    def settings(self, **params):
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
                print('-'+subitem)
                itemName = item + '__' + subitem
                try:
                    templateVars[itemName] = config[item][subitem]
                    print templateVars[itemName]
                except:
                    pass
        print templateVars
        return template.render ( templateVars )
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

cherrypy.config.update({'server.socket_host': '0.0.0.0', 'server.socket_port': 8080 })
cherrypy.quickstart(runServer())

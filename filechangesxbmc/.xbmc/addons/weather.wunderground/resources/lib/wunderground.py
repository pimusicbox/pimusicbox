# -*- coding: utf-8 -*-

import urllib2, gzip, base64
from StringIO import StringIO

WAIK             = 'NDEzNjBkMjFkZjFhMzczNg=='
WUNDERGROUND_URL = 'http://api.wunderground.com/api/%s/%s/%s/q/%s.%s'

def wundergroundapi(features, settings, query, fmt):
    url = WUNDERGROUND_URL % (base64.b64decode(WAIK)[::-1], features, settings, query, fmt)
    try:
        req = urllib2.Request(url)
        req.add_header('Accept-encoding', 'gzip')
        response = urllib2.urlopen(req)
        if response.info().get('Content-Encoding') == 'gzip':
            buf = StringIO(response.read())
            compr = gzip.GzipFile(fileobj=buf)
            data = compr.read()
        else:
            data = response.read()
        response.close()
    except:
        data = ''
    return data

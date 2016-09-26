# nifi-prov-1x.py

import json, sys
import cookielib
from pprint import pprint
import httplib, urllib2
import re
import time

HOST="localhost"
PORT="8080"
URLPATH="/provenance/"
HEADERS = {
    "Content-Type": "application/json",
    "Accept": "application/json, text/javascript, */*"
}

CACERT="/local/jfskora/localcerts/rootCA.pem"
CERT="/local/jfskora/localcerts/user1.crt"
KEY="/local/jfskora/localcerts/user1.key"


class MyHTTPSClientAuthHandler(urllib2.HTTPSHandler):

    def __init__(self, key, cert):
        urllib2.HTTPSHandler.__init__(self)
        self.key = key
        self.cert = cert

    def https_open(self, req):
        #Rather than pass in a reference to a connection class, we pass in
        # a reference to a function which, for all intents and purposes,
        # will behave as a constructor
        return self.do_open(self.getConnection, req)

    def getConnection(self, host, timeout=300):
        return httplib.HTTPSConnection(host,
                                       key_file=self.key,
                                       cert_file=self.cert,
                                       timeout=timeout)


class Client(object):

    def __init__(self, key=KEY, cert=CERT, host=HOST, port=PORT, proto="HTTP"):
        self.key = key
        self.cert = cert
        self.host = host
        self.port = port if type(port)==int else int(port)
        self.proto = proto
        self.baseUrl = "%s://%s:%d/nifi-api" % (self.proto, self.host, self.port)
        
        self.cookieJar = cookielib.CookieJar()
        self.handlers = []
        self.authHandler = MyHTTPSClientAuthHandler(key, cert)
        self.cookieHandler = urllib2.HTTPCookieProcessor(self.cookieJar)
        self.handlers.append(self.authHandler)
        self.handlers.append(self.cookieHandler)
        self.opener = urllib2.build_opener(*self.handlers)

    def getOpener(self):
        return self.opener
#.open(self.baseUrl + ("" if url and url[0]=="/" else "/") + url)


class ProvenanceQuery(object):

    opener = None
    debug = False

    def __init__(self, query, debug=False):
        self.client = Client()
        self.query = query
        self.opener = self.client.getOpener()
        self.debug = debug
        self.lastTime = None
        self.fmt = "%-10s %-27s %-20s %-36s %-10s %-20s %-20s"
        self.lines = 0
        self.pageSize = 20

    def start(self):
        self.request = urllib2.Request(self.client.baseUrl + "/provenance", data=json.dumps(query))
        for key in HEADERS.keys():
            self.request.add_header(key, HEADERS[key])
        if self.debug:
            print self.request.get_method() + " " + self.request.get_full_url() 
        self.response = self.opener.open(self.request)
        self.responseText = self.response.read()
        self.responseData = json.loads(self.responseText)
        if self.debug:
            pprint(self.responseData, indent=2)
        return self.response

    def header(self):
        print ""
        print self.fmt % ("id", "date/time", "type", "uuid", "size", "component name", "component type")
        print self.fmt % ("-"*10, "-"*27, "-"*20, "-"*36, "-"*10, "-"*20, "-"*20) 
        
    def page(self):
        url = self.responseData["provenance"]["uri"]
        self.request = urllib2.Request(url=url)
        if self.debug:
            print self.request.get_method() + " " + self.request.get_full_url()
        done = False
        while not done:
            self.response = self.opener.open(self.request)
            self.responseText = self.response.read()
            self.responseData = json.loads(self.responseText)
            done = self.responseData["provenance"]["finished"]
            events = self.responseData["provenance"]["results"]["provenanceEvents"]
            outEvents = [ev for ev in events if not self.lastTime or ev["eventTime"] > self.lastTime]
            if len(outEvents) > 0:
                for event in outEvents:
                    if self.lines % self.pageSize == 0:
                        self.header()
                    self.lines += 1
                    print self.fmt % (event["id"], event["eventTime"], event["eventType"],
                                    event["flowFileUuid"], event["fileSize"], event["componentName"],
                                    event["componentName"])
                times = [self.lastTime, ]
                times.extend([ev["eventTime"] for ev in outEvents])
                self.lastTime = max(times)
#            else:
#                if self.lines % self.pageSize == 0:
#                    self.header()
#                print "no new events at " + time.ctime()
#                self.lines += 1
        return(self.response)
        
    def close(self):
        url = self.responseData["provenance"]["uri"]
        self.request = urllib2.Request(url=url)
        self.request.get_method = lambda: "DELETE"
        if self.debug:
            print self.request.get_method() + " " + self.request.get_full_url()
        self.response = self.opener.open(self.request)
        if self.debug:
            pprint(self.response.read())
        return(self.response)

    def getLastTime(self):
        return self.lastTime
        

if __name__ == "__main__":

    query = { "provenance": { "request": {}}}
    query["provenance"]["request"]["maxResults"] = 100
    query["provenance"]["request"]["startDate"] = "09/26/2016 00:00:00 EDT"
    query["provenance"]["request"]["endDate"] = "09/26/2016 23:59:59 EDT"
    query["provenance"]["request"]["searchTerms"] = {}

    prov = ProvenanceQuery(query)
    while True:
        prov.start()
        prov.page()
        prov.close()

        query["provenance"]["request"]["startDate"] = re.sub("\.[0-9]{3}", "", prov.getLastTime())

        time.sleep(5)

# nifi-prov-1x.py

import json, sys
import cookielib
from pprint import pprint
import httplib, urllib2
import re
import datetime
import time
import traceback
import BaseHTTPServer
import optparse
import inspect

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

    def __init__(self, url, key, cert):
        self.key = key
        self.cert = cert
        self.url = url
        self.baseUrl = "%s/nifi-api" % (self.url)
        
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
    timeFmt = "%m/%d/%Y %H:%M:%S %Z"

    def __init__(self, url, query, line_count=0, debug=False):
        self.url = url
        self.client = Client(self.url, key=KEY, cert=CERT)
        self.opener = self.client.getOpener()

        self.query = query
        self.debug = debug
        self.lastTime = None
        self.fmt = "%-6s %-10s %-27s %-20s %-36s %-15s %-30s %-30s"
        self.milliPtrn = re.compile("\.[0-9]{3,3}")
        self.line_count = line_count
        self.pageSize = 20

    def start(self):
        self.request = urllib2.Request(self.client.baseUrl + "/provenance", data=json.dumps(query))
        for key in HEADERS.keys():
            self.request.add_header(key, HEADERS[key])
        if self.debug:
            print self.request.get_method() + " " + self.request.get_full_url() 
        try:
            self.response = self.opener.open(self.request)
        except Exception as e:
            if e.getcode() == 409:
                return None
        self.responseText = self.response.read()
        try:
            self.responseData = json.loads(self.responseText)
        except:
            traceback.print_exc()
            print self.responseText
        if not "provenance" in self.responseData:
            print self.responseData
        if self.debug:
            pprint(self.responseData, indent=2)
        return self.response

    def header(self):
        print ""
        print self.fmt % ("count", "id", "date/time", "type", "uuid", "size", "component name", "component type")
        print self.fmt % ("-"*6, "-"*10, "-"*27, "-"*20, "-"*36, "-"*15, "-"*30, "-"*30) 
        
    def apiToTime(self, t):
        return time.strptime(self.milliPtrn.sub("", t), self.timeFmt)

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
            outEvents = [ev for ev in events if not self.lastTime or 
                    self.apiToTime(ev["eventTime"]) > self.lastTime]
            if len(outEvents) > 0:
                for event in outEvents:
                    if self.line_count % self.pageSize == 0:
                        self.header()
                    self.line_count += 1
                    print self.fmt % (str(self.line_count), event["id"], event["eventTime"], event["eventType"],
                                    event["flowFileUuid"], event["fileSize"], event["componentName"],
                                    event["componentName"])
                times = [self.lastTime, ]
                times.extend([self.apiToTime(ev["eventTime"]) for ev in outEvents])
                self.lastTime = max(times)
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
    

def startOfDay(t):
    return time.localtime(time.mktime((t.tm_year, t.tm_mon, t.tm_mday, 0, 0 ,0, 0, 0, t.tm_isdst)))

def endOfDay(t):
    return time.localtime(time.mktime((t.tm_year, t.tm_mon, t.tm_mday, 23, 59, 59, 0, 0, t.tm_isdst)))

if __name__ == "__main__":

    parser = optparse.OptionParser()
    parser.add_option("-u", "--url", dest="url",
                        help="Target URL with protocol, host, and port.")
    parser.add_option("-s", "--sleep", dest="sleep", type="int", default="5",
                        help="Seconds before next poll if no events are received.")
    parser.add_option("--startdate", dest="startdate",
                        help="Date and time for start date parameter in 'mm/dd/yyyy hh:mm:ss tz' format.")
    parser.add_option("--enddate", dest="enddate",
                        help="Date and time for end date parameter in 'mm/dd/yyyy hh:mm:ss tz' format.")
    parser.add_option("-m", "--max", dest="maxrows", type="int", default="100",
                        help="Maximum rows to return.")
    (opts, args) = parser.parse_args()

    if not opts.url:
        parser.error("URL is required parameter")

    runTime = time.localtime()
    queryStart = startOfDay(runTime)
    queryEnd = endOfDay(runTime)

    query = { "provenance": { "request": {}}}
    query["provenance"]["request"]["maxResults"] = opts.maxrows
    if opts.startdate:
        query["provenance"]["request"]["startDate"] = opts.startdate
    else:    
        query["provenance"]["request"]["startDate"] = time.strftime(ProvenanceQuery.timeFmt, queryStart)
    if opts.enddate:
        query["provenance"]["request"]["endDate"] = opts.enddate
    else:
        query["provenance"]["request"]["endDate"] = time.strftime(ProvenanceQuery.timeFmt, queryEnd)
    query["provenance"]["request"]["searchTerms"] = {}

    line_count = 0
    while True:
#        print "-" * 60
#        print query["provenance"]["request"]["startDate"]
#        print "-" * 60
        prov = ProvenanceQuery(opts.url, query, line_count)
        if not prov.start():
            continue
        prov.page()
        line_count = prov.line_count
        prov.close()

        lastTime = prov.getLastTime()
        if lastTime:
            tmpTime = (datetime.datetime.fromtimestamp(time.mktime(lastTime)) + datetime.timedelta(0, 1)).timetuple()
            nextTime = time.struct_time((tmpTime.tm_year, tmpTime.tm_mon, tmpTime.tm_mday, tmpTime.tm_hour, 
                                tmpTime.tm_min, tmpTime.tm_sec, tmpTime.tm_wday, tmpTime.tm_yday, lastTime.tm_isdst))
            newTime = time.strftime(ProvenanceQuery.timeFmt, nextTime)
            query["provenance"]["request"]["startDate"] = newTime
        else:
            time.sleep(opts.sleep)


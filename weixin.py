#!/usr/bin/python
#_*_coding:utf-8 _*_
 
 
import urllib,urllib2
import json
import sys
import simplejson
 
def gettoken(corpid,corpsecret):
    gettoken_url = 'https://qyapi.weixin.qq.com/cgi-bin/gettoken?corpid=' + corpid + '&corpsecret=' + corpsecret
    try:
        token_file = urllib2.urlopen(gettoken_url)
    except urllib2.HTTPError as e:
        print e.code
        print e.read().decode("utf8")
        sys.exit()
    token_data = token_file.read().decode('utf8')
    token_json = json.loads(token_data)
    token_json.keys()
    token = token_json['access_token']
    return token
 
def senddata(access_token,user,content):
 
    send_url = 'https://qyapi.weixin.qq.com/cgi-bin/message/send?access_token=' + access_token
    send_values = {
        "touser":user,    #企业号中的用户帐号，在zabbix用户Media中配置，如果配置不正常，将按部门发送。
        "toparty":"2",    #企业号中的部门id，这里创建的运维部门ID是2
        "msgtype":"text", #消息类型位text文本类型，当然你可以设置为图文类型等；
        "agentid":"1",    #企业号中的应用id，这里创建的应用ID是1；
        "text":{
            "content":content
           },
        "safe":"0"
        }
#    send_data = json.dumps(send_values, ensure_ascii=False)
    send_data = simplejson.dumps(send_values, ensure_ascii=False).encode('utf-8')
    send_request = urllib2.Request(send_url, send_data)
    response = json.loads(urllib2.urlopen(send_request).read())
    print str(response)
 
 
if __name__ == '__main__':
    user = str(sys.argv[1])     #zabbix传过来的第一个参数
    content = str(sys.argv[3])  #zabbix传过来的第三个参数
 
    corpid =  'wxec0879f3c9fa1342'   #CorpID是企业号的标识
    corpsecret = 'I2AFaK8nsV9yc8ttYO8jz5SHf5CS7_oEQ9GhJI-ABqfLasuF6EBc_WxXWSVPzS6V' 
    accesstoken = gettoken(corpid,corpsecret)
    senddata(accesstoken,user,content)

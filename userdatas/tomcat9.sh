#!/bin/bash
amazon-linux-extras enable java-openjdk11
yum clean metadata && yum install -y java-11-openjdk ca-certificates
wget https://dlcdn.apache.org/tomcat/tomcat-9/v9.0.59/bin/apache-tomcat-9.0.59.tar.gz
tar zxvf apache-tomcat-9.0.59.tar.gz
mv apache-tomcat-9.0.59 /usr/local/src/tomcat9/
/usr/local/src/tomcat9/bin/startup.sh
# Tomcat 버전 확인
java -cp /usr/local/src/tomcat9/lib/catalina.jar org.apache.catalina.util.ServerInfo
sudo tee /etc/systemd/system/tomcat.service << EOF
[Unit]
Description=tomcat9
After=network.target syslog.target

[Service]
Type=forking
User=root
Group=root
ExecStart=/usr/local/src/tomcat9/bin/startup.sh
ExecStop=/usr/local/src/tomcat9/bin/shutdown.sh

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload

sed -i -r -e '/port 8009/ a\ \    <Connector port="8009" protocol="AJP/1.3" address="0.0.0.0" URIEncoding="UTF-8" secretRequired="true" secret="test" redirectPort="8443" />' /usr/local/src/tomcat9/conf/server.xml
\mv /usr/local/src/tomcat9/webapps/ROOT/index.jsp /usr/local/src/tomcat9/webapps/ROOT/index.jsp_bak
echo was server: `hostname -I` > /usr/local/src/tomcat9/webapps/ROOT/index.jsp

sudo tee /usr/local/src/tomcat9/webapps/ROOT/session.jsp << EOF
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
	Integer ival = (Integer)
	session.getAttribute("_session_counter");
	if (ival == null) { ival = new Integer(1); } 
	else { ival = new Integer(ival.intValue() + 1); }
	session.setAttribute("_session_counter", ival);
	System.out.println("worker11");
%>
<%@page import="java.net.InetAddress"%>
<%InetAddress inet = InetAddress.getLocalHost();
String serverAddr = inet.getHostAddress();
String addr = request.getRemoteAddr(); %>
<!DOCTYPE html>
<html>
	<head>
		<meta charset="UTF-8">
		<title>Insert title here</title>
	</head>
	<body>
		[**WAS1**]
		<!-- 서버 별로 번호를 다르게 표기 --><br>
		[<%=session.getId()%>]<br>
		Session Counter = [<%=ival%>]<br>
		<a href="./index.jsp">[Reload]</a><br>
		Current Session ID :
		<%=request.getRequestedSessionId()%>
		<br>
		inet: <%=inet%><br>
		serverAddr: <%=serverAddr%><br>
		addr: <%=addr%><br>
	</BODY>
</HTML>
EOF

systemctl start tomcat
systemctl enable tomcat
systemctl restart tomcat
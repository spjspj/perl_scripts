rem To Run sever

title Maven - server_console
cd c:\xmage_clean\mage\Mage.Server.Console 
set MAVEN_OPTS=-Xmx1500m -XX:MaxPermSize=128m
start /wait "maven - server_console" cmd /c mvn exec:java
cd c:\xmage_clean

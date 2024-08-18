rem To Run sever

title Maven - xmage
cd c:\xmage_clean\mage\Mage.Client 
set MAVEN_OPTS=-Xmx1500m -XX:MaxPermSize=128m
start /wait "maven 2 - xmage client" cmd /c mvn exec:java
cd c:\xmage_clean
timeout /t 200
call c:\xmage_clean\spjspj_bats\spjspj_client.bat

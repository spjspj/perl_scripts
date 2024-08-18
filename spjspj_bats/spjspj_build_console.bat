@echo off
setx JAVA_HOME "C:\Program Files\Java\jdk1.8.0_101"
cd c:\xmage_clean\mage\Mage.Server.Console\
cmd /C mvn install -q -amd -DskipTests
cd c:\xmage_clean\

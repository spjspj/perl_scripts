rem @echo off
rem To build server and client

rem from pom.xml        <module>Mage</module>
rem from pom.xml        <module>Mage.Common</module>
rem from pom.xml        <module>Mage.Server</module>
rem from pom.xml        <module>Mage.Client</module>
rem from pom.xml        <module>Mage.Plugins</module>
rem from pom.xml        <module>Mage.Server.Plugins</module>
rem from pom.xml        <module>Mage.Server.Console</module>
rem from pom.xml        <!--module>Mage.Sets</module-->
rem from pom.xml        <module>Mage.Tests</module>
rem from pom.xml        <module>Mage.Verify</module>

rem cd c:\xmage_clean\mage\Mage
rem cmd /C mvn clean -DskipTests
rem cd c:\xmage_clean\mage\Mage.Common
rem cmd /C mvn clean -DskipTests
rem cd c:\xmage_clean\mage\Mage.Server
rem cmd /C mvn clean -DskipTests
rem cd c:\xmage_clean\mage\Mage.Client
rem cmd /C mvn clean -DskipTests
rem cd c:\xmage_clean\mage\Mage.Plugins
rem cmd /C mvn clean -DskipTests
rem cd c:\xmage_clean\mage\Mage.Server.Plugins
rem cmd /C mvn clean -DskipTests
rem cd c:\xmage_clean\mage\Mage.Server.Console
rem cmd /C mvn clean -DskipTests
rem cd c:\xmage_clean\mage\Utils
rem cmd /C mvn clean -DskipTests
rem cd c:\xmage_clean\mage\repository
rem cmd /C mvn clean -DskipTests

setx JAVA_HOME "C:\Program Files\Java\jdk1.8.0_101"
rem setx PATH "%PATH%;%JAVA_HOME%\bin";

rem cd c:\xmage_clean\mage\Mage
rem cmd /C mvn install -q -amd -DskipTests
rem cd c:\xmage_clean\mage\Mage.Common
rem cmd /C mvn install -q -amd -DskipTests
rem cd c:\xmage_clean\mage\Mage.Server
rem cmd /C mvn install -q -amd -DskipTests
rem cd c:\xmage_clean\mage\Mage.Client
rem cmd /C mvn install -q -amd -DskipTests
rem cd c:\xmage_clean\mage\Mage.Plugins
rem cmd /C mvn install -q -amd -DskipTests
rem cd c:\xmage_clean\mage\Mage.Server.Plugins
rem cmd /C mvn install -q -amd -DskipTests
rem cd c:\xmage_clean\mage\Mage.Server.Console
rem cmd /C mvn install -q -amd -DskipTests
rem cd c:\xmage_clean\mage\Mage.Test
rem cmd /C mvn install -q -amd -DskipTests

rem gvim C:\xmage_clean\mage\Mage.Client\src\main\java\mage\client\dialog\PreferencesDialog.java C:\xmage_clean\mage\Mage.Client\src\main\java\mage\client\game\GamePanel.java C:\xmage_clean\mage\Mage.Client\src\main\java\mage\client\game\PlayAreaPanel.java C:\xmage_clean\mage\Mage.Client\src\main\java\mage\client\remote\CallbackClientImpl.java C:\xmage_clean\mage\Mage.Client\src\main\java\org\mage\plugins\card\dl\sources\ScryfallImageSupportCards.java C:\xmage_clean\mage\Mage.Common\src\main\java\mage\view\PlayerView.java C:\xmage_clean\mage\Mage.Server.Plugins\Mage.Player.Human\src\mage\player\human\HumanPlayer.java C:\xmage_clean\mage\Mage.Tests\src\test\java\org\mage\test\player\TestPlayer.java C:\xmage_clean\mage\Mage.Tests\src\test\java\org\mage\test\stub\PlayerStub.java C:\xmage_clean\mage\Mage\src\main\java\mage\constants\PlayerAction.java C:\xmage_clean\mage\Mage\src\main\java\mage\players\Player.java C:\xmage_clean\mage\Mage\src\main\java\mage\players\PlayerImpl.java
rem gvim C:\xmage_clean\mage\Mage.Server.Plugins\Mage.Player.Human\src\mage\player\human\HumanPlayer.java
rem cd c:\xmage_clean\
rem cd c:\xmage_clean\mage\
rem cmd /C mvn install -q -amd -DskipTests
rem cd c:\xmage_clean\mage\Mage\
rem cmd /C mvn install -q -amd -DskipTests
cd c:\xmage_clean\mage\Mage.Client\
cmd /C mvn install -q -amd -DskipTests
cd c:\xmage_clean\mage\Mage.Common\
cmd /C mvn install -q -amd -DskipTests

cd c:\xmage_clean\

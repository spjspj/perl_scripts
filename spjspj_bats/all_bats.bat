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

cd c:\xmage_clean\mage\Mage
cmd /C mvn install -q -amd -DskipTests
cd c:\xmage_clean\mage\Mage.Common
cmd /C mvn install -q -amd -DskipTests
cd c:\xmage_clean\mage\Mage.Server
cmd /C mvn install -q -amd -DskipTests
cd c:\xmage_clean\mage\Mage.Client
cmd /C mvn install -q -amd -DskipTests
cd c:\xmage_clean\mage\Mage.Plugins
cmd /C mvn install -q -amd -DskipTests
cd c:\xmage_clean\mage\Mage.Server.Plugins
cmd /C mvn install -q -amd -DskipTests
cd c:\xmage_clean\mage\Mage.Server.Console
cmd /C mvn install -q -amd -DskipTests
cd c:\xmage_clean\mage\Mage.Test
cmd /C mvn install -q -amd -DskipTests

rem gvim C:\xmage_clean\mage\Mage.Client\src\main\java\mage\client\dialog\PreferencesDialog.java C:\xmage_clean\mage\Mage.Client\src\main\java\mage\client\game\GamePanel.java C:\xmage_clean\mage\Mage.Client\src\main\java\mage\client\game
\PlayAreaPanel.java C:\xmage_clean\mage\Mage.Client\src\main\java\mage\client\remote\CallbackClientImpl.java C:\xmage_clean\mage\Mage.Client\src\main\java\org\mage\plugins\card\dl\sources\ScryfallImageSupportCards.java C:\xmage_clean\mag
e\Mage.Common\src\main\java\mage\view\PlayerView.java C:\xmage_clean\mage\Mage.Server.Plugins\Mage.Player.Human\src\mage\player\human\HumanPlayer.java C:\xmage_clean\mage\Mage.Tests\src\test\java\org\mage\test\player\TestPlayer.java C:\x
mage_clean\mage\Mage.Tests\src\test\java\org\mage\test\stub\PlayerStub.java C:\xmage_clean\mage\Mage\src\main\java\mage\constants\PlayerAction.java C:\xmage_clean\mage\Mage\src\main\java\mage\players\Player.java C:\xmage_clean\mage\Mage\
src\main\java\mage\players\PlayerImpl.java
rem gvim C:\xmage_clean\mage\Mage.Server.Plugins\Mage.Player.Human\src\mage\player\human\HumanPlayer.java
cd c:\xmage_clean\
cd c:\xmage_clean\mage\
cmd /C mvn install -amd -DskipTests
cd c:\xmage_clean\mage\Mage\
cmd /C mvn install -amd -DskipTests
cd c:\xmage_clean\mage\Mage.Client\
cmd /C mvn install -amd -DskipTests
cd c:\xmage_clean\mage\Mage.Common\
cmd /C mvn install -amd -DskipTests
cd c:\xmage_clean\mage\Mage.Plugins\
cmd /C mvn install -amd -DskipTests
cd c:\xmage_clean\mage\Mage.Plugins\Mage.Counter.Plugin\
cmd /C mvn install -amd -DskipTests
cd c:\xmage_clean\mage\Mage.Server\
cmd /C mvn install -amd -DskipTests
rem cd c:\xmage_clean\mage\Mage.Server.Console\
rem cmd /C mvn install -amd -DskipTests
rem cd c:\xmage_clean\mage\Mage.Server.Plugins\
rem cmd /C mvn install -amd -DskipTests
rem cd c:\xmage_clean\mage\Mage.Server.Plugins\Mage.Deck.Constructed\
rem cmd /C mvn install -amd -DskipTests
rem cd c:\xmage_clean\mage\Mage.Server.Plugins\Mage.Deck.Limited\
rem cmd /C mvn install -amd -DskipTests
rem cd c:\xmage_clean\mage\Mage.Server.Plugins\Mage.Game.BrawlDuel\
rem cmd /C mvn install -amd -DskipTests
rem cd c:\xmage_clean\mage\Mage.Server.Plugins\Mage.Game.BrawlFreeForAll\
rem cmd /C mvn install -amd -DskipTests
rem cd c:\xmage_clean\mage\Mage.Server.Plugins\Mage.Game.CanadianHighlanderDuel\
rem cmd /C mvn install -amd -DskipTests
rem cd c:\xmage_clean\mage\Mage.Server.Plugins\Mage.Game.CommanderDuel\
rem cmd /C mvn install -amd -DskipTests
rem cd c:\xmage_clean\mage\Mage.Server.Plugins\Mage.Game.CommanderFreeForAll\
rem cmd /C mvn install -amd -DskipTests
rem cd c:\xmage_clean\mage\Mage.Server.Plugins\Mage.Game.FreeForAll\
rem cmd /C mvn install -amd -DskipTests
rem cd c:\xmage_clean\mage\Mage.Server.Plugins\Mage.Game.FreeformCommanderDuel\
rem cmd /C mvn install -amd -DskipTests
rem cd c:\xmage_clean\mage\Mage.Server.Plugins\Mage.Game.FreeformCommanderFreeForAll\
rem cmd /C mvn install -amd -DskipTests
rem cd c:\xmage_clean\mage\Mage.Server.Plugins\Mage.Game.FreeformUnlimitedCommander\
rem cmd /C mvn install -amd -DskipTests
rem cd c:\xmage_clean\mage\Mage.Server.Plugins\Mage.Game.MomirDuel\
rem cmd /C mvn install -amd -DskipTests
rem cd c:\xmage_clean\mage\Mage.Server.Plugins\Mage.Game.MomirGame\
rem cmd /C mvn install -amd -DskipTests
rem cd c:\xmage_clean\mage\Mage.Server.Plugins\Mage.Game.OathbreakerDuel\
rem cmd /C mvn install -amd -DskipTests
rem cd c:\xmage_clean\mage\Mage.Server.Plugins\Mage.Game.OathbreakerFreeForAll\
rem cmd /C mvn install -amd -DskipTests
rem cd c:\xmage_clean\mage\Mage.Server.Plugins\Mage.Game.PennyDreadfulCommanderFreeForAll\
rem cmd /C mvn install -amd -DskipTests
rem cd c:\xmage_clean\mage\Mage.Server.Plugins\Mage.Game.TinyLeadersDuel\
rem cmd /C mvn install -amd -DskipTests
rem cd c:\xmage_clean\mage\Mage.Server.Plugins\Mage.Game.TwoPlayerDuel\
rem cmd /C mvn install -amd -DskipTests
rem cd c:\xmage_clean\mage\Mage.Server.Plugins\Mage.Player.AI\
rem cmd /C mvn install -amd -DskipTests
rem cd c:\xmage_clean\mage\Mage.Server.Plugins\Mage.Player.AI.DraftBot\
rem cmd /C mvn install -amd -DskipTests
rem cd c:\xmage_clean\mage\Mage.Server.Plugins\Mage.Player.AI.MA\
rem cmd /C mvn install -amd -DskipTests
rem cd c:\xmage_clean\mage\Mage.Server.Plugins\Mage.Player.AIMCTS\
rem cmd /C mvn install -amd -DskipTests
rem cd c:\xmage_clean\mage\Mage.Server.Plugins\Mage.Player.AIMinimax\
rem cmd /C mvn install -amd -DskipTests
rem cd c:\xmage_clean\mage\Mage.Server.Plugins\Mage.Player.Human\
rem cmd /C mvn install -amd -DskipTests
rem cd c:\xmage_clean\mage\Mage.Server.Plugins\Mage.Tournament.BoosterDraft\
rem cmd /C mvn install -amd -DskipTests
rem cd c:\xmage_clean\mage\Mage.Server.Plugins\Mage.Tournament.Constructed\
rem cmd /C mvn install -amd -DskipTests
rem cd c:\xmage_clean\mage\Mage.Server.Plugins\Mage.Tournament.Sealed\
rem cmd /C mvn install -amd -DskipTests

cd c:\xmage_clean\


<#ftl output_format="plainText" encoding="UTF-8">
<#--noinspection WrongPackageStatement-->
<#compress>
<#-- @ftlvariable name="data" type="net.javaru.iip.frc.wizard.FrcProjectWizardData" -->
<#--
    Template Language Reference: https://freemarker.apache.org/docs/ref.html
    Template Author's Guide:     https://freemarker.apache.org/docs/dgui.html
-->
<#--  To DEBUG templates, set system property 'frc.freemarker.debug' to true when launching the testing instance of IntelliJ IDEA -->
</#compress>
${data.copyright}

package ${data.basePackage};

import org.wpilib.driverstation.DriverStationDisplay;
import org.wpilib.driverstation.DriverStationDisplay.Mode;
import org.wpilib.opmode.PeriodicOpMode;
import org.wpilib.opmode.Teleop;
import org.wpilib.system.Timer;

@Teleop(name = "Default Teleop")
public class DefaultTeleop extends PeriodicOpMode {
  private final Timer timer = new Timer();
  private int loopCount;

  /** Called once when the robot is enabled. */
  @Override
  public void start() {
    DriverStationDisplay.setMode(Mode.Line);
    timer.restart();
    loopCount = 0;
  }

  /** Called periodically while the robot is enabled. */
  @Override
  public void periodic() {
    DriverStationDisplay.addLine("DriverStationDisplay line mode");
    DriverStationDisplay.addData("Runtime", "%.1f seconds", timer.get());
    DriverStationDisplay.addData("Loop Count", "%d", loopCount++);
    DriverStationDisplay.updateLines();
  }
}

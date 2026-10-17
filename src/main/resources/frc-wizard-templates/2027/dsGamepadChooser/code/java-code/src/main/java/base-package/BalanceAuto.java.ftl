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

import java.util.List;
import org.wpilib.driverstation.DSGamepadChooser;
import org.wpilib.driverstation.DriverStationDisplay;
import org.wpilib.driverstation.DriverStationDisplay.Mode;
import org.wpilib.opmode.Autonomous;
import org.wpilib.opmode.PeriodicOpMode;

/** An autonomous opmode with chooser balance parameters. */
@Autonomous(name = "Balance Auto")
public class BalanceAuto extends PeriodicOpMode {
  private final DSGamepadChooser chooser = new DSGamepadChooser(0);
  private String approach = "Center";
  private int attempts = 1;
  private double turnScale = 0.5;

  /** Creates a Balance Auto opmode. */
  public BalanceAuto() {
    DriverStationDisplay.setMode(Mode.Line);
    chooser.addOptions("Approach", List.of("Left", "Center", "Right"));
    chooser.addIntegerOptions("Attempts", 1, 3, 1);
    chooser.addDoubleOptions("Turn Scale", 0.2, 1.0, 0.2);
  }

  /** Called periodically while this opmode is selected and the robot is disabled. */
  @Override
  public void disabledPeriodic() {
    chooser.update();
    DriverStationDisplay.updateLines();
  }

  /** Called once when the robot transitions from disabled to enabled. */
  @Override
  public void start() {
    approach = chooser.getSelected("Approach");
    attempts = chooser.getSelectedInteger("Attempts");
    turnScale = chooser.getSelectedDouble("Turn Scale");
  }

  /** Called periodically while this opmode is enabled. */
  @Override
  public void periodic() {
    DriverStationDisplay.addData("Selected Auto", "Balance");
    DriverStationDisplay.addData("Approach", approach);
    DriverStationDisplay.addData("Attempts", attempts);
    DriverStationDisplay.addData("Turn Scale", turnScale);
    DriverStationDisplay.updateLines();
  }
}

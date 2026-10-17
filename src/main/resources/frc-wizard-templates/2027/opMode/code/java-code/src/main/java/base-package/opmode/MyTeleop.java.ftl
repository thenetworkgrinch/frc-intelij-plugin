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

package ${data.basePackage}.opmode;

import org.wpilib.opmode.PeriodicOpMode;
import org.wpilib.opmode.Teleop;
import ${data.basePackage}.Robot;

@Teleop
public class MyTeleop extends PeriodicOpMode {
  private final Robot robot;

  /** The Robot instance is passed into the opmode via the constructor. */
  public MyTeleop(Robot robot) {
    this.robot = robot;
  }

  @Override
  public void disabledPeriodic() {
    /* Called on every robot period while the robot is disabled. */
  }

  @Override
  public void start() {
    /* Called once when the robot is enabled. */
  }

  @Override
  public void periodic() {
    /* Called on every robot period while the robot is enabled. */
  }

  @Override
  public void end() {
    /* Called when the robot is disabled (after previously being enabled). */
  }

  @Override
  public void close() {
    /* Called when the opmode is de-selected / no additional methods will be called. */
  }
}

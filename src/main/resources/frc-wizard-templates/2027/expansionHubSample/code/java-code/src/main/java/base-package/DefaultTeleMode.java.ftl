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

import org.wpilib.driverstation.DriverStation;
import org.wpilib.driverstation.Gamepad;
import org.wpilib.opmode.PeriodicOpMode;
import org.wpilib.opmode.Teleop;

@Teleop
public class DefaultTeleMode extends PeriodicOpMode {
  private final Robot robot;
  private final Gamepad gamepad;

  public DefaultTeleMode(Robot robot) {
    this.robot = robot;
    this.gamepad = DriverStation.getGamepad(0);
  }

  @Override
  public void periodic() {
    robot.motor0.setThrottle(-gamepad.getLeftY());
    robot.motor1.setThrottle(-gamepad.getRightY());
    robot.motor2.setThrottle(-gamepad.getLeftX());
    robot.motor3.setThrottle(-gamepad.getRightX());
    robot.servo0.setPosition(gamepad.getLeftTrigger());
    robot.servo1.setPosition(gamepad.getRightTrigger());
  }
}

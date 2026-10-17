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

import org.wpilib.framework.OpModeRobot;
import org.wpilib.hardware.expansionhub.ExpansionHubMotor;
import org.wpilib.hardware.expansionhub.ExpansionHubServo;

/**
 * This is a demo program showing the use of the Expansion Hub motors and servos. The motors and
 * servos are driven using the controllers in the telop opmode, and timed in the auto op mode.
 */
public class ${data.robotClassSimpleName} extends OpModeRobot {
  public final ExpansionHubMotor motor0 = new ExpansionHubMotor(0, 0);
  public final ExpansionHubMotor motor1 = new ExpansionHubMotor(0, 1);
  public final ExpansionHubMotor motor2 = new ExpansionHubMotor(0, 2);
  public final ExpansionHubMotor motor3 = new ExpansionHubMotor(0, 3);

  public final ExpansionHubServo servo0 = new ExpansionHubServo(0, 0);
  public final ExpansionHubServo servo1 = new ExpansionHubServo(0, 1);

  /** Called once at the beginning of the robot program. */
  public Robot() {}
}

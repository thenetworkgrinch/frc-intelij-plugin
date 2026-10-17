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

import org.wpilib.opmode.Autonomous;
import org.wpilib.opmode.PeriodicOpMode;
import org.wpilib.system.Timer;

@Autonomous
public class DefaultAutoMode extends PeriodicOpMode {
  private final Robot robot;
  private final Timer timer = new Timer();

  public DefaultAutoMode(Robot robot) {
    this.robot = robot;
  }

  @Override
  public void start() {
    timer.reset();
    timer.start();
  }

  @Override
  public void periodic() {
    if (timer.get() < 2.0) {
      robot.motor0.setThrottle(0.5);
      robot.motor1.setThrottle(0.5);
    } else if (timer.get() < 4.0) {
      robot.motor0.setThrottle(0.9);
      robot.motor1.setThrottle(0.9);
    } else {
      robot.motor0.setThrottle(0.0);
      robot.motor1.setThrottle(0.0);
    }
  }
}

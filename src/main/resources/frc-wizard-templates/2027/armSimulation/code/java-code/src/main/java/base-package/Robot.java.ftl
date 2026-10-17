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

import org.wpilib.driverstation.Joystick;
import ${data.basePackage}.subsystems.Arm;
import org.wpilib.framework.TimedRobot;

/** This is a sample program to demonstrate the use of arm simulation with existing code. */
public class ${data.robotClassSimpleName} extends TimedRobot {
  private final Arm arm = new Arm();
  private final Joystick joystick = new Joystick(Constants.JOYSTICK_PORT);

  public Robot() {}

  @Override
  public void simulationPeriodic() {
    arm.simulationPeriodic();
  }

  @Override
  public void teleopInit() {
    arm.loadPreferences();
  }

  @Override
  public void teleopPeriodic() {
    if (joystick.getTrigger()) {
      // Here, we run PID control like normal.
      arm.reachSetpoint();
    } else {
      // Otherwise, we disable the motor.
      arm.stop();
    }
  }

  @Override
  public void close() {
    arm.close();
    super.close();
  }

  @Override
  public void disabledInit() {
    // This just makes sure that our simulation code knows that the motor's off.
    arm.stop();
  }
}

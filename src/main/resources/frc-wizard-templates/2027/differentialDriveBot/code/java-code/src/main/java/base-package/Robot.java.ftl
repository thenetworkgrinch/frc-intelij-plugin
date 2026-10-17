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

import org.wpilib.driverstation.Gamepad;
import org.wpilib.framework.TimedRobot;
import org.wpilib.math.filter.SlewRateLimiter;

public class ${data.robotClassSimpleName} extends TimedRobot {
  private final Gamepad controller = new Gamepad(0);
  private final Drivetrain drive = new Drivetrain();

  // Slew rate limiters to make joystick inputs more gentle; 1/3 sec from 0 to 1.
  private final SlewRateLimiter velocityLimiter = new SlewRateLimiter(3);
  private final SlewRateLimiter rotLimiter = new SlewRateLimiter(3);

  @Override
  public void autonomousPeriodic() {
    teleopPeriodic();
    drive.updateOdometry();
  }

  @Override
  public void teleopPeriodic() {
    // Get the x velocity. We are inverting this because gamepads return
    // negative values when we push forward.
    final var xVelocity =
        -velocityLimiter.calculate(controller.getLeftY()) * Drivetrain.MAX_VELOCITY;

    // Get the rate of angular rotation. We are inverting this because we want a
    // positive value when we pull to the left (remember, CCW is positive in
    // mathematics). Gamepads return positive values when you pull to
    // the right by default.
    final var rot = -rotLimiter.calculate(controller.getRightX()) * Drivetrain.MAX_ANGULAR_VELOCITY;

    drive.drive(xVelocity, rot);
  }
}

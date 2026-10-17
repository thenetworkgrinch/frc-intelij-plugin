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

package ${data.basePackage}.mechanisms;

import static org.wpilib.units.Units.Degrees;
import static org.wpilib.units.Units.Radians;

import org.wpilib.command3.Command;
import org.wpilib.command3.Mechanism;
import org.wpilib.epilogue.Logged;
import ${data.basePackage}.constants.IntakeConstants;
import ${data.basePackage}.stubs.ExampleSmartMotorController;
import org.wpilib.units.measure.Angle;

@Logged
public class IntakeWrist implements Mechanism {
  private final ExampleSmartMotorController motor =
      new ExampleSmartMotorController(IntakeConstants.WRIST_MOTOR_ID);

  public Command stop() {
    return runRepeatedly(() -> motor.setThrottle(0.0)).named("Intake.Wrist.Stop");
  }

  @Override
  public Command idle() {
    return stop();
  }

  /**
   * Moves the wrist to a specific angle. The command will exit when the target angle is reached.
   *
   * @param target The target angle to move to
   * @return A command that moves the wrist to the target angle
   */
  public Command moveToAngle(Angle target) {
    double targetRads = target.in(Radians);
    double tolerance = Radians.convertFrom(0.5, Degrees);

    return run(coroutine -> {
          motor.setSetpoint(ExampleSmartMotorController.PIDMode.POSITION, targetRads);

          coroutine.waitUntil(() -> Math.abs(motor.getEncoderDistance() - targetRads) <= tolerance);
        })
        .named("Intake.Wrist.MoveToAngle[" + target.toLongString() + "]");
  }

  /**
   * Moves the wrist to a specific angle. The command will hold the wrist at the target angle until
   * interrupted.
   *
   * @param target The target angle to hold
   * @return A command that holds the wrist at the target angle
   */
  public Command holdAngle(Angle target) {
    double targetRads = target.in(Radians);

    return run(coroutine -> {
          motor.setSetpoint(ExampleSmartMotorController.PIDMode.POSITION, targetRads);
          coroutine.park();
        })
        .named("Intake.Wrist.HoldAngle[" + target.toLongString() + "]");
  }

  /**
   * Moves the wrist to the stowed position and holds it there until interrupted.
   *
   * @return A command that stows the wrist
   */
  public Command stow() {
    return holdAngle(IntakeConstants.WRIST_STOW_ANGLE);
  }

  /**
   * Moves the wrist to the down position and holds it there until interrupted.
   *
   * @return A command that moves the wrist to the down position
   */
  public Command down() {
    return holdAngle(IntakeConstants.WRIST_DOWN_ANGLE);
  }
}

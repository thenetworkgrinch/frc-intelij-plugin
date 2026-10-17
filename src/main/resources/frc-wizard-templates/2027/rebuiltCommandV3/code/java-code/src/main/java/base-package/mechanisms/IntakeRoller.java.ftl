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

import static org.wpilib.units.Units.RadiansPerSecond;

import org.wpilib.command3.Command;
import org.wpilib.command3.Mechanism;
import org.wpilib.epilogue.Logged;
import ${data.basePackage}.constants.IntakeConstants;
import ${data.basePackage}.stubs.ExampleSmartMotorController;

@Logged
public class IntakeRoller implements Mechanism {
  private final ExampleSmartMotorController motor =
      new ExampleSmartMotorController(IntakeConstants.ROLLER_MOTOR_ID);

  /**
   * Stops the roller motor. This command keeps the roller off until interrupted by another command.
   *
   * @return Command to stop the roller
   */
  public Command stop() {
    return runRepeatedly(() -> motor.setThrottle(0.0)).named("Intake.Roller.Stop");
  }

  @Override
  public Command idle() {
    return stop();
  }

  /**
   * Starts the roller motor in intake mode. This command keeps the roller running until interrupted
   * by another command.
   *
   * @return Command to start the roller in intake mode
   */
  public Command intake() {
    return run(coroutine -> {
          motor.setSetpoint(
              ExampleSmartMotorController.PIDMode.VELOCITY,
              IntakeConstants.ROLLER_INTAKE_SPEED.in(RadiansPerSecond));

          coroutine.park();
        })
        .named("Intake.Roller.Intake");
  }

  /**
   * Starts the roller motor in expel mode. This command keeps the roller running until interrupted
   * by another command.
   *
   * @return Command to start the roller in expel mode
   */
  public Command expel() {
    return run(coroutine -> {
          motor.setSetpoint(
              ExampleSmartMotorController.PIDMode.VELOCITY,
              IntakeConstants.ROLLER_EXPULSION_SPEED.in(RadiansPerSecond));

          coroutine.park();
        })
        .named("Intake.Roller.Expel");
  }
}

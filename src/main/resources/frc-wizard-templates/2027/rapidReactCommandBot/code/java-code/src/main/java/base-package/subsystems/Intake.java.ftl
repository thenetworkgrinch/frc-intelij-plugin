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

package ${data.basePackage}.subsystems;

import static ${data.basePackage}.Constants.IntakeConstants;

import org.wpilib.command2.Command;
import org.wpilib.command2.SubsystemBase;
import org.wpilib.drivers.motor.PWMSparkMax;
import org.wpilib.epilogue.Logged;
import ${data.basePackage}.Constants.IntakeConstants;
import org.wpilib.hardware.bus.CANPort;
import org.wpilib.hardware.pneumatic.DoubleSolenoid;
import org.wpilib.hardware.pneumatic.PneumaticsModuleType;

@Logged
public class Intake extends SubsystemBase {
  private final PWMSparkMax motor = new PWMSparkMax(IntakeConstants.MOTOR_PORT);

  // Double solenoid connected to two channels of a PCM with the default CAN ID
  private final DoubleSolenoid pistons =
      new DoubleSolenoid(
          CANPort.CAN_S0,
          PneumaticsModuleType.CTRE_PCM,
          IntakeConstants.SOLENOID_PORTS[0],
          IntakeConstants.SOLENOID_PORTS[1]);

  /** Returns a command that deploys the intake, and then runs the intake motor indefinitely. */
  public Command intakeCommand() {
    return runOnce(() -> pistons.set(DoubleSolenoid.Value.FORWARD))
        .andThen(run(() -> motor.setThrottle(1.0)))
        .withName("Intake");
  }

  /** Returns a command that turns off and retracts the intake. */
  public Command retractCommand() {
    return runOnce(
            () -> {
              motor.setThrottle(0.0);
              pistons.set(DoubleSolenoid.Value.REVERSE);
            })
        .withName("Retract");
  }
}

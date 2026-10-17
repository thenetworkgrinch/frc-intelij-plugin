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

import org.wpilib.command2.Command;
import org.wpilib.command2.SubsystemBase;
import org.wpilib.command2.button.Trigger;
import org.wpilib.drivers.motor.PWMSparkMax;
import org.wpilib.epilogue.Logged;
import org.wpilib.epilogue.NotLogged;
import ${data.basePackage}.Constants.StorageConstants;
import org.wpilib.hardware.discrete.DigitalInput;

@Logged
public class Storage extends SubsystemBase {
  private final PWMSparkMax motor = new PWMSparkMax(StorageConstants.MOTOR_PORT);
  @NotLogged // We'll log a more meaningful boolean instead
  private final DigitalInput ballSensor = new DigitalInput(StorageConstants.BALL_SENSOR_PORT);

  // Expose trigger from subsystem to improve readability and ease
  // inter-subsystem communications
  /** Whether the ball storage is full. */
  @Logged(name = "Has Cargo")
  public final Trigger hasCargo = new Trigger(ballSensor::get);

  /** Create a new Storage subsystem. */
  public Storage() {
    // Set default command to turn off the storage motor and then idle
    setDefaultCommand(runOnce(() -> motor.setThrottle(0)).andThen(run(() -> {})).withName("Idle"));
  }

  /** Returns a command that runs the storage motor indefinitely. */
  public Command runCommand() {
    return run(() -> motor.setThrottle(1)).withName("run");
  }
}

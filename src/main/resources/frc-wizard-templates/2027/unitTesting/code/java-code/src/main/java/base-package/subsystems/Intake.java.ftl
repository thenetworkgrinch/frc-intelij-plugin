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

import org.wpilib.drivers.motor.PWMSparkMax;
import ${data.basePackage}.Constants.IntakeConstants;
import org.wpilib.hardware.bus.CANPort;
import org.wpilib.hardware.pneumatic.DoubleSolenoid;
import org.wpilib.hardware.pneumatic.PneumaticsModuleType;

public class Intake implements AutoCloseable {
  private final PWMSparkMax motor;
  private final DoubleSolenoid piston;

  public Intake() {
    motor = new PWMSparkMax(IntakeConstants.MOTOR_PORT);
    piston =
        new DoubleSolenoid(
            CANPort.CAN_S0,
            PneumaticsModuleType.CTRE_PCM,
            IntakeConstants.PISTON_FWD_CHANNEL,
            IntakeConstants.PISTON_REV_CHANNEL);
  }

  public void deploy() {
    piston.set(DoubleSolenoid.Value.FORWARD);
  }

  public void retract() {
    piston.set(DoubleSolenoid.Value.REVERSE);
    motor.setThrottle(0); // turn off the motor
  }

  public void activate(double velocity) {
    if (isDeployed()) {
      motor.setThrottle(velocity);
    } else { // if piston isn't open, do nothing
      motor.setThrottle(0);
    }
  }

  public boolean isDeployed() {
    return piston.get() == DoubleSolenoid.Value.FORWARD;
  }

  @Override
  public void close() {
    piston.close();
    motor.close();
  }
}

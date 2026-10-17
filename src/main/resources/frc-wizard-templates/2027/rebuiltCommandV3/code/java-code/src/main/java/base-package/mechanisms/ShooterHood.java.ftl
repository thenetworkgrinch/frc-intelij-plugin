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

import static org.wpilib.units.Units.Radians;

import java.util.function.Supplier;
import org.wpilib.command3.Command;
import org.wpilib.command3.Mechanism;
import org.wpilib.epilogue.Logged;
import ${data.basePackage}.constants.ShooterConstants;
import ${data.basePackage}.stubs.ExampleSmartMotorController;
import org.wpilib.units.measure.Angle;

/** The hood for the shooter. The hood moves up and down to adjust the trajectory of the shots. */
@Logged
public class ShooterHood implements Mechanism {
  private final ExampleSmartMotorController hoodMotor;

  /**
   * Creates a new shooter hood. This should only be used by the {@link Shooter} mechanism, not the
   * central Robot class.
   */
  public ShooterHood() {
    hoodMotor = new ExampleSmartMotorController(ShooterConstants.HOOD_MOTOR_ID);

    hoodMotor.setPID(ShooterConstants.HOOD_KP, 0, 0);
  }

  @Override
  public Command idle() {
    return runRepeatedly(hoodMotor::stopMotor).named("ShooterHood.Idle");
  }

  /**
   * Moves the hood to the specified angle and holds it. This command will run forever unless
   * interrupted.
   *
   * @param angle A dynamic supplier for the desired hood angle.
   */
  public Command runHoodAngle(Supplier<Angle> angle) {
    return runRepeatedly(
            () -> {
              hoodMotor.setSetpoint(
                  ExampleSmartMotorController.PIDMode.POSITION, angle.get().in(Radians));
            })
        .named("Shooter.Hood.RunHoodAngle");
  }
}

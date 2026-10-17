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

import org.wpilib.epilogue.Logged;
import ${data.basePackage}.stubs.ExampleSmartMotorController;
import org.wpilib.math.geometry.Rotation2d;
import org.wpilib.math.kinematics.SwerveModulePosition;
import org.wpilib.math.kinematics.SwerveModuleVelocity;

@Logged
public final class SwerveModule {
  private final ExampleSmartMotorController driveMotor;
  private final ExampleSmartMotorController turnMotor;

  /**
   * Creates a new swerve module with the given drive and turn motors. This constructor is
   * package-private and should only be called by the SwerveDrive class.
   *
   * @param driveMotor The motor that drives the module.
   * @param turnMotor The motor that turns the module.
   */
  SwerveModule(ExampleSmartMotorController driveMotor, ExampleSmartMotorController turnMotor) {
    this.driveMotor = driveMotor;
    this.turnMotor = turnMotor;
  }

  /**
   * Sets the target velocity of this module.
   *
   * @param targetVelocity The target velocity of the module.
   */
  public void setTargetVelocity(SwerveModuleVelocity targetVelocity) {
    driveMotor.setSetpoint(ExampleSmartMotorController.PIDMode.VELOCITY, targetVelocity.velocity);
    turnMotor.setSetpoint(
        ExampleSmartMotorController.PIDMode.POSITION, targetVelocity.angle.getRadians());
  }

  /** Stops the module by turning off the drive and turn motors. */
  public void stop() {
    driveMotor.setThrottle(0.0);
    turnMotor.setThrottle(0.0);
  }

  /**
   * Gets the current position of the module.
   *
   * @return The current position of the module.
   */
  public SwerveModulePosition getPosition() {
    return new SwerveModulePosition(
        driveMotor.getEncoderDistance(), Rotation2d.fromRadians(turnMotor.getEncoderDistance()));
  }

  /**
   * Gets the current velocity of the module.
   *
   * @return The current velocity of the module.
   */
  public SwerveModuleVelocity getVelocity() {
    return new SwerveModuleVelocity(
        driveMotor.getEncoderRate(), Rotation2d.fromRadians(turnMotor.getEncoderDistance()));
  }
}

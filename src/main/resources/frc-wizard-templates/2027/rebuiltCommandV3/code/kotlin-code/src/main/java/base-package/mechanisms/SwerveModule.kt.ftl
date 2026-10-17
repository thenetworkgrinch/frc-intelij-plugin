<#ftl output_format="plainText" encoding="UTF-8">
<#--noinspection WrongPackageStatement-->
<#compress>
<#-- @ftlvariable name="data" type="net.javaru.iip.frc.wizard.FrcProjectWizardData" -->
<#--
    IMPORTANT: This template uses alternate square bracket interpolation syntax
               For example:
                    [=data.robotClassSimpleName]
               rather than:
                    ${data.robotClassSimpleName}
               so as to not clash with Kotlin string templates syntax
               The option to use that can't be set in the template, but has to be set as an
               option on the Configuration object in the code. Note that this only affects interpolation
               syntax, and *NOT* Tag syntax. So we will still use `<#if isSuchAndSuch>` and not `[#if isSuchAndSuch]`.
               Tag syntax can be changed if desired, but we are not.
    Template Language Reference: https://freemarker.apache.org/docs/ref.html
    Template Author's Guide:     https://freemarker.apache.org/docs/dgui.html
-->
<#--  To DEBUG templates, set system property 'frc.freemarker.debug' to true when launching the testing instance of IntelliJ IDEA -->
</#compress>
package [=data.basePackage].mechanisms

import org.wpilib.epilogue.Logged
import [=data.basePackage].stubs.ExampleSmartMotorController
import org.wpilib.math.geometry.Rotation2d
import org.wpilib.math.kinematics.SwerveModulePosition
import org.wpilib.math.kinematics.SwerveModuleVelocity

/**
 * A swerve module with the given drive and turn motors. The constructor is internal and should
 * only be called by the SwerveDrive class.
 *
 * @param driveMotor The motor that drives the module.
 * @param turnMotor The motor that turns the module.
 */
@Logged
class SwerveModule internal constructor(
    private val driveMotor: ExampleSmartMotorController,
    private val turnMotor: ExampleSmartMotorController)
{
    /**
     * Sets the target velocity of this module.
     *
     * @param targetVelocity The target velocity of the module.
     */
    fun setTargetVelocity(targetVelocity: SwerveModuleVelocity)
    {
        driveMotor.setSetpoint(ExampleSmartMotorController.PIDMode.VELOCITY, targetVelocity.velocity)
        turnMotor.setSetpoint(
            ExampleSmartMotorController.PIDMode.POSITION, targetVelocity.angle.radians)
    }

    /** Stops the module by turning off the drive and turn motors. */
    fun stop()
    {
        driveMotor.setThrottle(0.0)
        turnMotor.setThrottle(0.0)
    }

    /** The current position of the module. */
    val position: SwerveModulePosition
        get() = SwerveModulePosition(
            driveMotor.getEncoderDistance(), Rotation2d.fromRadians(turnMotor.getEncoderDistance()))

    /** The current velocity of the module. */
    val velocity: SwerveModuleVelocity
        get() = SwerveModuleVelocity(
            driveMotor.getEncoderRate(), Rotation2d.fromRadians(turnMotor.getEncoderDistance()))
}

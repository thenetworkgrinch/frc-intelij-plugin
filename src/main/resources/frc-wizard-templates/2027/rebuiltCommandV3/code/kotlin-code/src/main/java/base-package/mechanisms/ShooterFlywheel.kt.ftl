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
import org.wpilib.units.Units.RPM

import org.wpilib.command3.Command
import org.wpilib.command3.Mechanism
import [=data.basePackage].constants.ShooterConstants
import [=data.basePackage].stubs.ExampleSmartMotorController
import org.wpilib.units.measure.AngularVelocity

/**
 * The flywheel for the shooter. The flywheel spins up to shoot the ball.
 *
 * Creates a new shooter flywheel. This should only be used by the [Shooter] mechanism, not
 * the central Robot object.
 */
@Logged
class ShooterFlywheel : Mechanism
{
    private val flywheelMotorPrimary =
        ExampleSmartMotorController(ShooterConstants.PRIMARY_SHOOTER_MOTOR_ID)
    private val flywheelMotorSecondary =
        ExampleSmartMotorController(ShooterConstants.SECONDARY_SHOOTER_MOTOR_ID)
    private val flywheelMotorTertiary =
        ExampleSmartMotorController(ShooterConstants.TERTIARY_SHOOTER_MOTOR_ID)
    private val flywheelMotorQuatenary =
        ExampleSmartMotorController(ShooterConstants.QUATERNARY_SHOOTER_MOTOR_ID)

    init
    {
        flywheelMotorSecondary.follow(flywheelMotorPrimary)
        flywheelMotorTertiary.follow(flywheelMotorPrimary)
        flywheelMotorQuatenary.follow(flywheelMotorPrimary)

        flywheelMotorPrimary.setPID(ShooterConstants.FLYWHEEL_KP, 0.0, 0.0)
    }

    override fun idle(): Command
    {
        return runRepeatedly(flywheelMotorPrimary::stopMotor).named("ShooterFlywheel.Idle")
    }

    /**
     * Runs the flywheel at the specified speed and holds it. This command will run forever unless
     * interrupted.
     *
     * @param speed A dynamic supplier for the desired flywheel speed.
     */
    fun runFlywheelSpeed(speed: () -> AngularVelocity): Command
    {
        return runRepeatedly {
            flywheelMotorPrimary.setSetpoint(
                ExampleSmartMotorController.PIDMode.VELOCITY, speed().`in`(RPM))
        }
            .named("Shooter.Flywheel.RunFlywheelSpeed")
    }
}

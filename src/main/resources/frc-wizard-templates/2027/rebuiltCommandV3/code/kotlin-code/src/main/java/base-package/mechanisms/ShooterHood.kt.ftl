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
import org.wpilib.units.Units.Radians

import org.wpilib.command3.Command
import org.wpilib.command3.Mechanism
import [=data.basePackage].constants.ShooterConstants
import [=data.basePackage].stubs.ExampleSmartMotorController
import org.wpilib.units.measure.Angle

/**
 * The hood for the shooter. The hood moves up and down to adjust the trajectory of the shots.
 *
 * Creates a new shooter hood. This should only be used by the [Shooter] mechanism, not the
 * central Robot object.
 */
@Logged
class ShooterHood : Mechanism
{
    private val hoodMotor = ExampleSmartMotorController(ShooterConstants.HOOD_MOTOR_ID)

    init
    {
        hoodMotor.setPID(ShooterConstants.HOOD_KP, 0.0, 0.0)
    }

    override fun idle(): Command
    {
        return runRepeatedly(hoodMotor::stopMotor).named("ShooterHood.Idle")
    }

    /**
     * Moves the hood to the specified angle and holds it. This command will run forever unless
     * interrupted.
     *
     * @param angle A dynamic supplier for the desired hood angle.
     */
    fun runHoodAngle(angle: () -> Angle): Command
    {
        return runRepeatedly {
            hoodMotor.setSetpoint(
                ExampleSmartMotorController.PIDMode.POSITION, angle().`in`(Radians))
        }
            .named("Shooter.Hood.RunHoodAngle")
    }
}

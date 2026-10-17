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
import org.wpilib.units.Units.Degrees
import org.wpilib.units.Units.Radians

import kotlin.math.abs
import org.wpilib.command3.Command
import org.wpilib.command3.Mechanism
import [=data.basePackage].constants.IntakeConstants
import [=data.basePackage].stubs.ExampleSmartMotorController
import org.wpilib.units.measure.Angle

@Logged
class IntakeWrist : Mechanism
{
    private val motor = ExampleSmartMotorController(IntakeConstants.WRIST_MOTOR_ID)

    fun stop(): Command
    {
        return runRepeatedly { motor.setThrottle(0.0) }.named("Intake.Wrist.Stop")
    }

    override fun idle(): Command = stop()

    /**
     * Moves the wrist to a specific angle. The command will exit when the target angle is reached.
     *
     * @param target The target angle to move to
     * @return A command that moves the wrist to the target angle
     */
    fun moveToAngle(target: Angle): Command
    {
        val targetRads = target.`in`(Radians)
        val tolerance = Radians.convertFrom(0.5, Degrees)

        return run { coroutine ->
            motor.setSetpoint(ExampleSmartMotorController.PIDMode.POSITION, targetRads)

            coroutine.waitUntil { abs(motor.getEncoderDistance() - targetRads) <= tolerance }
        }
            .named("Intake.Wrist.MoveToAngle[${target.toLongString()}]")
    }

    /**
     * Moves the wrist to a specific angle. The command will hold the wrist at the target angle until
     * interrupted.
     *
     * @param target The target angle to hold
     * @return A command that holds the wrist at the target angle
     */
    fun holdAngle(target: Angle): Command
    {
        val targetRads = target.`in`(Radians)

        return run { coroutine ->
            motor.setSetpoint(ExampleSmartMotorController.PIDMode.POSITION, targetRads)
            coroutine.park()
        }
            .named("Intake.Wrist.HoldAngle[${target.toLongString()}]")
    }

    /**
     * Moves the wrist to the stowed position and holds it there until interrupted.
     *
     * @return A command that stows the wrist
     */
    fun stow(): Command = holdAngle(IntakeConstants.WRIST_STOW_ANGLE)

    /**
     * Moves the wrist to the down position and holds it there until interrupted.
     *
     * @return A command that moves the wrist to the down position
     */
    fun down(): Command = holdAngle(IntakeConstants.WRIST_DOWN_ANGLE)
}

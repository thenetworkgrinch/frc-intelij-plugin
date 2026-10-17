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
import org.wpilib.units.Units.RadiansPerSecond

import org.wpilib.command3.Command
import org.wpilib.command3.Mechanism
import [=data.basePackage].constants.IntakeConstants
import [=data.basePackage].stubs.ExampleSmartMotorController

@Logged
class IntakeRoller : Mechanism
{
    private val motor = ExampleSmartMotorController(IntakeConstants.ROLLER_MOTOR_ID)

    /**
     * Stops the roller motor. This command keeps the roller off until interrupted by another command.
     *
     * @return Command to stop the roller
     */
    fun stop(): Command
    {
        return runRepeatedly { motor.setThrottle(0.0) }.named("Intake.Roller.Stop")
    }

    override fun idle(): Command = stop()

    /**
     * Starts the roller motor in intake mode. This command keeps the roller running until interrupted
     * by another command.
     *
     * @return Command to start the roller in intake mode
     */
    fun intake(): Command
    {
        return run { coroutine ->
            motor.setSetpoint(
                ExampleSmartMotorController.PIDMode.VELOCITY,
                IntakeConstants.ROLLER_INTAKE_SPEED.`in`(RadiansPerSecond))

            coroutine.park()
        }
            .named("Intake.Roller.Intake")
    }

    /**
     * Starts the roller motor in expel mode. This command keeps the roller running until interrupted
     * by another command.
     *
     * @return Command to start the roller in expel mode
     */
    fun expel(): Command
    {
        return run { coroutine ->
            motor.setSetpoint(
                ExampleSmartMotorController.PIDMode.VELOCITY,
                IntakeConstants.ROLLER_EXPULSION_SPEED.`in`(RadiansPerSecond))

            coroutine.park()
        }
            .named("Intake.Roller.Expel")
    }
}

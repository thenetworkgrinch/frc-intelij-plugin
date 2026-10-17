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
package [=data.basePackage].subsystems

import org.wpilib.epilogue.Logged
import org.wpilib.epilogue.NotLogged
import org.wpilib.command2.Command
import org.wpilib.command2.SubsystemBase
import org.wpilib.command2.button.Trigger
import org.wpilib.drivers.motor.PWMSparkMax
import [=data.basePackage].Constants.StorageConstants
import org.wpilib.hardware.discrete.DigitalInput

@Logged
class Storage : SubsystemBase()
{
    private val motor = PWMSparkMax(StorageConstants.MOTOR_PORT)
    @NotLogged // We'll log a more meaningful boolean instead
    private val ballSensor = DigitalInput(StorageConstants.BALL_SENSOR_PORT)

    // Expose trigger from subsystem to improve readability and ease
    // inter-subsystem communications
    /** Whether the ball storage is full. */
    @field:Logged(name = "Has Cargo")
    @get:NotLogged
    val hasCargo = Trigger(ballSensor::get)

    /** Create a new Storage subsystem. */
    init
    {
        // Set default command to turn off the storage motor and then idle
        defaultCommand = runOnce { motor.throttle = 0.0 }.andThen(run {}).withName("Idle")
    }

    /** Returns a command that runs the storage motor indefinitely. */
    fun runCommand(): Command = run { motor.throttle = 1.0 }.withName("run")
}

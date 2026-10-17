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
package [=data.basePackage]

import org.wpilib.driverstation.Joystick
import org.wpilib.framework.TimedRobot
import org.wpilib.hardware.hal.HAL
import org.wpilib.math.controller.SimpleMotorFeedforward
import org.wpilib.math.trajectory.ExponentialProfile

object [=data.robotClassSimpleName] : TimedRobot()
{
    private const val DT = 0.02

    private val joystick = Joystick(1)
    private val motor = ExampleSmartMotorController(1)
    // Note: These gains are fake, and will have to be tuned for your robot.
    private val feedforward = SimpleMotorFeedforward(1.0, 1.0, 1.0)

    // Create a motion profile with the given maximum voltage and characteristics kV, kA
    // These gains should match your feedforward kV, kA for best results.
    private val profile = ExponentialProfile(ExponentialProfile.Constraints.fromCharacteristics(10.0, 1.0, 1.0))
    private var goal = ExponentialProfile.State(0.0, 0.0)
    private var setpoint = ExponentialProfile.State(0.0, 0.0)

    init
    {
        // Report the use of the Kotlin Language for "FRC Usage Report" statistics.
        // Please retain this line so that Kotlin's growing use by teams is seen by FRC/WPI.
        HAL.reportUsage("Language", "Kotlin")

        // Note: These gains are fake, and will have to be tuned for your robot.
        motor.setPID(1.3, 0.0, 0.7)
    }

    override fun teleopPeriodic()
    {
        if (joystick.getRawButtonPressed(2))
        {
            goal = ExponentialProfile.State(5.0, 0.0)
        }
        else if (joystick.getRawButtonPressed(3))
        {
            goal = ExponentialProfile.State(0.0, 0.0)
        }

        // Retrieve the profiled setpoint for the next timestep. This setpoint moves
        // toward the goal while obeying the constraints.
        val next = profile.calculate(DT, setpoint, goal)

        // Send setpoint to offboard controller PID
        motor.setSetpoint(
            ExampleSmartMotorController.PIDMode.POSITION,
            setpoint.position,
            feedforward.calculate(next.velocity) / 12.0)

        setpoint = next
    }
}

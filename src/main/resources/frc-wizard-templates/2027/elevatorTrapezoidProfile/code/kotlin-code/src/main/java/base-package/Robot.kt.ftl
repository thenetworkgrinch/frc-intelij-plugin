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
import org.wpilib.math.trajectory.TrapezoidProfile

object [=data.robotClassSimpleName] : TimedRobot()
{
    private const val DT = 0.02

    private val joystick = Joystick(1)
    private val motor = ExampleSmartMotorController(1)
    // Note: These gains are fake, and will have to be tuned for your robot.
    private val feedforward = SimpleMotorFeedforward(1.0, 1.5)

    // Create a motion profile with the given maximum velocity and maximum
    // acceleration constraints for the next setpoint.
    private val profile = TrapezoidProfile(TrapezoidProfile.Constraints(1.75, 0.75))
    private var goal = TrapezoidProfile.State()
    private var setpoint = TrapezoidProfile.State()

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
            goal = TrapezoidProfile.State(5.0, 0.0)
        }
        else if (joystick.getRawButtonPressed(3))
        {
            goal = TrapezoidProfile.State()
        }

        // Retrieve the profiled setpoint for the next timestep. This setpoint moves
        // toward the goal while obeying the constraints.
        setpoint = profile.calculate(DT, setpoint, goal)

        // Send setpoint to offboard controller PID
        motor.setSetpoint(
            ExampleSmartMotorController.PIDMode.POSITION,
            setpoint.position,
            feedforward.calculate(setpoint.velocity) / 12.0)
    }
}

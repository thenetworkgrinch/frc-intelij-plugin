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

import org.wpilib.drivers.motor.PWMSparkMax
import org.wpilib.driverstation.Joystick
import org.wpilib.framework.TimedRobot
import org.wpilib.hardware.hal.HAL
import org.wpilib.hardware.rotation.Encoder
import org.wpilib.math.controller.ElevatorFeedforward
import org.wpilib.math.controller.ProfiledPIDController
import org.wpilib.math.trajectory.TrapezoidProfile
import kotlin.math.PI

object [=data.robotClassSimpleName] : TimedRobot()
{
    private const val DT = 0.02
    private const val MAX_VELOCITY = 1.75
    private const val MAX_ACCELERATION = 0.75
    private const val kP = 1.3
    private const val kI = 0.0
    private const val kD = 0.7
    private const val kS = 1.1
    private const val kG = 1.2
    private const val kV = 1.3

    private val joystick = Joystick(1)
    private val encoder = Encoder(2, 3)
    private val motor = PWMSparkMax(1)

    // Create a PID controller whose setpoint change is subject to maximum
    // velocity and acceleration constraints.
    private val constraints = TrapezoidProfile.Constraints(MAX_VELOCITY, MAX_ACCELERATION)
    private val controller = ProfiledPIDController(kP, kI, kD, constraints, DT)
    private val feedforward = ElevatorFeedforward(kS, kG, kV)

    init
    {
        // Report the use of the Kotlin Language for "FRC Usage Report" statistics.
        // Please retain this line so that Kotlin's growing use by teams is seen by FRC/WPI.
        HAL.reportUsage("Language", "Kotlin")

        encoder.distancePerPulse = 1.0 / 360.0 * 2.0 * PI * 1.5
    }

    override fun teleopPeriodic()
    {
        if (joystick.getRawButtonPressed(2))
        {
            controller.setGoal(5.0)
        }
        else if (joystick.getRawButtonPressed(3))
        {
            controller.setGoal(0.0)
        }

        // Run controller and update motor output
        motor.setVoltage(
            controller.calculate(encoder.distance)
                + feedforward.calculate(controller.setpoint.velocity))
    }
}

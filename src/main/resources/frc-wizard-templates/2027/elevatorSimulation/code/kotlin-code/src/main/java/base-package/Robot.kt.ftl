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

import [=data.basePackage].subsystems.Elevator
import org.wpilib.driverstation.Joystick
import org.wpilib.framework.TimedRobot
import org.wpilib.hardware.hal.HAL

/**
 * This is a sample program to demonstrate the use of elevator simulation.
 *
 * The robot is written as an object rather than a class since there should only ever be a single instance.
 */
object [=data.robotClassSimpleName] : TimedRobot()
{
    private val joystick = Joystick(Constants.JOYSTICK_PORT)
    private val elevator = Elevator()

    init
    {
        // Report the use of the Kotlin Language for "FRC Usage Report" statistics.
        // Please retain this line so that Kotlin's growing use by teams is seen by FRC/WPI.
        HAL.reportUsage("Language", "Kotlin")
    }

    override fun robotPeriodic()
    {
        // Update the telemetry, including mechanism visualization, regardless of mode.
        elevator.updateTelemetry()
    }

    override fun simulationPeriodic()
    {
        // Update the simulation model.
        elevator.simulationPeriodic()
    }

    override fun teleopPeriodic()
    {
        if (joystick.trigger)
        {
            // Here, we set the constant setpoint of 0.75 meters.
            elevator.reachGoal(Constants.SETPOINT)
        }
        else
        {
            // Otherwise, we update the setpoint to 0.
            elevator.reachGoal(0.0)
        }
    }

    override fun disabledInit()
    {
        // This just makes sure that our simulation code knows that the motor's off.
        elevator.stop()
    }

    override fun close()
    {
        elevator.close()
        super.close()
    }
}

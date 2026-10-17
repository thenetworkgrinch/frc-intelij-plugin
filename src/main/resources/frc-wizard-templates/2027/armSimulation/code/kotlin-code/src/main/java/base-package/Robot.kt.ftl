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

import [=data.basePackage].subsystems.Arm
import org.wpilib.driverstation.Joystick
import org.wpilib.framework.TimedRobot
import org.wpilib.hardware.hal.HAL

/**
 * This is a sample program to demonstrate the use of arm simulation with existing code.
 *
 * The robot is written as an object rather than a class since there should only ever be a single instance.
 */
object [=data.robotClassSimpleName] : TimedRobot()
{
    private val arm = Arm()
    private val joystick = Joystick(Constants.JOYSTICK_PORT)

    init
    {
        // Report the use of the Kotlin Language for "FRC Usage Report" statistics.
        // Please retain this line so that Kotlin's growing use by teams is seen by FRC/WPI.
        HAL.reportUsage("Language", "Kotlin")
    }

    override fun simulationPeriodic()
    {
        arm.simulationPeriodic()
    }

    override fun teleopInit()
    {
        arm.loadPreferences()
    }

    override fun teleopPeriodic()
    {
        if (joystick.trigger)
        {
            // Here, we run PID control like normal.
            arm.reachSetpoint()
        }
        else
        {
            // Otherwise, we disable the motor.
            arm.stop()
        }
    }

    override fun close()
    {
        arm.close()
        super.close()
    }

    override fun disabledInit()
    {
        // This just makes sure that our simulation code knows that the motor's off.
        arm.stop()
    }
}

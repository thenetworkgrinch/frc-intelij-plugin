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

import org.wpilib.driverstation.Gamepad
import org.wpilib.framework.TimedRobot
import org.wpilib.hardware.hal.HAL
import org.wpilib.math.filter.SlewRateLimiter

object [=data.robotClassSimpleName] : TimedRobot()
{
    private val controller = Gamepad(0)
    private val drive = Drivetrain()

    // Slew rate limiters to make joystick inputs more gentle; 1/3 sec from 0 to 1.
    private val velocityLimiter = SlewRateLimiter(3.0)
    private val rotLimiter = SlewRateLimiter(3.0)

    init
    {
        // Report the use of the Kotlin Language for "FRC Usage Report" statistics.
        // Please retain this line so that Kotlin's growing use by teams is seen by FRC/WPI.
        HAL.reportUsage("Language", "Kotlin")
    }

    override fun autonomousPeriodic()
    {
        teleopPeriodic()
        drive.updateOdometry()
    }

    override fun teleopPeriodic()
    {
        // Get the x velocity. We are inverting this because gamepads return
        // negative values when we push forward.
        val xVelocity = -velocityLimiter.calculate(controller.leftY) * Drivetrain.MAX_VELOCITY

        // Get the rate of angular rotation. We are inverting this because we want a
        // positive value when we pull to the left (remember, CCW is positive in
        // mathematics). Gamepads return positive values when you pull to
        // the right by default.
        val rot = -rotLimiter.calculate(controller.rightX) * Drivetrain.MAX_ANGULAR_VELOCITY

        drive.drive(xVelocity, rot)
    }
}

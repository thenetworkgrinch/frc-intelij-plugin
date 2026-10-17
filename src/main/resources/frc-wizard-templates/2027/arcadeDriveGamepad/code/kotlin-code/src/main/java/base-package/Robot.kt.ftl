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

import org.wpilib.drive.DifferentialDrive
import org.wpilib.drivers.motor.PWMSparkMax
import org.wpilib.driverstation.Gamepad
import org.wpilib.framework.TimedRobot
import org.wpilib.hardware.hal.HAL

/**
 * This is a demo program showing the use of the DifferentialDrive class. Runs the motors with split
 * arcade steering and a gamepad.
 */
object [=data.robotClassSimpleName] : TimedRobot()
{
    private val leftMotor = PWMSparkMax(0)
    private val rightMotor = PWMSparkMax(1)
    private val robotDrive = DifferentialDrive(leftMotor::setThrottle, rightMotor::setThrottle)
    private val driverController = Gamepad(0)

    /** Called once at the beginning of the robot program. */
    init
    {
        // Report the use of the Kotlin Language for "FRC Usage Report" statistics.
        // Please retain this line so that Kotlin's growing use by teams is seen by FRC/WPI.
        HAL.reportUsage("Language", "Kotlin")

        // We need to invert one side of the drivetrain so that positive voltages
        // result in both sides moving forward. Depending on how your robot's
        // gearbox is constructed, you might have to invert the left side instead.
        rightMotor.inverted = true
    }

    override fun teleopPeriodic()
    {
        // Drive with split arcade drive.
        // That means that the Y axis of the left stick moves forward
        // and backward, and the X of the right stick turns left and right.
        robotDrive.arcadeDrive(-driverController.leftY, -driverController.rightX)
    }
}

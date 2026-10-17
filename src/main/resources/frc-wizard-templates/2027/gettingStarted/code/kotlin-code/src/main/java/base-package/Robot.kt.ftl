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
import org.wpilib.system.Timer

/**
 * The functions in this object (which basically functions as a singleton class) are called automatically
 * corresponding to each mode, as described in the TimedRobot documentation. If you change the name of this
 * object or its package after creating this project, you must also update the `Main.kt` file in the project.
 */
object [=data.robotClassSimpleName] : TimedRobot()
{
    private val leftDrive = PWMSparkMax(0)
    private val rightDrive = PWMSparkMax(1)
    private val robotDrive = DifferentialDrive(leftDrive::setThrottle, rightDrive::setThrottle)
    private val controller = Gamepad(0)
    private val timer = Timer()

    /** Called once at the beginning of the robot program. */
    init
    {
        // Report the use of the Kotlin Language for "FRC Usage Report" statistics.
        // Please retain this line so that Kotlin's growing use by teams is seen by FRC/WPI.
        HAL.reportUsage("Language", "Kotlin")

        // We need to invert one side of the drivetrain so that positive voltages
        // result in both sides moving forward. Depending on how your robot's
        // gearbox is constructed, you might have to invert the left side instead.
        rightDrive.setInverted(true)
    }

    /** This function is run once each time the robot enters autonomous mode. */
    override fun autonomousInit()
    {
        timer.restart()
    }

    /** This function is called periodically during autonomous. */
    override fun autonomousPeriodic()
    {
        // Drive for 2 seconds
        if (timer.get() < 2.0)
        {
            // Drive forwards half velocity, make sure to turn input squaring off
            robotDrive.arcadeDrive(0.5, 0.0, false)
        }
        else
        {
            robotDrive.arcadeDrive(0.0, 0.0, false) // stop robot
        }
    }

    /** This function is called once each time the robot enters teleoperated mode. */
    override fun teleopInit() {}

    /** This function is called periodically during teleoperated mode. */
    override fun teleopPeriodic()
    {
        robotDrive.arcadeDrive(-controller.leftY, -controller.rightX)
    }

    /** This function is called once each time the robot enters utility mode. */
    override fun utilityInit() {}

    /** This function is called periodically during utility mode. */
    override fun utilityPeriodic() {}
}

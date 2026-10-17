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
import org.wpilib.driverstation.Joystick
import org.wpilib.framework.TimedRobot
import org.wpilib.hardware.hal.HAL
import org.wpilib.hardware.imu.OnboardIMU

/**
 * This is a sample program to demonstrate how to use a gyro sensor to make a robot drive straight.
 * This program uses a joystick to drive forwards and backwards while the gyro is used for direction
 * keeping.
 */
object [=data.robotClassSimpleName] : TimedRobot()
{
    private const val ANGLE_SETPOINT = 0.0
    private const val kP = 0.005 // proportional turning constant

    private const val LEFT_MOTOR_PORT = 0
    private const val RIGHT_MOTOR_PORT = 1
    private val IMU_MOUNT_ORIENTATION = OnboardIMU.MountOrientation.FLAT
    private const val JOYSTICK_PORT = 0

    private val leftDrive = PWMSparkMax(LEFT_MOTOR_PORT)
    private val rightDrive = PWMSparkMax(RIGHT_MOTOR_PORT)
    private val robotDrive = DifferentialDrive(leftDrive::setThrottle, rightDrive::setThrottle)
    private val imu = OnboardIMU(IMU_MOUNT_ORIENTATION)
    private val joystick = Joystick(JOYSTICK_PORT)

    /** Called once at the beginning of the robot program. */
    init
    {
        // Report the use of the Kotlin Language for "FRC Usage Report" statistics.
        // Please retain this line so that Kotlin's growing use by teams is seen by FRC/WPI.
        HAL.reportUsage("Language", "Kotlin")

        // We need to invert one side of the drivetrain so that positive voltages
        // result in both sides moving forward. Depending on how your robot's
        // gearbox is constructed, you might have to invert the left side instead.
        rightDrive.inverted = true
    }

    /**
     * The motor velocity is set from the joystick while the DifferentialDrive turning value is
     * assigned from the error between the setpoint and the gyro angle.
     */
    override fun teleopPeriodic()
    {
        val turningValue = (ANGLE_SETPOINT - imu.rotation2d.degrees) * kP
        robotDrive.arcadeDrive(-joystick.y, -turningValue)
    }
}

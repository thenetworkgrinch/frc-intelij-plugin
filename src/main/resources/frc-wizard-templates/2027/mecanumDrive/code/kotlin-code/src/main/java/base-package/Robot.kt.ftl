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

import org.wpilib.drive.MecanumDrive
import org.wpilib.drivers.motor.PWMSparkMax
import org.wpilib.driverstation.Joystick
import org.wpilib.framework.TimedRobot
import org.wpilib.hardware.hal.HAL
import org.wpilib.hardware.imu.OnboardIMU

/**
 * This is a sample program that uses mecanum drive with a gyro sensor to maintain rotation vectors
 * in relation to the starting orientation of the robot (field-oriented controls).
 */
object [=data.robotClassSimpleName] : TimedRobot()
{
    private const val FRONT_LEFT_CHANNEL = 0
    private const val REAR_LEFT_CHANNEL = 1
    private const val FRONT_RIGHT_CHANNEL = 2
    private const val REAR_RIGHT_CHANNEL = 3
    private val IMU_MOUNT_ORIENTATION = OnboardIMU.MountOrientation.FLAT
    private const val JOYSTICK_PORT = 0

    private val robotDrive: MecanumDrive
    private val imu = OnboardIMU(IMU_MOUNT_ORIENTATION)
    private val joystick = Joystick(JOYSTICK_PORT)

    /** Called once at the beginning of the robot program. */
    init
    {
        // Report the use of the Kotlin Language for "FRC Usage Report" statistics.
        // Please retain this line so that Kotlin's growing use by teams is seen by FRC/WPI.
        HAL.reportUsage("Language", "Kotlin")

        val frontLeft = PWMSparkMax(FRONT_LEFT_CHANNEL)
        val rearLeft = PWMSparkMax(REAR_LEFT_CHANNEL)
        val frontRight = PWMSparkMax(FRONT_RIGHT_CHANNEL)
        val rearRight = PWMSparkMax(REAR_RIGHT_CHANNEL)

        // Invert the right side motors.
        // You may need to change or remove this to match your robot.
        frontRight.inverted = true
        rearRight.inverted = true

        robotDrive = MecanumDrive(
            frontLeft::setThrottle,
            rearLeft::setThrottle,
            frontRight::setThrottle,
            rearRight::setThrottle)
    }

    /** Mecanum drive is used with the gyro angle as an input. */
    override fun teleopPeriodic()
    {
        // Use the joystick Y axis for forward movement, X axis for lateral
        // movement, and Z axis for rotation.
        robotDrive.driveCartesian(-joystick.y, -joystick.x, -joystick.z, imu.rotation2d)
    }
}

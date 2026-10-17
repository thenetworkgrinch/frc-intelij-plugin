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
package [=data.basePackage].subsystems

import org.wpilib.command2.SubsystemBase
import org.wpilib.drive.DifferentialDrive
import org.wpilib.hardware.rotation.Encoder
import org.wpilib.xrp.XRPGyro
import org.wpilib.xrp.XRPMotor
import kotlin.math.PI

/** Creates a new Drivetrain. */
class Drivetrain : SubsystemBase()
{
    companion object
    {
        private const val GEAR_RATIO =
            (30.0 / 14.0) * (28.0 / 16.0) * (36.0 / 9.0) * (26.0 / 8.0) // 48.75:1
        private const val COUNTS_PER_MOTOR_SHAFT_REV = 12.0
        private const val COUNTS_PER_REVOLUTION =
            COUNTS_PER_MOTOR_SHAFT_REV * GEAR_RATIO // 585.0
        private const val WHEEL_DIAMETER_INCH = 2.3622 // 60 mm
    }

    // The XRP has the left and right motors set to
    // channels 0 and 1 respectively
    private val leftMotor = XRPMotor(0)
    private val rightMotor = XRPMotor(1)

    // The XRP has onboard encoders that are hardcoded
    // to use DIO pins 4/5 and 6/7 for the left and right
    private val leftEncoder = Encoder(4, 5)
    private val rightEncoder = Encoder(6, 7)

    // Set up the differential drive controller
    private val diffDrive = DifferentialDrive(leftMotor::setThrottle, rightMotor::setThrottle)

    // Set up the XRPGyro
    private val gyro = XRPGyro()

    init
    {
        // We need to invert one side of the drivetrain so that positive voltages
        // result in both sides moving forward. Depending on how your robot's
        // gearbox is constructed, you might have to invert the left side instead.
        rightMotor.inverted = true

        // Use inches as unit for encoder distances
        leftEncoder.distancePerPulse = (PI * WHEEL_DIAMETER_INCH) / COUNTS_PER_REVOLUTION
        rightEncoder.distancePerPulse = (PI * WHEEL_DIAMETER_INCH) / COUNTS_PER_REVOLUTION
        resetEncoders()
    }

    fun arcadeDrive(xaxisVelocity: Double, zaxisRotate: Double)
    {
        diffDrive.arcadeDrive(xaxisVelocity, zaxisRotate)
    }

    fun resetEncoders()
    {
        leftEncoder.reset()
        rightEncoder.reset()
    }

    val leftEncoderCount: Int
        get() = leftEncoder.get()

    val rightEncoderCount: Int
        get() = rightEncoder.get()

    val leftDistanceInch: Double
        get() = leftEncoder.distance

    val rightDistanceInch: Double
        get() = rightEncoder.distance

    val averageDistanceInch: Double
        get() = (leftDistanceInch + rightDistanceInch) / 2.0

    /**
     * Current angle of the XRP around the X-axis.
     *
     * @return The current angle of the XRP in degrees
     */
    val gyroAngleX: Double
        get() = gyro.angleX

    /**
     * Current angle of the XRP around the Y-axis.
     *
     * @return The current angle of the XRP in degrees
     */
    val gyroAngleY: Double
        get() = gyro.angleY

    /**
     * Current angle of the XRP around the Z-axis.
     *
     * @return The current angle of the XRP in degrees
     */
    val gyroAngleZ: Double
        get() = gyro.angleZ

    /** Reset the gyro. */
    fun resetGyro()
    {
        gyro.reset()
    }

    override fun periodic()
    {
        // This method will be called once per scheduler run
    }
}

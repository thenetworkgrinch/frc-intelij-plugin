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
import org.wpilib.drivers.motor.Spark
import org.wpilib.hardware.rotation.Encoder
import org.wpilib.romi.RomiGyro
import org.wpilib.telemetry.TelemetryTable
import kotlin.math.PI

/** Creates a new Drivetrain. */
class Drivetrain : SubsystemBase()
{
    companion object
    {
        private const val COUNTS_PER_REVOLUTION = 1440.0
        private const val WHEEL_DIAMETER_INCH = 2.75591 // 70 mm
    }

    // The Romi has the left and right motors set to
    // PWM channels 0 and 1 respectively
    private val leftMotor = Spark(0)
    private val rightMotor = Spark(1)

    // The Romi has onboard encoders that are hardcoded
    // to use DIO pins 4/5 and 6/7 for the left and right
    private val leftEncoder = Encoder(4, 5)
    private val rightEncoder = Encoder(6, 7)

    // Set up the differential drive controller
    private val diffDrive = DifferentialDrive(leftMotor::setThrottle, rightMotor::setThrottle)

    // Set up the RomiGyro
    private val gyro = RomiGyro()

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
     * Current angle of the Romi around the X-axis.
     *
     * @return The current angle of the Romi in degrees
     */
    val gyroAngleX: Double
        get() = gyro.angleX

    /**
     * Current angle of the Romi around the Y-axis.
     *
     * @return The current angle of the Romi in degrees
     */
    val gyroAngleY: Double
        get() = gyro.angleY

    /**
     * Current angle of the Romi around the Z-axis.
     *
     * @return The current angle of the Romi in degrees
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

    override fun logTo(table: TelemetryTable)
    {
        super.logTo(table)
        table.log("drive", diffDrive)
        table.log("gyro", gyro)
        table.log("left distance", leftDistanceInch)
        table.log("right distance", rightDistanceInch)
    }
}

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
import org.wpilib.hardware.imu.OnboardIMU
import org.wpilib.hardware.rotation.Encoder
import org.wpilib.math.controller.PIDController
import org.wpilib.math.controller.SimpleMotorFeedforward
import org.wpilib.math.kinematics.ChassisVelocities
import org.wpilib.math.kinematics.DifferentialDriveKinematics
import org.wpilib.math.kinematics.DifferentialDriveOdometry
import org.wpilib.math.kinematics.DifferentialDriveWheelVelocities
import kotlin.math.PI

/** Represents a differential drive style drivetrain. */
class Drivetrain
{
    companion object
    {
        const val MAX_VELOCITY = 3.0 // meters per second
        const val MAX_ANGULAR_VELOCITY = 2 * PI // one rotation per second

        private const val TRACKWIDTH = 0.381 * 2 // meters
        private const val WHEEL_RADIUS = 0.0508 // meters
        private const val ENCODER_RESOLUTION = 4096
    }

    private val leftLeader = PWMSparkMax(1)
    private val leftFollower = PWMSparkMax(2)
    private val rightLeader = PWMSparkMax(3)
    private val rightFollower = PWMSparkMax(4)

    private val leftEncoder = Encoder(0, 1)
    private val rightEncoder = Encoder(2, 3)

    private val imu = OnboardIMU(OnboardIMU.MountOrientation.FLAT)

    private val leftPIDController = PIDController(1.0, 0.0, 0.0)
    private val rightPIDController = PIDController(1.0, 0.0, 0.0)

    private val kinematics = DifferentialDriveKinematics(TRACKWIDTH)

    private val odometry: DifferentialDriveOdometry

    // Gains are for example purposes only - must be determined for your own robot!
    private val feedforward = SimpleMotorFeedforward(1.0, 3.0)

    /**
     * Constructs a differential drive object. Sets the encoder distance per pulse and resets the
     * gyro.
     */
    init
    {
        imu.resetYaw()

        leftLeader.addFollower(leftFollower)
        rightLeader.addFollower(rightFollower)

        // We need to invert one side of the drivetrain so that positive voltages
        // result in both sides moving forward. Depending on how your robot's
        // gearbox is constructed, you might have to invert the left side instead.
        rightLeader.inverted = true

        // Set the distance per pulse for the drive encoders. We can simply use the
        // distance traveled for one rotation of the wheel divided by the encoder
        // resolution.
        leftEncoder.distancePerPulse = 2 * PI * WHEEL_RADIUS / ENCODER_RESOLUTION
        rightEncoder.distancePerPulse = 2 * PI * WHEEL_RADIUS / ENCODER_RESOLUTION

        leftEncoder.reset()
        rightEncoder.reset()

        odometry = DifferentialDriveOdometry(imu.rotation2d, leftEncoder.distance, rightEncoder.distance)
    }

    /**
     * Sets the desired wheel velocities.
     *
     * @param velocities The desired wheel velocities.
     */
    fun setVelocities(velocities: DifferentialDriveWheelVelocities)
    {
        val leftFeedforward = feedforward.calculate(velocities.left)
        val rightFeedforward = feedforward.calculate(velocities.right)

        val leftOutput = leftPIDController.calculate(leftEncoder.rate, velocities.left)
        val rightOutput = rightPIDController.calculate(rightEncoder.rate, velocities.right)
        leftLeader.setVoltage(leftOutput + leftFeedforward)
        rightLeader.setVoltage(rightOutput + rightFeedforward)
    }

    /**
     * Drives the robot with the given linear velocity and angular velocity.
     *
     * @param xVelocity Linear velocity in m/s.
     * @param rot Angular velocity in rad/s.
     */
    fun drive(xVelocity: Double, rot: Double)
    {
        val wheelVelocities = kinematics.toWheelVelocities(ChassisVelocities(xVelocity, 0.0, rot))
        setVelocities(wheelVelocities)
    }

    /** Updates the field-relative position. */
    fun updateOdometry()
    {
        odometry.update(imu.rotation2d, leftEncoder.distance, rightEncoder.distance)
    }
}

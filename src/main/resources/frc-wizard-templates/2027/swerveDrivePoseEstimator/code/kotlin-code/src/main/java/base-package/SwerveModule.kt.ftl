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
import org.wpilib.hardware.rotation.Encoder
import org.wpilib.math.controller.PIDController
import org.wpilib.math.controller.ProfiledPIDController
import org.wpilib.math.controller.SimpleMotorFeedforward
import org.wpilib.math.geometry.Rotation2d
import org.wpilib.math.kinematics.SwerveModulePosition
import org.wpilib.math.kinematics.SwerveModuleVelocity
import org.wpilib.math.trajectory.TrapezoidProfile

/**
 * Constructs a SwerveModule with a drive motor, turning motor, drive encoder and turning encoder.
 *
 * @param driveMotorChannel PWM output for the drive motor.
 * @param turningMotorChannel PWM output for the turning motor.
 * @param driveEncoderChannelA DIO input for the drive encoder channel A
 * @param driveEncoderChannelB DIO input for the drive encoder channel B
 * @param turningEncoderChannelA DIO input for the turning encoder channel A
 * @param turningEncoderChannelB DIO input for the turning encoder channel B
 */
class SwerveModule(
    driveMotorChannel: Int,
    turningMotorChannel: Int,
    driveEncoderChannelA: Int,
    driveEncoderChannelB: Int,
    turningEncoderChannelA: Int,
    turningEncoderChannelB: Int
)
{
    companion object
    {
        private const val WHEEL_RADIUS = 0.0508
        private const val ENCODER_RESOLUTION = 4096

        private const val MODULE_MAX_ANGULAR_VELOCITY = Drivetrain.MAX_ANGULAR_VELOCITY
        private const val MODULE_MAX_ANGULAR_ACCELERATION = 2 * Math.PI // radians per second squared
    }

    private val driveMotor = PWMSparkMax(driveMotorChannel)
    private val turningMotor = PWMSparkMax(turningMotorChannel)

    private val driveEncoder = Encoder(driveEncoderChannelA, driveEncoderChannelB)
    private val turningEncoder = Encoder(turningEncoderChannelA, turningEncoderChannelB)

    // Gains are for example purposes only - must be determined for your own robot!
    private val drivePIDController = PIDController(1.0, 0.0, 0.0)

    // Gains are for example purposes only - must be determined for your own robot!
    private val turningPIDController = ProfiledPIDController(
        1.0,
        0.0,
        0.0,
        TrapezoidProfile.Constraints(MODULE_MAX_ANGULAR_VELOCITY, MODULE_MAX_ANGULAR_ACCELERATION)
    )

    // Gains are for example purposes only - must be determined for your own robot!
    private val driveFeedforward = SimpleMotorFeedforward(1.0, 3.0)
    private val turnFeedforward = SimpleMotorFeedforward(1.0, 0.5)

    init
    {
        // Set the distance per pulse for the drive encoder. We can simply use the
        // distance traveled for one rotation of the wheel divided by the encoder
        // resolution.
        driveEncoder.setDistancePerPulse(2 * Math.PI * WHEEL_RADIUS / ENCODER_RESOLUTION)

        // Set the distance (in this case, angle) in radians per pulse for the turning encoder.
        // This is the the angle through an entire rotation (2 * pi) divided by the
        // encoder resolution.
        turningEncoder.setDistancePerPulse(2 * Math.PI / ENCODER_RESOLUTION)

        // Limit the PID Controller's input range between -pi and pi and set the input
        // to be continuous.
        turningPIDController.enableContinuousInput(-Math.PI, Math.PI)
    }

    /** The current state of the module. */
    val state: SwerveModuleVelocity
        get() = SwerveModuleVelocity(driveEncoder.rate, Rotation2d(turningEncoder.distance))

    /** The current position of the module. */
    val position: SwerveModulePosition
        get() = SwerveModulePosition(driveEncoder.distance, Rotation2d(turningEncoder.distance))

    /**
     * Sets the desired state for the module.
     *
     * @param desiredVelocity Desired velocity.
     */
    fun setDesiredVelocity(desiredVelocity: SwerveModuleVelocity)
    {
        val encoderRotation = Rotation2d(turningEncoder.distance)

        // Optimize the desired velocity to avoid spinning further than 90 degrees, then scale velocity
        // by cosine of angle error. This scales down movement perpendicular to the desired direction of
        // travel that can occur when modules change directions. This results in smoother driving.
        val velocity = desiredVelocity.optimize(encoderRotation).cosineScale(encoderRotation)

        // Calculate the drive output from the drive PID controller and feedforward.
        val driveOutput = drivePIDController.calculate(driveEncoder.rate, velocity.velocity) +
            driveFeedforward.calculate(desiredVelocity.velocity)

        // Calculate the turning motor output from the turning PID controller and feedforward.
        val turnOutput = turningPIDController.calculate(turningEncoder.distance, velocity.angle.radians) +
            turnFeedforward.calculate(turningPIDController.setpoint.velocity)

        driveMotor.setVoltage(driveOutput)
        turningMotor.setVoltage(turnOutput)
    }
}

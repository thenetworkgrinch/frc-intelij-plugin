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
import org.wpilib.math.geometry.Translation2d
import org.wpilib.math.kinematics.ChassisVelocities
import org.wpilib.math.kinematics.MecanumDriveKinematics
import org.wpilib.math.kinematics.MecanumDriveOdometry
import org.wpilib.math.kinematics.MecanumDriveWheelPositions
import org.wpilib.math.kinematics.MecanumDriveWheelVelocities
import kotlin.math.PI

/** Represents a mecanum drive style drivetrain. */
class Drivetrain
{
    companion object
    {
        const val MAX_VELOCITY = 3.0 // 3 meters per second
        const val MAX_ANGULAR_VELOCITY = PI // 1/2 rotation per second
    }

    private val frontLeftMotor = PWMSparkMax(1)
    private val frontRightMotor = PWMSparkMax(2)
    private val backLeftMotor = PWMSparkMax(3)
    private val backRightMotor = PWMSparkMax(4)

    private val frontLeftEncoder = Encoder(0, 1)
    private val frontRightEncoder = Encoder(2, 3)
    private val backLeftEncoder = Encoder(4, 5)
    private val backRightEncoder = Encoder(6, 7)

    private val frontLeftLocation = Translation2d(0.381, 0.381)
    private val frontRightLocation = Translation2d(0.381, -0.381)
    private val backLeftLocation = Translation2d(-0.381, 0.381)
    private val backRightLocation = Translation2d(-0.381, -0.381)

    private val frontLeftPIDController = PIDController(1.0, 0.0, 0.0)
    private val frontRightPIDController = PIDController(1.0, 0.0, 0.0)
    private val backLeftPIDController = PIDController(1.0, 0.0, 0.0)
    private val backRightPIDController = PIDController(1.0, 0.0, 0.0)

    private val imu = OnboardIMU(OnboardIMU.MountOrientation.FLAT)

    private val kinematics =
        MecanumDriveKinematics(frontLeftLocation, frontRightLocation, backLeftLocation, backRightLocation)

    private val odometry = MecanumDriveOdometry(kinematics, imu.rotation2d, getCurrentWheelDistances())

    // Gains are for example purposes only - must be determined for your own robot!
    private val feedforward = SimpleMotorFeedforward(1.0, 3.0)

    /** Constructs a MecanumDrive and resets the gyro. */
    init
    {
        imu.resetYaw()
        // We need to invert one side of the drivetrain so that positive voltages
        // result in both sides moving forward. Depending on how your robot's
        // gearbox is constructed, you might have to invert the left side instead.
        frontRightMotor.inverted = true
        backRightMotor.inverted = true
    }

    /**
     * Returns the current wheel distances measured by the drivetrain.
     *
     * @return The current wheel distances measured by the drivetrain.
     */
    fun getCurrentWheelDistances(): MecanumDriveWheelPositions =
        MecanumDriveWheelPositions(
            frontLeftEncoder.distance,
            frontRightEncoder.distance,
            backLeftEncoder.distance,
            backRightEncoder.distance)

    /**
     * Returns the current wheel velocities of the drivetrain.
     *
     * @return The current wheel velocities of the drivetrain.
     */
    fun getCurrentWheelVelocities(): MecanumDriveWheelVelocities =
        MecanumDriveWheelVelocities(
            frontLeftEncoder.rate,
            frontRightEncoder.rate,
            backLeftEncoder.rate,
            backRightEncoder.rate)

    /**
     * Set the desired velocities for each wheel.
     *
     * @param velocities The desired wheel velocities.
     */
    fun setVelocities(velocities: MecanumDriveWheelVelocities)
    {
        val frontLeftFeedforward = feedforward.calculate(velocities.frontLeft)
        val frontRightFeedforward = feedforward.calculate(velocities.frontRight)
        val backLeftFeedforward = feedforward.calculate(velocities.rearLeft)
        val backRightFeedforward = feedforward.calculate(velocities.rearRight)

        val frontLeftOutput = frontLeftPIDController.calculate(frontLeftEncoder.rate, velocities.frontLeft)
        val frontRightOutput = frontRightPIDController.calculate(frontRightEncoder.rate, velocities.frontRight)
        val backLeftOutput = backLeftPIDController.calculate(backLeftEncoder.rate, velocities.rearLeft)
        val backRightOutput = backRightPIDController.calculate(backRightEncoder.rate, velocities.rearRight)

        frontLeftMotor.setVoltage(frontLeftOutput + frontLeftFeedforward)
        frontRightMotor.setVoltage(frontRightOutput + frontRightFeedforward)
        backLeftMotor.setVoltage(backLeftOutput + backLeftFeedforward)
        backRightMotor.setVoltage(backRightOutput + backRightFeedforward)
    }

    /**
     * Method to drive the robot using joystick info.
     *
     * @param xVelocity Velocity of the robot in the x direction (forward).
     * @param yVelocity Velocity of the robot in the y direction (sideways).
     * @param rot Angular rate of the robot.
     * @param fieldRelative Whether the provided x and y velocities are relative to the field.
     * @param period The time period, in seconds, over which the velocities are discretized.
     */
    fun drive(xVelocity: Double, yVelocity: Double, rot: Double, fieldRelative: Boolean, period: Double)
    {
        var chassisVelocities = ChassisVelocities(xVelocity, yVelocity, rot)
        if (fieldRelative)
        {
            chassisVelocities = chassisVelocities.toRobotRelative(imu.rotation2d)
        }
        setVelocities(kinematics.toWheelVelocities(chassisVelocities.discretize(period)).desaturate(MAX_VELOCITY))
    }

    /** Updates the field relative position of the robot. */
    fun updateOdometry()
    {
        odometry.update(imu.rotation2d, getCurrentWheelDistances())
    }
}

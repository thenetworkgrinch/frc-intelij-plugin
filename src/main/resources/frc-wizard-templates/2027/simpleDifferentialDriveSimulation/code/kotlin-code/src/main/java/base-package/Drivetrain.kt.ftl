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
import org.wpilib.math.geometry.Pose2d
import org.wpilib.math.kinematics.ChassisVelocities
import org.wpilib.math.kinematics.DifferentialDriveKinematics
import org.wpilib.math.kinematics.DifferentialDriveOdometry
import org.wpilib.math.kinematics.DifferentialDriveWheelVelocities
import org.wpilib.math.numbers.N2
import org.wpilib.math.system.DCMotor
import org.wpilib.math.system.LinearSystem
import org.wpilib.math.system.Models
import org.wpilib.simulation.DifferentialDrivetrainSim
import org.wpilib.simulation.EncoderSim
import org.wpilib.smartdashboard.Field2d
import org.wpilib.system.RobotController
import org.wpilib.telemetry.Telemetry

class Drivetrain
{
    companion object
    {
        // 3 meters per second.
        const val MAX_VELOCITY = 3.0
        // 1/2 rotation per second.
        const val MAX_ANGULAR_VELOCITY = Math.PI

        private const val TRACKWIDTH = 0.381 * 2
        private const val WHEEL_RADIUS = 0.0508
        private const val ENCODER_RESOLUTION = -4096
    }

    private val leftLeader = PWMSparkMax(1)
    private val leftFollower = PWMSparkMax(2)
    private val rightLeader = PWMSparkMax(3)
    private val rightFollower = PWMSparkMax(4)

    private val leftEncoder = Encoder(0, 1)
    private val rightEncoder = Encoder(2, 3)

    private val leftPIDController = PIDController(8.5, 0.0, 0.0)
    private val rightPIDController = PIDController(8.5, 0.0, 0.0)

    private val imu = OnboardIMU(OnboardIMU.MountOrientation.FLAT)

    private val kinematics = DifferentialDriveKinematics(TRACKWIDTH)
    private val odometry = DifferentialDriveOdometry(imu.rotation2d, leftEncoder.distance, rightEncoder.distance)

    // Gains are for example purposes only - must be determined for your own
    // robot!
    private val feedforward = SimpleMotorFeedforward(1.0, 3.0)

    // Simulation classes help us simulate our robot
    private val leftEncoderSim = EncoderSim(leftEncoder)
    private val rightEncoderSim = EncoderSim(rightEncoder)
    private val fieldSim = Field2d()
    private val drivetrainSystem: LinearSystem<N2, N2, N2> = Models.differentialDriveFromSysId(1.98, 0.2, 1.5, 0.3)
    private val drivetrainSimulator =
        DifferentialDrivetrainSim(drivetrainSystem, DCMotor.getCIM(2), 8.0, TRACKWIDTH, WHEEL_RADIUS, null)

    /** Subsystem constructor. */
    init
    {
        leftLeader.addFollower(leftFollower)
        rightLeader.addFollower(rightFollower)

        // We need to invert one side of the drivetrain so that positive voltages
        // result in both sides moving forward. Depending on how your robot's
        // gearbox is constructed, you might have to invert the left side instead.
        rightLeader.inverted = true

        // Set the distance per pulse for the drive encoders. We can simply use the
        // distance traveled for one rotation of the wheel divided by the encoder
        // resolution.
        leftEncoder.setDistancePerPulse(2 * Math.PI * WHEEL_RADIUS / ENCODER_RESOLUTION)
        rightEncoder.setDistancePerPulse(2 * Math.PI * WHEEL_RADIUS / ENCODER_RESOLUTION)

        leftEncoder.reset()
        rightEncoder.reset()

        rightLeader.inverted = true
    }

    /** Sets velocities to the drivetrain motors. */
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
     * Controls the robot using arcade drive.
     *
     * @param xVelocity the velocity for the x axis
     * @param rot the rotation
     */
    fun drive(xVelocity: Double, rot: Double)
    {
        setVelocities(kinematics.toWheelVelocities(ChassisVelocities(xVelocity, 0.0, rot)))
    }

    /** Update robot odometry. */
    fun updateOdometry()
    {
        odometry.update(imu.rotation2d, leftEncoder.distance, rightEncoder.distance)
    }

    /** Resets robot odometry. */
    fun resetOdometry(pose: Pose2d)
    {
        drivetrainSimulator.pose = pose
        odometry.resetPosition(imu.rotation2d, leftEncoder.distance, rightEncoder.distance, pose)
    }

    /** The current robot pose. */
    val pose: Pose2d
        get() = odometry.pose

    /** Update our simulation. This should be run every robot loop in simulation. */
    fun simulationPeriodic()
    {
        // To update our simulation, we set motor voltage inputs, update the
        // simulation, and write the simulated positions and velocities to our
        // simulated encoder and gyro. We negate the right side so that positive
        // voltages make the right side move forward.
        drivetrainSimulator.setInputs(
            leftLeader.throttle * RobotController.getInputVoltage(),
            rightLeader.throttle * RobotController.getInputVoltage()
        )
        drivetrainSimulator.update(0.02)

        leftEncoderSim.setDistance(drivetrainSimulator.leftPosition)
        leftEncoderSim.setRate(drivetrainSimulator.leftVelocity)
        rightEncoderSim.setDistance(drivetrainSimulator.rightPosition)
        rightEncoderSim.setRate(drivetrainSimulator.rightVelocity)
        // gyroSim.setAngle(-drivetrainSimulator.heading.degrees)
    }

    /** Update odometry - this should be run every robot loop. */
    fun periodic()
    {
        updateOdometry()
        fieldSim.setRobotPose(odometry.pose)
        Telemetry.log("Field", fieldSim)
    }
}

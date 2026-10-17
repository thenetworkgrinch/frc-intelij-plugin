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
import org.wpilib.fields.Field
import org.wpilib.fields.Fields
import org.wpilib.hardware.imu.OnboardIMU
import org.wpilib.hardware.rotation.Encoder
import org.wpilib.math.controller.PIDController
import org.wpilib.math.controller.SimpleMotorFeedforward
import org.wpilib.math.estimator.DifferentialDrivePoseEstimator
import org.wpilib.math.geometry.Pose2d
import org.wpilib.math.geometry.Pose3d
import org.wpilib.math.geometry.Quaternion
import org.wpilib.math.geometry.Rotation3d
import org.wpilib.math.geometry.Transform3d
import org.wpilib.math.geometry.Translation3d
import org.wpilib.math.kinematics.ChassisVelocities
import org.wpilib.math.kinematics.DifferentialDriveKinematics
import org.wpilib.math.kinematics.DifferentialDriveWheelVelocities
import org.wpilib.math.linalg.VecBuilder
import org.wpilib.math.numbers.N2
import org.wpilib.math.system.DCMotor
import org.wpilib.math.system.LinearSystem
import org.wpilib.math.system.Models
import org.wpilib.math.util.ComputerVisionUtil
import org.wpilib.math.util.Units
import org.wpilib.networktables.DoubleArrayEntry
import org.wpilib.networktables.DoubleArrayTopic
import org.wpilib.simulation.DifferentialDrivetrainSim
import org.wpilib.simulation.EncoderSim
import org.wpilib.simulation.OnboardIMUSim
import org.wpilib.smartdashboard.Field2d
import org.wpilib.system.RobotController
import org.wpilib.system.Timer
import org.wpilib.telemetry.Telemetry

/**
 * Represents a differential drive style drivetrain.
 *
 * Constructs a differential drive object. Sets the encoder distance per pulse and resets the
 * gyro.
 */
class Drivetrain(cameraToObjectTopic: DoubleArrayTopic)
{
    companion object
    {
        const val MAX_VELOCITY = 3.0 // meters per second
        const val MAX_ANGULAR_VELOCITY = 2 * Math.PI // one rotation per second

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

    private val objectInField: Pose3d

    private val robotToCamera = Transform3d(Translation3d(1.0, 1.0, 1.0), Rotation3d(0.0, 0.0, Math.PI / 2))

    private val cameraToObjectEntry: DoubleArrayEntry

    private val defaultVal = doubleArrayOf(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)

    private val fieldSim = Field2d()
    private val fieldApproximation = Field2d()

    /* Here we use DifferentialDrivePoseEstimator so that we can fuse odometry readings. The
    numbers used  below are robot specific, and should be tuned. */
    private val poseEstimator = DifferentialDrivePoseEstimator(
        imu.rotation2d,
        leftEncoder.distance,
        rightEncoder.distance,
        Pose2d.ZERO,
        VecBuilder.fill(0.05, 0.05, Units.degreesToRadians(5.0)),
        VecBuilder.fill(0.5, 0.5, Units.degreesToRadians(30.0))
    )

    // Gains are for example purposes only - must be determined for your own robot!
    private val feedforward = SimpleMotorFeedforward(1.0, 3.0)

    // Simulation classes
    private val leftEncoderSim = EncoderSim(leftEncoder)
    private val rightEncoderSim = EncoderSim(rightEncoder)
    private val drivetrainSystem: LinearSystem<N2, N2, N2> = Models.differentialDriveFromSysId(1.98, 0.2, 1.5, 0.3)
    private val drivetrainSimulator =
        DifferentialDrivetrainSim(drivetrainSystem, DCMotor.getCIM(2), 8.0, TRACKWIDTH, WHEEL_RADIUS, null)

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
        leftEncoder.setDistancePerPulse(2 * Math.PI * WHEEL_RADIUS / ENCODER_RESOLUTION)
        rightEncoder.setDistancePerPulse(2 * Math.PI * WHEEL_RADIUS / ENCODER_RESOLUTION)

        leftEncoder.reset()
        rightEncoder.reset()

        cameraToObjectEntry = cameraToObjectTopic.getEntry(defaultVal)

        objectInField = Field.loadField(Fields.FRC_2024_CRESCENDO).getTagPose(1).get()
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

    /**
     * Computes and publishes to a network tables topic the transformation from the camera's pose to
     * the object's pose. This method exists solely for the purposes of simulation, and this would
     * normally be handled by computer vision.
     *
     * The object could be a target or a fiducial marker.
     *
     * @param objectInField The object's field-relative position.
     * @param robotToCamera The transformation from the robot's pose to the camera's pose.
     * @param cameraToObjectEntry The networktables entry publishing and querying example computer
     *     vision measurements.
     */
    fun publishCameraToObject(
        objectInField: Pose3d,
        robotToCamera: Transform3d,
        cameraToObjectEntry: DoubleArrayEntry,
        drivetrainSimulator: DifferentialDrivetrainSim
    )
    {
        val robotInField = Pose3d(drivetrainSimulator.pose)
        val cameraInField = robotInField.plus(robotToCamera)
        val cameraToObject = Transform3d(cameraInField, objectInField)

        // Publishes double array with Translation3D elements {x, y, z} and Rotation3D elements {w, x,
        // y, z} which describe
        // the cameraToObject transformation.
        val value = doubleArrayOf(
            cameraToObject.x,
            cameraToObject.y,
            cameraToObject.z,
            cameraToObject.rotation.quaternion.w,
            cameraToObject.rotation.quaternion.x,
            cameraToObject.rotation.quaternion.y,
            cameraToObject.rotation.quaternion.z
        )
        cameraToObjectEntry.set(value)
    }

    /**
     * Queries the camera-to-object transformation from networktables to compute the robot's
     * field-relative pose from vision measurements.
     *
     * The object could be a target or a fiducial marker.
     *
     * @param objectInField The object's field-relative pose.
     * @param robotToCamera The transformation from the robot's pose to the camera's pose.
     * @param cameraToObjectEntry The networktables entry publishing and querying example computer
     *     vision measurements.
     */
    fun objectToRobotPose(
        objectInField: Pose3d,
        robotToCamera: Transform3d,
        cameraToObjectEntry: DoubleArrayEntry
    ): Pose3d
    {
        val value = cameraToObjectEntry.get()

        // Reconstruct cameraToObject Transform3D from networktables.
        val translation = Translation3d(value[0], value[1], value[2])
        val rotation = Rotation3d(Quaternion(value[3], value[4], value[5], value[6]))
        val cameraToObject = Transform3d(translation, rotation)

        return ComputerVisionUtil.objectToRobotPose(objectInField, cameraToObject, robotToCamera)
    }

    /** Updates the field-relative position. */
    fun updateOdometry()
    {
        poseEstimator.update(imu.rotation2d, leftEncoder.distance, rightEncoder.distance)

        // Publish cameraToObject transformation to networktables --this would normally be handled by
        // the
        // computer vision solution.
        publishCameraToObject(objectInField, robotToCamera, cameraToObjectEntry, drivetrainSimulator)

        // Compute the robot's field-relative position exclusively from vision measurements.
        val visionMeasurement3d = objectToRobotPose(objectInField, robotToCamera, cameraToObjectEntry)

        // Convert robot pose from Pose3d to Pose2d needed to apply vision measurements.
        val visionMeasurement2d = visionMeasurement3d.toPose2d()

        // Apply vision measurements. For simulation purposes only, we don't input a latency delay -- on
        // a real robot, this must be calculated based either on known latency or timestamps.
        poseEstimator.addVisionMeasurement(visionMeasurement2d, Timer.getTimestamp())
    }

    /** This method is called periodically during simulation. */
    fun simulationPeriodic()
    {
        // To update our simulation, we set motor voltage inputs, update the
        // simulation, and write the simulated positions and velocities to our
        // simulated encoder and gyro.
        drivetrainSimulator.setInputs(
            leftLeader.throttle * RobotController.getInputVoltage(),
            rightLeader.throttle * RobotController.getInputVoltage()
        )
        drivetrainSimulator.update(0.02)

        leftEncoderSim.setDistance(drivetrainSimulator.leftPosition)
        leftEncoderSim.setRate(drivetrainSimulator.leftVelocity)
        rightEncoderSim.setDistance(drivetrainSimulator.rightPosition)
        rightEncoderSim.setRate(drivetrainSimulator.rightVelocity)
        OnboardIMUSim.setYaw(-drivetrainSimulator.heading.radians)
    }

    /** This method is called periodically, no matter the mode. */
    fun periodic()
    {
        updateOdometry()
        fieldSim.setRobotPose(drivetrainSimulator.pose)
        fieldApproximation.setRobotPose(poseEstimator.estimatedPosition)

        Telemetry.log("Field", fieldSim)
        Telemetry.log("FieldEstimation", fieldApproximation)
    }
}

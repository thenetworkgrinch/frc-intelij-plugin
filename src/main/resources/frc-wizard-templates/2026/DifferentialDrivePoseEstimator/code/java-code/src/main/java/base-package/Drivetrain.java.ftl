<#ftl output_format="plainText" encoding="UTF-8">
<#--noinspection WrongPackageStatement-->
<#compress>
<#-- @ftlvariable name="data" type="net.javaru.iip.frc.wizard.FrcProjectWizardData" -->
<#--
    Template Language Reference: https://freemarker.apache.org/docs/ref.html
    Template Author's Guide:     https://freemarker.apache.org/docs/dgui.html
-->
<#--  To DEBUG templates, set system property 'frc.freemarker.debug' to true when launching the testing instance of IntelliJ IDEA -->
</#compress>
${data.copyright}

package ${data.basePackage};

import edu.wpi.first.apriltag.AprilTagFieldLayout;
import edu.wpi.first.apriltag.AprilTagFields;
import edu.wpi.first.math.ComputerVisionUtil;
import edu.wpi.first.math.VecBuilder;
import edu.wpi.first.math.controller.PIDController;
import edu.wpi.first.math.controller.SimpleMotorFeedforward;
import edu.wpi.first.math.estimator.DifferentialDrivePoseEstimator;
import edu.wpi.first.math.geometry.Pose2d;
import edu.wpi.first.math.geometry.Pose3d;
import edu.wpi.first.math.geometry.Quaternion;
import edu.wpi.first.math.geometry.Rotation3d;
import edu.wpi.first.math.geometry.Transform3d;
import edu.wpi.first.math.geometry.Translation3d;
import edu.wpi.first.math.kinematics.ChassisSpeeds;
import edu.wpi.first.math.kinematics.DifferentialDriveKinematics;
import edu.wpi.first.math.kinematics.DifferentialDriveWheelSpeeds;
import edu.wpi.first.math.numbers.N2;
import edu.wpi.first.math.system.LinearSystem;
import edu.wpi.first.math.system.plant.DCMotor;
import edu.wpi.first.math.system.plant.LinearSystemId;
import edu.wpi.first.math.util.Units;
import edu.wpi.first.networktables.DoubleArrayEntry;
import edu.wpi.first.networktables.DoubleArrayTopic;
import edu.wpi.first.wpilibj.AnalogGyro;
import edu.wpi.first.wpilibj.Encoder;
import edu.wpi.first.wpilibj.RobotController;
import edu.wpi.first.wpilibj.Timer;
import edu.wpi.first.wpilibj.motorcontrol.PWMSparkMax;
import edu.wpi.first.wpilibj.simulation.AnalogGyroSim;
import edu.wpi.first.wpilibj.simulation.DifferentialDrivetrainSim;
import edu.wpi.first.wpilibj.simulation.EncoderSim;
import edu.wpi.first.wpilibj.smartdashboard.Field2d;
import edu.wpi.first.wpilibj.smartdashboard.SmartDashboard;



/** Represents a differential drive style drivetrain. */
public class Drivetrain
{
    public static final double MAX_SPEED = 3.0; // meters per second
    public static final double MAX_ANGULAR_SPEED = 2 * Math.PI; // one rotation per second
    
    private static final double TRACK_WIDTH = 0.381 * 2; // meters
    private static final double WHEEL_RADIUS = 0.0508; // meters
    private static final int ENCODER_RESOLUTION = 4096;
    
    private final PWMSparkMax leftLeader = new PWMSparkMax(1);
    private final PWMSparkMax leftFollower = new PWMSparkMax(2);
    private final PWMSparkMax rightLeader = new PWMSparkMax(3);
    private final PWMSparkMax rightFollower = new PWMSparkMax(4);
    
    private final Encoder leftEncoder = new Encoder(0, 1);
    private final Encoder rightEncoder = new Encoder(2, 3);
    
    private final AnalogGyro gyro = new AnalogGyro(0);
    
    private final PIDController leftPIDController = new PIDController(1, 0, 0);
    private final PIDController rightPIDController = new PIDController(1, 0, 0);
    
    private final DifferentialDriveKinematics kinematics =
            new DifferentialDriveKinematics(TRACK_WIDTH);
    
    private final Pose3d objectInField;
    
    private final Transform3d robotToCamera =
            new Transform3d(new Translation3d(1, 1, 1), new Rotation3d(0, 0, Math.PI / 2));
    
    private final DoubleArrayEntry cameraToObjectEntry;
    
    private final double[] defaultVal = {0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0};
    
    private final Field2d fieldSim = new Field2d();
    private final Field2d fieldApproximation = new Field2d();
    
    /* Here we use DifferentialDrivePoseEstimator so that we can fuse odometry readings. The
    numbers used  below are robot specific, and should be tuned. */
    private final DifferentialDrivePoseEstimator poseEstimator =
            new DifferentialDrivePoseEstimator(
                    kinematics,
                    gyro.getRotation2d(),
                    leftEncoder.getDistance(),
                    rightEncoder.getDistance(),
                    Pose2d.kZero,
                    VecBuilder.fill(0.05, 0.05, Units.degreesToRadians(5)),
                    VecBuilder.fill(0.5, 0.5, Units.degreesToRadians(30)));
    
    // Gains are for example purposes only - must be determined for your own robot!
    private final SimpleMotorFeedforward feedforward = new SimpleMotorFeedforward(1, 3);
    
    // Simulation classes
    private final AnalogGyroSim gyroSim = new AnalogGyroSim(gyro);
    private final EncoderSim leftEncoderSim = new EncoderSim(leftEncoder);
    private final EncoderSim rightEncoderSim = new EncoderSim(rightEncoder);
    private final LinearSystem<N2, N2, N2> drivetrainSystem =
            LinearSystemId.identifyDrivetrainSystem(1.98, 0.2, 1.5, 0.3);
    private final DifferentialDrivetrainSim drivetrainSimulator =
            new DifferentialDrivetrainSim(
                    drivetrainSystem, DCMotor.getCIM(2), 8, TRACK_WIDTH, WHEEL_RADIUS, null);
    
    
    /**
     * Constructs a differential drive object. Sets the encoder distance per pulse and resets the
     * gyro.
     */
    public Drivetrain(DoubleArrayTopic cameraToObjectTopic)
    {
        gyro.reset();
        
        leftLeader.addFollower(leftFollower);
        rightLeader.addFollower(rightFollower);
        
        // We need to invert one side of the drivetrain so that positive voltages
        // result in both sides moving forward. Depending on how your robot's
        // gearbox is constructed, you might have to invert the left side instead.
        rightLeader.setInverted(true);
        
        // Set the distance per pulse for the drive encoders. We can simply use the
        // distance traveled for one rotation of the wheel divided by the encoder
        // resolution.
        leftEncoder.setDistancePerPulse(2 * Math.PI * WHEEL_RADIUS / ENCODER_RESOLUTION);
        rightEncoder.setDistancePerPulse(2 * Math.PI * WHEEL_RADIUS / ENCODER_RESOLUTION);
        
        leftEncoder.reset();
        rightEncoder.reset();
        
        cameraToObjectEntry = cameraToObjectTopic.getEntry(defaultVal);
        
        objectInField =
                AprilTagFieldLayout.loadField(AprilTagFields.k2024Crescendo).getTagPose(0).get();
        
        SmartDashboard.putData("Field", fieldSim);
        SmartDashboard.putData("FieldEstimation", fieldApproximation);
    }
    
    
    /**
     * Sets the desired wheel speeds.
     *
     * @param speeds The desired wheel speeds.
     */
    public void setSpeeds(DifferentialDriveWheelSpeeds speeds)
    {
        final double leftFeedforward = feedforward.calculate(speeds.leftMetersPerSecond);
        final double rightFeedforward = feedforward.calculate(speeds.rightMetersPerSecond);
        
        final double leftOutput =
                leftPIDController.calculate(leftEncoder.getRate(), speeds.leftMetersPerSecond);
        final double rightOutput =
                rightPIDController.calculate(rightEncoder.getRate(), speeds.rightMetersPerSecond);
        leftLeader.setVoltage(leftOutput + leftFeedforward);
        rightLeader.setVoltage(rightOutput + rightFeedforward);
    }
    
    
    /**
     * Drives the robot with the given linear velocity and angular velocity.
     *
     * @param xSpeed   Linear velocity in m/s.
     * @param rotation Angular velocity in rad/s.
     */
    public void drive(double xSpeed, double rotation)
    {
        var wheelSpeeds = kinematics.toWheelSpeeds(new ChassisSpeeds(xSpeed, 0.0, rotation));
        setSpeeds(wheelSpeeds);
    }
    
    
    /**
     * Computes and publishes to a network tables topic the transformation from the camera's pose to
     * the object's pose. This method exists solely for the purposes of simulation, and this would
     * normally be handled by computer vision.
     *
     * <p>The object could be a target or a fiducial marker.
     *
     * @param objectInField       The object's field-relative position.
     * @param robotToCamera       The transformation from the robot's pose to the camera's pose.
     * @param cameraToObjectEntry The networktables entry publishing and querying example computer
     *                            vision measurements.
     */
    public void publishCameraToObject(
            Pose3d objectInField,
            Transform3d robotToCamera,
            DoubleArrayEntry cameraToObjectEntry,
            DifferentialDrivetrainSim drivetrainSimulator)
    {
        Pose3d robotInField = new Pose3d(drivetrainSimulator.getPose());
        Pose3d cameraInField = robotInField.plus(robotToCamera);
        Transform3d cameraToObject = new Transform3d(cameraInField, objectInField);
        
        // Publishes double array with Translation3D elements {x, y, z} and Rotation3D elements {w, x,
        // y, z} which describe
        // the cameraToObject transformation.
        double[] val = {
                cameraToObject.getX(),
                cameraToObject.getY(),
                cameraToObject.getZ(),
                cameraToObject.getRotation().getQuaternion().getW(),
                cameraToObject.getRotation().getQuaternion().getX(),
                cameraToObject.getRotation().getQuaternion().getY(),
                cameraToObject.getRotation().getQuaternion().getZ()
        };
        cameraToObjectEntry.set(val);
    }
    
    
    /**
     * Queries the camera-to-object transformation from networktables to compute the robot's
     * field-relative pose from vision measurements.
     *
     * <p>The object could be a target or a fiducial marker.
     *
     * @param objectInField       The object's field-relative pose.
     * @param robotToCamera       The transformation from the robot's pose to the camera's pose.
     * @param cameraToObjectEntry The networktables entry publishing and querying example computer
     *                            vision measurements.
     */
    public Pose3d objectToRobotPose(
            Pose3d objectInField, Transform3d robotToCamera, DoubleArrayEntry cameraToObjectEntry)
    {
        double[] val = cameraToObjectEntry.get();
        
        // Reconstruct cameraToObject Transform3D from networktables.
        Translation3d translation = new Translation3d(val[0], val[1], val[2]);
        Rotation3d rotation = new Rotation3d(new Quaternion(val[3], val[4], val[5], val[6]));
        Transform3d cameraToObject = new Transform3d(translation, rotation);
        
        return ComputerVisionUtil.objectToRobotPose(objectInField, cameraToObject, robotToCamera);
    }
    
    
    /** Updates the field-relative position. */
    public void updateOdometry()
    {
        poseEstimator.update(
                gyro.getRotation2d(), leftEncoder.getDistance(), rightEncoder.getDistance());
        
        // Publish cameraToObject transformation to networktables --this would normally be handled by
        // the
        // computer vision solution.
        publishCameraToObject(
                objectInField, robotToCamera, cameraToObjectEntry, drivetrainSimulator);
        
        // Compute the robot's field-relative position exclusively from vision measurements.
        Pose3d visionMeasurement3d =
                objectToRobotPose(objectInField, robotToCamera, cameraToObjectEntry);
        
        // Convert robot pose from Pose3d to Pose2d needed to apply vision measurements.
        Pose2d visionMeasurement2d = visionMeasurement3d.toPose2d();
        
        // Apply vision measurements. For simulation purposes only, we don't input a latency delay -- on
        // a real robot, this must be calculated based either on known latency or timestamps.
        poseEstimator.addVisionMeasurement(visionMeasurement2d, Timer.getTimestamp());
    }
    
    
    /** This method is called periodically during simulation. */
    public void simulationPeriodic()
    {
        // To update our simulation, we set motor voltage inputs, update the
        // simulation, and write the simulated positions and velocities to our
        // simulated encoder and gyro.
        drivetrainSimulator.setInputs(
                leftLeader.get() * RobotController.getInputVoltage(),
                rightLeader.get() * RobotController.getInputVoltage());
        drivetrainSimulator.update(0.02);
        
        leftEncoderSim.setDistance(drivetrainSimulator.getLeftPositionMeters());
        leftEncoderSim.setRate(drivetrainSimulator.getLeftVelocityMetersPerSecond());
        rightEncoderSim.setDistance(drivetrainSimulator.getRightPositionMeters());
        rightEncoderSim.setRate(drivetrainSimulator.getRightVelocityMetersPerSecond());
        gyroSim.setAngle(-drivetrainSimulator.getHeading().getDegrees());
    }
    
    
    /** This method is called periodically, no matter the mode. */
    public void periodic()
    {
        updateOdometry();
        fieldSim.setRobotPose(drivetrainSimulator.getPose());
        fieldApproximation.setRobotPose(poseEstimator.getEstimatedPosition());
    }
}

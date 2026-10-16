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

import edu.wpi.first.math.controller.PIDController;
import edu.wpi.first.math.controller.SimpleMotorFeedforward;
import edu.wpi.first.math.kinematics.ChassisSpeeds;
import edu.wpi.first.math.kinematics.DifferentialDriveKinematics;
import edu.wpi.first.math.kinematics.DifferentialDriveOdometry;
import edu.wpi.first.math.kinematics.DifferentialDriveWheelSpeeds;
import edu.wpi.first.wpilibj.AnalogGyro;
import edu.wpi.first.wpilibj.Encoder;
import edu.wpi.first.wpilibj.motorcontrol.PWMSparkMax;



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
    
    private final DifferentialDriveOdometry odometry;
    
    // Gains are for example purposes only - must be determined for your own robot!
    private final SimpleMotorFeedforward feedforward = new SimpleMotorFeedforward(1, 3);
    
    
    /**
     * Constructs a differential drive object. Sets the encoder distance per pulse and resets the
     * gyro.
     */
    public Drivetrain()
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
        
        odometry =
                new DifferentialDriveOdometry(
                        gyro.getRotation2d(), leftEncoder.getDistance(), rightEncoder.getDistance());
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
    
    
    /** Updates the field-relative position. */
    public void updateOdometry()
    {
        odometry.update(
                gyro.getRotation2d(), leftEncoder.getDistance(), rightEncoder.getDistance());
    }
}

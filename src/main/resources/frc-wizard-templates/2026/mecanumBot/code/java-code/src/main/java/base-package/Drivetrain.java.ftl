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
import edu.wpi.first.math.geometry.Translation2d;
import edu.wpi.first.math.kinematics.ChassisSpeeds;
import edu.wpi.first.math.kinematics.MecanumDriveKinematics;
import edu.wpi.first.math.kinematics.MecanumDriveOdometry;
import edu.wpi.first.math.kinematics.MecanumDriveWheelPositions;
import edu.wpi.first.math.kinematics.MecanumDriveWheelSpeeds;
import edu.wpi.first.wpilibj.AnalogGyro;
import edu.wpi.first.wpilibj.Encoder;
import edu.wpi.first.wpilibj.motorcontrol.PWMSparkMax;



/** Represents a mecanum drive style drivetrain. */
public class Drivetrain
{
    public static final double MAX_SPEED = 3.0; // 3 meters per second
    public static final double MAX_ANGULAR_SPEED = Math.PI; // 1/2 rotation per second
    
    private final PWMSparkMax frontLeftMotor = new PWMSparkMax(1);
    private final PWMSparkMax frontRightMotor = new PWMSparkMax(2);
    private final PWMSparkMax backLeftMotor = new PWMSparkMax(3);
    private final PWMSparkMax backRightMotor = new PWMSparkMax(4);
    
    private final Encoder frontLeftEncoder = new Encoder(0, 1);
    private final Encoder frontRightEncoder = new Encoder(2, 3);
    private final Encoder backLeftEncoder = new Encoder(4, 5);
    private final Encoder backRightEncoder = new Encoder(6, 7);
    
    private final Translation2d frontLeftLocation = new Translation2d(0.381, 0.381);
    private final Translation2d frontRightLocation = new Translation2d(0.381, -0.381);
    private final Translation2d backLeftLocation = new Translation2d(-0.381, 0.381);
    private final Translation2d backRightLocation = new Translation2d(-0.381, -0.381);
    
    private final PIDController frontLeftPIDController = new PIDController(1, 0, 0);
    private final PIDController frontRightPIDController = new PIDController(1, 0, 0);
    private final PIDController backLeftPIDController = new PIDController(1, 0, 0);
    private final PIDController backRightPIDController = new PIDController(1, 0, 0);
    
    private final AnalogGyro gyro = new AnalogGyro(0);
    
    private final MecanumDriveKinematics kinematics =
            new MecanumDriveKinematics(
                    frontLeftLocation, frontRightLocation, backLeftLocation, backRightLocation);
    
    private final MecanumDriveOdometry odometry =
            new MecanumDriveOdometry(kinematics, gyro.getRotation2d(), getCurrentDistances());
    
    // Gains are for example purposes only - must be determined for your own robot!
    private final SimpleMotorFeedforward feedforward = new SimpleMotorFeedforward(1, 3);
    
    
    /** Constructs a MecanumDrive and resets the gyro. */
    public Drivetrain()
    {
        gyro.reset();
        // We need to invert one side of the drivetrain so that positive voltages
        // result in both sides moving forward. Depending on how your robot's
        // gearbox is constructed, you might have to invert the left side instead.
        frontRightMotor.setInverted(true);
        backRightMotor.setInverted(true);
    }
    
    
    /**
     * Returns the current state of the drivetrain.
     *
     * @return The current state of the drivetrain.
     */
    public MecanumDriveWheelSpeeds getCurrentState()
    {
        return new MecanumDriveWheelSpeeds(
                frontLeftEncoder.getRate(),
                frontRightEncoder.getRate(),
                backLeftEncoder.getRate(),
                backRightEncoder.getRate());
    }
    
    
    /**
     * Returns the current distances measured by the drivetrain.
     *
     * @return The current distances measured by the drivetrain.
     */
    public MecanumDriveWheelPositions getCurrentDistances()
    {
        return new MecanumDriveWheelPositions(
                frontLeftEncoder.getDistance(),
                frontRightEncoder.getDistance(),
                backLeftEncoder.getDistance(),
                backRightEncoder.getDistance());
    }
    
    
    /**
     * Set the desired speeds for each wheel.
     *
     * @param speeds The desired wheel speeds.
     */
    public void setSpeeds(MecanumDriveWheelSpeeds speeds)
    {
        final double frontLeftFeedforward = feedforward.calculate(speeds.frontLeftMetersPerSecond);
        final double frontRightFeedforward = feedforward.calculate(speeds.frontRightMetersPerSecond);
        final double backLeftFeedforward = feedforward.calculate(speeds.rearLeftMetersPerSecond);
        final double backRightFeedforward = feedforward.calculate(speeds.rearRightMetersPerSecond);
        
        final double frontLeftOutput =
                frontLeftPIDController.calculate(
                        frontLeftEncoder.getRate(), speeds.frontLeftMetersPerSecond);
        final double frontRightOutput =
                frontRightPIDController.calculate(
                        frontRightEncoder.getRate(), speeds.frontRightMetersPerSecond);
        final double backLeftOutput =
                backLeftPIDController.calculate(
                        backLeftEncoder.getRate(), speeds.rearLeftMetersPerSecond);
        final double backRightOutput =
                backRightPIDController.calculate(
                        backRightEncoder.getRate(), speeds.rearRightMetersPerSecond);
        
        frontLeftMotor.setVoltage(frontLeftOutput + frontLeftFeedforward);
        frontRightMotor.setVoltage(frontRightOutput + frontRightFeedforward);
        backLeftMotor.setVoltage(backLeftOutput + backLeftFeedforward);
        backRightMotor.setVoltage(backRightOutput + backRightFeedforward);
    }
    
    
    /**
     * Method to drive the robot using joystick info.
     *
     * @param xSpeed        Speed of the robot in the x direction (forward).
     * @param ySpeed        Speed of the robot in the y direction (sideways).
     * @param rotation      Angular rate of the robot.
     * @param fieldRelative Whether the provided x and y speeds are relative to the field.
     */
    public void drive(
            double xSpeed, double ySpeed, double rotation, boolean fieldRelative, double periodSeconds)
    {
        var mecanumDriveWheelSpeeds =
                kinematics.toWheelSpeeds(
                        ChassisSpeeds.discretize(
                                fieldRelative
                                ? ChassisSpeeds.fromFieldRelativeSpeeds(
                                        xSpeed, ySpeed, rotation, gyro.getRotation2d())
                                : new ChassisSpeeds(xSpeed, ySpeed, rotation),
                                periodSeconds));
        mecanumDriveWheelSpeeds.desaturate(MAX_SPEED);
        setSpeeds(mecanumDriveWheelSpeeds);
    }
    
    
    /** Updates the field relative position of the robot. */
    public void updateOdometry()
    {
        odometry.update(gyro.getRotation2d(), getCurrentDistances());
    }
}

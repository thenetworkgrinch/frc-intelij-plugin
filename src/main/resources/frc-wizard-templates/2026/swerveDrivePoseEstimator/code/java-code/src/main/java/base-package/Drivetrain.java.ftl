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

import edu.wpi.first.math.VecBuilder;
import edu.wpi.first.math.estimator.SwerveDrivePoseEstimator;
import edu.wpi.first.math.geometry.Pose2d;
import edu.wpi.first.math.geometry.Translation2d;
import edu.wpi.first.math.kinematics.ChassisSpeeds;
import edu.wpi.first.math.kinematics.SwerveDriveKinematics;
import edu.wpi.first.math.kinematics.SwerveModulePosition;
import edu.wpi.first.math.util.Units;
import edu.wpi.first.wpilibj.AnalogGyro;
import edu.wpi.first.wpilibj.Timer;



/** Represents a swerve drive style drivetrain. */
public class Drivetrain
{
    public static final double MAX_SPEED = 3.0; // 3 meters per second
    public static final double MAX_ANGULAR_SPEED = Math.PI; // 1/2 rotation per second
    
    private final Translation2d frontLeftLocation = new Translation2d(0.381, 0.381);
    private final Translation2d frontRightLocation = new Translation2d(0.381, -0.381);
    private final Translation2d backLeftLocation = new Translation2d(-0.381, 0.381);
    private final Translation2d backRightLocation = new Translation2d(-0.381, -0.381);
    
    private final SwerveModule frontLeft = new SwerveModule(1, 2, 0, 1, 2, 3);
    private final SwerveModule frontRight = new SwerveModule(3, 4, 4, 5, 6, 7);
    private final SwerveModule backLeft = new SwerveModule(5, 6, 8, 9, 10, 11);
    private final SwerveModule backRight = new SwerveModule(7, 8, 12, 13, 14, 15);
    
    private final AnalogGyro gyro = new AnalogGyro(0);
    
    private final SwerveDriveKinematics kinematics =
            new SwerveDriveKinematics(
                    frontLeftLocation, frontRightLocation, backLeftLocation, backRightLocation);
    
    /* Here we use SwerveDrivePoseEstimator so that we can fuse odometry readings. The numbers used
    below are robot specific, and should be tuned. */
    private final SwerveDrivePoseEstimator poseEstimator =
            new SwerveDrivePoseEstimator(
                    kinematics,
                    gyro.getRotation2d(),
                    new SwerveModulePosition[] {
                            frontLeft.getPosition(),
                            frontRight.getPosition(),
                            backLeft.getPosition(),
                            backRight.getPosition()
                    },
                    Pose2d.kZero,
                    VecBuilder.fill(0.05, 0.05, Units.degreesToRadians(5)),
                    VecBuilder.fill(0.5, 0.5, Units.degreesToRadians(30)));
    
    
    public Drivetrain()
    {
        gyro.reset();
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
        var swerveModuleStates =
                kinematics.toSwerveModuleStates(
                        ChassisSpeeds.discretize(
                                fieldRelative
                                ? ChassisSpeeds.fromFieldRelativeSpeeds(
                                        xSpeed, ySpeed, rotation, poseEstimator.getEstimatedPosition().getRotation())
                                : new ChassisSpeeds(xSpeed, ySpeed, rotation),
                                periodSeconds));
        SwerveDriveKinematics.desaturateWheelSpeeds(swerveModuleStates, MAX_SPEED);
        frontLeft.setDesiredState(swerveModuleStates[0]);
        frontRight.setDesiredState(swerveModuleStates[1]);
        backLeft.setDesiredState(swerveModuleStates[2]);
        backRight.setDesiredState(swerveModuleStates[3]);
    }
    
    
    /** Updates the field relative position of the robot. */
    public void updateOdometry()
    {
        poseEstimator.update(
                gyro.getRotation2d(),
                new SwerveModulePosition[] {
                        frontLeft.getPosition(),
                        frontRight.getPosition(),
                        backLeft.getPosition(),
                        backRight.getPosition()
                });
        
        // Also apply vision measurements. We use 0.3 seconds in the past as an example -- on
        // a real robot, this must be calculated based either on latency or timestamps.
        poseEstimator.addVisionMeasurement(
                ExampleGlobalMeasurementSensor.getEstimatedGlobalPose(
                        poseEstimator.getEstimatedPosition()),
                Timer.getTimestamp() - 0.3);
    }
}

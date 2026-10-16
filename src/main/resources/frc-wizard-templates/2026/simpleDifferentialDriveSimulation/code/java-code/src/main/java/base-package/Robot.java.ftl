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

import java.util.List;

import edu.wpi.first.math.controller.LTVUnicycleController;
import edu.wpi.first.math.filter.SlewRateLimiter;
import edu.wpi.first.math.geometry.Pose2d;
import edu.wpi.first.math.geometry.Rotation2d;
import edu.wpi.first.math.kinematics.ChassisSpeeds;
import edu.wpi.first.math.trajectory.Trajectory;
import edu.wpi.first.math.trajectory.TrajectoryConfig;
import edu.wpi.first.math.trajectory.TrajectoryGenerator;
import edu.wpi.first.wpilibj.TimedRobot;
import edu.wpi.first.wpilibj.Timer;
import edu.wpi.first.wpilibj.XboxController;



public class ${data.robotClassSimpleName} extends TimedRobot
{
    private final XboxController controller = new XboxController(0);
    
    // Slew rate limiters to make joystick inputs more gentle; 1/3 sec from 0
    // to 1.
    private final SlewRateLimiter speedLimiter = new SlewRateLimiter(3);
    private final SlewRateLimiter rotateLimiter = new SlewRateLimiter(3);
    
    private final Drivetrain drive = new Drivetrain();
    private final LTVUnicycleController feedback = new LTVUnicycleController(0.020);
    private final Timer timer = new Timer();
    private final Trajectory trajectory;
    
    
    /** Called once at the beginning of the robot program. */
    public Robot()
    {
        trajectory =
                TrajectoryGenerator.generateTrajectory(
                        new Pose2d(2, 2, Rotation2d.kZero),
                        List.of(),
                        new Pose2d(6, 4, Rotation2d.kZero),
                        new TrajectoryConfig(2, 2));
    }
    
    
    @Override
    public void robotPeriodic()
    {
        drive.periodic();
    }
    
    
    @Override
    public void autonomousInit()
    {
        timer.restart();
        drive.resetOdometry(trajectory.getInitialPose());
    }
    
    
    @Override
    public void autonomousPeriodic()
    {
        double elapsed = timer.get();
        Trajectory.State reference = trajectory.sample(elapsed);
        ChassisSpeeds speeds = feedback.calculate(drive.getPose(), reference);
        drive.drive(speeds.vxMetersPerSecond, speeds.omegaRadiansPerSecond);
    }
    
    
    @Override
    public void teleopPeriodic()
    {
        // Get the x speed. We are inverting this because Xbox controllers return
        // negative values when we push forward.
        double xSpeed = -speedLimiter.calculate(controller.getLeftY()) * Drivetrain.MAX_SPEED;
        
        // Get the rate of angular rotation. We are inverting this because we want a
        // positive value when we pull to the left (remember, CCW is positive in
        // mathematics). Xbox controllers return positive values when you pull to
        // the right by default.
        double rot = -rotateLimiter.calculate(controller.getRightX()) * Drivetrain.MAX_ANGULAR_SPEED;
        drive.drive(xSpeed, rot);
    }
    
    
    @Override
    public void simulationPeriodic()
    {
        drive.simulationPeriodic();
    }
}

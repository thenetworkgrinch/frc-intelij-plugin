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

import edu.wpi.first.math.controller.PIDController;
import edu.wpi.first.math.controller.ProfiledPIDController;
import edu.wpi.first.math.geometry.Pose2d;
import edu.wpi.first.math.geometry.Rotation2d;
import edu.wpi.first.math.geometry.Translation2d;
import edu.wpi.first.math.trajectory.Trajectory;
import edu.wpi.first.math.trajectory.TrajectoryConfig;
import edu.wpi.first.math.trajectory.TrajectoryGenerator;
import edu.wpi.first.wpilibj.XboxController;
import edu.wpi.first.wpilibj.XboxController.Button;
import ${data.basePackage}.Constants.AutoConstants;
import ${data.basePackage}.Constants.DriveConstants;
import ${data.basePackage}.Constants.OIConstants;
import ${data.basePackage}.subsystems.DriveSubsystem;
import edu.wpi.first.wpilibj2.command.Command;
import edu.wpi.first.wpilibj2.command.Commands;
import edu.wpi.first.wpilibj2.command.InstantCommand;
import edu.wpi.first.wpilibj2.command.MecanumControllerCommand;
import edu.wpi.first.wpilibj2.command.RunCommand;
import edu.wpi.first.wpilibj2.command.button.JoystickButton;



/*
 * This class is where the bulk of the robot should be declared.  Since Command-based is a
 * "declarative" paradigm, very little robot logic should actually be handled in the {@link Robot}
 * periodic methods (other than the scheduler calls).  Instead, the structure of the robot
 * (including subsystems, commands, and button mappings) should be declared here.
 */
public class RobotContainer
{
    // The robot's subsystems
    private final DriveSubsystem robotDrive = new DriveSubsystem();
    
    // The driver's controller
    XboxController driverController = new XboxController(OIConstants.DRIVER_CONTROLLER_PORT);
    
    
    /** The container for the robot. Contains subsystems, OI devices, and commands. */
    public RobotContainer()
    {
        // Configure the button bindings
        configureButtonBindings();
        
        // Configure default commands
        // Set the default drive command to split-stick arcade drive
        robotDrive.setDefaultCommand(
                // A split-stick arcade command, with forward/backward controlled by the left
                // hand, and turning controlled by the right.
                new RunCommand(
                        () ->
                                robotDrive.drive(
                                        -driverController.getLeftY(),
                                        -driverController.getRightX(),
                                        -driverController.getLeftX(),
                                        false),
                        robotDrive));
    }
    
    
    /**
     * Use this method to define your button->command mappings. Buttons can be created by
     * instantiating a {@link edu.wpi.first.wpilibj.GenericHID} or one of its subclasses ({@link
     * edu.wpi.first.wpilibj.Joystick} or {@link XboxController}), and then calling passing it to a
     * {@link JoystickButton}.
     */
    private void configureButtonBindings()
    {
        // Drive at half speed when the right bumper is held
        new JoystickButton(driverController, Button.kRightBumper.value)
                .onTrue(new InstantCommand(() -> robotDrive.setMaxOutput(0.5)))
                .onFalse(new InstantCommand(() -> robotDrive.setMaxOutput(1)));
    }
    
    
    /**
     * Use this to pass the autonomous command to the main {@link Robot} class.
     *
     * @return the command to run in autonomous
     */
    public Command getAutonomousCommand()
    {
        // Create config for trajectory
        TrajectoryConfig config =
                new TrajectoryConfig(
                        AutoConstants.MAX_SPEED_METERS_PER_SECOND,
                        AutoConstants.MAX_ACCELERATION_METERS_PER_SECOND_SQUARED)
                        // Add kinematics to ensure max speed is actually obeyed
                        .setKinematics(DriveConstants.DRIVE_KINEMATICS);
        
        // An example trajectory to follow. All units in meters.
        Trajectory exampleTrajectory =
                TrajectoryGenerator.generateTrajectory(
                        // Start at the origin facing the +X direction
                        Pose2d.kZero,
                        // Pass through these two interior waypoints, making an 's' curve path
                        List.of(new Translation2d(1, 1), new Translation2d(2, -1)),
                        // End 3 meters straight ahead of where we started, facing forward
                        new Pose2d(3, 0, Rotation2d.kZero),
                        config);
        
        MecanumControllerCommand mecanumControllerCommand =
                new MecanumControllerCommand(
                        exampleTrajectory,
                        robotDrive::getPose,
                        DriveConstants.FEEDFORWARD,
                        DriveConstants.DRIVE_KINEMATICS,
                        
                        // Position controllers
                        new PIDController(AutoConstants.PX_CONTROLLER, 0, 0),
                        new PIDController(AutoConstants.PY_CONTROLLER, 0, 0),
                        new ProfiledPIDController(
                                AutoConstants.P_THETA_CONTROLLER, 0, 0, AutoConstants.THETA_CONTROLLER_CONSTRAINTS),
                        
                        // Needed for normalizing wheel speeds
                        AutoConstants.MAX_SPEED_METERS_PER_SECOND,
                        
                        // Velocity PIDs
                        new PIDController(DriveConstants.P_FRONT_LEFT_VEL, 0, 0),
                        new PIDController(DriveConstants.P_REAR_LEFT_VEL, 0, 0),
                        new PIDController(DriveConstants.P_FRONT_RIGHT_VEL, 0, 0),
                        new PIDController(DriveConstants.P_REAR_RIGHT_VEL, 0, 0),
                        robotDrive::getCurrentWheelSpeeds,
                        robotDrive::setDriveMotorControllersVolts, // Consumer for the output motor voltages
                        robotDrive);
        
        // Reset odometry to the initial pose of the trajectory, run path following
        // command, then stop at the end.
        return Commands.sequence(
                new InstantCommand(() -> robotDrive.resetOdometry(exampleTrajectory.getInitialPose())),
                mecanumControllerCommand,
                new InstantCommand(() -> robotDrive.drive(0, 0, 0, false)));
    }
}

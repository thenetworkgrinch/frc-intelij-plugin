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

import edu.wpi.first.wpilibj.GenericHID;
import edu.wpi.first.wpilibj.Joystick;
import edu.wpi.first.wpilibj.XboxController;
import ${data.basePackage}.commands.ArcadeDrive;
import ${data.basePackage}.commands.AutonomousDistance;
import ${data.basePackage}.commands.AutonomousTime;
import ${data.basePackage}.subsystems.Arm;
import ${data.basePackage}.subsystems.Drivetrain;
import edu.wpi.first.wpilibj.smartdashboard.SendableChooser;
import edu.wpi.first.wpilibj.smartdashboard.SmartDashboard;
import edu.wpi.first.wpilibj.xrp.XRPOnBoardIO;
import edu.wpi.first.wpilibj2.command.Command;
import edu.wpi.first.wpilibj2.command.InstantCommand;
import edu.wpi.first.wpilibj2.command.PrintCommand;
import edu.wpi.first.wpilibj2.command.button.JoystickButton;
import edu.wpi.first.wpilibj2.command.button.Trigger;



/**
 * This class is where the bulk of the robot should be declared. Since Command-based is a
 * "declarative" paradigm, very little robot logic should actually be handled in the {@link Robot}
 * periodic methods (other than the scheduler calls). Instead, the structure of the robot (including
 * subsystems, commands, and button mappings) should be declared here.
 */
public class RobotContainer
{
    // The robot's subsystems and commands are defined here...
    private final Drivetrain drivetrain = new Drivetrain();
    private final XRPOnBoardIO onboardIO = new XRPOnBoardIO();
    private final Arm arm = new Arm();
    
    // Assumes a gamepad plugged into channel 0
    private final Joystick controller = new Joystick(0);
    
    // Create SmartDashboard chooser for autonomous routines
    private final SendableChooser<Command> chooser = new SendableChooser<>();
    
    
    /** The container for the robot. Contains subsystems, OI devices, and commands. */
    public RobotContainer()
    {
        // Configure the button bindings
        configureButtonBindings();
    }
    
    
    /**
     * Use this method to define your button->command mappings. Buttons can be created by
     * instantiating a {@link GenericHID} or one of its subclasses ({@link
     * edu.wpi.first.wpilibj.Joystick} or {@link XboxController}), and then passing it to a {@link
     * edu.wpi.first.wpilibj2.command.button.JoystickButton}.
     */
    private void configureButtonBindings()
    {
        // Default command is arcade drive. This will run unless another command
        // is scheduled over it.
        drivetrain.setDefaultCommand(getArcadeDriveCommand());
        
        // Example of how to use the onboard IO
        Trigger userButton = new Trigger(onboardIO::getUserButtonPressed);
        userButton
                .onTrue(new PrintCommand("USER Button Pressed"))
                .onFalse(new PrintCommand("USER Button Released"));
        
        JoystickButton joystickAButton = new JoystickButton(controller, 1);
        joystickAButton
                .onTrue(new InstantCommand(() -> arm.setAngle(45.0), arm))
                .onFalse(new InstantCommand(() -> arm.setAngle(0.0), arm));
        
        JoystickButton joystickBButton = new JoystickButton(controller, 2);
        joystickBButton
                .onTrue(new InstantCommand(() -> arm.setAngle(90.0), arm))
                .onFalse(new InstantCommand(() -> arm.setAngle(0.0), arm));
        
        // Setup SmartDashboard options
        chooser.setDefaultOption("Auto Routine Distance", new AutonomousDistance(drivetrain));
        chooser.addOption("Auto Routine Time", new AutonomousTime(drivetrain));
        SmartDashboard.putData(chooser);
    }
    
    
    /**
     * Use this to pass the autonomous command to the main {@link Robot} class.
     *
     * @return the command to run in autonomous
     */
    public Command getAutonomousCommand()
    {
        return chooser.getSelected();
    }
    
    
    /**
     * Use this to pass the teleop command to the main {@link Robot} class.
     *
     * @return the command to run in teleop
     */
    public Command getArcadeDriveCommand()
    {
        return new ArcadeDrive(
                drivetrain, () -> -controller.getRawAxis(1), () -> -controller.getRawAxis(2));
    }
}

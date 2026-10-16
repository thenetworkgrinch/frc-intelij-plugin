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

import edu.wpi.first.wpilibj.PS4Controller;
import ${data.basePackage}.Constants.OIConstants;
import ${data.basePackage}.commands.Autos;
import ${data.basePackage}.subsystems.DriveSubsystem;
import ${data.basePackage}.subsystems.HatchSubsystem;
import edu.wpi.first.wpilibj.shuffleboard.EventImportance;
import edu.wpi.first.wpilibj.shuffleboard.Shuffleboard;
import edu.wpi.first.wpilibj.smartdashboard.SendableChooser;
import edu.wpi.first.wpilibj2.command.Command;
import edu.wpi.first.wpilibj2.command.CommandScheduler;
import edu.wpi.first.wpilibj2.command.Commands;
import edu.wpi.first.wpilibj2.command.button.CommandPS4Controller;



/**
 * This class is where the bulk of the robot should be declared. Since Command-based is a
 * "declarative" paradigm, very little robot logic should actually be handled in the {@link Robot}
 * periodic methods (other than the scheduler calls). Instead, the structure of the robot (including
 * subsystems, commands, and button mappings) should be declared here.
 */
public class RobotContainer
{
    // The robot's subsystems
    private final DriveSubsystem robotDrive = new DriveSubsystem();
    private final HatchSubsystem hatchSubsystem = new HatchSubsystem();
    
    // Retained command handles
    
    // The autonomous routines
    // A simple auto routine that drives forward a specified distance, and then stops.
    private final Command simpleAuto = Autos.simpleAuto(robotDrive);
    // A complex auto routine that drives forward, drops a hatch, and then drives backward.
    private final Command complexAuto = Autos.complexAuto(robotDrive, hatchSubsystem);
    
    // A chooser for autonomous commands
    SendableChooser<Command> chooser = new SendableChooser<>();
    
    // The driver's controller
    CommandPS4Controller driverController =
            new CommandPS4Controller(OIConstants.DRIVER_CONTROLLER_PORT);
    
    
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
                Commands.run(
                        () ->
                                robotDrive.arcadeDrive(
                                        -driverController.getLeftY(), -driverController.getRightX()),
                        robotDrive));
        
        // Add commands to the autonomous command chooser
        chooser.setDefaultOption("Simple Auto", simpleAuto);
        chooser.addOption("Complex Auto", complexAuto);
        
        // Put the chooser on the dashboard
        Shuffleboard.getTab("Autonomous").add(chooser);
        
        // Put subsystems to dashboard.
        Shuffleboard.getTab("Drivetrain").add(robotDrive);
        Shuffleboard.getTab("HatchSubsystem").add(hatchSubsystem);
        
        // Set the scheduler to log Shuffleboard events for command initialize, interrupt, finish
        CommandScheduler.getInstance()
                        .onCommandInitialize(
                                command ->
                                        Shuffleboard.addEventMarker(
                                                "Command initialized", command.getName(), EventImportance.kNormal));
        CommandScheduler.getInstance()
                        .onCommandInterrupt(
                                command ->
                                        Shuffleboard.addEventMarker(
                                                "Command interrupted", command.getName(), EventImportance.kNormal));
        CommandScheduler.getInstance()
                        .onCommandFinish(
                                command ->
                                        Shuffleboard.addEventMarker(
                                                "Command finished", command.getName(), EventImportance.kNormal));
    }
    
    
    /**
     * Use this method to define your button->command mappings. Buttons can be created by
     * instantiating a {@link edu.wpi.first.wpilibj.GenericHID} or one of its subclasses ({@link
     * edu.wpi.first.wpilibj.Joystick} or {@link PS4Controller}), and then passing it to a {@link
     * edu.wpi.first.wpilibj2.command.button.JoystickButton}.
     */
    private void configureButtonBindings()
    {
        // Grab the hatch when the Circle button is pressed.
        driverController.circle().onTrue(hatchSubsystem.grabHatchCommand());
        // Release the hatch when the Square button is pressed.
        driverController.square().onTrue(hatchSubsystem.releaseHatchCommand());
        // While holding R1, drive at half speed
        driverController
                .R1()
                .onTrue(Commands.runOnce(() -> robotDrive.setMaxOutput(0.5)))
                .onFalse(Commands.runOnce(() -> robotDrive.setMaxOutput(1)));
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
}

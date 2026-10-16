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

import edu.wpi.first.wpilibj.XboxController;
import ${data.basePackage}.Constants.AutoConstants;
import ${data.basePackage}.Constants.OIConstants;
import ${data.basePackage}.commands.ComplexAuto;
import ${data.basePackage}.commands.DefaultDrive;
import ${data.basePackage}.commands.DriveDistance;
import ${data.basePackage}.commands.GrabHatch;
import ${data.basePackage}.commands.HalveDriveSpeed;
import ${data.basePackage}.commands.ReleaseHatch;
import ${data.basePackage}.subsystems.DriveSubsystem;
import ${data.basePackage}.subsystems.HatchSubsystem;
import edu.wpi.first.wpilibj.shuffleboard.EventImportance;
import edu.wpi.first.wpilibj.shuffleboard.Shuffleboard;
import edu.wpi.first.wpilibj.smartdashboard.SendableChooser;
import edu.wpi.first.wpilibj2.command.Command;
import edu.wpi.first.wpilibj2.command.CommandScheduler;
import edu.wpi.first.wpilibj2.command.button.JoystickButton;

import static edu.wpi.first.wpilibj.XboxController.Button;



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
    
    // The autonomous routines
    
    // A simple auto routine that drives forward a specified distance, and then stops.
    private final Command simpleAuto =
            new DriveDistance(
                    AutoConstants.AUTO_DRIVE_DISTANCE_INCHES, AutoConstants.AUTO_DRIVE_SPEED, robotDrive);
    
    // A complex auto routine that drives forward, drops a hatch, and then drives backward.
    private final Command complexAuto = new ComplexAuto(robotDrive, hatchSubsystem);
    
    // A chooser for autonomous commands
    SendableChooser<Command> chooser = new SendableChooser<>();
    
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
                new DefaultDrive(
                        robotDrive,
                        () -> -driverController.getLeftY(),
                        () -> -driverController.getRightX()));
        
        // Add commands to the autonomous command chooser
        chooser.setDefaultOption("Simple Auto", simpleAuto);
        chooser.addOption("Complex Auto", complexAuto);
        
        // Put the chooser on the dashboard
        Shuffleboard.getTab("Autonomous").add(chooser);
        // Put subsystems to dashboard.
        Shuffleboard.getTab("Drivetrain").add(robotDrive);
        Shuffleboard.getTab("HatchSubsystem").add(hatchSubsystem);
        
        // Log Shuffleboard events for command initialize, execute, finish, interrupt
        CommandScheduler.getInstance()
                        .onCommandInitialize(
                                command ->
                                        Shuffleboard.addEventMarker(
                                                "Command initialized", command.getName(), EventImportance.kNormal));
        CommandScheduler.getInstance()
                        .onCommandExecute(
                                command ->
                                        Shuffleboard.addEventMarker(
                                                "Command executed", command.getName(), EventImportance.kNormal));
        CommandScheduler.getInstance()
                        .onCommandFinish(
                                command ->
                                        Shuffleboard.addEventMarker(
                                                "Command finished", command.getName(), EventImportance.kNormal));
        CommandScheduler.getInstance()
                        .onCommandInterrupt(
                                command ->
                                        Shuffleboard.addEventMarker(
                                                "Command interrupted", command.getName(), EventImportance.kNormal));
    }
    
    
    /**
     * Use this method to define your button->command mappings. Buttons can be created by
     * instantiating a {@link edu.wpi.first.wpilibj.GenericHID} or one of its subclasses ({@link
     * edu.wpi.first.wpilibj.Joystick} or {@link XboxController}), and then passing it to a {@link
     * edu.wpi.first.wpilibj2.command.button.JoystickButton}.
     */
    private void configureButtonBindings()
    {
        // Grab the hatch when the 'A' button is pressed.
        new JoystickButton(driverController, Button.kA.value).onTrue(new GrabHatch(hatchSubsystem));
        // Release the hatch when the 'B' button is pressed.
        new JoystickButton(driverController, Button.kB.value)
                .onTrue(new ReleaseHatch(hatchSubsystem));
        // While holding the shoulder button, drive at half speed
        new JoystickButton(driverController, Button.kRightBumper.value)
                .whileTrue(new HalveDriveSpeed(robotDrive));
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

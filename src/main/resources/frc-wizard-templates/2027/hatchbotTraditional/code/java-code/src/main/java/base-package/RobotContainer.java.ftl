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

import static org.wpilib.driverstation.Gamepad.Button;

import org.wpilib.command2.Command;
import org.wpilib.command2.button.GamepadButton;
import org.wpilib.driverstation.Gamepad;
import ${data.basePackage}.Constants.AutoConstants;
import ${data.basePackage}.Constants.OIConstants;
import ${data.basePackage}.commands.ComplexAuto;
import ${data.basePackage}.commands.DefaultDrive;
import ${data.basePackage}.commands.DriveDistance;
import ${data.basePackage}.commands.GrabHatch;
import ${data.basePackage}.commands.HalveDriveVelocity;
import ${data.basePackage}.commands.ReleaseHatch;
import ${data.basePackage}.subsystems.DriveSubsystem;
import ${data.basePackage}.subsystems.HatchSubsystem;
import org.wpilib.telemetry.Telemetry;
import org.wpilib.tunable.Selectable;
import org.wpilib.tunable.Tunables;

/**
 * This class is where the bulk of the robot should be declared. Since Command-based is a
 * "declarative" paradigm, very little robot logic should actually be handled in the {@link Robot}
 * periodic methods (other than the scheduler calls). Instead, the structure of the robot (including
 * subsystems, commands, and button mappings) should be declared here.
 */
public class RobotContainer {
  // The robot's subsystems
  private final DriveSubsystem robotDrive = new DriveSubsystem();
  private final HatchSubsystem hatchSubsystem = new HatchSubsystem();

  // The autonomous routines

  // A simple auto routine that drives forward a specified distance, and then stops.
  private final Command simpleAuto =
      new DriveDistance(
          AutoConstants.AUTO_DRIVE_DISTANCE_INCHES, AutoConstants.AUTO_DRIVE_VELOCITY, robotDrive);

  // A complex auto routine that drives forward, drops a hatch, and then drives backward.
  private final Command complexAuto = new ComplexAuto(robotDrive, hatchSubsystem);

  // A chooser for autonomous commands
  private final Selectable<Command> chooser = new Selectable<>();

  // The driver's controller
  Gamepad driverController = new Gamepad(OIConstants.DRIVER_CONTROLLER_PORT);

  /** The container for the robot. Contains subsystems, OI devices, and commands. */
  public RobotContainer() {
    // Configure the button bindings
    configureButtonBindings();

    // Configure default commands
    // Set the default drive command to split-stick arcade drive
    robotDrive.setDefaultCommand(
        // A split-stick arcade command, with forward/backward controlled by the left
        // hand, and turning controlled by the right.
        new DefaultDrive(
            robotDrive, () -> -driverController.getLeftY(), () -> -driverController.getRightX()));

    // Add commands to the autonomous command chooser
    chooser.addDefault("Simple Auto", simpleAuto);
    chooser.add("Complex Auto", complexAuto);

    // Put the chooser on the dashboard
    Tunables.publish("Autonomous", chooser);
  }

  /**
   * Use this method to define your button->command mappings. Buttons can be created by
   * instantiating a {@link org.wpilib.driverstation.GenericHID} or one of its subclasses ({@link
   * org.wpilib.driverstation.Joystick} or {@link Gamepad}), and then passing it to a {@link
   * org.wpilib.command2.button.JoystickButton}.
   */
  private void configureButtonBindings() {
    // Grab the hatch when the 'Face Down' button is pressed.
    new GamepadButton(driverController, Button.FACE_DOWN).onTrue(new GrabHatch(hatchSubsystem));
    // Release the hatch when the 'Face Right' button is pressed.
    new GamepadButton(driverController, Button.FACE_RIGHT).onTrue(new ReleaseHatch(hatchSubsystem));
    // While holding the bumper button, drive at half velocity
    new GamepadButton(driverController, Button.RIGHT_BUMPER)
        .whileTrue(new HalveDriveVelocity(robotDrive));
  }

  /**
   * Use this to pass the autonomous command to the main {@link Robot} class.
   *
   * @return the command to run in autonomous
   */
  public Command getAutonomousCommand() {
    return chooser.getSelected();
  }

  /** Update telemetry. */
  public void updateTelemetry() {
    Telemetry.log("Drivetrain", robotDrive);
    Telemetry.log("HatchSubsystem", hatchSubsystem);
  }
}

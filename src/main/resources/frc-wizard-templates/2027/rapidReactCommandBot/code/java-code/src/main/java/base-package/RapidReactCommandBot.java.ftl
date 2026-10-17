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

import static org.wpilib.command2.Commands.parallel;

import org.wpilib.command2.Command;
import org.wpilib.command2.button.CommandGamepad;
import org.wpilib.command2.button.Trigger;
import org.wpilib.epilogue.Logged;
import ${data.basePackage}.Constants.AutoConstants;
import ${data.basePackage}.Constants.OIConstants;
import ${data.basePackage}.Constants.ShooterConstants;
import ${data.basePackage}.subsystems.Drive;
import ${data.basePackage}.subsystems.Intake;
import ${data.basePackage}.subsystems.Pneumatics;
import ${data.basePackage}.subsystems.Shooter;
import ${data.basePackage}.subsystems.Storage;

/**
 * This class is where the bulk of the robot should be declared. Since Command-based is a
 * "declarative" paradigm, very little robot logic should actually be handled in the {@link Robot}
 * periodic methods (other than the scheduler calls). Instead, the structure of the robot (including
 * subsystems, commands, and button mappings) should be declared here.
 */
@Logged(name = "Rapid React Command Robot Container")
public class RapidReactCommandBot {
  // The robot's subsystems
  private final Drive drive = new Drive();
  private final Intake intake = new Intake();
  private final Storage storage = new Storage();
  private final Shooter shooter = new Shooter();
  private final Pneumatics pneumatics = new Pneumatics();

  // The driver's controller
  CommandGamepad driverController = new CommandGamepad(OIConstants.DRIVER_CONTROLLER_PORT);

  /**
   * Use this method to define bindings between conditions and commands. These are useful for
   * automating robot behaviors based on button and sensor input.
   *
   * <p>Should be called in the robot class constructor.
   *
   * <p>Event binding methods are available on the {@link Trigger} class.
   */
  public void configureBindings() {
    // Automatically run the storage motor whenever the ball storage is not full,
    // and turn it off whenever it fills. Uses subsystem-hosted trigger to
    // improve readability and make inter-subsystem communication easier.
    storage.hasCargo.whileFalse(storage.runCommand());

    // Automatically disable and retract the intake whenever the ball storage is full.
    storage.hasCargo.onTrue(intake.retractCommand());

    // Control the drive with split-stick arcade controls
    drive.setDefaultCommand(
        drive.arcadeDriveCommand(
            () -> -driverController.getLeftY(), () -> -driverController.getRightX()));

    // Deploy the intake with the left face button
    driverController.faceLeft().onTrue(intake.intakeCommand());
    // Retract the intake with the up face button
    driverController.faceUp().onTrue(intake.retractCommand());

    // Fire the shooter with the down face button
    driverController
        .faceDown()
        .onTrue(
            parallel(
                    shooter.shootCommand(ShooterConstants.SHOOTER_TARGET_RPS), storage.runCommand())
                // Since we composed this inline we should give it a name
                .withName("Shoot"));

    // Toggle compressor with the Start button
    driverController.start().toggleOnTrue(pneumatics.disableCompressorCommand());
  }

  /**
   * Use this to define the command that runs during autonomous.
   *
   * <p>Scheduled during {@link Robot#autonomousInit()}.
   */
  public Command getAutonomousCommand() {
    // Drive forward for 2 meters at half velocity with a 3 second timeout
    return drive
        .driveDistanceCommand(AutoConstants.DRIVE_DISTANCE, AutoConstants.DRIVE_VELOCITY)
        .withTimeout(AutoConstants.TIMEOUT);
  }
}

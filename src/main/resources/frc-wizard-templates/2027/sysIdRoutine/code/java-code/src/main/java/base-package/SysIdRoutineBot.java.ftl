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

import org.wpilib.command2.Command;
import org.wpilib.command2.button.CommandGamepad;
import org.wpilib.command2.button.Trigger;
import org.wpilib.command2.sysid.SysIdRoutine;
import ${data.basePackage}.Constants.OIConstants;
import ${data.basePackage}.subsystems.Drive;
import ${data.basePackage}.subsystems.Shooter;

/**
 * This class is where the bulk of the robot should be declared. Since Command-based is a
 * "declarative" paradigm, very little robot logic should actually be handled in the {@link Robot}
 * periodic methods (other than the scheduler calls). Instead, the structure of the robot (including
 * subsystems, commands, and button mappings) should be declared here.
 */
public class SysIdRoutineBot {
  // The robot's subsystems
  private final Drive drive = new Drive();
  private final Shooter shooter = new Shooter();

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
    // Control the drive with split-stick arcade controls
    drive.setDefaultCommand(
        drive.arcadeDriveCommand(
            () -> -driverController.getLeftY(), () -> -driverController.getRightX()));

    // Bind full set of SysId routine tests to buttons; a complete routine should run each of these
    // once.
    // Using bumpers as a modifier and combining it with the buttons so that we can have both sets
    // of bindings at once
    driverController
        .faceDown()
        .and(driverController.rightBumper())
        .whileTrue(drive.sysIdQuasistatic(SysIdRoutine.Direction.FORWARD));
    driverController
        .faceRight()
        .and(driverController.rightBumper())
        .whileTrue(drive.sysIdQuasistatic(SysIdRoutine.Direction.REVERSE));
    driverController
        .faceLeft()
        .and(driverController.rightBumper())
        .whileTrue(drive.sysIdDynamic(SysIdRoutine.Direction.FORWARD));
    driverController
        .faceUp()
        .and(driverController.rightBumper())
        .whileTrue(drive.sysIdDynamic(SysIdRoutine.Direction.REVERSE));

    // Control the shooter wheel with the left trigger
    shooter.setDefaultCommand(shooter.runShooter(driverController::getLeftTrigger));

    driverController
        .faceDown()
        .and(driverController.leftBumper())
        .whileTrue(shooter.sysIdQuasistatic(SysIdRoutine.Direction.FORWARD));
    driverController
        .faceRight()
        .and(driverController.leftBumper())
        .whileTrue(shooter.sysIdQuasistatic(SysIdRoutine.Direction.REVERSE));
    driverController
        .faceLeft()
        .and(driverController.leftBumper())
        .whileTrue(shooter.sysIdDynamic(SysIdRoutine.Direction.FORWARD));
    driverController
        .faceUp()
        .and(driverController.leftBumper())
        .whileTrue(shooter.sysIdDynamic(SysIdRoutine.Direction.REVERSE));
  }

  /**
   * Use this to define the command that runs during autonomous.
   *
   * <p>Scheduled during {@link Robot#autonomousInit()}.
   */
  public Command getAutonomousCommand() {
    // Do nothing
    return drive.run(() -> {});
  }
}

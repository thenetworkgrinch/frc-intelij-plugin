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

import ${data.basePackage}.Constants.OIConstants;
import ${data.basePackage}.subsystems.Drive;
import ${data.basePackage}.subsystems.Shooter;
import edu.wpi.first.wpilibj2.command.Command;
import edu.wpi.first.wpilibj2.command.button.CommandXboxController;
import edu.wpi.first.wpilibj2.command.button.Trigger;
import edu.wpi.first.wpilibj2.command.sysid.SysIdRoutine;



/**
 * This class is where the bulk of the robot should be declared. Since Command-based is a
 * "declarative" paradigm, very little robot logic should actually be handled in the {@link Robot}
 * periodic methods (other than the scheduler calls). Instead, the structure of the robot (including
 * subsystems, commands, and button mappings) should be declared here.
 */
public class SysIdRoutineBot
{
    // The robot's subsystems
    private final Drive drive = new Drive();
    private final Shooter shooter = new Shooter();
    
    // The driver's controller
    CommandXboxController driverController =
            new CommandXboxController(OIConstants.DRIVER_CONTROLLER_PORT);
    
    
    /**
     * Use this method to define bindings between conditions and commands. These are useful for
     * automating robot behaviors based on button and sensor input.
     *
     * <p>Should be called in the robot class constructor.
     *
     * <p>Event binding methods are available on the {@link Trigger} class.
     */
    public void configureBindings()
    {
        // Control the drive with split-stick arcade controls
        drive.setDefaultCommand(
                drive.arcadeDriveCommand(
                        () -> -driverController.getLeftY(), () -> -driverController.getRightX()));
        
        // Bind full set of SysId routine tests to buttons; a complete routine should run each of these
        // once.
        // Using bumpers as a modifier and combining it with the buttons so that we can have both sets
        // of bindings at once
        driverController
                .a()
                .and(driverController.rightBumper())
                .whileTrue(drive.sysIdQuasistatic(SysIdRoutine.Direction.kForward));
        driverController
                .b()
                .and(driverController.rightBumper())
                .whileTrue(drive.sysIdQuasistatic(SysIdRoutine.Direction.kReverse));
        driverController
                .x()
                .and(driverController.rightBumper())
                .whileTrue(drive.sysIdDynamic(SysIdRoutine.Direction.kForward));
        driverController
                .y()
                .and(driverController.rightBumper())
                .whileTrue(drive.sysIdDynamic(SysIdRoutine.Direction.kReverse));
        
        // Control the shooter wheel with the left trigger
        shooter.setDefaultCommand(shooter.runShooter(driverController::getLeftTriggerAxis));
        
        driverController
                .a()
                .and(driverController.leftBumper())
                .whileTrue(shooter.sysIdQuasistatic(SysIdRoutine.Direction.kForward));
        driverController
                .b()
                .and(driverController.leftBumper())
                .whileTrue(shooter.sysIdQuasistatic(SysIdRoutine.Direction.kReverse));
        driverController
                .x()
                .and(driverController.leftBumper())
                .whileTrue(shooter.sysIdDynamic(SysIdRoutine.Direction.kForward));
        driverController
                .y()
                .and(driverController.leftBumper())
                .whileTrue(shooter.sysIdDynamic(SysIdRoutine.Direction.kReverse));
    }
    
    
    /**
     * Use this to define the command that runs during autonomous.
     *
     * <p>Scheduled during {@link Robot#autonomousInit()}.
     */
    public Command getAutonomousCommand()
    {
        // Do nothing
        return drive.run(() -> {});
    }
}

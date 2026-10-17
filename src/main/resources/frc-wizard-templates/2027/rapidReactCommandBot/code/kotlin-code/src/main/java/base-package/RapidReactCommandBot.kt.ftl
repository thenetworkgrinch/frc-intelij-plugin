<#ftl output_format="plainText" encoding="UTF-8">
<#--noinspection WrongPackageStatement-->
<#compress>
<#-- @ftlvariable name="data" type="net.javaru.iip.frc.wizard.FrcProjectWizardData" -->
<#--
    IMPORTANT: This template uses alternate square bracket interpolation syntax
               For example:
                    [=data.robotClassSimpleName]
               rather than:
                    ${data.robotClassSimpleName}
               so as to not clash with Kotlin string templates syntax
               The option to use that can't be set in the template, but has to be set as an
               option on the Configuration object in the code. Note that this only affects interpolation
               syntax, and *NOT* Tag syntax. So we will still use `<#if isSuchAndSuch>` and not `[#if isSuchAndSuch]`.
               Tag syntax can be changed if desired, but we are not.
    Template Language Reference: https://freemarker.apache.org/docs/ref.html
    Template Author's Guide:     https://freemarker.apache.org/docs/dgui.html
-->
<#--  To DEBUG templates, set system property 'frc.freemarker.debug' to true when launching the testing instance of IntelliJ IDEA -->
</#compress>
package [=data.basePackage]

import org.wpilib.command2.Command
import org.wpilib.epilogue.Logged
import org.wpilib.command2.Commands.parallel
import org.wpilib.command2.button.CommandGamepad
import org.wpilib.command2.button.Trigger
import [=data.basePackage].Constants.AutoConstants
import [=data.basePackage].Constants.OIConstants
import [=data.basePackage].Constants.ShooterConstants
import [=data.basePackage].subsystems.Drive
import [=data.basePackage].subsystems.Intake
import [=data.basePackage].subsystems.Pneumatics
import [=data.basePackage].subsystems.Shooter
import [=data.basePackage].subsystems.Storage

/**
 * This class is where the bulk of the robot should be declared. Since Command-based is a
 * "declarative" paradigm, very little robot logic should actually be handled in the [Robot]
 * periodic methods (other than the scheduler calls). Instead, the structure of the robot (including
 * subsystems, commands, and button mappings) should be declared here.
 */
@Logged(name = "Rapid React Command Robot Container")
class RapidReactCommandBot
{
    // The robot's subsystems
    private val drive = Drive()
    private val intake = Intake()
    private val storage = Storage()
    private val shooter = Shooter()
    private val pneumatics = Pneumatics()

    // The driver's controller
    val driverController = CommandGamepad(OIConstants.DRIVER_CONTROLLER_PORT)

    /**
     * Use this method to define bindings between conditions and commands. These are useful for
     * automating robot behaviors based on button and sensor input.
     *
     * Should be called in the robot object's initializer block.
     *
     * Event binding methods are available on the [Trigger] class.
     */
    fun configureBindings()
    {
        // Automatically run the storage motor whenever the ball storage is not full,
        // and turn it off whenever it fills. Uses subsystem-hosted trigger to
        // improve readability and make inter-subsystem communication easier.
        storage.hasCargo.whileFalse(storage.runCommand())

        // Automatically disable and retract the intake whenever the ball storage is full.
        storage.hasCargo.onTrue(intake.retractCommand())

        // Control the drive with split-stick arcade controls
        drive.defaultCommand =
            drive.arcadeDriveCommand({ -driverController.leftY }, { -driverController.rightX })

        // Deploy the intake with the left face button
        driverController.faceLeft().onTrue(intake.intakeCommand())
        // Retract the intake with the up face button
        driverController.faceUp().onTrue(intake.retractCommand())

        // Fire the shooter with the down face button
        driverController
            .faceDown()
            .onTrue(
                parallel(shooter.shootCommand(ShooterConstants.SHOOTER_TARGET_RPS), storage.runCommand())
                    // Since we composed this inline we should give it a name
                    .withName("Shoot"))

        // Toggle compressor with the Start button
        driverController.start().toggleOnTrue(pneumatics.disableCompressorCommand())
    }

    /**
     * Use this to define the command that runs during autonomous.
     *
     * Scheduled during [Robot.autonomousInit].
     */
    fun getAutonomousCommand(): Command
    {
        // Drive forward for 2 meters at half velocity with a 3 second timeout
        return drive
            .driveDistanceCommand(AutoConstants.DRIVE_DISTANCE, AutoConstants.DRIVE_VELOCITY)
            .withTimeout(AutoConstants.TIMEOUT)
    }
}

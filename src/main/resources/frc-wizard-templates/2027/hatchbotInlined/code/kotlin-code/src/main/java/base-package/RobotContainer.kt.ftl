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
import org.wpilib.command2.Commands
import org.wpilib.command2.button.CommandGamepad
import [=data.basePackage].Constants.OIConstants
import [=data.basePackage].commands.Autos
import [=data.basePackage].subsystems.DriveSubsystem
import [=data.basePackage].subsystems.HatchSubsystem
import org.wpilib.telemetry.Telemetry
import org.wpilib.tunable.Selectable
import org.wpilib.tunable.Tunables

/**
 * This class is where the bulk of the robot should be declared. Since Command-based is a
 * "declarative" paradigm, very little robot logic should actually be handled in the [Robot]
 * periodic methods (other than the scheduler calls). Instead, the structure of the robot (including
 * subsystems, commands, and button mappings) should be declared here.
 */
class RobotContainer
{
    // The robot's subsystems
    private val robotDrive = DriveSubsystem()
    private val hatchSubsystem = HatchSubsystem()

    // Retained command handles

    // The autonomous routines
    // A simple auto routine that drives forward a specified distance, and then stops.
    private val simpleAuto: Command = Autos.simpleAuto(robotDrive)
    // A complex auto routine that drives forward, drops a hatch, and then drives backward.
    private val complexAuto: Command = Autos.complexAuto(robotDrive, hatchSubsystem)

    // A chooser for autonomous commands
    private val chooser = Selectable<Command>()

    // The driver's controller
    val driverController = CommandGamepad(OIConstants.DRIVER_CONTROLLER_PORT)

    /** The container for the robot. Contains subsystems, OI devices, and commands. */
    init
    {
        // Configure the button bindings
        configureButtonBindings()

        // Configure default commands
        // Set the default drive command to split-stick arcade drive
        robotDrive.defaultCommand =
            // A split-stick arcade command, with forward/backward controlled by the left
            // hand, and turning controlled by the right.
            Commands.run(
                { robotDrive.arcadeDrive(-driverController.leftY, -driverController.rightX) },
                robotDrive,
                        )

        // Add commands to the autonomous command chooser
        chooser.addDefault("Simple Auto", simpleAuto)
        chooser.add("Complex Auto", complexAuto)

        // Put the chooser on the dashboard
        Tunables.publish("Autonomous", chooser)
    }

    /** Update telemetry. */
    fun updateTelemetry()
    {
        // Put subsystems to telemetry.
        Telemetry.log("Drivetrain", robotDrive)
        Telemetry.log("HatchSubsystem", hatchSubsystem)
    }

    /**
     * Use this method to define your button->command mappings. Buttons can be created by
     * instantiating a [GenericHID][org.wpilib.driverstation.GenericHID] or one of its subclasses
     * ([Joystick][org.wpilib.driverstation.Joystick] or [Gamepad][org.wpilib.driverstation.Gamepad]),
     * and then passing it to a [JoystickButton][org.wpilib.command2.button.JoystickButton].
     */
    private fun configureButtonBindings()
    {
        // Grab the hatch when the right face button is pressed.
        driverController.faceRight().onTrue(hatchSubsystem.grabHatchCommand())
        // Release the hatch when the left face button is pressed.
        driverController.faceLeft().onTrue(hatchSubsystem.releaseHatchCommand())
        // While holding right bumper, drive at half velocity
        driverController
            .rightBumper()
            .onTrue(Commands.runOnce({ robotDrive.setMaxOutput(0.5) }))
            .onFalse(Commands.runOnce({ robotDrive.setMaxOutput(1.0) }))
    }

    /**
     * Use this to pass the autonomous command to the main [Robot] object.
     *
     * @return the command to run in autonomous
     */
    val autonomousCommand: Command?
        get() = chooser.selected
}

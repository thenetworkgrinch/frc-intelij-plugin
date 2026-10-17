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
import org.wpilib.command2.button.GamepadButton
import org.wpilib.driverstation.Gamepad
import org.wpilib.driverstation.Gamepad.Button
import [=data.basePackage].Constants.AutoConstants
import [=data.basePackage].Constants.OIConstants
import [=data.basePackage].commands.ComplexAuto
import [=data.basePackage].commands.DefaultDrive
import [=data.basePackage].commands.DriveDistance
import [=data.basePackage].commands.GrabHatch
import [=data.basePackage].commands.HalveDriveVelocity
import [=data.basePackage].commands.ReleaseHatch
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

    // The autonomous routines

    // A simple auto routine that drives forward a specified distance, and then stops.
    private val simpleAuto: Command =
        DriveDistance(AutoConstants.AUTO_DRIVE_DISTANCE_INCHES, AutoConstants.AUTO_DRIVE_VELOCITY, robotDrive)

    // A complex auto routine that drives forward, drops a hatch, and then drives backward.
    private val complexAuto: Command = ComplexAuto(robotDrive, hatchSubsystem)

    // A chooser for autonomous commands
    private val chooser = Selectable<Command>()

    // The driver's controller
    val driverController = Gamepad(OIConstants.DRIVER_CONTROLLER_PORT)

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
            DefaultDrive(robotDrive, { -driverController.leftY }, { -driverController.rightX })

        // Add commands to the autonomous command chooser
        chooser.addDefault("Simple Auto", simpleAuto)
        chooser.add("Complex Auto", complexAuto)

        // Put the chooser on the dashboard
        Tunables.publish("Autonomous", chooser)
    }

    /**
     * Use this method to define your button->command mappings. Buttons can be created by
     * instantiating a [GenericHID][org.wpilib.driverstation.GenericHID] or one of its subclasses
     * ([Joystick][org.wpilib.driverstation.Joystick] or [Gamepad]), and then passing it to a
     * [JoystickButton][org.wpilib.command2.button.JoystickButton].
     */
    private fun configureButtonBindings()
    {
        // Grab the hatch when the 'Face Down' button is pressed.
        GamepadButton(driverController, Button.FACE_DOWN).onTrue(GrabHatch(hatchSubsystem))
        // Release the hatch when the 'Face Right' button is pressed.
        GamepadButton(driverController, Button.FACE_RIGHT).onTrue(ReleaseHatch(hatchSubsystem))
        // While holding the bumper button, drive at half velocity
        GamepadButton(driverController, Button.RIGHT_BUMPER)
            .whileTrue(HalveDriveVelocity(robotDrive))
    }

    /**
     * Use this to pass the autonomous command to the main [Robot] object.
     *
     * @return the command to run in autonomous
     */
    val autonomousCommand: Command?
        get() = chooser.selected

    /** Update telemetry. */
    fun updateTelemetry()
    {
        Telemetry.log("Drivetrain", robotDrive)
        Telemetry.log("HatchSubsystem", hatchSubsystem)
    }
}

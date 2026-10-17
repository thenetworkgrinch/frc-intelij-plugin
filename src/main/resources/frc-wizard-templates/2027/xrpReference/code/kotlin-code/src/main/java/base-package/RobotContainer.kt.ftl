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
import org.wpilib.command2.InstantCommand
import org.wpilib.command2.PrintCommand
import org.wpilib.command2.button.JoystickButton
import org.wpilib.command2.button.Trigger
import org.wpilib.driverstation.Joystick
import [=data.basePackage].commands.ArcadeDrive
import [=data.basePackage].commands.AutonomousDistance
import [=data.basePackage].commands.AutonomousTime
import [=data.basePackage].subsystems.Arm
import [=data.basePackage].subsystems.Drivetrain
import org.wpilib.tunable.Selectable
import org.wpilib.tunable.Tunables
import org.wpilib.xrp.XRPOnBoardIO

/**
 * This class is where the bulk of the robot should be declared. Since Command-based is a
 * "declarative" paradigm, very little robot logic should actually be handled in the [Robot]
 * periodic methods (other than the scheduler calls). Instead, the structure of the robot (including
 * subsystems, commands, and button mappings) should be declared here.
 */
class RobotContainer
{
    // The robot's subsystems and commands are defined here...
    private val drivetrain = Drivetrain()
    private val onboardIO = XRPOnBoardIO()
    private val arm = Arm()

    // Assumes a gamepad plugged into channel 0
    private val controller = Joystick(0)

    // Create SmartDashboard chooser for autonomous routines
    private val chooser = Selectable<Command>()

    /** The container for the robot. Contains subsystems, OI devices, and commands. */
    init
    {
        // Configure the button bindings
        configureButtonBindings()
    }

    /**
     * Use this method to define your button->command mappings. Buttons can be created by
     * instantiating a [GenericHID][org.wpilib.driverstation.GenericHID] or one of its subclasses
     * ([Joystick][org.wpilib.driverstation.Joystick] or [Gamepad][org.wpilib.driverstation.Gamepad]),
     * and then passing it to a [JoystickButton][org.wpilib.command2.button.JoystickButton].
     */
    private fun configureButtonBindings()
    {
        // Default command is arcade drive. This will run unless another command
        // is scheduled over it.
        drivetrain.defaultCommand = arcadeDriveCommand

        // Example of how to use the onboard IO
        val userButton = Trigger(onboardIO::getUserButtonPressed)
        userButton
            .onTrue(PrintCommand("USER Button Pressed"))
            .onFalse(PrintCommand("USER Button Released"))

        val joystickAButton = JoystickButton(controller, 1)
        joystickAButton
            .onTrue(InstantCommand({ arm.setAngle(45.0) }, arm))
            .onFalse(InstantCommand({ arm.setAngle(0.0) }, arm))

        val joystickBButton = JoystickButton(controller, 2)
        joystickBButton
            .onTrue(InstantCommand({ arm.setAngle(90.0) }, arm))
            .onFalse(InstantCommand({ arm.setAngle(0.0) }, arm))

        // Setup SmartDashboard options
        chooser.addDefault("Auto Routine Distance", AutonomousDistance(drivetrain))
        chooser.add("Auto Routine Time", AutonomousTime(drivetrain))
        Tunables.publish("Auto Chooser", chooser)
    }

    /**
     * Use this to pass the autonomous command to the main [Robot] object.
     *
     * @return the command to run in autonomous
     */
    val autonomousCommand: Command?
        get() = chooser.selected

    /**
     * Use this to pass the teleop command to the main [Robot] object.
     *
     * @return the command to run in teleop
     */
    val arcadeDriveCommand: Command
        get() = ArcadeDrive(drivetrain, { -controller.getRawAxis(1) }, { -controller.getRawAxis(2) })
}

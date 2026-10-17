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
import [=data.basePackage].commands.ExampleCommand

/**
 * This object is where the bulk of the robot should be declared. Since Command-based is a
 * "declarative" paradigm, very little robot logic should actually be handled in the [Robot]
 * periodic functions (other than the scheduler calls). Instead, the structure of the robot (including
 * subsystems, commands, and button mappings) should be declared here.
 *
 * In Kotlin, it is recommended that all your Subsystems are Kotlin objects, as the `XRPDrivetrain` is.
 * As such, there can only ever be a single instance. This eliminates the need to create reference
 * variables to the various subsystems in this container to pass into to commands. The commands can
 * just directly reference the (single instance of the) object.
 */
object RobotContainer
{
    // The robot's commands are defined here...
    private val autoCommand = ExampleCommand()

    init
    {
        // Configure the button bindings
        configureButtonBindings()
    }

    /**
     * Use this function to define your button->command mappings. Buttons can be created by
     * instantiating a [GenericHID][org.wpilib.driverstation.GenericHID] or one of its subclasses
     * ([Joystick][org.wpilib.driverstation.Joystick] or [Gamepad][org.wpilib.driverstation.Gamepad]),
     * and then passing it to a [JoystickButton][org.wpilib.command2.button.JoystickButton].
     */
    private fun configureButtonBindings() {}

    /**
     * Use this to pass the autonomous command to the main [Robot] object.
     *
     * @return the command to run in autonomous
     */
    fun getAutonomousCommand(): Command
    {
        // An ExampleCommand will run in autonomous
        return autoCommand
    }
}

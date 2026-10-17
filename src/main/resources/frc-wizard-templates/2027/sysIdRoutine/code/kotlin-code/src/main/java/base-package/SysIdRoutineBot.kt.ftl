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
import org.wpilib.command2.button.CommandGamepad
import org.wpilib.command2.button.Trigger
import org.wpilib.command2.sysid.SysIdRoutine
import [=data.basePackage].Constants.OIConstants
import [=data.basePackage].subsystems.Drive
import [=data.basePackage].subsystems.Shooter

/**
 * This class is where the bulk of the robot should be declared. Since Command-based is a
 * "declarative" paradigm, very little robot logic should actually be handled in the [Robot]
 * periodic methods (other than the scheduler calls). Instead, the structure of the robot (including
 * subsystems, commands, and button mappings) should be declared here.
 */
class SysIdRoutineBot
{
    // The robot's subsystems
    private val drive = Drive()
    private val shooter = Shooter()

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
        // Control the drive with split-stick arcade controls
        drive.defaultCommand =
            drive.arcadeDriveCommand({ -driverController.leftY }, { -driverController.rightX })

        // Bind full set of SysId routine tests to buttons; a complete routine should run each of these
        // once.
        // Using bumpers as a modifier and combining it with the buttons so that we can have both sets
        // of bindings at once
        driverController
            .faceDown()
            .and(driverController.rightBumper())
            .whileTrue(drive.sysIdQuasistatic(SysIdRoutine.Direction.FORWARD))
        driverController
            .faceRight()
            .and(driverController.rightBumper())
            .whileTrue(drive.sysIdQuasistatic(SysIdRoutine.Direction.REVERSE))
        driverController
            .faceLeft()
            .and(driverController.rightBumper())
            .whileTrue(drive.sysIdDynamic(SysIdRoutine.Direction.FORWARD))
        driverController
            .faceUp()
            .and(driverController.rightBumper())
            .whileTrue(drive.sysIdDynamic(SysIdRoutine.Direction.REVERSE))

        // Control the shooter wheel with the left trigger
        shooter.defaultCommand = shooter.runShooter(driverController::getLeftTrigger)

        driverController
            .faceDown()
            .and(driverController.leftBumper())
            .whileTrue(shooter.sysIdQuasistatic(SysIdRoutine.Direction.FORWARD))
        driverController
            .faceRight()
            .and(driverController.leftBumper())
            .whileTrue(shooter.sysIdQuasistatic(SysIdRoutine.Direction.REVERSE))
        driverController
            .faceLeft()
            .and(driverController.leftBumper())
            .whileTrue(shooter.sysIdDynamic(SysIdRoutine.Direction.FORWARD))
        driverController
            .faceUp()
            .and(driverController.leftBumper())
            .whileTrue(shooter.sysIdDynamic(SysIdRoutine.Direction.REVERSE))
    }

    /**
     * Use this to define the command that runs during autonomous.
     *
     * Scheduled during [Robot.autonomousInit].
     */
    fun getAutonomousCommand(): Command
    {
        // Do nothing
        return drive.run {}
    }
}

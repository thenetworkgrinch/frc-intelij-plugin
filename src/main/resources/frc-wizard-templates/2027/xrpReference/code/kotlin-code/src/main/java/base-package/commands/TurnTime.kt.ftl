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
package [=data.basePackage].commands

import org.wpilib.command2.Command
import [=data.basePackage].subsystems.Drivetrain

/*
 * Creates a new TurnTime command. This command will turn your robot for a
 * desired rotational velocity and time.
 */

/**
 * Creates a new TurnTime.
 *
 * @param velocity The velocity which the robot will turn. Negative is in reverse.
 * @param time How much time to turn in seconds
 * @param drive The drive subsystem on which this command will run
 */
class TurnTime(velocity: Double, time: Double, private val drive: Drivetrain) : Command()
{
    private val duration: Double = time * 1000
    private val rotationalVelocity: Double = velocity
    private var startTime: Long = 0

    init
    {
        addRequirements(drive)
    }

    // Called when the command is initially scheduled.
    override fun initialize()
    {
        startTime = System.currentTimeMillis()
        drive.arcadeDrive(0.0, 0.0)
    }

    // Called every time the scheduler runs while the command is scheduled.
    override fun execute()
    {
        drive.arcadeDrive(0.0, rotationalVelocity)
    }

    // Called once the command ends or is interrupted.
    override fun end(interrupted: Boolean)
    {
        drive.arcadeDrive(0.0, 0.0)
    }

    // Returns true when the command should end.
    override fun isFinished(): Boolean = (System.currentTimeMillis() - startTime) >= duration
}

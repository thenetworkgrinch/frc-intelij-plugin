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
import [=data.basePackage].subsystems.DriveSubsystem
import kotlin.math.abs

/**
 * Creates a new DriveDistance.
 *
 * @param inches The number of inches the robot will drive
 * @param velocity The velocity at which the robot will drive
 * @param drive The drive subsystem on which this command will run
 */
class DriveDistance(inches: Double, private val velocity: Double, private val drive: DriveSubsystem) : Command()
{
    private val distance: Double = inches

    init
    {
        addRequirements(drive)
    }

    override fun initialize()
    {
        drive.resetEncoders()
        drive.arcadeDrive(velocity, 0.0)
    }

    override fun execute()
    {
        drive.arcadeDrive(velocity, 0.0)
    }

    override fun end(interrupted: Boolean)
    {
        drive.arcadeDrive(0.0, 0.0)
    }

    override fun isFinished(): Boolean = abs(drive.averageEncoderDistance) >= distance
}

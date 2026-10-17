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

/**
 * A command to drive the robot with joystick input (passed in as `() -> Double` lambdas). Written
 * explicitly for pedagogical purposes - actual code should inline a command this simple with
 * [RunCommand][org.wpilib.command2.RunCommand].
 *
 * @param subsystem The drive subsystem this command wil run on.
 * @param forward The control input for driving forwards/backwards
 * @param rotation The control input for turning
 */
class DefaultDrive(
    subsystem: DriveSubsystem,
    private val forward: () -> Double,
    private val rotation: () -> Double,
                  ) : Command()
{
    private val drive: DriveSubsystem = subsystem

    init
    {
        addRequirements(drive)
    }

    override fun execute()
    {
        drive.arcadeDrive(forward(), rotation())
    }
}

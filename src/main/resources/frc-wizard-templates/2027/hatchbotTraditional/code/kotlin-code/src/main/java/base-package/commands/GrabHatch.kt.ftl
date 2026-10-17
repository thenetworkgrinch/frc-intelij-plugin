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
import [=data.basePackage].subsystems.HatchSubsystem

/**
 * A simple command that grabs a hatch with the [HatchSubsystem]. Written explicitly for
 * pedagogical purposes. Actual code should inline a command this simple with
 * [InstantCommand][org.wpilib.command2.InstantCommand].
 */
class GrabHatch(subsystem: HatchSubsystem) : Command()
{
    // The subsystem the command runs on
    private val hatchSubsystem: HatchSubsystem = subsystem

    init
    {
        addRequirements(hatchSubsystem)
    }

    override fun initialize()
    {
        hatchSubsystem.grabHatch()
    }

    override fun isFinished(): Boolean = true
}

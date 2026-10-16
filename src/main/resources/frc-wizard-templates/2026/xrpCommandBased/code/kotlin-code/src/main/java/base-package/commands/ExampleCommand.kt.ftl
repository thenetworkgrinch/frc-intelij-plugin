<#ftl output_format="plainText" encoding="UTF-8">
<#--noinspection WrongPackageStatement-->
<#compress>
<#-- @ftlvariable name="data" type="net.javaru.iip.frc.wizard.FrcProjectWizardData" -->
<#--
    IMPORTANT: This tempolate uses alternate square bracket interpolation syntax
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

import edu.wpi.first.wpilibj2.command.Command
import frc.robot.subsystems.XRPDrivetrain

/** An example command that uses the [XRPDrivetrain] subsystem. */
class ExampleCommand() : Command()
{
    init
    {
        // Use addRequirements() here to declare subsystem dependencies.
        addRequirements(XRPDrivetrain)
    }

    // Called when the command is initially scheduled.
    override fun initialize()
    {
    }

    // Called every time the scheduler runs while the command is scheduled.
    override fun execute()
    {
    }

    // Called once the command ends or is interrupted.
    override fun end(interrupted: Boolean)
    {
    }

    // Returns true when the command should end.
    override fun isFinished(): Boolean
    {
        return false
    }
}
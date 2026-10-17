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

import org.wpilib.command2.SequentialCommandGroup
import [=data.basePackage].subsystems.Drivetrain

/**
 * Creates a new Autonomous Drive based on time. This will drive out for a period of time, turn
 * around for time (equivalent to time to turn around) and drive forward again. This should mimic
 * driving out, turning around and driving back.
 *
 * @param drivetrain The drive subsystem on which this command will run
 */
class AutonomousTime(drivetrain: Drivetrain) : SequentialCommandGroup()
{
    init
    {
        addCommands(
            DriveTime(-0.6, 2.0, drivetrain),
            TurnTime(-0.5, 1.3, drivetrain),
            DriveTime(-0.6, 2.0, drivetrain),
            TurnTime(0.5, 1.3, drivetrain),
                   )
    }
}

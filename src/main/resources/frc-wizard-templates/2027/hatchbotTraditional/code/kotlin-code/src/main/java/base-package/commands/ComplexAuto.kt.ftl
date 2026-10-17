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
import [=data.basePackage].Constants.AutoConstants
import [=data.basePackage].subsystems.DriveSubsystem
import [=data.basePackage].subsystems.HatchSubsystem

/**
 * A complex auto command that drives forward, releases a hatch, and then drives backward.
 *
 * @param drive The drive subsystem this command will run on
 * @param hatch The hatch subsystem this command will run on
 */
class ComplexAuto(drive: DriveSubsystem, hatch: HatchSubsystem) : SequentialCommandGroup()
{
    init
    {
        addCommands(
            // Drive forward the specified distance
            DriveDistance(AutoConstants.AUTO_DRIVE_DISTANCE_INCHES, AutoConstants.AUTO_DRIVE_VELOCITY, drive),

            // Release the hatch
            ReleaseHatch(hatch),

            // Drive backward the specified distance
            DriveDistance(AutoConstants.AUTO_BACKUP_DISTANCE_INCHES, -AutoConstants.AUTO_DRIVE_VELOCITY, drive),
                   )
    }
}

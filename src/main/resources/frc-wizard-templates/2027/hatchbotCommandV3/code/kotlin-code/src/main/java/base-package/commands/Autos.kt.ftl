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

import org.wpilib.command3.Command
import [=data.basePackage].Constants.AutoConstants
import [=data.basePackage].mechanisms.DriveMechanism
import [=data.basePackage].mechanisms.HatchMechanism

/** Container for auto command factories. */
object Autos
{
    /** A simple auto routine that drives forward a specified distance and then stops. */
    fun simpleAuto(drive: DriveMechanism): Command
    {
        return drive.driveDistance(
            AutoConstants.AUTO_DRIVE_DISTANCE_INCHES, AutoConstants.AUTO_DRIVE_SPEED)
    }

    /** A complex auto routine that drives forward, drops a hatch, and then drives backward. */
    fun complexAuto(driveMechanism: DriveMechanism, hatchMechanism: HatchMechanism): Command
    {
        // NOTE: requirement behavior.
        // To require each mechanism for while it's active, replace `requiring` with `noRequirements`.
        return Command.requiring(driveMechanism, hatchMechanism)
            .executing { coro ->
                // Drive forward up to the front of the cargo ship
                coro.await(
                    driveMechanism.driveDistance(
                        AutoConstants.AUTO_DRIVE_DISTANCE_INCHES, AutoConstants.AUTO_DRIVE_SPEED))

                // Release the hatch
                coro.await(hatchMechanism.releaseHatchCommand())

                // Drive backward the specified distance
                coro.await(
                    driveMechanism.driveDistance(
                        AutoConstants.AUTO_BACKUP_DISTANCE_INCHES, AutoConstants.AUTO_DRIVE_SPEED))
            }
            .named("Complex Auto")
    }
}

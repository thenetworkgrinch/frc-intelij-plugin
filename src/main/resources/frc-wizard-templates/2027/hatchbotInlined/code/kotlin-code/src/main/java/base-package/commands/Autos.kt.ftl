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
import org.wpilib.command2.Commands
import org.wpilib.command2.FunctionalCommand
import [=data.basePackage].Constants.AutoConstants
import [=data.basePackage].subsystems.DriveSubsystem
import [=data.basePackage].subsystems.HatchSubsystem

/** Container for auto command factories. */
object Autos
{
    /** A simple auto routine that drives forward a specified distance, and then stops. */
    fun simpleAuto(drive: DriveSubsystem): Command =
        FunctionalCommand(
            // Reset encoders on command start
            drive::resetEncoders,
            // Drive forward while the command is executing
            { drive.arcadeDrive(AutoConstants.AUTO_DRIVE_VELOCITY, 0.0) },
            // Stop driving at the end of the command
            { _ -> drive.arcadeDrive(0.0, 0.0) },
            // End the command when the robot's driven distance exceeds the desired value
            { drive.averageEncoderDistance >= AutoConstants.AUTO_DRIVE_DISTANCE_INCHES },
            // Require the drive subsystem
            drive,
                         )

    /** A complex auto routine that drives forward, drops a hatch, and then drives backward. */
    fun complexAuto(driveSubsystem: DriveSubsystem, hatchSubsystem: HatchSubsystem): Command =
        Commands.sequence(
            // Drive forward up to the front of the cargo ship
            FunctionalCommand(
                // Reset encoders on command start
                driveSubsystem::resetEncoders,
                // Drive forward while the command is executing
                { driveSubsystem.arcadeDrive(AutoConstants.AUTO_DRIVE_VELOCITY, 0.0) },
                // Stop driving at the end of the command
                { _ -> driveSubsystem.arcadeDrive(0.0, 0.0) },
                // End the command when the robot's driven distance exceeds the desired value
                { driveSubsystem.averageEncoderDistance >= AutoConstants.AUTO_DRIVE_DISTANCE_INCHES },
                // Require the drive subsystem
                driveSubsystem,
                             ),

            // Release the hatch
            hatchSubsystem.releaseHatchCommand(),

            // Drive backward the specified distance
            FunctionalCommand(
                // Reset encoders on command start
                driveSubsystem::resetEncoders,
                // Drive backward while the command is executing
                { driveSubsystem.arcadeDrive(-AutoConstants.AUTO_DRIVE_VELOCITY, 0.0) },
                // Stop driving at the end of the command
                { _ -> driveSubsystem.arcadeDrive(0.0, 0.0) },
                // End the command when the robot's driven distance exceeds the desired value
                { driveSubsystem.averageEncoderDistance <= AutoConstants.AUTO_BACKUP_DISTANCE_INCHES },
                // Require the drive subsystem
                driveSubsystem,
                             ),
                         )
}

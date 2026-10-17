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
package [=data.basePackage].constants

import org.wpilib.units.Units.FeetPerSecond
import org.wpilib.units.Units.Inches
import org.wpilib.units.Units.RotationsPerSecond

import org.wpilib.math.geometry.Translation2d
import org.wpilib.math.kinematics.SwerveDriveKinematics
import org.wpilib.units.measure.AngularVelocity
import org.wpilib.units.measure.LinearVelocity

object DriveConstants
{
    // +X is front, +Y is left
    val FRONT_LEFT_MODULE_POSITION = Translation2d(Inches.of(10.5), Inches.of(10.5))
    val FRONT_RIGHT_MODULE_POSITION = Translation2d(Inches.of(10.5), Inches.of(-10.5))
    val BACK_LEFT_MODULE_POSITION = Translation2d(Inches.of(-10.5), Inches.of(10.5))
    val BACK_RIGHT_MODULE_POSITION = Translation2d(Inches.of(-10.5), Inches.of(-10.5))

    val KINEMATICS = SwerveDriveKinematics(
        FRONT_LEFT_MODULE_POSITION, FRONT_RIGHT_MODULE_POSITION,
        BACK_LEFT_MODULE_POSITION, BACK_RIGHT_MODULE_POSITION)

    val MAX_VELOCITY: LinearVelocity = FeetPerSecond.of(15.0)
    val MAX_TURN_RATE: AngularVelocity = RotationsPerSecond.of(1.5)

    // All drive IDs are odd, all turn IDs are even
    const val FRONT_LEFT_DRIVE_ID = 1
    const val FRONT_LEFT_TURN_ID = 2
    const val FRONT_RIGHT_DRIVE_ID = 3
    const val FRONT_RIGHT_TURN_ID = 4
    const val REAR_LEFT_DRIVE_ID = 5
    const val REAR_LEFT_TURN_ID = 6
    const val REAR_RIGHT_DRIVE_ID = 7
    const val REAR_RIGHT_TURN_ID = 8
}

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
package [=data.basePackage]

import kotlin.math.PI

/**
 * The Constants object provides a convenient place for teams to hold robot-wide numerical or boolean
 * constants. This object should not be used for any other purpose. All String, Boolean, and numeric
 * (Int, Long, Float, Double) constants should use `const val` definitions. Other constant types
 * should use `val` definitions. Do not put anything functional in this object.
 *
 * It is advised to import this object (or one of its nested objects) wherever the
 * constants are needed, to reduce verbosity.
 */
object Constants
{
    object DriveConstants
    {
        const val LEFT_MOTOR1_PORT = 0
        const val LEFT_MOTOR2_PORT = 1
        const val RIGHT_MOTOR1_PORT = 2
        const val RIGHT_MOTOR2_PORT = 3

        val LEFT_ENCODER_PORTS = intArrayOf(0, 1)
        val RIGHT_ENCODER_PORTS = intArrayOf(2, 3)
        const val LEFT_ENCODER_REVERSED = false
        const val RIGHT_ENCODER_REVERSED = true

        const val ENCODER_CPR = 1024
        const val WHEEL_DIAMETER_INCHES = 6.0
        const val ENCODER_DISTANCE_PER_PULSE =
            // Assumes the encoders are directly mounted on the wheel shafts
            (WHEEL_DIAMETER_INCHES * PI) / ENCODER_CPR
    }

    object HatchConstants
    {
        const val HATCH_SOLENOID_MODULE = 0
        val HATCH_SOLENOID_PORTS = intArrayOf(0, 1)
    }

    object AutoConstants
    {
        const val AUTO_DRIVE_DISTANCE_INCHES = 60.0
        const val AUTO_BACKUP_DISTANCE_INCHES = 20.0
        const val AUTO_DRIVE_VELOCITY = 0.5
    }

    object OIConstants
    {
        const val DRIVER_CONTROLLER_PORT = 0
    }
}

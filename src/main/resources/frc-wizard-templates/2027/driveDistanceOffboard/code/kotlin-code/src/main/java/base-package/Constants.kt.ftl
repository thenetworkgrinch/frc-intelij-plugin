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

/**
 * The Constants object provides a convenient place for teams to hold robot-wide numerical or boolean
 * constants. This object should not be used for any other purpose. All String, Boolean, and numeric
 * (Int, Long, Float, Double) constants should use `const` definitions. Do not put anything
 * functional in this object.
 *
 * It is advised to import this object (or one of its nested objects) wherever the
 * constants are needed, to reduce verbosity.
 */
object Constants
{
    object DriveConstants
    {
        const val DT = 0.02
        const val LEFT_MOTOR1_PORT = 0
        const val LEFT_MOTOR2_PORT = 1
        const val RIGHT_MOTOR1_PORT = 2
        const val RIGHT_MOTOR2_PORT = 3

        // These are example values only - DO NOT USE THESE FOR YOUR OWN ROBOT!
        // These characterization values MUST be determined either experimentally or theoretically
        // for *your* robot's drive.
        // The SysId tool provides a convenient method for obtaining these values for your robot.
        const val ks = 1.0 // V
        const val kv = 0.8 // V/(m/s)
        const val ka = 0.15 // V/(m/s²)

        const val kp = 1.0

        const val MAX_VELOCITY = 3.0 // m/s
        const val MAX_ACCELERATION = 3.0 // m/s²
    }

    object OIConstants
    {
        const val DRIVER_CONTROLLER_PORT = 0
    }
}

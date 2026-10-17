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

object ShooterConstants
{
    const val HOOD_MOTOR_ID = 10
    const val PRIMARY_SHOOTER_MOTOR_ID = 11
    const val SECONDARY_SHOOTER_MOTOR_ID = 12
    const val TERTIARY_SHOOTER_MOTOR_ID = 13
    const val QUATERNARY_SHOOTER_MOTOR_ID = 14

    const val HOOD_KP = 80.0

    /** Example motor velocity feedforward constant, in volts per RPM. */
    const val EXAMPLE_MOTOR_KV = 12.0 / 6000.0

    /** Voltage necessary to break static friction to get the flywheel moving. */
    const val FLYWHEEL_KS = 1.25

    const val FLYWHEEL_KP = 100.0
}

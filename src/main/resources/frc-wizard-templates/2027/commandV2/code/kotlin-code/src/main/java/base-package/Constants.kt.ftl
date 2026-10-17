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

/*
 * The Constants object provides a convenient place for teams to hold robot-wide numerical or boolean
 * constants. This object should not be used for any other purpose. All String, Boolean, and numeric
 * (Int, Long, Float, Double) constants should use `const val` definitions. Other constant types should
 * use `val` definitions. Do not put anything functional in this object.
 *
 * It is advised to import this object (or one of its nested objects) wherever the
 * constants are needed, to reduce verbosity.
 */
object Constants
{
    object OperatorConstants
    {
        const val DRIVER_CONTROLLER_PORT = 0
    }
}

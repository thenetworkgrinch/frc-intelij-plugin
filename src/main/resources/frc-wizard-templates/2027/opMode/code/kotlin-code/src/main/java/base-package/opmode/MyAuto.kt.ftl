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
package [=data.basePackage].opmode

import org.wpilib.opmode.Autonomous
import org.wpilib.opmode.PeriodicOpMode
import [=data.basePackage].Robot

/**
 * An example autonomous opmode.
 *
 * The [Robot] instance is passed into the opmode via the constructor. (Since [Robot] is a Kotlin
 * object, it can also be referenced directly.)
 */
@Autonomous(name = "My Auto", group = "Group 1")
class MyAuto(private val robot: Robot) : PeriodicOpMode()
{
    /*
     * This function runs periodically, using the same period as the Robot instance.
     *
     * Additional periodic functions may be configured with addPeriodic(),
     * which can have periods that differ from the main Robot instance.
     */
    override fun periodic()
    {
        // Put custom auto code here
    }
}

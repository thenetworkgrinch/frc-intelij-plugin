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
package [=data.basePackage].opmodes.auto

import [=data.basePackage].[=data.robotClassSimpleName]
import org.wpilib.opmode.Autonomous
import org.wpilib.opmode.OpMode

/**
 * Creates a new autonomous opmode that does nothing. This constructor is called automatically by
 * the OpModeRobot framework when the program starts up.
 *
 * @param robot The robot instance to control.
 */
@Autonomous
@Suppress("UNUSED_PARAMETER")
class DoNothingAuto(robot: [=data.robotClassSimpleName]) : OpMode
{
    init
    {
        // Robot mechanisms have idle default commands, so we don't need to do anything special
    }
}

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

import org.wpilib.opmode.PeriodicOpMode
import org.wpilib.opmode.Teleop
import [=data.basePackage].Robot

/**
 * An example teleoperated opmode.
 *
 * The [Robot] instance is passed into the opmode via the constructor. (Since [Robot] is a Kotlin
 * object, it can also be referenced directly.)
 */
@Teleop
class MyTeleop(private val robot: Robot) : PeriodicOpMode()
{
    override fun disabledPeriodic()
    {
        /* Called on every robot period while the robot is disabled. */
    }

    override fun start()
    {
        /* Called once when the robot is enabled. */
    }

    override fun periodic()
    {
        /* Called on every robot period while the robot is enabled. */
    }

    override fun end()
    {
        /* Called when the robot is disabled (after previously being enabled). */
    }

    override fun close()
    {
        /* Called when the opmode is de-selected / no additional methods will be called. */
    }
}

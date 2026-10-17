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

import org.wpilib.opmode.Autonomous
import org.wpilib.opmode.PeriodicOpMode
import org.wpilib.system.Timer

@Autonomous
class DefaultAutoMode(private val robot: [=data.robotClassSimpleName]) : PeriodicOpMode()
{
    private val timer = Timer()

    override fun start()
    {
        timer.reset()
        timer.start()
    }

    override fun periodic()
    {
        if (timer.get() < 2.0)
        {
            robot.motor0.setThrottle(0.5)
            robot.motor1.setThrottle(0.5)
        }
        else if (timer.get() < 4.0)
        {
            robot.motor0.setThrottle(0.9)
            robot.motor1.setThrottle(0.9)
        }
        else
        {
            robot.motor0.setThrottle(0.0)
            robot.motor1.setThrottle(0.0)
        }
    }
}

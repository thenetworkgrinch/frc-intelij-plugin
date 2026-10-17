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

import org.wpilib.driverstation.DriverStationDisplay
import org.wpilib.driverstation.DriverStationDisplay.Mode
import org.wpilib.opmode.PeriodicOpMode
import org.wpilib.opmode.Teleop
import org.wpilib.system.Timer

@Teleop(name = "Default Teleop")
class DefaultTeleop : PeriodicOpMode()
{
    private val timer = Timer()
    private var loopCount = 0

    /** Called once when the robot is enabled. */
    override fun start()
    {
        DriverStationDisplay.setMode(Mode.Line)
        timer.restart()
        loopCount = 0
    }

    /** Called periodically while the robot is enabled. */
    override fun periodic()
    {
        DriverStationDisplay.addLine("DriverStationDisplay line mode")
        DriverStationDisplay.addData("Runtime", "%.1f seconds", timer.get())
        DriverStationDisplay.addData("Loop Count", "%d", loopCount++)
        DriverStationDisplay.updateLines()
    }
}

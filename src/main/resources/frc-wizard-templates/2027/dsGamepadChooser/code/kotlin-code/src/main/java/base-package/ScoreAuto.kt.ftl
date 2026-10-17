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

import org.wpilib.driverstation.DSGamepadChooser
import org.wpilib.driverstation.DriverStationDisplay
import org.wpilib.driverstation.DriverStationDisplay.Mode
import org.wpilib.opmode.Autonomous
import org.wpilib.opmode.PeriodicOpMode

/** An autonomous opmode with chooser scoring parameters. */
@Autonomous(name = "Score Auto")
class ScoreAuto : PeriodicOpMode()
{
    private val chooser = DSGamepadChooser(0)
    private var target = "High"
    private var delay = 0
    private var speed = 0.25

    /** Creates a Score Auto opmode. */
    init
    {
        DriverStationDisplay.setMode(Mode.Line)
        chooser.addOptions("Target", listOf("High", "Mid", "Low"))
        chooser.addIntegerOptions("Delay", 0, 5, 1)
        chooser.addDoubleOptions("Speed", 0.25, 1.0, 0.25)
    }

    /** Called periodically while this opmode is selected and the robot is disabled. */
    override fun disabledPeriodic()
    {
        chooser.update()
        DriverStationDisplay.updateLines()
    }

    /** Called once when the robot transitions from disabled to enabled. */
    override fun start()
    {
        target = chooser.getSelected("Target")
        delay = chooser.getSelectedInteger("Delay")
        speed = chooser.getSelectedDouble("Speed")
    }

    /** Called periodically while this opmode is enabled. */
    override fun periodic()
    {
        DriverStationDisplay.addData("Selected Auto", "Score")
        DriverStationDisplay.addData("Target", target)
        DriverStationDisplay.addData("Delay", delay)
        DriverStationDisplay.addData("Speed", speed)
        DriverStationDisplay.updateLines()
    }
}

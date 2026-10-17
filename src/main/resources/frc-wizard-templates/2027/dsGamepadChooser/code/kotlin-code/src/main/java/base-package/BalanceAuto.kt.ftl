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

/** An autonomous opmode with chooser balance parameters. */
@Autonomous(name = "Balance Auto")
class BalanceAuto : PeriodicOpMode()
{
    private val chooser = DSGamepadChooser(0)
    private var approach = "Center"
    private var attempts = 1
    private var turnScale = 0.5

    /** Creates a Balance Auto opmode. */
    init
    {
        DriverStationDisplay.setMode(Mode.Line)
        chooser.addOptions("Approach", listOf("Left", "Center", "Right"))
        chooser.addIntegerOptions("Attempts", 1, 3, 1)
        chooser.addDoubleOptions("Turn Scale", 0.2, 1.0, 0.2)
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
        approach = chooser.getSelected("Approach")
        attempts = chooser.getSelectedInteger("Attempts")
        turnScale = chooser.getSelectedDouble("Turn Scale")
    }

    /** Called periodically while this opmode is enabled. */
    override fun periodic()
    {
        DriverStationDisplay.addData("Selected Auto", "Balance")
        DriverStationDisplay.addData("Approach", approach)
        DriverStationDisplay.addData("Attempts", attempts)
        DriverStationDisplay.addData("Turn Scale", turnScale)
        DriverStationDisplay.updateLines()
    }
}

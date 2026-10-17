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
    private var seconds = 0

    /** Called once when the robot is enabled. */
    override fun start()
    {
        DriverStationDisplay.setMode(Mode.RawAnsi)
        timer.restart()
        seconds = 0

        DriverStationDisplay.writeRawAnsi(
            "\u001b[2J\u001b[H" +
                "DriverStationDisplay ANSI mode\n" +
                "This header and footer stay on screen.\n" +
                "Seconds elapsed:      \n" +
                "Only the number above is rewritten.")
        updateSecondsDisplay()
    }

    /** Called periodically while the robot is enabled. */
    override fun periodic()
    {
        if (timer.advanceIfElapsed(1.0))
        {
            seconds++
            updateSecondsDisplay()
        }
    }

    private fun updateSecondsDisplay()
    {
        val color = COLORS[seconds % COLORS.size]
        DriverStationDisplay.writeRawAnsi("\u001b[3;18H\u001b[38;5;%dm%5d\u001b[0m".format(color, seconds))
    }

    companion object
    {
        private val COLORS = intArrayOf(
            196, 202, 208, 214, 220, 226, 118, 46, 48, 51,
            45, 39, 33, 27, 21, 57, 93, 129, 165, 201
        )
    }
}

<#ftl output_format="plainText" encoding="UTF-8">
<#--noinspection WrongPackageStatement-->
<#compress>
<#-- @ftlvariable name="data" type="net.javaru.iip.frc.wizard.FrcProjectWizardData" -->
<#--
    IMPORTANT: This tempolate uses alternate square bracket interpolation syntax
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

import edu.wpi.first.hal.DriverStationJNI
import edu.wpi.first.util.WPIUtilJNI
import edu.wpi.first.wpilibj.DriverStation
import edu.wpi.first.wpilibj.RobotBase
import edu.wpi.first.wpilibj.internal.DriverStationModeThread

/**
 * Educational robot base class. Do NOT use for competitions.
 * This is a simple robot used for teaching purposes.
 */
open class EducationalRobot : RobotBase() {

    open fun disabled() {}

    open fun run() {}

    open fun autonomous() {
        run()
    }

    open fun teleop() {
        run()
    }

    open fun test() {
        run()
    }

    @Volatile
    private var exit = false

    override fun startCompetition() {
        val modeThread = DriverStationModeThread()
        val event = WPIUtilJNI.createEvent(false, false)
        DriverStation.provideRefreshedDataEventHandle(event)

        // Tell the DS that the robot is ready to be enabled
        DriverStationJNI.observeUserProgramStarting()
        while (!Thread.currentThread().isInterrupted && !exit) {
            when {
                isDisabled -> {
                    modeThread.inDisabled(true)
                    disabled()
                    modeThread.inDisabled(false)
                    while (isDisabled) {
                        try {
                            WPIUtilJNI.waitForObject(event)
                        } catch (e: InterruptedException) {
                            Thread.currentThread().interrupt()
                        }
                    }
                }
                isAutonomous -> {
                    modeThread.inAutonomous(true)
                    autonomous()
                    modeThread.inAutonomous(false)
                    while (isAutonomousEnabled) {
                        try {
                            WPIUtilJNI.waitForObject(event)
                        } catch (e: InterruptedException) {
                            Thread.currentThread().interrupt()
                        }
                    }
                }
                isTest -> {
                    modeThread.inTest(true)
                    test()
                    modeThread.inTest(false)
                    while (isTest && isEnabled) {
                        try {
                            WPIUtilJNI.waitForObject(event)
                        } catch (e: InterruptedException) {
                            Thread.currentThread().interrupt()
                        }
                    }
                }
                else -> {
                    modeThread.inTeleop(true)
                    teleop()
                    modeThread.inTeleop(false)
                    while (isTeleopEnabled) {
                        try {
                            WPIUtilJNI.waitForObject(event)
                        } catch (e: InterruptedException) {
                            Thread.currentThread().interrupt()
                        }
                    }
                }
            }
        }
        DriverStation.removeRefreshedDataEventHandle(event)
        modeThread.close()
    }

    override fun endCompetition() {
        exit = true
    }
}
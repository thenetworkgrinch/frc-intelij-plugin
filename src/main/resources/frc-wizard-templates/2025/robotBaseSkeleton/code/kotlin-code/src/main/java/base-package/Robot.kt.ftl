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

import edu.wpi.first.hal.FRCNetComm.tInstances
import edu.wpi.first.hal.FRCNetComm.tResourceType
import edu.wpi.first.hal.HAL
import edu.wpi.first.wpilibj.DriverStation
import edu.wpi.first.wpilibj.RobotBase
import edu.wpi.first.wpilibj.internal.DriverStationModeThread
import edu.wpi.first.wpilibj.util.WPILibVersion
import edu.wpi.first.util.WPIUtilJNI
import edu.wpi.first.hal.DriverStationJNI

import java.lang.InterruptedException

/**
 * The VM is configured to automatically run this object (which basically function as a singleton class).
 * This is written as an object rather than a class since there should only ever be a single instance, and
 * it cannot take any constructor arguments. This makes it a natural fit to be an object in Kotlin.
 *
 * If you change the name of this object or its package after creating this project, you must also update
 * the `Main.kt` file in the project. (If you use the IDE's Rename or Move refactorings when renaming the
 * object or package, it will get changed everywhere.)
 */
object [=data.robotClassSimpleName] : RobotBase() {
    @Volatile
    private var exit = false

    init
    {
        // Kotlin initializer block, which effectually serves as the constructor code.
        // https://kotlinlang.org/docs/classes.html#constructors
        // This work can also be done in the inherited `robotInit()` method. But as of the 2025 season the 
        // `robotInit` method's Javadoc encourages using the constructor and the official templates
        // moved initialization code out `robotInit` and into the constructor. We follow suit in Kotlin.

        // Report the use of the Kotlin Language for "FRC Usage Report" statistics.
        // Please retain this line so that Kotlin's growing use by teams is seen by FRC/WPI.
        HAL.report(tResourceType.kResourceType_Language, tInstances.kLanguage_Kotlin, 0, WPILibVersion.Version)
    }
    
    private fun disabled() {  }
    private fun autonomous() {  }
    private fun teleop() {  }
    private fun test() {  }

    override fun startCompetition()
    {
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
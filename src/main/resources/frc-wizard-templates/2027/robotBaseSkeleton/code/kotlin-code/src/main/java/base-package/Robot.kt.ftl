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

import org.wpilib.driverstation.RobotState
import org.wpilib.driverstation.internal.DriverStationBackend
import org.wpilib.framework.RobotBase
import org.wpilib.hardware.hal.ControlWord
import org.wpilib.hardware.hal.HAL
import org.wpilib.hardware.hal.RobotMode
import org.wpilib.internal.DriverStationModeThread
import org.wpilib.util.WPIUtilJNI

/**
 * The VM is configured to automatically run this object (which basically functions as a singleton class).
 * This is written as an object rather than a class since there should only ever be a single instance, and
 * it cannot take any constructor arguments. This makes it a natural fit to be an object in Kotlin.
 *
 * If you change the name of this object or its package after creating this project, you must also update
 * the `Main.kt` file in the project. (If you use the IDE's Rename or Move refactorings when renaming the
 * object or package, it will get changed everywhere.)
 */
object [=data.robotClassSimpleName] : RobotBase()
{
    init
    {
        // Kotlin initializer block, which effectually serves as the constructor code.
        // https://kotlinlang.org/docs/classes.html#constructors

        // Report the use of the Kotlin Language for "FRC Usage Report" statistics.
        // Please retain this line so that Kotlin's growing use by teams is seen by FRC/WPI.
        HAL.reportUsage("Language", "Kotlin")
    }

    fun disabled() {}

    fun autonomous() {}

    fun teleop() {}

    fun utility() {}

    @Volatile
    private var exit = false

    override fun startCompetition()
    {
        // Create an opmode per robot mode
        RobotState.addOpMode(RobotMode.AUTONOMOUS, "Auto")
        RobotState.addOpMode(RobotMode.TELEOPERATED, "Teleop")
        RobotState.addOpMode(RobotMode.UTILITY, "Utility")
        RobotState.publishOpModes()

        val word = ControlWord()
        val modeThread = DriverStationModeThread(word)

        val event = WPIUtilJNI.makeEvent(false, false)

        DriverStationBackend.provideRefreshedDataEventHandle(event)

        // Tell the DS that the robot is ready to be enabled
        DriverStationBackend.observeUserProgramStarting()

        while (!Thread.currentThread().isInterrupted && !exit)
        {
            DriverStationBackend.refreshControlWordFromCache(word)
            modeThread.inControl(word)
            when
            {
                isDisabled()   ->
                {
                    disabled()
                    while (isDisabled())
                    {
                        try
                        {
                            WPIUtilJNI.waitForObject(event)
                        }
                        catch (e: InterruptedException)
                        {
                            Thread.currentThread().interrupt()
                        }
                    }
                }
                isAutonomous() ->
                {
                    autonomous()
                    while (isAutonomousEnabled())
                    {
                        try
                        {
                            WPIUtilJNI.waitForObject(event)
                        }
                        catch (e: InterruptedException)
                        {
                            Thread.currentThread().interrupt()
                        }
                    }
                }
                isUtility()    ->
                {
                    utility()
                    while (isUtility() && isEnabled())
                    {
                        try
                        {
                            WPIUtilJNI.waitForObject(event)
                        }
                        catch (e: InterruptedException)
                        {
                            Thread.currentThread().interrupt()
                        }
                    }
                }
                else           ->
                {
                    teleop()
                    while (isTeleopEnabled())
                    {
                        try
                        {
                            WPIUtilJNI.waitForObject(event)
                        }
                        catch (e: InterruptedException)
                        {
                            Thread.currentThread().interrupt()
                        }
                    }
                }
            }
        }

        DriverStationBackend.removeRefreshedDataEventHandle(event)
        modeThread.close()
    }

    override fun endCompetition()
    {
        exit = true
    }
}

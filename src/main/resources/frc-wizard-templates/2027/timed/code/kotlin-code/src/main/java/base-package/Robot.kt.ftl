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

import org.wpilib.framework.TimedRobot
import org.wpilib.hardware.hal.HAL
import org.wpilib.tunable.Selectable
import org.wpilib.tunable.Tunables

/**
 * The functions in this object (which basically functions as a singleton class) are called automatically
 * corresponding to each mode, as described in the TimedRobot documentation.
 * This is written as an object rather than a class since there should only ever be a single instance, and
 * it cannot take any constructor arguments. This makes it a natural fit to be an object in Kotlin.
 *
 * If you change the name of this object or its package after creating this project, you must also update
 * the `Main.kt` file in the project. (If you use the IDE's Rename or Move refactorings when renaming the
 * object or package, it will get changed everywhere.)
 */
object [=data.robotClassSimpleName] : TimedRobot()
{
    private var selectedAutoMode = AutoMode.default
    private val autoModeChooser = Selectable<AutoMode>().also { chooser ->
        chooser.addDefault(AutoMode.default.optionName, AutoMode.default)
        AutoMode.entries.filter { it != AutoMode.default }.forEach { chooser.add(it.optionName, it) }
    }

    /**
     * A enumeration of the available autonomous modes.
     *
     * @param optionName The name for the [autoModeChooser] option.
     * @param periodicFunction The function that is called in the [autonomousPeriodic] function each time it is called.
     * @param autoInitFunction An optional function that is called in the [autonomousInit] function.
     */
    private enum class AutoMode(val optionName: String,
                                val periodicFunction: () -> Unit,
                                val autoInitFunction: () -> Unit = { /* No op by default */ } )
    {
        CUSTOM_AUTO_1("Custom Auto Mode 1", ::autoMode1),
        CUSTOM_AUTO_2("Custom Auto Mode 2", ::autoMode2),
        ;
        companion object
        {
            /** The default auto mode. */
            val default = CUSTOM_AUTO_1
        }
    }

    init
    {
        // Kotlin initializer block, which effectually serves as the constructor code.
        // https://kotlinlang.org/docs/classes.html#constructors

        // Report the use of the Kotlin Language for "FRC Usage Report" statistics.
        // Please retain this line so that Kotlin's growing use by teams is seen by FRC/WPI.
        HAL.reportUsage("Language", "Kotlin")
        Tunables.publish("Auto choices", autoModeChooser)
    }

    /**
     * This method is called every 20 ms, no matter the mode. Use this for items like
     * diagnostics that you want ran during disabled, autonomous, teleoperated and utility.
     *
     * This runs after the mode specific periodic methods, but before LiveWindow and
     * SmartDashboard integrated updating.
     */
    override fun robotPeriodic() {}

    override fun autonomousInit()
    {
        /* This autonomousInit function (along with the autoModeChooser above) shows how to select
        between different autonomous modes using the dashboard. You can add additional auto modes by
        adding additional options to the AutoMode enum. */
        selectedAutoMode = autoModeChooser.selected ?: AutoMode.default
        println("Selected auto mode: ${selectedAutoMode.optionName}")
        selectedAutoMode.autoInitFunction.invoke()
    }

    /** This method is called periodically during autonomous.  */
    override fun autonomousPeriodic() = selectedAutoMode.periodicFunction.invoke()

    private fun autoMode1()
    {
        // Put custom auto mode 1 code here
    }

    private fun autoMode2()
    {
        // Put custom auto mode 2 code here
    }

    /** This method is called once when teleop is enabled.  */
    override fun teleopInit() {}

    /** This method is called periodically during operator control.  */
    override fun teleopPeriodic() {}

    /** This method is called once when the robot is disabled.  */
    override fun disabledInit() {}

    /** This method is called periodically when disabled.  */
    override fun disabledPeriodic() {}

    /** This method is called once when utility mode is enabled.  */
    override fun utilityInit() {}

    /** This method is called periodically during utility mode.  */
    override fun utilityPeriodic() {}

    /** This method is called once when the robot is first started up.  */
    override fun simulationInit() {}

    /** This method is called periodically whilst in simulation.  */
    override fun simulationPeriodic() {}
}

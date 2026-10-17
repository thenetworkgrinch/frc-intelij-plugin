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

import org.wpilib.framework.TimesliceRobot
import org.wpilib.hardware.hal.HAL
import org.wpilib.tunable.Selectable
import org.wpilib.tunable.Tunables

/**
 * The functions in this object (which basically functions as a singleton class) are called automatically
 * corresponding to each mode, as described in the TimesliceRobot documentation.
 * This is written as an object rather than a class since there should only ever be a single instance, and
 * it cannot take any constructor arguments. This makes it a natural fit to be an object in Kotlin.
 *
 * If you change the name of this object or its package after creating this project, you must also update
 * the `Main.kt` file in the project. (If you use the IDE's Rename or Move refactorings when renaming the
 * object or package, it will get changed everywhere.)
 *
 * The call to the `TimesliceRobot(0.005, 0.01)` constructor runs the robot periodic() functions
 * for 5 ms, and runs controllers every 10 ms.
 */
object [=data.robotClassSimpleName] : TimesliceRobot(0.005, 0.01)
{
    private var selectedAutoMode = AutoMode.default
    private val autoModeChooser = Selectable<AutoMode>().also { chooser ->
        chooser.addDefault(AutoMode.default.optionName, AutoMode.default)
        AutoMode.entries.filter { it != AutoMode.default }.forEach { chooser.add(it.optionName, it) }
    }

    /**
     * An enumeration of the available autonomous modes.
     *
     * @param optionName The name for the [autoModeChooser] option.
     * @param periodicFunction The function that is called in the [autonomousPeriodic] function each time it is called.
     */
    private enum class AutoMode(val optionName: String, val periodicFunction: () -> Unit)
    {
        DEFAULT_AUTO("Default Auto", ::defaultAuto),
        CUSTOM_AUTO("My Auto", ::customAuto),
        ;

        companion object
        {
            /** The default auto mode. */
            val default = DEFAULT_AUTO
        }
    }

    init
    {
        // Kotlin initializer block, which effectually serves as the constructor code.
        // https://kotlinlang.org/docs/classes.html#constructors
        // It is run when the robot is first started up and should be used for any initialization code.

        // Report the use of the Kotlin Language for "FRC Usage Report" statistics.
        // Please retain this line so that Kotlin's growing use by teams is seen by FRC/WPI.
        HAL.reportUsage("Language", "Kotlin")

        // Runs for 2 ms after robot periodic functions
        schedule({}, 0.002)

        // Runs for 2 ms after first controller function
        schedule({}, 0.002)

        // Total usage: 5 ms (robot) + 2 ms (controller 1) + 2 ms (controller 2)
        // = 9 ms -> 90% allocated

        Tunables.publish("Auto choices", autoModeChooser)
    }

    /**
     * This function is called every robot packet, no matter the mode. Use this for items like
     * diagnostics that you want ran during disabled, autonomous, teleoperated and utility.
     *
     * This runs after the mode specific periodic functions, but before LiveWindow and
     * SmartDashboard integrated updating.
     */
    override fun robotPeriodic() {}

    /**
     * This autonomous (along with the chooser code above) shows how to select between different
     * autonomous modes using the dashboard. You can add additional auto modes by adding additional
     * entries to the [AutoMode] enum; each entry is automatically added to the chooser.
     *
     * If you prefer the LabVIEW Dashboard, remove all of the chooser code and uncomment the
     * getString line to get the auto name from the text box below the Gyro.
     */
    override fun autonomousInit()
    {
        selectedAutoMode = autoModeChooser.selected ?: AutoMode.default
        // selectedAutoMode = AutoMode.valueOf(SmartDashboard.getString("Auto Selector", AutoMode.default.name))
        println("Auto selected: ${selectedAutoMode.optionName}")
    }

    /** This function is called periodically during autonomous. */
    override fun autonomousPeriodic() = selectedAutoMode.periodicFunction.invoke()

    private fun defaultAuto()
    {
        // Put default auto code here
    }

    private fun customAuto()
    {
        // Put custom auto code here
    }

    /** This function is called once when teleop is enabled. */
    override fun teleopInit() {}

    /** This function is called periodically during operator control. */
    override fun teleopPeriodic() {}

    /** This function is called once when the robot is disabled. */
    override fun disabledInit() {}

    /** This function is called periodically when disabled. */
    override fun disabledPeriodic() {}

    /** This function is called once when utility mode is enabled. */
    override fun utilityInit() {}

    /** This function is called periodically during utility mode. */
    override fun utilityPeriodic() {}
}

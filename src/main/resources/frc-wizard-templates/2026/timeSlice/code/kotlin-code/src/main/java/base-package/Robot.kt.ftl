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
import edu.wpi.first.wpilibj.TimesliceRobot
import edu.wpi.first.wpilibj.livewindow.LiveWindow
import edu.wpi.first.wpilibj.smartdashboard.SendableChooser
import edu.wpi.first.wpilibj.smartdashboard.SmartDashboard
import edu.wpi.first.wpilibj.util.WPILibVersion

/**
 * The VM is configured to automatically run this object (which basically functions as a singleton class),
 * and to call the functions corresponding to each mode, as described in the TimesliceRobot documentation.
 * This is written as an object rather than a class since there should only ever be a single instance, and
 * it cannot take any constructor arguments. This makes it a natural fit to be an object in Kotlin.
 *
 * If you change the name of this object or its package after creating this project, you must also update
 * the `Main.kt` file in the project. (If you use the IDE's Rename or Move refactorings when renaming the
 * object or package, it will get changed everywhere.)
 *
 * The call to the `TimesliceRobot()` constructor sets the `robotPeriodicAllocation` and `controllerPeriod`.
 */
object [=data.robotClassSimpleName] : TimesliceRobot(0.005, 0.01)
{
    private const val DEFAULT_AUTO = "Default"
    private const val CUSTOM_AUTO = "My Auto"
    private var autoSelected: String? = null
    private val chooser = SendableChooser<String>()

    init
    {
        // Super constructor call:  Run robot periodic() method for 5 ms, and run controllers every 10 ms

        // LiveWindow causes drastic overruns in robot periodic method that will
        // interfere with controllers
        LiveWindow.disableAllTelemetry()

        // Runs for 2 ms after robot periodic method
        schedule({}, 0.002)

        // Runs for 2 ms after first controller method
        schedule({}, 0.002)

        // Total usage: 5 ms (robot) + 2 ms (controller 1) + 2 ms (controller 2)
        // = 9 ms -> 90% allocated
    }

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
        chooser.setDefaultOption("Default Auto", DEFAULT_AUTO)
        chooser.addOption("My Auto", CUSTOM_AUTO)
        SmartDashboard.putData("Auto choices", chooser)
    }

    /**
     * This function is called every 20 ms, no matter the mode. Use this for items like diagnostics
     * that you want ran during disabled, autonomous, teleoperated and test.
     *
     *
     * This runs after the mode specific periodic methods, but before LiveWindow and
     * SmartDashboard integrated updating.
     */
    override fun robotPeriodic() {}

    /**
     * This autonomous (along with the chooser code above) shows how to select between different
     * autonomous modes using the dashboard. The sendable chooser code works with the Java
     * SmartDashboard. If you prefer the LabVIEW Dashboard, remove all the chooser code and
     * uncomment the getString line to get the auto name from the text box below the Gyro
     *
     * You can add additional auto modes by adding additional comparisons to the switch structure
     * below with additional strings. If using the SendableChooser, make sure to add them to the
     * chooser code above as well.
     */
    override fun autonomousInit()
    {
        autoSelected = chooser.selected
        // autoSelected = SmartDashboard.getString("Auto Selector", DEFAULT_AUTO);
        println("Auto selected: $autoSelected")
    }

    /** This method is called periodically during autonomous.  */
    override fun autonomousPeriodic()
    {
        when (autoSelected) {
            CUSTOM_AUTO -> { TODO("CUSTOM_AUTO is not implemented yet") }
            DEFAULT_AUTO -> {  TODO("DEFAULT_AUTO is not implemented yet") }
            else -> {}
        }
    }

    /** This method is called once when teleop is enabled.  */
    override fun teleopInit() {}

    /** This method is called periodically during operator control.  */
    override fun teleopPeriodic() {}

    /** This method is called once when the robot is disabled.  */
    override fun disabledInit() {}

    /** This method is called periodically when disabled.  */
    override fun disabledPeriodic() {}

    /** This method is called once when test mode is enabled.  */
    override fun testInit() {}

    /** This method is called periodically during test mode.  */
    override fun testPeriodic() {}
}
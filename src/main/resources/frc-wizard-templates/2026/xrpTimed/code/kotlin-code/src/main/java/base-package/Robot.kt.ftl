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

import edu.wpi.first.wpilibj.TimedRobot
import edu.wpi.first.wpilibj.smartdashboard.SendableChooser
import edu.wpi.first.wpilibj.smartdashboard.SmartDashboard
import edu.wpi.first.wpilibj.util.WPILibVersion

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
    private const val DEFAULT_AUTO = "Default"
    private const val CUSTOM_AUTO = "My Auto"
    private var autoSelected: String? = null
    private val chooser = SendableChooser<String>()

    init
    {
        chooser.setDefaultOption("Default Auto", DEFAULT_AUTO)
        chooser.addOption("My Auto", CUSTOM_AUTO)
        SmartDashboard.putData("Auto choices", chooser)
    }

    /**
     * This function is called every 20 ms, no matter the mode. Use this for items like
     * diagnostics that you want ran during disabled, autonomous, teleoperated and test.
     *
     * This runs after the mode specific periodic functions, but before LiveWindow and
     * SmartDashboard integrated updating.
     */
    override fun robotPeriodic()
    {

    }

    /**
     * This autonomous (along with the chooser code above) shows how to select between different
     * autonomous modes using the dashboard. The sendable chooser code works with the Java
     * SmartDashboard. If you prefer the LabVIEW Dashboard, remove all the chooser code and
     * uncomment the getString line to get the auto name from the text box below the Gyro
     *
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
        XRPDrivetrain.resetEncoders()
    }

    /** This function is called periodically during autonomous.  */
    override fun autonomousPeriodic()
    {
        when (autoSelected) {
            CUSTOM_AUTO -> { TODO("CUSTOM_AUTO is not implemented yet") }
            DEFAULT_AUTO -> {  TODO("DEFAULT_AUTO is not implemented yet") }
            else -> {}
        }
    }

    /** This function is called once when teleop is enabled.  */
    override fun teleopInit()
    {

    }

    /** This function is called periodically during operator control.  */
    override fun teleopPeriodic()
    {

    }

    /** This function is called once when the robot is disabled.  */
    override fun disabledInit()
    {

    }

    /** This function is called periodically when disabled.  */
    override fun disabledPeriodic()
    {

    }

    /** This function is called once when test mode is enabled.  */
    override fun testInit()
    {

    }
}
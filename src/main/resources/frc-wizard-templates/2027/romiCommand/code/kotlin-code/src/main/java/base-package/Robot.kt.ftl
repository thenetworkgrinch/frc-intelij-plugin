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

import org.wpilib.command2.Command
import org.wpilib.command2.CommandScheduler
import org.wpilib.framework.TimedRobot
import org.wpilib.hardware.hal.HAL

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
    /** The autonomous command to run. It is set in [autonomousInit]. */
    private var autonomousCommand: Command? = null

    init
    {
        // Kotlin initializer block, which effectually serves as the constructor code.
        // https://kotlinlang.org/docs/classes.html#constructors
        // It is run when the robot is first started up and should be used for any initialization code.

        // Report the use of the Kotlin Language for "FRC Usage Report" statistics.
        // Please retain this line so that Kotlin's growing use by teams is seen by FRC/WPI.
        HAL.reportUsage("Language", "Kotlin")

        // Access the RobotContainer object so that it is initialized. This will perform all our button
        // bindings, and put our autonomous chooser on the dashboard.
        RobotContainer
    }

    /**
     * This function is called every 20 ms, no matter the mode. Use this for items like diagnostics
     * that you want ran during disabled, autonomous, teleoperated and utility.
     *
     * This runs after the mode specific periodic functions, but before LiveWindow and
     * SmartDashboard integrated updating.
     */
    override fun robotPeriodic()
    {
        // Runs the Scheduler.  This is responsible for polling buttons, adding newly-scheduled
        // commands, running already-scheduled commands, removing finished or interrupted commands,
        // and running subsystem periodic() methods.  This must be called from the robot's periodic
        // block in order for anything in the Command-based framework to work.
        CommandScheduler.getInstance().run()
    }

    /** This function is called once each time the robot enters Disabled mode. */
    override fun disabledInit() {}

    override fun disabledPeriodic() {}

    /** This autonomous runs the autonomous command selected by your [RobotContainer] object. */
    override fun autonomousInit()
    {
        autonomousCommand = RobotContainer.getAutonomousCommand()

        // schedule the autonomous command (example)
        autonomousCommand?.let { CommandScheduler.getInstance().schedule(it) }
    }

    /** This function is called periodically during autonomous. */
    override fun autonomousPeriodic() {}

    override fun autonomousExit()
    {
        // This makes sure that the autonomous stops running when
        // autonomous mode ends. If you want the autonomous to
        // continue until interrupted by another command, remove
        // this line or comment it out.
        autonomousCommand?.cancel()
    }

    /** This function is called once each time the robot enters operator control. */
    override fun teleopInit() {}

    /** This function is called periodically during operator control. */
    override fun teleopPeriodic() {}

    override fun utilityInit()
    {
        // Cancels all running commands at the start of utility mode.
        CommandScheduler.getInstance().cancelAll()
    }

    /** This function is called periodically during utility mode. */
    override fun utilityPeriodic() {}
}

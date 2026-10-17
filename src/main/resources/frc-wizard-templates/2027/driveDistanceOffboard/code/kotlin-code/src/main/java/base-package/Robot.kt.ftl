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
 * corresponding to each mode, as described in the TimedRobot documentation. If you change the name of
 * this object or its package after creating this project, you must also update the `Main.kt` file in
 * the project.
 */
object [=data.robotClassSimpleName] : TimedRobot()
{
    private var autonomousCommand: Command? = null

    private val robotContainer: RobotContainer

    /**
     * This initializer block is run when the robot is first started up and should be used for any
     * initialization code.
     */
    init
    {
        // Report the use of the Kotlin Language for "FRC Usage Report" statistics.
        // Please retain this line so that Kotlin's growing use by teams is seen by FRC/WPI.
        HAL.reportUsage("Language", "Kotlin")

        // Instantiate our RobotContainer.  This will perform all our button bindings, and put our
        // autonomous chooser on the dashboard.
        robotContainer = RobotContainer()
    }

    /**
     * This method is called every 20 ms, no matter the mode. Use this for items like diagnostics
     * that you want ran during disabled, autonomous, teleoperated and test.
     *
     * This runs after the mode specific periodic methods, but before LiveWindow and
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

    /** This method is called once each time the robot enters Disabled mode. */
    override fun disabledInit() {}

    override fun disabledPeriodic() {}

    /** This autonomous runs the autonomous command selected by your [RobotContainer] class. */
    override fun autonomousInit()
    {
        autonomousCommand = robotContainer.getAutonomousCommand()

        /*
         * val autoSelected = SmartDashboard.getString("Auto Selector", "Default")
         * autonomousCommand = when (autoSelected) {
         *     "My Auto" -> MyAutoCommand()
         *     "Default Auto" -> ExampleCommand()
         *     else -> ExampleCommand()
         * }
         */

        // schedule the autonomous command (example)
        autonomousCommand?.let { CommandScheduler.getInstance().schedule(it) }
    }

    /** This method is called periodically during autonomous. */
    override fun autonomousPeriodic() {}

    override fun autonomousExit()
    {
        // This makes sure that the autonomous stops running when
        // autonomous mode ends. If you want the autonomous to
        // continue until interrupted by another command, remove
        // this line or comment it out.
        autonomousCommand?.cancel()
    }

    /** This method is called once each time the robot enters operator control. */
    override fun teleopInit() {}

    /** This method is called periodically during operator control. */
    override fun teleopPeriodic() {}

    override fun utilityInit()
    {
        // Cancels all running commands at the start of utility mode.
        CommandScheduler.getInstance().cancelAll()
    }

    /** This method is called periodically during utility mode. */
    override fun utilityPeriodic() {}
}

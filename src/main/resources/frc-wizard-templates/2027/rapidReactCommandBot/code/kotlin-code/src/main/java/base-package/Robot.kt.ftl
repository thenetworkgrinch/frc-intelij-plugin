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
import org.wpilib.epilogue.Epilogue
import org.wpilib.epilogue.Logged
import org.wpilib.framework.TimedRobot
import org.wpilib.hardware.hal.HAL
import org.wpilib.system.DataLogManager

/**
 * The functions in this object (which basically functions as a singleton class) are called automatically
 * corresponding to each mode, as described in the TimedRobot documentation. If you change the name of
 * this object or its package after creating this project, you must also update the `Main.kt` file in
 * the project.
 */
@Logged(name = "Rapid React Command Robot")
object [=data.robotClassSimpleName] : TimedRobot()
{
    // These are public so that Epilogue logs them: a Kotlin object keeps its properties in static
    // fields, which Epilogue does not log, so they are logged through their getters instead.
    @get:Logged(name = "autonomousCommand")
    var autonomousCommand: Command? = null
        private set

    @get:Logged(name = "robot")
    val robot = RapidReactCommandBot()

    /**
     * This initializer block is run when the robot is first started up and should be used for any
     * initialization code.
     */
    init
    {
        // Report the use of the Kotlin Language for "FRC Usage Report" statistics.
        // Please retain this line so that Kotlin's growing use by teams is seen by FRC/WPI.
        HAL.reportUsage("Language", "Kotlin")

        // Configure default commands and condition bindings on robot startup
        robot.configureBindings()

        // Initialize data logging.
        DataLogManager.start()
        Epilogue.bind(this)
    }

    /**
     * This method is called every robot packet, no matter the mode. Use this for items like
     * diagnostics that you want ran during disabled, autonomous, teleoperated and test.
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

    override fun autonomousInit()
    {
        autonomousCommand = robot.getAutonomousCommand()

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

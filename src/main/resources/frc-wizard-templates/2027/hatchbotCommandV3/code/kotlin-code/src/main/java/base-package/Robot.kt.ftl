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

import org.wpilib.command3.Command
import org.wpilib.command3.Scheduler
import org.wpilib.command3.button.CommandGamepad
import org.wpilib.driverstation.DriverStation
import [=data.basePackage].commands.Autos
import [=data.basePackage].mechanisms.DriveMechanism
import [=data.basePackage].mechanisms.HatchMechanism
import org.wpilib.framework.TimedRobot
import org.wpilib.hardware.hal.HAL
import org.wpilib.system.DataLogManager
import org.wpilib.telemetry.Telemetry
import org.wpilib.tunable.Selectable
import org.wpilib.tunable.Tunables

/**
 * The functions in this object (which basically functions as a singleton class) are called automatically
 * corresponding to each mode, as described in the TimedRobot documentation. If you change the name of this
 * object or its package after creating this project, you must also update the `Main.kt` file in the project.
 */
object [=data.robotClassSimpleName] : TimedRobot()
{
    /**
     * A chooser for autonomous commands. Drivers can choose between different autonomous modes on a
     * dashboard before the start of a match.
     */
    private val autonomousChooser = Selectable<Command>()

    // The driver's controller
    private val driverController = CommandGamepad(Constants.OIConstants.DRIVER_CONTROLLER_PORT)

    // The robot's mechanisms
    private val robotDrive = DriveMechanism()
    private val hatchMechanism = HatchMechanism()

    /**
     * This initializer block is run when the robot is first started up and should be used for any
     * initialization code.
     */
    init
    {
        // Report the use of the Kotlin Language for "FRC Usage Report" statistics.
        // Please retain this line so that Kotlin's growing use by teams is seen by FRC/WPI.
        HAL.reportUsage("Language", "Kotlin")

        // Configure the button bindings
        configureButtonBindings()

        // Configure default commands
        // Set the default drive command to split-stick arcade drive with forward/backward controlled by
        // the left hand, and turning controlled by the right.
        robotDrive.setDefaultCommand(
            robotDrive.arcadeDrive({ -driverController.leftY }, { -driverController.rightX }))

        // Add commands to the autonomous command chooser
        autonomousChooser.addDefault("Simple Auto", Autos.simpleAuto(robotDrive))
        autonomousChooser.add("Complex Auto", Autos.complexAuto(robotDrive, hatchMechanism))

        // Put the chooser on the dashboard
        Tunables.publish("Autonomous", autonomousChooser)

        // Start recording to data log
        DataLogManager.start()

        // Record DS control and joystick data.
        // Change to `false` to not record joystick data.
        DriverStation.startDataLog(DataLogManager.getLog(), true)
    }

    /** Use this function to define your button->command mappings. */
    private fun configureButtonBindings()
    {
        // Grab the hatch when the Circle button is pressed.
        driverController.faceRight().onTrue(hatchMechanism.grabHatchCommand())
        // Release the hatch when the Square button is pressed.
        driverController.faceLeft().onTrue(hatchMechanism.releaseHatchCommand())
        // While holding R1, drive at half speed
        driverController
            .rightBumper()
            .onTrue(Command.noRequirements { _ -> robotDrive.setMaxOutput(0.5) }.named("Set half speed"))
            .onFalse(Command.noRequirements { _ -> robotDrive.setMaxOutput(1.0) }.named("Set full speed"))
    }

    /**
     * This function is called every 20 ms, no matter the mode. Use this for items like diagnostics
     * that you want ran during disabled, autonomous, teleoperated and test.
     *
     * This runs after the mode specific periodic functions, but before LiveWindow and
     * SmartDashboard integrated updating.
     */
    override fun robotPeriodic()
    {
        // Runs the scheduler.  This is responsible for polling buttons, running scheduled commands,
        // and removing finished or interrupted commands.
        // This must be called from the robot's periodic block in order for anything in the
        // Command-based framework to work.
        Scheduler.getDefault().run()
        Telemetry.log("Drivetrain", robotDrive)
        Telemetry.log("HatchMechanism", hatchMechanism)
    }

    /** This function is called once each time the robot enters Disabled mode. */
    override fun disabledInit() {}

    override fun disabledPeriodic() {}

    /** This autonomous runs the autonomous command selected by the [autonomousChooser]. */
    override fun autonomousInit()
    {
        val autonomousCommand: Command? = autonomousChooser.selected

        // Schedule the autonomous command.
        // Because we schedule this command in the autonomous mode, it will be automatically canceled
        // when the autonomous mode ends.
        if (autonomousCommand != null)
        {
            Scheduler.getDefault().schedule(autonomousCommand)
        }
    }

    /** This function is called periodically during autonomous. */
    override fun autonomousPeriodic() {}

    override fun teleopInit() {}

    /** This function is called periodically during operator control. */
    override fun teleopPeriodic() {}

    override fun utilityInit()
    {
        // Cancel all running commands at the start of utility mode.
        Scheduler.getDefault().cancelAll()
    }

    /** This function is called periodically during utility mode. */
    override fun utilityPeriodic() {}
}

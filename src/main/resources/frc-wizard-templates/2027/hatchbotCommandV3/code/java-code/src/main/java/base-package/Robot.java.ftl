<#ftl output_format="plainText" encoding="UTF-8">
<#--noinspection WrongPackageStatement-->
<#compress>
<#-- @ftlvariable name="data" type="net.javaru.iip.frc.wizard.FrcProjectWizardData" -->
<#--
    Template Language Reference: https://freemarker.apache.org/docs/ref.html
    Template Author's Guide:     https://freemarker.apache.org/docs/dgui.html
-->
<#--  To DEBUG templates, set system property 'frc.freemarker.debug' to true when launching the testing instance of IntelliJ IDEA -->
</#compress>
${data.copyright}

package ${data.basePackage};

import org.wpilib.command3.Command;
import org.wpilib.command3.Scheduler;
import org.wpilib.command3.button.CommandGamepad;
import org.wpilib.driverstation.DriverStation;
import ${data.basePackage}.commands.Autos;
import ${data.basePackage}.mechanisms.DriveMechanism;
import ${data.basePackage}.mechanisms.HatchMechanism;
import org.wpilib.framework.TimedRobot;
import org.wpilib.system.DataLogManager;
import org.wpilib.telemetry.Telemetry;
import org.wpilib.tunable.Selectable;
import org.wpilib.tunable.Tunables;

/**
 * The methods in this class are called automatically corresponding to each mode, as described in
 * the TimedRobot documentation. If you change the name of this class or the package after creating
 * this project, you must also update the Main.java file in the project.
 */
public class ${data.robotClassSimpleName} extends TimedRobot {
  /**
   * A chooser for autonomous commands. Drivers can choose between different autonomous modes on a
   * dashboard before the start of a match.
   */
  private final Selectable<Command> autonomousChooser = new Selectable<>();

  // The driver's controller
  private final CommandGamepad driverController =
      new CommandGamepad(Constants.OIConstants.DRIVER_CONTROLLER_PORT);

  // The robot's mechanisms
  private final DriveMechanism robotDrive = new DriveMechanism();
  private final HatchMechanism hatchMechanism = new HatchMechanism();

  /**
   * This constructor is run when the robot is first started up and should be used for any
   * initialization code.
   */
  public Robot() {
    // Configure the button bindings
    configureButtonBindings();

    // Configure default commands
    // Set the default drive command to split-stick arcade drive with forward/backward controlled by
    // the left hand, and turning controlled by the right.
    robotDrive.setDefaultCommand(
        robotDrive.arcadeDrive(
            () -> -driverController.getLeftY(), () -> -driverController.getRightX()));

    // Add commands to the autonomous command chooser
    autonomousChooser.addDefault("Simple Auto", Autos.simpleAuto(robotDrive));
    autonomousChooser.add("Complex Auto", Autos.complexAuto(robotDrive, hatchMechanism));

    // Put the chooser on the dashboard
    Tunables.publish("Autonomous", autonomousChooser);

    // Start recording to data log
    DataLogManager.start();

    // Record DS control and joystick data.
    // Change to `false` to not record joystick data.
    DriverStation.startDataLog(DataLogManager.getLog(), true);
  }

  /** Use this method to define your button->command mappings. */
  private void configureButtonBindings() {
    // Grab the hatch when the Circle button is pressed.
    driverController.faceRight().onTrue(hatchMechanism.grabHatchCommand());
    // Release the hatch when the Square button is pressed.
    driverController.faceLeft().onTrue(hatchMechanism.releaseHatchCommand());
    // While holding R1, drive at half speed
    driverController
        .rightBumper()
        .onTrue(Command.noRequirements(_ -> robotDrive.setMaxOutput(0.5)).named("Set half speed"))
        .onFalse(Command.noRequirements(_ -> robotDrive.setMaxOutput(1)).named("Set full speed"));
  }

  /**
   * This method is called every 20 ms, no matter the mode. Use this for items like diagnostics
   * that you want ran during disabled, autonomous, teleoperated and test.
   *
   * <p>This runs after the mode specific periodic methods, but before LiveWindow and
   * SmartDashboard integrated updating.
   */
  @Override
  public void robotPeriodic() {
    // Runs the scheduler.  This is responsible for polling buttons, running scheduled commands,
    // and removing finished or interrupted commands.
    // This must be called from the robot's periodic block in order for anything in the
    // Command-based framework to work.
    Scheduler.getDefault().run();
    Telemetry.log("Drivetrain", robotDrive);
    Telemetry.log("HatchMechanism", hatchMechanism);
  }

  /** This method is called once each time the robot enters Disabled mode. */
  @Override
  public void disabledInit() {}

  @Override
  public void disabledPeriodic() {}

  /** This autonomous runs the autonomous command selected by the {@link #autonomousChooser}. */
  @Override
  public void autonomousInit() {
    Command autonomousCommand = autonomousChooser.getSelected();

    // Schedule the autonomous command.
    // Because we schedule this command in the autonomous mode, it will be automatically canceled
    // when the autonomous mode ends.
    if (autonomousCommand != null) {
      Scheduler.getDefault().schedule(autonomousCommand);
    }
  }

  /** This method is called periodically during autonomous. */
  @Override
  public void autonomousPeriodic() {}

  @Override
  public void teleopInit() {}

  /** This method is called periodically during operator control. */
  @Override
  public void teleopPeriodic() {}

  @Override
  public void utilityInit() {
    // Cancel all running commands at the start of utility mode.
    Scheduler.getDefault().cancelAll();
  }

  /** This method is called periodically during utility mode. */
  @Override
  public void utilityPeriodic() {}
}

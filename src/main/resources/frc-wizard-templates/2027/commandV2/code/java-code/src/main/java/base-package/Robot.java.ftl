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

<#if data.getIncludeKotlinSupport()>
import org.wpilib.hardware.hal.HAL;
</#if>
import org.wpilib.command2.Command;
import org.wpilib.command2.CommandScheduler;
import org.wpilib.framework.TimedRobot;

/**
 * The methods in this class are called automatically corresponding to each mode, as described in
 * the TimedRobot documentation. If you change the name of this class or the package after creating
 * this project, you must also update the Main.java file in the project.
 */
public class ${data.robotClassSimpleName} extends TimedRobot {
  private Command autonomousCommand;

  private final RobotContainer robotContainer;

  /**
   * This constructor is run when the robot is first started up and should be used for any
   * initialization code.
   */
  public Robot() {
<#if data.getIncludeKotlinSupport()>
    // Report the use of Kotlin for "FRC Usage Report" statistics.
    // Please only remove if you remove *all* use of Kotlin from the robot.
    HAL.reportUsage("Language", "Kotlin");
</#if>
    // Instantiate our RobotContainer.  This will perform all our button bindings, and put our
    // autonomous chooser on the dashboard.
    robotContainer = new RobotContainer();
  }

  /**
   * This method is called every 20 ms, no matter the mode. Use this for items like diagnostics
   * that you want ran during disabled, autonomous, teleoperated and utility.
   *
   * <p>This runs after the mode specific periodic methods, but before LiveWindow and
   * SmartDashboard integrated updating.
   */
  @Override
  public void robotPeriodic() {
    // Runs the Scheduler.  This is responsible for polling buttons, adding newly-scheduled
    // commands, running already-scheduled commands, removing finished or interrupted commands,
    // and running subsystem periodic() methods.  This must be called from the robot's periodic
    // block in order for anything in the Command-based framework to work.
    CommandScheduler.getInstance().run();
  }

  /** This method is called once each time the robot enters Disabled mode. */
  @Override
  public void disabledInit() {}

  @Override
  public void disabledPeriodic() {}

  /** This autonomous runs the autonomous command selected by your {@link RobotContainer} class. */
  @Override
  public void autonomousInit() {
    autonomousCommand = robotContainer.getAutonomousCommand();

    // schedule the autonomous command (example)
    if (autonomousCommand != null) {
      CommandScheduler.getInstance().schedule(autonomousCommand);
    }
  }

  /** This method is called periodically during autonomous. */
  @Override
  public void autonomousPeriodic() {}

  @Override
  public void autonomousExit() {
    // This makes sure that the autonomous stops running when
    // autonomous mode ends. If you want the autonomous to
    // continue until interrupted by another command, remove
    // this line or comment it out.
    if (autonomousCommand != null) {
      autonomousCommand.cancel();
    }
  }

  /** This method is called once each time the robot enters operator control. */
  @Override
  public void teleopInit() {}

  /** This method is called periodically during operator control. */
  @Override
  public void teleopPeriodic() {}

  @Override
  public void utilityInit() {
    // Cancels all running commands at the start of utility mode.
    CommandScheduler.getInstance().cancelAll();
  }

  /** This method is called periodically during utility mode. */
  @Override
  public void utilityPeriodic() {}

  /** This method is called once when the robot is first started up. */
  @Override
  public void simulationInit() {}

  /** This method is called periodically whilst in simulation. */
  @Override
  public void simulationPeriodic() {}
}

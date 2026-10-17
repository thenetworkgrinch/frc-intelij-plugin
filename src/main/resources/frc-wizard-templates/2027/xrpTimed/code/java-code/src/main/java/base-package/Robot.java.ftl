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
import org.wpilib.framework.TimedRobot;
import org.wpilib.tunable.Selectable;
import org.wpilib.tunable.Tunables;

/**
 * The methods in this class are called automatically corresponding to each mode, as described in
 * the TimedRobot documentation. If you change the name of this class or the package after creating
 * this project, you must also update the Main.java file in the project.
 */
public class ${data.robotClassSimpleName} extends TimedRobot {
  private static final String DEFAULT_AUTO = "Default";
  private static final String CUSTOM_AUTO = "My Auto";
  private String autoSelected;
  private final Selectable<String> chooser = new Selectable<>();

  private final XRPDrivetrain drivetrain = new XRPDrivetrain();

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
    chooser.addDefault("Default Auto", DEFAULT_AUTO);
    chooser.add("My Auto", CUSTOM_AUTO);
    Tunables.publish("Auto choices", chooser);
  }

  /**
   * This method is called every 20 ms, no matter the mode. Use this for items like diagnostics
   * that you want ran during disabled, autonomous, teleoperated and utility.
   *
   * <p>This runs after the mode specific periodic methods, but before LiveWindow and
   * SmartDashboard integrated updating.
   */
  @Override
  public void robotPeriodic() {}

  /**
   * This autonomous (along with the chooser code above) shows how to select between different
   * autonomous modes using the dashboard. The sendable chooser code works with the Java
   * SmartDashboard. If you prefer the LabVIEW Dashboard, remove all of the chooser code and
   * uncomment the getString line to get the auto name from the text box below the Gyro
   *
   * <p>You can add additional auto modes by adding additional comparisons to the switch structure
   * below with additional strings. If using Selectable make sure to add them to the chooser code
   * above as well.
   */
  @Override
  public void autonomousInit() {
    autoSelected = chooser.getSelected();
    // autoSelected = SmartDashboard.getString("Auto Selector", DEFAULT_AUTO);
    System.out.println("Auto selected: " + autoSelected);

    drivetrain.resetEncoders();
  }

  /** This method is called periodically during autonomous. */
  @Override
  public void autonomousPeriodic() {
    switch (autoSelected) {
      case CUSTOM_AUTO:
        // Put custom auto code here
        break;
      case DEFAULT_AUTO:
      default:
        // Put default auto code here
        break;
    }
  }

  /** This method is called once when teleop is enabled. */
  @Override
  public void teleopInit() {}

  /** This method is called periodically during operator control. */
  @Override
  public void teleopPeriodic() {}

  /** This method is called once when the robot is disabled. */
  @Override
  public void disabledInit() {}

  /** This method is called periodically when disabled. */
  @Override
  public void disabledPeriodic() {}

  /** This method is called once when utility mode is enabled. */
  @Override
  public void utilityInit() {}

  /** This method is called periodically during utility mode. */
  @Override
  public void utilityPeriodic() {}
}

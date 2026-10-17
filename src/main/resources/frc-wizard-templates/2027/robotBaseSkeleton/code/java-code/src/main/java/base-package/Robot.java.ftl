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
import org.wpilib.driverstation.RobotState;
import org.wpilib.driverstation.internal.DriverStationBackend;
import org.wpilib.framework.RobotBase;
import org.wpilib.hardware.hal.ControlWord;
import org.wpilib.hardware.hal.RobotMode;
import org.wpilib.internal.DriverStationModeThread;
import org.wpilib.util.WPIUtilJNI;

/**
 * This class is run automatically. If you change the name of this class or the package after
 * creating this project, you must also update the Main.java file in the project.
 */
public class ${data.robotClassSimpleName} extends RobotBase {
<#if data.getIncludeKotlinSupport()>
  public Robot() {
    // Report the use of Kotlin for "FRC Usage Report" statistics.
    // Please only remove if you remove *all* use of Kotlin from the robot.
    HAL.reportUsage("Language", "Kotlin");
  }
<#else>
  public Robot() {}
</#if>

  public void disabled() {}

  public void autonomous() {}

  public void teleop() {}

  public void utility() {}

  private volatile boolean exit;

  @Override
  public void startCompetition() {
    // Create an opmode per robot mode
    RobotState.addOpMode(RobotMode.AUTONOMOUS, "Auto");
    RobotState.addOpMode(RobotMode.TELEOPERATED, "Teleop");
    RobotState.addOpMode(RobotMode.UTILITY, "Utility");
    RobotState.publishOpModes();

    final ControlWord word = new ControlWord();
    DriverStationModeThread modeThread = new DriverStationModeThread(word);

    int event = WPIUtilJNI.makeEvent(false, false);

    DriverStationBackend.provideRefreshedDataEventHandle(event);

    // Tell the DS that the robot is ready to be enabled
    DriverStationBackend.observeUserProgramStarting();

    while (!Thread.currentThread().isInterrupted() && !exit) {
      DriverStationBackend.refreshControlWordFromCache(word);
      modeThread.inControl(word);
      if (isDisabled()) {
        disabled();
        while (isDisabled()) {
          try {
            WPIUtilJNI.waitForObject(event);
          } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
          }
        }
      } else if (isAutonomous()) {
        autonomous();
        while (isAutonomousEnabled()) {
          try {
            WPIUtilJNI.waitForObject(event);
          } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
          }
        }
      } else if (isUtility()) {
        utility();
        while (isUtility() && isEnabled()) {
          try {
            WPIUtilJNI.waitForObject(event);
          } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
          }
        }
      } else {
        teleop();
        while (isTeleopEnabled()) {
          try {
            WPIUtilJNI.waitForObject(event);
          } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
          }
        }
      }
    }

    DriverStationBackend.removeRefreshedDataEventHandle(event);
    modeThread.close();
  }

  @Override
  public void endCompetition() {
    exit = true;
  }
}

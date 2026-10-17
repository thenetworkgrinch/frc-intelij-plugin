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
import org.wpilib.command3.Scheduler;
import org.wpilib.command3.button.CommandGamepad;
import org.wpilib.framework.OpModeRobot;
import ${data.basePackage}.constants.DriverConstants;
import ${data.basePackage}.mechanisms.ExampleMechanism;

public class ${data.robotClassSimpleName} extends OpModeRobot {
  final ExampleMechanism exampleMechanism = new ExampleMechanism();
  final CommandGamepad exampleController =
      new CommandGamepad(DriverConstants.DRIVER_CONTROLLER_PORT);

<#if data.getIncludeKotlinSupport()>
  public Robot() {
    // Report the use of Kotlin for "FRC Usage Report" statistics.
    // Please only remove if you remove *all* use of Kotlin from the robot.
    HAL.reportUsage("Language", "Kotlin");
  }
<#else>
  public Robot() {}
</#if>

  @Override
  public void robotPeriodic() {
    Scheduler.getDefault().run();
  }
}

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

/**
 * The run() method is called automatically when the robot is enabled. If you change the name of
 * this class or the package after creating this project, you must also update the Main.java file in
 * the project.
 */
public class ${data.robotClassSimpleName} extends EducationalRobot {
  /**
   * This constructor is run when the robot is first started up and should be used for any
   * initialization code.
   */
<#if data.getIncludeKotlinSupport()>
  public Robot() {
    // Report the use of Kotlin for "FRC Usage Report" statistics.
    // Please only remove if you remove *all* use of Kotlin from the robot.
    HAL.reportUsage("Language", "Kotlin");
  }
<#else>
  public Robot() {}
</#if>

  /** This method is run when the robot is enabled. */
  @Override
  public void run() {}
}

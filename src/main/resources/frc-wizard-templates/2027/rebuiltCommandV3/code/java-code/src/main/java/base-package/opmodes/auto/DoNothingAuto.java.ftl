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

package ${data.basePackage}.opmodes.auto;

import ${data.basePackage}.Robot;
import org.wpilib.opmode.Autonomous;
import org.wpilib.opmode.OpMode;

@Autonomous
public class DoNothingAuto implements OpMode {
  /**
   * Creates a new autonomous opmode that does nothing. This constructor is called automatically by
   * the OpModeRobot framework when the program starts up.
   *
   * @param robot The robot instance to control.
   */
  public DoNothingAuto(Robot robot) {
    // Robot mechanisms have idle default commands, so we don't need to do anything special
  }
}

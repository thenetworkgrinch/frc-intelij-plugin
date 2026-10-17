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

import org.wpilib.opmode.Autonomous;
import org.wpilib.opmode.OpMode;

@Autonomous
public class ExampleAuto implements OpMode {
  public ExampleAuto(Robot robot) {
    robot.exampleMechanism.exampleCondition.whileTrue(robot.exampleMechanism.exampleCommand());
  }
}

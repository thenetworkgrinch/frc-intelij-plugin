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

package ${data.basePackage}.opmode;

import org.wpilib.opmode.Autonomous;
import org.wpilib.opmode.PeriodicOpMode;
import ${data.basePackage}.Robot;

@Autonomous(name = "My Auto", group = "Group 1")
public class MyAuto extends PeriodicOpMode {
  private final Robot robot;

  /** The Robot instance is passed into the opmode via the constructor. */
  public MyAuto(Robot robot) {
    this.robot = robot;
  }

  /*
   * This method runs periodically, using the same period as the Robot instance.
   *
   * Additional periodic methods may be configured with addPeriodic(),
   * which can have periods that differ from the main Robot instance.
   */
  @Override
  public void periodic() {
    // Put custom auto code here
  }
}

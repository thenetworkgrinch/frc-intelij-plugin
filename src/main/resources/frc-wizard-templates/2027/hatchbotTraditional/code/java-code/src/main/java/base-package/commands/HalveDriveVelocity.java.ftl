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

package ${data.basePackage}.commands;

import org.wpilib.command2.Command;
import ${data.basePackage}.subsystems.DriveSubsystem;

public class HalveDriveVelocity extends Command {
  private final DriveSubsystem drive;

  public HalveDriveVelocity(DriveSubsystem drive) {
    this.drive = drive;
  }

  @Override
  public void initialize() {
    drive.setMaxOutput(0.5);
  }

  @Override
  public void end(boolean interrupted) {
    drive.setMaxOutput(1);
  }
}

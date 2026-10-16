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

import ${data.basePackage}.subsystems.HatchSubsystem;
import edu.wpi.first.wpilibj2.command.InstantCommand;



/** A command that releases the hatch. */
public class ReleaseHatch extends InstantCommand
{
    public ReleaseHatch(HatchSubsystem subsystem)
    {
        super(subsystem::releaseHatch, subsystem);
    }
}

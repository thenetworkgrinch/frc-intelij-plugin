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
import edu.wpi.first.wpilibj2.command.Command;



/**
 * A simple command that grabs a hatch with the {@link HatchSubsystem}. Written explicitly for
 * pedagogical purposes. Actual code should inline a command this simple with {@link
 * edu.wpi.first.wpilibj2.command.InstantCommand}.
 */
public class GrabHatch extends Command
{
    // The subsystem the command runs on
    private final HatchSubsystem hatchSubsystem;
    
    
    public GrabHatch(HatchSubsystem subsystem)
    {
        hatchSubsystem = subsystem;
        addRequirements(hatchSubsystem);
    }
    
    
    @Override
    public void initialize()
    {
        hatchSubsystem.grabHatch();
    }
    
    
    @Override
    public boolean isFinished()
    {
        return true;
    }
}

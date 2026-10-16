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

import ${data.basePackage}.subsystems.Drivetrain;
import edu.wpi.first.wpilibj2.command.SequentialCommandGroup;



public class AutonomousTime extends SequentialCommandGroup
{
    /**
     * Creates a new Autonomous Drive based on time. This will drive out for a period of time, turn
     * around for time (equivalent to time to turn around) and drive forward again. This should mimic
     * driving out, turning around and driving back.
     *
     * @param drivetrain The drive subsystem on which this command will run
     */
    public AutonomousTime(Drivetrain drivetrain)
    {
        addCommands(
                new DriveTime(-0.6, 2.0, drivetrain),
                new TurnTime(-0.5, 1.3, drivetrain),
                new DriveTime(-0.6, 2.0, drivetrain),
                new TurnTime(0.5, 1.3, drivetrain));
    }
}
